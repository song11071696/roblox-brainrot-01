-- Conveyor: the brainrot belt that feeds the whole game loop.
-- Every few seconds a new brainrot (rolled from the catalog, sometimes
-- mutated) spawns at the gate and rides the belt across the map in the 3D
-- world. A player walks up, sees its name/rarity/$-per-second label, and
-- buys it; the brainrot then hops off the belt into their hands and they
-- carry it to their base. Unbought brainrots fall off the far end and despawn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local WorldBuilder = require(script.Parent.WorldBuilder)

local Conveyor = {}

-- Riding brainrots: { CharacterId, Mutation, Model, PositionX, Bought }
local Riding = {}
-- Bought but not yet placed: id -> record (the belt copy is destroyed at buy)
local BoughtRecords = {}
local nextId = 0
local economy = nil
local baseManager = nil

-- The belt runs along X at this Z, on the floor.
Conveyor.BeltZ = -40
Conveyor.BeltY = 1
Conveyor.StartX = -80
Conveyor.EndX = 80

-- Set the systems the conveyor talks to. Called once at boot.
function Conveyor.init(economyModule, baseManagerModule)
	economy = economyModule
	baseManager = baseManagerModule
end

-- Spawn one brainrot at the gate and put it on the belt.
function Conveyor.spawnBrainrot()
	if #Riding >= Config.ConveyorMaxAlive then
		return nil
	end
	local character = Catalog.rollCharacter()
	local mutation = Catalog.rollMutation()
	nextId += 1
	local spawnPos = Vector3.new(Conveyor.StartX, Conveyor.BeltY, Conveyor.BeltZ)
	local model = WorldBuilder.buildBrainrot(character.Id, mutation, spawnPos)
	if not model then
		return nil
	end
	model.Parent = workspace
	local record = {
		Id = nextId,
		CharacterId = character.Id,
		Mutation = mutation,
		Model = model,
		X = Conveyor.StartX,
		Bought = false,
	}
	-- In-world Buy prompt: walk up to the belt and hold E on the brainrot.
	local prompt = WorldBuilder.addPrompt(model, "Buy", character.Name .. " - " .. Config.formatMoney(character.Cost), 0)
	if prompt then
		prompt.Triggered:Connect(function(player)
			local ok, message = Conveyor.buyBrainrot(player, record.Id)
			if not ok then
				economy.notify(player, message, Color3.fromRGB(255, 120, 120))
			end
		end)
	end
	table.insert(Riding, record)
	return record
end

-- Move every riding brainrot along the belt; despawn what reaches the end.
function Conveyor.stepBelt(dt)
	for i = #Riding, 1, -1 do
		local record = Riding[i]
		if record.Bought then
			table.remove(Riding, i)
		else
			record.X += Config.ConveyorSpeed * dt
			if record.X >= Conveyor.EndX then
				if record.Model then
					record.Model:Destroy()
				end
				table.remove(Riding, i)
			else
				local pos = Vector3.new(record.X, Conveyor.BeltY, Conveyor.BeltZ)
				-- The model can be destroyed by a buy in the same frame the
				-- belt steps, so never PivotTo a model that is gone.
				if record.Model then
					record.Model:PivotTo(CFrame.new(pos + Vector3.new(0, 1.5, 0)))
				end
			end
		end
	end
end

-- The brainrot nearest to a position on the belt, within reach.
function Conveyor.nearestBrainrot(position, maxDistance)
	local best = nil
	local bestDistance = maxDistance
	for _, record in ipairs(Riding) do
		if not record.Bought and record.Model then
			local distance = (record.Model:GetPivot().Position - position).Magnitude
			if distance < bestDistance then
				best = record
				bestDistance = distance
			end
		end
	end
	return best
end

-- Buy the brainrot with this id: charge the player, lift it off the belt,
-- and hand it to the client to carry to their base. Returns success + text.
function Conveyor.buyBrainrot(player, recordId)
	if not economy or not baseManager then
		return false, "Conveyor is still warming up."
	end
	local record = nil
	for _, candidate in ipairs(Riding) do
		if candidate.Id == recordId and not candidate.Bought then
			record = candidate
			break
		end
	end
	if not record then
		return false, "That brainrot already left the belt."
	end
	local character = Catalog.getCharacter(record.CharacterId)
	if not character then
		return false, "Unknown brainrot."
	end
	if not baseManager.getBase(player) then
		return false, "You have no base yet."
	end
	if not baseManager.firstFreeSlot(player) then
		return false, "Your base is full! Sell one or rebirth first."
	end
	if not economy.trySpend(player, character.Cost) then
		return false, "Need " .. Config.formatMoney(character.Cost) .. " for " .. character.Name .. "."
	end
	record.Bought = true
	-- Lift it off the belt at once: burst, destroy the belt copy, remember
	-- the purchase until the player places it on their base.
	local beltPosition = record.Model and record.Model:GetPivot().Position or Vector3.new(record.X, Conveyor.BeltY, Conveyor.BeltZ)
	WorldBuilder.playBuyBurst(beltPosition)
	if record.Model then
		record.Model:Destroy()
		record.Model = nil
	end
	for i, candidate in ipairs(Riding) do
		if candidate.Id == record.Id then
			table.remove(Riding, i)
			break
		end
	end
	BoughtRecords[record.Id] = record
	-- Tell the client to carry this brainrot; the client confirms placement
	-- with PlaceBrainrot once the player reaches their base.
	local carryEvent = ReplicatedStorage:FindFirstChild("CarryBrainrot")
	if carryEvent then
		carryEvent:FireClient(player, record.Id, record.CharacterId, record.Mutation)
	end
	economy.notify(player, "Bought " .. character.Name .. " for " .. Config.formatMoney(character.Cost) .. "! Carry it to your base.", Color3.fromRGB(120, 255, 120))
	return true, "Bought " .. character.Name .. "!"
end

-- The client reached its base with a bought brainrot: place it in a slot.
function Conveyor.placeCarriedBrainrot(player, recordId)
	local record = BoughtRecords[recordId]
	if not record then
		return false, "Nothing to place."
	end
	-- Rebuild the model fresh at the base (the belt copy was removed at buy).
	local placePos = baseManager.getPlotPosition(player) or Vector3.new(0, 0, 60)
	local model = WorldBuilder.buildBrainrot(record.CharacterId, record.Mutation, placePos)
	if not model then
		return false, "Could not build that brainrot."
	end
	-- Label it with its owner so visitors know whose it is.
	local head = model:FindFirstChild("Head")
	if head then
		local billboard = head:FindFirstChild("BrainrotLabel")
		if billboard then
			local ownerLabel = billboard:FindFirstChild("OwnerLabel")
			if ownerLabel then
				ownerLabel.Text = "Owner: " .. player.Name
			end
		end
	end
	local ok, result = baseManager.placeBrainrot(player, record.CharacterId, record.Mutation, model)
	if not ok then
		model:Destroy()
		return false, result
	end
	BoughtRecords[recordId] = nil
	local character = Catalog.getCharacter(record.CharacterId)
	economy.notify(player, character.Name .. " is earning " .. Config.formatMoney(Catalog.incomePerSecond(character, record.Mutation, economy.getRebirthMultiplier(player))) .. "/s on your base!", Color3.fromRGB(120, 255, 120))
	return true, "Placed!"
end

-- Create the RemoteEvents/Functions the client uses to buy and place.
function Conveyor.createRemotes()
	local buyEvent = Instance.new("RemoteEvent")
	buyEvent.Name = "BuyBrainrot"
	buyEvent.Parent = ReplicatedStorage
	buyEvent.OnServerEvent:Connect(function(player, recordId)
		local ok, message = Conveyor.buyBrainrot(player, recordId)
		if not ok then
			economy.notify(player, message, Color3.fromRGB(255, 120, 120))
		end
	end)

	local carryEvent = Instance.new("RemoteEvent")
	carryEvent.Name = "CarryBrainrot"
	carryEvent.Parent = ReplicatedStorage

	local placeEvent = Instance.new("RemoteEvent")
	placeEvent.Name = "PlaceBrainrot"
	placeEvent.Parent = ReplicatedStorage
	placeEvent.OnServerEvent:Connect(function(player, recordId)
		local ok, message = Conveyor.placeCarriedBrainrot(player, recordId)
		if not ok then
			economy.notify(player, message, Color3.fromRGB(255, 120, 120))
		end
	end)

	-- The client asks which brainrots are riding, to show buy prompts.
	local listFunction = Instance.new("RemoteFunction")
	listFunction.Name = "ListConveyor"
	listFunction.Parent = ReplicatedStorage
	listFunction.OnServerInvoke = function(_player)
		local list = {}
		for _, record in ipairs(Riding) do
			if not record.Bought then
				local character = Catalog.getCharacter(record.CharacterId)
				table.insert(list, {
					Id = record.Id,
					CharacterId = record.CharacterId,
					Name = character and character.Name or "?",
					Rarity = character and character.Rarity or "Common",
					Cost = character and character.Cost or 0,
					IncomePerSecond = character and Catalog.incomePerSecond(character, record.Mutation, 1) or 0,
					Mutation = record.Mutation,
					X = record.X,
				})
			end
		end
		return list
	end
end

-- Start the spawn loop and the belt movement.
function Conveyor.start()
	Conveyor.createRemotes()
	task.spawn(function()
		while true do
			task.wait(Config.ConveyorSpawnInterval)
			Conveyor.spawnBrainrot()
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		Conveyor.stepBelt(dt)
	end)
	-- Two starters on the belt so the first player sees the loop at once.
	Conveyor.spawnBrainrot()
	Conveyor.spawnBrainrot()
end

return Conveyor
