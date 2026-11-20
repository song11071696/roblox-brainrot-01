-- WorldBuilder: builds one brainrot character as a 3D model in the world.
-- Every character is a chunky little statue made of parts (a body, a head,
-- eyes, an accent hat or prop) so each of the 12 originals reads at a glance
-- on the conveyor and on a base. A floating BillboardGui label above it
-- shows its name, rarity colour, mutation and dollars per second.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local Config = require(ReplicatedStorage.Shared.Config)

local WorldBuilder = {}

-- Make the name/rarity/income label that floats over a brainrot.
function WorldBuilder.attachLabel(model, character, mutation, ownerName)
	local income = Catalog.incomePerSecond(character, mutation, 1)
	local head = model:FindFirstChild("Head")
	if not head then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotLabel"
	billboard.Size = UDim2.fromOffset(220, 70)
	billboard.StudsOffset = Vector3.new(0, 3.4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = character.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.BackgroundTransparency = 1
	local mutationText = mutation ~= "Normal" and (" | " .. mutation) or ""
	rarityLabel.Text = character.Rarity .. mutationText
	rarityLabel.TextColor3 = Catalog.getRarityColour(character.Rarity)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextStrokeTransparency = 0.2
	rarityLabel.Parent = billboard

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Position = UDim2.new(0, 0, 0.7, 0)
	incomeLabel.Size = UDim2.new(1, 0, 0.3, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = Config.formatMoney(income) .. "/s"
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.GothamBold
	incomeLabel.TextStrokeTransparency = 0.2
	incomeLabel.Parent = billboard

	-- Owner line: always present so the server can fill it in when the
	-- brainrot is placed on a base (nil owner = still on the conveyor).
	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.Name = "OwnerLabel"
	ownerLabel.Position = UDim2.new(0, 0, 1, 0)
	ownerLabel.Size = UDim2.new(1, 0, 0.25, 0)
	ownerLabel.BackgroundTransparency = 1
	ownerLabel.Text = ownerName and ("Owner: " .. ownerName) or ""
	ownerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ownerLabel.TextScaled = true
	ownerLabel.Font = Enum.Font.SourceSans
	ownerLabel.Parent = billboard
end

-- Build the 3D model for one character id with a mutation tint.
-- Returns the Model, anchored, standing on the given position.
function WorldBuilder.buildBrainrot(characterId, mutation, position)
	local character = Catalog.getCharacter(characterId)
	if not character then
		return nil
	end
	local scale = character.Scale or 1
	local mutationColour = Catalog.MutationColours[mutation] or Color3.fromRGB(255, 255, 255)

	local model = Instance.new("Model")
	model.Name = character.Name:gsub(" ", "") .. "_" .. mutation

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(3 * scale, 3 * scale, 2 * scale)
	body.Position = position + Vector3.new(0, 1.5 * scale, 0)
	body.Color = character.BodyColour
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2.6 * scale, 2.6 * scale, 2.6 * scale)
	head.Position = position + Vector3.new(0, 4.4 * scale, 0)
	head.Color = character.BodyColour
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	-- Eyes: two white balls with dark pupils, so the statue has a face.
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.7 * scale, 0.7 * scale, 0.4 * scale)
		eye.Position = position + Vector3.new(0.6 * scale * side, 4.7 * scale, 1.2 * scale)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model

		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Shape = Enum.PartType.Ball
		pupil.Size = Vector3.new(0.35 * scale, 0.35 * scale, 0.2 * scale)
		pupil.Position = position + Vector3.new(0.6 * scale * side, 4.7 * scale, 1.4 * scale)
		pupil.Color = Color3.fromRGB(20, 20, 20)
		pupil.Material = Enum.Material.SmoothPlastic
		pupil.Anchored = true
		pupil.CanCollide = false
		pupil.Parent = model
	end

	-- Accent prop: a little hat/crown in the character's accent colour.
	local prop = Instance.new("Part")
	prop.Name = "AccentProp"
	prop.Shape = Enum.PartType.Cylinder
	prop.Size = Vector3.new(1.2 * scale, 2.4 * scale, 2.4 * scale)
	prop.Position = position + Vector3.new(0, 6 * scale, 0)
	prop.Color = character.AccentColour
	prop.Material = Enum.Material.SmoothPlastic
	prop.Anchored = true
	prop.CanCollide = false
	prop.Parent = model

	-- Mutation glow: a point light in the mutation colour for Golden+,
	-- and a sparkle trail for Rainbow.
	if mutation ~= "Normal" then
		local light = Instance.new("PointLight")
		light.Name = "MutationGlow"
		light.Color = mutationColour
		light.Brightness = 2
		light.Range = 8
		light.Parent = body
	end
	if mutation == "Rainbow" then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "RainbowSparkles"
		sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 110, 220), Color3.fromRGB(120, 230, 255))
		sparkles.Rate = 12
		sparkles.Lifetime = NumberRange.new(0.6)
		sparkles.Speed = NumberRange.new(2)
		sparkles.Parent = head
	elseif mutation == "Golden" then
		-- Golden gets a gentler gold shimmer, so it reads as special
		-- without outshining Rainbow.
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "GoldenSparkles"
		sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 240, 160))
		sparkles.Rate = 6
		sparkles.Lifetime = NumberRange.new(0.5)
		sparkles.Speed = NumberRange.new(1.5)
		sparkles.Parent = head
	end

	model.PrimaryPart = body
	WorldBuilder.attachLabel(model, character, mutation, nil)
	return model
end

-- Add a ProximityPrompt to a brainrot model so players can act on it in the
-- 3D world (buy it off the belt, or steal it off a base). Returns the prompt.
function WorldBuilder.addPrompt(model, actionText, objectText, holdDuration)
	local body = model.PrimaryPart or model:FindFirstChild("Body")
	if not body then
		return nil
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BrainrotPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = holdDuration or 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	return prompt
end

-- Move a whole brainrot model so its feet sit at the new position.
function WorldBuilder.moveModel(model, position)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	local offset = primary.Position - model:GetPivot().Position
	model:PivotTo(CFrame.new(position + Vector3.new(0, 1.5, 0) + offset))
end

-- Small celebration burst when a brainrot is bought or placed.
function WorldBuilder.playBuyBurst(position)
	local burst = Instance.new("Part")
	burst.Name = "BuyBurst"
	burst.Shape = Enum.PartType.Ball
	burst.Size = Vector3.new(1, 1, 1)
	burst.Position = position + Vector3.new(0, 3, 0)
	burst.Color = Color3.fromRGB(255, 215, 0)
	burst.Material = Enum.Material.Neon
	burst.Anchored = true
	burst.CanCollide = false
	burst.Transparency = 0.3
	burst.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 120, 60))
	emitter.Rate = 60
	emitter.Lifetime = NumberRange.new(0.8)
	emitter.Speed = NumberRange.new(12)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = burst
	task.delay(1.2, function()
		burst:Destroy()
	end)
end

return WorldBuilder
