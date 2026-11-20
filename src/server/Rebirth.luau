-- Rebirth: the long climb. Spend your lifetime earnings to reset your
-- money and your brainrots and come back stronger: every rebirth adds a
-- permanent +50% income multiplier (up to level 10). The requirement grows
-- each time, so the first rebirth is a mid-game goal and the tenth is an
-- endgame one. Upgrades reset with it; the multiplier never does.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Rebirth = {}

local economy = nil
local baseManager = nil

function Rebirth.init(economyModule, baseManagerModule)
	economy = economyModule
	baseManager = baseManagerModule
end

-- Lifetime earnings needed to rebirth at the player's current level.
function Rebirth.requirementFor(player)
	local profile = economy.getProfile(player)
	local level = profile and profile.RebirthLevel or 0
	return math.floor(Config.RebirthBaseRequirement * (Config.RebirthRequirementGrowth ^ level))
end

-- Can this player rebirth right now?
function Rebirth.canRebirth(player)
	local profile = economy.getProfile(player)
	if not profile then
		return false
	end
	if profile.RebirthLevel >= Config.RebirthMaxLevel then
		return false, "Max rebirth level reached!"
	end
	if profile.LifetimeEarned < Rebirth.requirementFor(player) then
		return false, "Need " .. Config.formatMoney(Rebirth.requirementFor(player)) .. " lifetime earned to rebirth."
	end
	return true, "Ready!"
end

-- Do the rebirth: clear the base, reset money, raise the multiplier.
function Rebirth.doRebirth(player)
	local can, reason = Rebirth.canRebirth(player)
	if not can then
		return false, reason
	end
	-- Clear every brainrot off the player's base first.
	local base = baseManager.getBase(player)
	if base then
		for _, slot in ipairs(base.Slots) do
			if slot.Model then
				slot.Model:Destroy()
			end
		end
		base.Slots = {}
	end
	economy.resetForRebirth(player)
	local profile = economy.getProfile(player)
	local nextReq = Rebirth.requirementFor(player)
	economy.notify(player, "✨ REBIRTH " .. profile.RebirthLevel .. "! Your income is now x" .. string.format("%.1f", economy.getRebirthMultiplier(player)) .. " forever! Next rebirth: " .. Config.formatMoney(nextReq) .. " lifetime.", Color3.fromRGB(255, 220, 90))
	return true, "Reborn!"
end

-- Create the rebirth remote the HUD button calls.
function Rebirth.createRemotes()
	local rebirthEvent = Instance.new("RemoteEvent")
	rebirthEvent.Name = "RequestRebirth"
	rebirthEvent.Parent = ReplicatedStorage
	rebirthEvent.OnServerEvent:Connect(function(player)
		local ok, message = Rebirth.doRebirth(player)
		if not ok then
			economy.notify(player, message, Color3.fromRGB(255, 120, 120))
		end
	end)

	local upgradeEvent = Instance.new("RemoteEvent")
	upgradeEvent.Name = "BuyUpgrade"
	upgradeEvent.Parent = ReplicatedStorage
	upgradeEvent.OnServerEvent:Connect(function(player)
		local ok, message = economy.buyUpgrade(player)
		economy.notify(player, message, ok and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 120, 120))
	end)

	local sellEvent = Instance.new("RemoteEvent")
	sellEvent.Name = "SellBrainrot"
	sellEvent.Parent = ReplicatedStorage
	sellEvent.OnServerEvent:Connect(function(player, slotIndex)
		local ok, message = baseManager.sellBrainrot(player, slotIndex, economy)
		economy.notify(player, message, ok and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 120, 120))
	end)
end

return Rebirth
