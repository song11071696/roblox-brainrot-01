-- Economy: the one place player money lives.
-- Every other system asks Economy for a balance, a charge or a payout;
-- nobody keeps their own copy of a player's money. Money is earned by the
-- brainrots standing on a player's base, once a second, at each brainrot's
-- rate times the player's rebirth multiplier and upgrade bonus.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)

local Economy = {}

-- player -> { Money, LifetimeEarned, RebirthLevel, UpgradeLevel }
local Profiles = {}

local moneyChangedEvent = nil

function Economy.getMoneyChangedEvent()
	return moneyChangedEvent
end

-- Create the RemoteEvents the client listens to. Called once at boot.
function Economy.createRemotes()
	moneyChangedEvent = Instance.new("RemoteEvent")
	moneyChangedEvent.Name = "MoneyChanged"
	moneyChangedEvent.Parent = ReplicatedStorage

	local notify = Instance.new("RemoteEvent")
	notify.Name = "Notify"
	notify.Parent = ReplicatedStorage

	local rebirthEvent = Instance.new("RemoteEvent")
	rebirthEvent.Name = "RebirthChanged"
	rebirthEvent.Parent = ReplicatedStorage
end

-- Give a joining player a fresh profile and their starting cash.
function Economy.createProfile(player)
	Profiles[player] = {
		Money = Config.StartMoney,
		LifetimeEarned = 0,
		RebirthLevel = 0,
		UpgradeLevel = 0,
	}
	Economy.pushMoney(player)
	return Profiles[player]
end

-- Forget a leaving player's profile.
function Economy.removeProfile(player)
	Profiles[player] = nil
end

function Economy.getProfile(player)
	return Profiles[player]
end

function Economy.getMoney(player)
	local profile = Profiles[player]
	if not profile then
		return 0
	end
	return profile.Money
end

-- Lifetime earnings so far (drives the rebirth requirement).
function Economy.getLifetimeEarned(player)
	local profile = Profiles[player]
	if not profile then
		return 0
	end
	return profile.LifetimeEarned
end

-- The player's permanent income multiplier from rebirths.
function Economy.getRebirthMultiplier(player)
	local profile = Profiles[player]
	if not profile then
		return 1
	end
	return 1 + profile.RebirthLevel * Config.RebirthMultiplierPerLevel
end

-- The player's upgrade bonus: +10% income per upgrade level.
function Economy.getUpgradeMultiplier(player)
	local profile = Profiles[player]
	if not profile then
		return 1
	end
	return 1 + profile.UpgradeLevel * 0.1
end

-- Combined income multiplier for this player's brainrots.
function Economy.getIncomeMultiplier(player)
	return Economy.getRebirthMultiplier(player) * Economy.getUpgradeMultiplier(player)
end

-- Try to spend money. Returns true and deducts, or false and deducts nothing.
function Economy.trySpend(player, amount)
	local profile = Profiles[player]
	if not profile or profile.Money < amount then
		return false
	end
	profile.Money -= amount
	Economy.pushMoney(player)
	return true
end

-- Add money (payouts, refunds). LifetimeEarned only grows from earnings,
-- not from refunds, so pass countedAsEarnings = true for brainrot income.
function Economy.addMoney(player, amount, countedAsEarnings)
	local profile = Profiles[player]
	if not profile then
		return
	end
	profile.Money += amount
	if countedAsEarnings then
		profile.LifetimeEarned += amount
	end
	Economy.pushMoney(player)
end

-- Send the player's current money, rebirth level and upgrade level to the HUD.
function Economy.pushMoney(player)
	local profile = Profiles[player]
	if not profile or not moneyChangedEvent then
		return
	end
	moneyChangedEvent:FireClient(player, profile.Money, profile.LifetimeEarned, profile.RebirthLevel, profile.UpgradeLevel)
end

-- Tell one player something in their HUD feed.
function Economy.notify(player, text, colour)
	local notify = ReplicatedStorage:FindFirstChild("Notify")
	if notify then
		notify:FireClient(player, text, colour)
	end
end

-- The earnings tick: every brainrot on the player's base pays its rate.
-- baseManager is asked for the placed brainrots; it is passed in so this
-- module never requires the whole server tree at load time.
function Economy.payEarningsTick(baseManager)
	for player, profile in pairs(Profiles) do
		local placed = baseManager.getPlacedBrainrots(player)
		if placed then
			local total = 0
			for _, brainrot in ipairs(placed) do
				local character = Catalog.getCharacter(brainrot.CharacterId)
				if character then
					total += Catalog.incomePerSecond(character, brainrot.Mutation, Economy.getRebirthMultiplier(player))
				end
			end
			total = math.floor(total * Economy.getUpgradeMultiplier(player))
			if total > 0 then
				profile.Money += total
				profile.LifetimeEarned += total
				Economy.pushMoney(player)
			end
		end
	end
end

-- Start the once-a-second payout loop.
function Economy.startEarningsLoop(baseManager)
	task.spawn(function()
		while true do
			task.wait(Config.EconomyTickSeconds)
			Economy.payEarningsTick(baseManager)
		end
	end)
end

-- Wipe money and lifetime progress for a rebirth. Rebirth level is kept.
function Economy.resetForRebirth(player)
	local profile = Profiles[player]
	if not profile then
		return false
	end
	profile.Money = Config.StartMoney
	profile.LifetimeEarned = 0
	profile.UpgradeLevel = 0
	profile.RebirthLevel += 1
	Economy.pushMoney(player)
	local rebirthEvent = ReplicatedStorage:FindFirstChild("RebirthChanged")
	if rebirthEvent then
		rebirthEvent:FireClient(player, profile.RebirthLevel, Economy.getRebirthMultiplier(player))
	end
	return true
end

-- Cost of the next upgrade level on this player's base.
function Economy.nextUpgradeCost(player)
	local profile = Profiles[player]
	local level = profile and profile.UpgradeLevel or 0
	return math.floor(Config.UpgradeBaseCost * (Config.UpgradeCostGrowth ^ level))
end

-- Buy one upgrade level: +10% income on this base until rebirth.
function Economy.buyUpgrade(player)
	local profile = Profiles[player]
	if not profile then
		return false, "No profile yet."
	end
	if profile.UpgradeLevel >= Config.UpgradeMaxLevel then
		return false, "Upgrades maxed out!"
	end
	local cost = Economy.nextUpgradeCost(player)
	if profile.Money < cost then
		return false, "Need " .. Config.formatMoney(cost) .. " to upgrade."
	end
	profile.Money -= cost
	profile.UpgradeLevel += 1
	Economy.pushMoney(player)
	return true, "Base upgraded to level " .. profile.UpgradeLevel .. " (+10% income)!"
end

Players.PlayerAdded:Connect(function(player)
	Economy.createProfile(player)
end)

Players.PlayerRemoving:Connect(function(player)
	Economy.removeProfile(player)
end)

return Economy
