-- StealSystem: the steal mechanic that makes other players' bases matter.
-- Walk into another player's base, grab one of their brainrots, and carry
-- it home: if you get far enough from their plot before the carry timer
-- runs out, it is yours and it starts earning on your base instead. Bases
-- can be locked: a locked base cannot be stolen from until its cooldown
-- ends, and every steal attempt locks the victim's base, so a base can only
-- be hit once per cooldown. Stealing is the risk; the lock is the defence.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)

local StealSystem = {}

-- player -> { Victim, SlotIndex, CharacterId, Mutation, EndsAt }
local ActiveSteals = {}
local economy = nil
local baseManager = nil

function StealSystem.init(economyModule, baseManagerModule)
	economy = economyModule
	baseManager = baseManagerModule
end

-- Start a steal: lift a brainrot off the victim's base into the thief's arms.
function StealSystem.startSteal(thief, victim, slotIndex)
	if thief == victim then
		return false, "That is your own base!"
	end
	if not baseManager.getBase(victim) then
		return false, "That player has no base."
	end
	if baseManager.isLocked(victim) then
		return false, victim.Name .. "'s base is LOCKED for " .. baseManager.lockSecondsLeft(victim) .. "s!"
	end
	if ActiveSteals[thief] then
		return false, "You are already carrying a stolen brainrot!"
	end
	local base = baseManager.getBase(victim)
	local record = nil
	for _, slot in ipairs(base.Slots) do
		if slot.SlotIndex == slotIndex then
			record = slot
			break
		end
	end
	if not record then
		return false, "Nothing in that slot."
	end
	local character = Catalog.getCharacter(record.CharacterId)
	-- Lock the victim's base the moment the steal starts.
	baseManager.lockBase(victim)
	baseManager.removePlacedBrainrot(victim, slotIndex)
	if record.Model then
		record.Model:Destroy()
	end
	ActiveSteals[thief] = {
		Victim = victim,
		SlotIndex = slotIndex,
		CharacterId = record.CharacterId,
		Mutation = record.Mutation,
		EndsAt = os.clock() + Config.StealCarrySeconds,
	}
	economy.notify(victim, "⚠️ " .. thief.Name .. " is stealing your " .. (character and character.Name or "brainrot") .. "! Chase them!", Color3.fromRGB(255, 80, 80))
	economy.notify(thief, "RUN! Get " .. Config.StealEscapeDistance .. " studs from their base in " .. Config.StealCarrySeconds .. "s!", Color3.fromRGB(255, 220, 80))
	local stealEvent = ReplicatedStorage:FindFirstChild("StealStarted")
	if stealEvent then
		stealEvent:FireClient(thief, record.CharacterId, record.Mutation)
		stealEvent:FireClient(victim, record.CharacterId, record.Mutation)
	end
	return true, "Steal started!"
end

-- The thief made it: the brainrot is placed on the thief's base.
function StealSystem.completeSteal(thief)
	local steal = ActiveSteals[thief]
	if not steal then
		return false
	end
	ActiveSteals[thief] = nil
	local WorldBuilder = require(script.Parent.WorldBuilder)
	local placePos = baseManager.getPlotPosition(thief) or Vector3.new(0, 0, 60)
	local model = WorldBuilder.buildBrainrot(steal.CharacterId, steal.Mutation, placePos)
	if not model then
		return false
	end
	local ok, result = baseManager.placeBrainrot(thief, steal.CharacterId, steal.Mutation, model)
	if not ok then
		model:Destroy()
		economy.notify(thief, "Steal failed: " .. result, Color3.fromRGB(255, 120, 120))
		return false
	end
	local character = Catalog.getCharacter(steal.CharacterId)
	economy.notify(thief, "Stole " .. (character and character.Name or "a brainrot") .. "! It now earns for YOU.", Color3.fromRGB(120, 255, 120))
	return true
end

-- The carry timer ran out before the thief escaped: the brainrot snaps
-- back to the victim's base.
function StealSystem.failSteal(thief)
	local steal = ActiveSteals[thief]
	if not steal then
		return
	end
	ActiveSteals[thief] = nil
	local victim = steal.Victim
	local WorldBuilder = require(script.Parent.WorldBuilder)
	local placePos = baseManager.getPlotPosition(victim) or Vector3.new(0, 0, 60)
	local model = WorldBuilder.buildBrainrot(steal.CharacterId, steal.Mutation, placePos)
	if model then
		local ok = baseManager.placeBrainrot(victim, steal.CharacterId, steal.Mutation, model)
		if not ok then
			model:Destroy()
		end
	end
	economy.notify(thief, "Too slow! The brainrot snapped back to its owner.", Color3.fromRGB(255, 120, 120))
	economy.notify(victim, "Your brainrot snapped back home. Your base is safe!", Color3.fromRGB(120, 255, 120))
end

-- Every heartbeat: check each active steal for escape or timeout.
function StealSystem.checkSteals()
	for thief, steal in pairs(ActiveSteals) do
		local character = thief.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			StealSystem.failSteal(thief)
		elseif not baseManager.getBase(steal.Victim) then
			-- The victim left mid-steal: nothing to snap back to, so the
			-- brainrot is lost with them and the steal simply ends.
			ActiveSteals[thief] = nil
			economy.notify(thief, "Your victim left the game. The steal is over.", Color3.fromRGB(255, 120, 120))
		else
			local victimPos = baseManager.getPlotPosition(steal.Victim)
			local distance = victimPos and (root.Position - victimPos).Magnitude or 0
			if distance >= Config.StealEscapeDistance then
				StealSystem.completeSteal(thief)
			elseif os.clock() >= steal.EndsAt then
				StealSystem.failSteal(thief)
			end
		end
	end
end

-- The owner locks their own base on purpose (defence button in the HUD).
function StealSystem.lockOwnBase(player)
	if baseManager.isLocked(player) then
		return false, "Already locked for " .. baseManager.lockSecondsLeft(player) .. "s."
	end
	baseManager.lockBase(player)
	economy.notify(player, "Base locked for " .. Config.BaseLockCooldown .. "s. Nobody can steal from you!", Color3.fromRGB(120, 200, 255))
	return true, "Locked!"
end

-- Create the remotes the client uses to steal and to lock its base.
function StealSystem.createRemotes()
	local stealEvent = Instance.new("RemoteEvent")
	stealEvent.Name = "StealBrainrot"
	stealEvent.Parent = ReplicatedStorage
	stealEvent.OnServerEvent:Connect(function(thief, victimName, slotIndex)
		local victim = Players:FindFirstChild(victimName)
		if not victim then
			economy.notify(thief, "That player left.", Color3.fromRGB(255, 120, 120))
			return
		end
		local ok, message = StealSystem.startSteal(thief, victim, slotIndex)
		if not ok then
			economy.notify(thief, message, Color3.fromRGB(255, 120, 120))
		end
	end)

	local lockEvent = Instance.new("RemoteEvent")
	lockEvent.Name = "LockBase"
	lockEvent.Parent = ReplicatedStorage
	lockEvent.OnServerEvent:Connect(function(player)
		local ok, message = StealSystem.lockOwnBase(player)
		if not ok then
			economy.notify(player, message, Color3.fromRGB(255, 120, 120))
		end
	end)

	local startedEvent = Instance.new("RemoteEvent")
	startedEvent.Name = "StealStarted"
	startedEvent.Parent = ReplicatedStorage
end

-- Start the steal watchdog loop.
function StealSystem.start()
	StealSystem.createRemotes()
	task.spawn(function()
		while true do
			task.wait(0.2)
			StealSystem.checkSteals()
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	ActiveSteals[player] = nil
end)

return StealSystem
