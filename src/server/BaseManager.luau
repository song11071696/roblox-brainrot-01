-- BaseManager: the 8 player base plots, and who owns which brainrot on them.
-- Each plot is a coloured floor in the 3D world with 6 slots. A brainrot
-- bought from the conveyor is carried to the owner's plot and placed in a
-- free slot, where it stands in the world and earns money every second.
-- Bases also have a lock: while locked, nobody can steal from that base.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)

local BaseManager = {}

-- player -> { Plot, Slots = { { CharacterId, Mutation, Model, SlotIndex } } }
local Bases = {}
-- player -> unix time when the lock cooldown ends
local LockUntil = {}

-- Plot centres, matching the floors built in default.project.json.
-- Row A (north, z = 60), row B (south, z = -90).
BaseManager.PlotPositions = {
	Vector3.new(-105, 0, 60),
	Vector3.new(-35, 0, 60),
	Vector3.new(35, 0, 60),
	Vector3.new(105, 0, 60),
	Vector3.new(-105, 0, -90),
	Vector3.new(-35, 0, -90),
	Vector3.new(35, 0, -90),
	Vector3.new(105, 0, -90),
}

BaseManager.PlotColours = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(90, 170, 255),
	Color3.fromRGB(120, 220, 90),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(180, 100, 255),
	Color3.fromRGB(255, 140, 200),
	Color3.fromRGB(90, 220, 220),
	Color3.fromRGB(255, 130, 60),
}

-- The 6 slot offsets inside a plot, two rows of three.
local SlotOffsets = {
	Vector3.new(-7, 0, -5),
	Vector3.new(0, 0, -5),
	Vector3.new(7, 0, -5),
	Vector3.new(-7, 0, 5),
	Vector3.new(0, 0, 5),
	Vector3.new(7, 0, 5),
}

-- Hand the next free plot to a joining player.
function BaseManager.assignPlot(player)
	local taken = {}
	for _, base in pairs(Bases) do
		taken[base.PlotIndex] = true
	end
	for i = 1, Config.PlotCount do
		if not taken[i] then
			Bases[player] = { PlotIndex = i, Slots = {} }
			LockUntil[player] = 0
			BaseManager.paintPlotSign(player)
			return i
		end
	end
	return nil -- server full: 8 plots taken
end

-- Colour the plot's sign with the owner's name so the world shows who lives there.
function BaseManager.paintPlotSign(player)
	local base = Bases[player]
	if not base then
		return
	end
	local plot = workspace:FindFirstChild("Plots")
	if not plot then
		return
	end
	local folder = plot:FindFirstChild("Plot" .. base.PlotIndex)
	if not folder then
		return
	end
	local sign = folder:FindFirstChild("OwnerSign")
	if sign then
		local label = sign:FindFirstChildOfClass("SurfaceGui")
		if label then
			local text = label:FindFirstChildOfClass("TextLabel")
			if text then
				text.Text = player.Name .. "'s Base"
				text.TextColor3 = BaseManager.PlotColours[base.PlotIndex]
			end
		end
	end
end

-- Forget a leaving player's base and clear their brainrots from the world.
function BaseManager.removeBase(player)
	local base = Bases[player]
	if base then
		for _, slot in ipairs(base.Slots) do
			if slot.Model then
				slot.Model:Destroy()
			end
		end
	end
	Bases[player] = nil
	LockUntil[player] = nil
end

function BaseManager.getBase(player)
	return Bases[player]
end

-- The world position of a plot centre.
function BaseManager.getPlotPosition(player)
	local base = Bases[player]
	if not base then
		return nil
	end
	return BaseManager.PlotPositions[base.PlotIndex]
end

-- All brainrots standing on a player's base (for Economy's payout tick).
function BaseManager.getPlacedBrainrots(player)
	local base = Bases[player]
	if not base then
		return {}
	end
	return base.Slots
end

-- First free slot index on this player's base, or nil when full.
function BaseManager.firstFreeSlot(player)
	local base = Bases[player]
	if not base then
		return nil
	end
	for i = 1, Config.SlotsPerPlot do
		local used = false
		for _, slot in ipairs(base.Slots) do
			if slot.SlotIndex == i then
				used = true
				break
			end
		end
		if not used then
			return i
		end
	end
	return nil
end

-- Callback injected at boot (by init.server.luau): when a Steal prompt on a
-- placed brainrot fires, this runs StealSystem.startSteal. Kept as a field
-- so BaseManager never has to require StealSystem (no require cycle).
BaseManager.onStealPrompt = nil

-- Place a brainrot model on the player's base in a free slot.
-- Returns true and the slot record, or false and a reason.
function BaseManager.placeBrainrot(player, characterId, mutation, model)
	local base = Bases[player]
	if not base then
		return false, "You have no base yet."
	end
	local slotIndex = BaseManager.firstFreeSlot(player)
	if not slotIndex then
		return false, "Your base is full! Rebirth or sell to make room."
	end
	local plotPos = BaseManager.PlotPositions[base.PlotIndex]
	local slotPos = plotPos + SlotOffsets[slotIndex]
	model:PivotTo(CFrame.new(slotPos + Vector3.new(0, 1.5, 0)))
	model.Parent = workspace
	local record = {
		CharacterId = characterId,
		Mutation = mutation,
		Model = model,
		SlotIndex = slotIndex,
	}
	-- In-world Steal prompt: hold E on someone else's brainrot to grab it.
	local character = Catalog.getCharacter(characterId)
	local WorldBuilder = require(script.Parent.WorldBuilder)
	local prompt = WorldBuilder.addPrompt(model, "Steal", character and character.Name or "Brainrot", 0.5)
	if prompt then
		prompt.Triggered:Connect(function(thief)
			if BaseManager.onStealPrompt then
				BaseManager.onStealPrompt(thief, player, slotIndex)
			end
		end)
	end
	table.insert(base.Slots, record)
	return true, record
end

-- Remove one placed brainrot from a base (stolen, or sold). Returns the record.
function BaseManager.removePlacedBrainrot(owner, slotIndex)
	local base = Bases[owner]
	if not base then
		return nil
	end
	for i, slot in ipairs(base.Slots) do
		if slot.SlotIndex == slotIndex then
			table.remove(base.Slots, i)
			return slot
		end
	end
	return nil
end

-- Sell a placed brainrot back for half its cost.
function BaseManager.sellBrainrot(player, slotIndex, economy)
	local base = Bases[player]
	if not base then
		return false, "You have no base yet."
	end
	local record = BaseManager.removePlacedBrainrot(player, slotIndex)
	if not record then
		return false, "Nothing in that slot."
	end
	local character = Catalog.getCharacter(record.CharacterId)
	if record.Model then
		record.Model:Destroy()
	end
	local refund = character and math.floor(character.Cost * Config.SellRefundFraction) or 0
	economy.addMoney(player, refund, false)
	return true, "Sold for " .. Config.formatMoney(refund) .. "."
end

-- Is this base locked against stealing right now?
function BaseManager.isLocked(player)
	local untilTime = LockUntil[player] or 0
	return os.time() < untilTime
end

-- Seconds left on the lock, or 0.
function BaseManager.lockSecondsLeft(player)
	local untilTime = LockUntil[player] or 0
	return math.max(0, untilTime - os.time())
end

-- Lock a base for the cooldown (after a steal, or when the owner locks it).
function BaseManager.lockBase(player)
	LockUntil[player] = os.time() + Config.BaseLockCooldown
end

-- How many brainrots (and how much income) a base holds, for the HUD.
function BaseManager.baseSummary(player)
	local base = Bases[player]
	if not base then
		return 0, 0
	end
	return #base.Slots, Config.SlotsPerPlot
end

Players.PlayerAdded:Connect(function(player)
	BaseManager.assignPlot(player)
end)

Players.PlayerRemoving:Connect(function(player)
	BaseManager.removeBase(player)
end)

return BaseManager
