-- HUD: the whole Brainrot Bay interface, built in code on a ScreenGui over
-- the 3D world. Top-right money (kept clear of Roblox's top-left menu
-- buttons), a shop listing the brainrots riding the conveyor, base buttons
-- for rebirth / upgrade / lock, a carry banner, a tsunami warning banner
-- and a notification feed. Every button fires one server RemoteEvent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local Config = require(ReplicatedStorage.Shared.Config)
local CarryState = require(script.Parent.CarryState)
local SoundClient = require(script.Parent.SoundClient)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBayGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function makeLabel(parent, name, text, size, position, textSize, colour)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = colour or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.3
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position, colour)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = colour
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.GothamBold
	button.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	button.Parent = parent
	return button
end

-- Top-right money panel (top-left corner stays clear for Roblox's menu).
local moneyPanel = Instance.new("Frame")
moneyPanel.Name = "MoneyPanel"
moneyPanel.AnchorPoint = Vector2.new(1, 0)
moneyPanel.Position = UDim2.new(1, -12, 0, 12)
moneyPanel.Size = UDim2.fromOffset(280, 86)
moneyPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
moneyPanel.BackgroundTransparency = 0.25
moneyPanel.BorderSizePixel = 0
moneyPanel.Parent = gui
local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 10)
moneyCorner.Parent = moneyPanel

local moneyLabel = makeLabel(moneyPanel, "MoneyLabel", "$100", UDim2.new(1, -16, 0, 40), UDim2.new(0, 8, 0, 4), 30, Color3.fromRGB(120, 255, 120))
local incomeLabel = makeLabel(moneyPanel, "IncomeLabel", "Place brainrots on your base to earn /s", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 46), 15, Color3.fromRGB(200, 200, 200))
local rebirthLabel = makeLabel(moneyPanel, "RebirthLabel", "Rebirth 0  |  x1.0 income", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 66), 14, Color3.fromRGB(255, 220, 90))

-- Title, top-centre.
local titleLabel = makeLabel(gui, "TitleLabel", "🌊 BRAINROT BAY 🌊", UDim2.fromOffset(300, 36), UDim2.new(0.5, -150, 0, 8), 28, Color3.fromRGB(255, 220, 90))
titleLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Tsunami warning banner, centre-top under the title, hidden until a wave.
local tsunamiBanner = Instance.new("Frame")
tsunamiBanner.Name = "TsunamiBanner"
tsunamiBanner.AnchorPoint = Vector2.new(0.5, 0)
tsunamiBanner.Position = UDim2.new(0.5, 0, 0, 52)
tsunamiBanner.Size = UDim2.fromOffset(520, 44)
tsunamiBanner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
tsunamiBanner.BackgroundTransparency = 0.15
tsunamiBanner.BorderSizePixel = 0
tsunamiBanner.Visible = false
tsunamiBanner.Parent = gui
local tsunamiCorner = Instance.new("UICorner")
tsunamiCorner.CornerRadius = UDim.new(0, 10)
tsunamiCorner.Parent = tsunamiBanner
local tsunamiLabel = makeLabel(tsunamiBanner, "TsunamiLabel", "", UDim2.new(1, -16, 1, 0), UDim2.new(0, 8, 0, 0), 20, Color3.fromRGB(255, 255, 255))
tsunamiLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Shop panel, left side: brainrots currently riding the conveyor.
local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.Position = UDim2.new(0, 12, 0, 120)
shopPanel.Size = UDim2.fromOffset(300, 380)
shopPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
shopPanel.BackgroundTransparency = 0.25
shopPanel.BorderSizePixel = 0
shopPanel.Parent = gui
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 10)
shopCorner.Parent = shopPanel
makeLabel(shopPanel, "ShopTitle", "🛒 CONVEYOR SHOP", UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 0, 6), 20, Color3.fromRGB(255, 220, 90))
makeLabel(shopPanel, "ShopHint", "Walk to the belt and press E, or buy here:", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 34), 13, Color3.fromRGB(200, 200, 200))

local shopList = Instance.new("Frame")
shopList.Name = "ShopList"
shopList.Position = UDim2.new(0, 8, 0, 58)
shopList.Size = UDim2.new(1, -16, 1, -66)
shopList.BackgroundTransparency = 1
shopList.Parent = shopPanel

-- Base panel, right side under the money: rebirth, upgrade, lock, sell.
local basePanel = Instance.new("Frame")
basePanel.Name = "BasePanel"
basePanel.AnchorPoint = Vector2.new(1, 0)
basePanel.Position = UDim2.new(1, -12, 0, 110)
basePanel.Size = UDim2.fromOffset(280, 210)
basePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
basePanel.BackgroundTransparency = 0.25
basePanel.BorderSizePixel = 0
basePanel.Parent = gui
local baseCorner = Instance.new("UICorner")
baseCorner.CornerRadius = UDim.new(0, 10)
baseCorner.Parent = basePanel
makeLabel(basePanel, "BaseTitle", "🏠 MY BASE", UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 0, 6), 20, Color3.fromRGB(120, 200, 255))

local rebirthButton = makeButton(basePanel, "RebirthButton", "✨ REBIRTH", UDim2.new(1, -16, 0, 40), UDim2.new(0, 8, 0, 42), Color3.fromRGB(180, 90, 220))
local upgradeButton = makeButton(basePanel, "UpgradeButton", "⬆️ UPGRADE BASE", UDim2.new(1, -16, 0, 40), UDim2.new(0, 8, 0, 90), Color3.fromRGB(40, 140, 90))
local lockButton = makeButton(basePanel, "LockButton", "🔒 LOCK BASE (60s)", UDim2.new(1, -16, 0, 40), UDim2.new(0, 8, 0, 138), Color3.fromRGB(60, 90, 180))
makeLabel(basePanel, "BaseHint", "Rebirth resets money + brainrots\nfor a permanent +50% income.", UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 0, 182), 13, Color3.fromRGB(200, 200, 200))

-- Carry banner, bottom-centre: shows while carrying a bought brainrot.
local carryBanner = Instance.new("Frame")
carryBanner.Name = "CarryBanner"
carryBanner.AnchorPoint = Vector2.new(0.5, 1)
carryBanner.Position = UDim2.new(0.5, 0, 1, -16)
carryBanner.Size = UDim2.fromOffset(460, 56)
carryBanner.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
carryBanner.BackgroundTransparency = 0.15
carryBanner.BorderSizePixel = 0
carryBanner.Visible = false
carryBanner.Parent = gui
local carryCorner = Instance.new("UICorner")
carryCorner.CornerRadius = UDim.new(0, 10)
carryCorner.Parent = carryBanner
local carryLabel = makeLabel(carryBanner, "CarryLabel", "", UDim2.new(0.6, 0, 1, 0), UDim2.new(0, 12, 0, 0), 18, Color3.fromRGB(255, 255, 255))
local placeButton = makeButton(carryBanner, "PlaceButton", "📍 PLACE (E)", UDim2.fromOffset(140, 40), UDim2.new(1, -152, 0, 8), Color3.fromRGB(40, 160, 60))

-- Notification feed, bottom-left.
local feedPanel = Instance.new("Frame")
feedPanel.Name = "FeedPanel"
feedPanel.Position = UDim2.new(0, 12, 1, -140)
feedPanel.Size = UDim2.fromOffset(340, 124)
feedPanel.BackgroundTransparency = 1
feedPanel.Parent = gui
local feedLabel = makeLabel(feedPanel, "FeedLabel", "", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 15, Color3.fromRGB(255, 255, 255))
feedLabel.TextYAlignment = Enum.TextYAlignment.Bottom

local feedLines = {}
local function pushFeed(text, colour)
	table.insert(feedLines, 1, text)
	if #feedLines > 5 then
		table.remove(feedLines)
	end
	feedLabel.Text = table.concat(feedLines, "\n")
	feedLabel.TextColor3 = colour or Color3.fromRGB(255, 255, 255)
end

-- Remotes the HUD talks to.
local moneyChanged = ReplicatedStorage:WaitForChild("MoneyChanged", 10)
local notifyEvent = ReplicatedStorage:WaitForChild("Notify", 10)
local tsunamiEvent = ReplicatedStorage:WaitForChild("TsunamiWarning", 10)
local carryEvent = ReplicatedStorage:WaitForChild("CarryBrainrot", 10)
local stealEvent = ReplicatedStorage:WaitForChild("StealStarted", 10)
local rebirthChanged = ReplicatedStorage:WaitForChild("RebirthChanged", 10)
local listConveyor = ReplicatedStorage:WaitForChild("ListConveyor", 10)

local currentMoney = Config.StartMoney

local function refreshMoneyLabels()
	moneyLabel.Text = Config.formatMoney(currentMoney)
end

if moneyChanged then
	moneyChanged.OnClientEvent:Connect(function(money, _lifetime, rebirthLevel, _upgradeLevel)
		currentMoney = money
		refreshMoneyLabels()
		if rebirthLevel then
			rebirthLabel.Text = "Rebirth " .. rebirthLevel .. "  |  x" .. string.format("%.1f", 1 + rebirthLevel * 0.5) .. " income"
		end
	end)
end

if notifyEvent then
	notifyEvent.OnClientEvent:Connect(function(text, colour)
		pushFeed(text, colour)
	end)
end

if rebirthChanged then
	rebirthChanged.OnClientEvent:Connect(function(level, multiplier)
		rebirthLabel.Text = "Rebirth " .. level .. "  |  x" .. string.format("%.1f", multiplier) .. " income"
		pushFeed("✨ Rebirth " .. level .. "! Income x" .. string.format("%.1f", multiplier) .. " forever!", Color3.fromRGB(255, 220, 90))
		SoundClient.play("Rebirth")
	end)
end

if tsunamiEvent then
	tsunamiEvent.OnClientEvent:Connect(function(secondsLeft, message)
		tsunamiBanner.Visible = true
		tsunamiLabel.Text = message
		if secondsLeft and secondsLeft > 0 then
			SoundClient.play("TsunamiWarning")
			task.delay(secondsLeft, function()
				if tsunamiBanner.Visible then
					tsunamiLabel.Text = "🌊 TSUNAMI! RUN TO HIGH GROUND!"
				end
			end)
		end
		task.delay(20, function()
			tsunamiBanner.Visible = false
		end)
	end)
end

if carryEvent then
	carryEvent.OnClientEvent:Connect(function(recordId, characterId, mutation)
		CarryState.setCarried(recordId, characterId, mutation)
		local character = Catalog.getCharacter(characterId)
		carryLabel.Text = "Carrying: " .. (character and character.Name or "?") .. " (" .. mutation .. ") — run to your base!"
		carryBanner.Visible = true
		SoundClient.play("Buy")
	end)
end

if stealEvent then
	stealEvent.OnClientEvent:Connect(function(_characterId, _mutation)
		SoundClient.play("StealAlarm")
	end)
end

-- Shop refresh: ask the server what is riding the belt, rebuild the rows.
local function refreshShop()
	if not listConveyor then
		return
	end
	local ok, list = pcall(function()
		return listConveyor:InvokeServer()
	end)
	if not ok or not list then
		return
	end
	-- Cheapest first, so a new player sees what they can afford at once.
	table.sort(list, function(a, b)
		return a.Cost < b.Cost
	end)
	for _, child in ipairs(shopList:GetChildren()) do
		child:Destroy()
	end
	for i, item in ipairs(list) do
		if i > 5 then
			break
		end
		local row = Instance.new("Frame")
		row.Name = "ShopRow"
		row.Size = UDim2.new(1, 0, 0, 56)
		row.Position = UDim2.new(0, 0, 0, (i - 1) * 60)
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		row.BackgroundTransparency = 0.2
		row.BorderSizePixel = 0
		row.Parent = shopList
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row

		local rarityColour = Catalog.getRarityColour(item.Rarity)
		makeLabel(row, "ItemName", item.Name, UDim2.new(0.62, 0, 0, 22), UDim2.new(0, 8, 0, 2), 16, Color3.fromRGB(255, 255, 255))
		local rarityLabel = makeLabel(row, "ItemRarity", item.Rarity .. (item.Mutation ~= "Normal" and (" | " .. item.Mutation) or ""), UDim2.new(0.62, 0, 0, 18), UDim2.new(0, 8, 0, 26), 13, rarityColour)
		rarityLabel.TextStrokeTransparency = 0.3
		makeLabel(row, "ItemStats", Config.formatMoney(item.Cost) .. "  •  " .. Config.formatMoney(item.IncomePerSecond) .. "/s", UDim2.new(0.62, 0, 0, 16), UDim2.new(0, 8, 0, 40), 13, Color3.fromRGB(120, 255, 120))

		local buyButton = makeButton(row, "BuyButton", "BUY", UDim2.fromOffset(72, 40), UDim2.new(1, -80, 0, 8), Color3.fromRGB(40, 160, 60))
		buyButton.TextSize = 16
		local itemId = item.Id
		buyButton.MouseButton1Click:Connect(function()
			SoundClient.play("Click")
			local buyEvent = ReplicatedStorage:WaitForChild("BuyBrainrot", 5)
			if buyEvent then
				buyEvent:FireServer(itemId)
			end
		end)
	end
	if #list == 0 then
		makeLabel(shopList, "EmptyLabel", "Belt is empty — next brainrot\nrides in any second...", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0), 15, Color3.fromRGB(200, 200, 200))
	end
	refreshMoneyLabels()
end

task.spawn(function()
	while true do
		refreshShop()
		task.wait(2)
	end
end)

-- Base buttons.
rebirthButton.MouseButton1Click:Connect(function()
	SoundClient.play("Click")
	local event = ReplicatedStorage:WaitForChild("RequestRebirth", 5)
	if event then
		event:FireServer()
	end
end)

upgradeButton.MouseButton1Click:Connect(function()
	SoundClient.play("Click")
	local event = ReplicatedStorage:WaitForChild("BuyUpgrade", 5)
	if event then
		event:FireServer()
	end
end)

lockButton.MouseButton1Click:Connect(function()
	SoundClient.play("Click")
	local event = ReplicatedStorage:WaitForChild("LockBase", 5)
	if event then
		event:FireServer()
	end
end)

-- Place the carried brainrot on your base.
local function placeCarried()
	if not CarryState.isCarrying() then
		return
	end
	local recordId = CarryState.CarriedId
	CarryState.clearCarried()
	carryBanner.Visible = false
	SoundClient.play("Place")
	local event = ReplicatedStorage:WaitForChild("PlaceBrainrot", 5)
	if event then
		event:FireServer(recordId)
	end
end

placeButton.MouseButton1Click:Connect(placeCarried)

-- Game.client.luau calls this through the shared CarryState module; expose
-- the placer on the HUD's own module table via a BindableEvent for the E key.
local placeSignal = Instance.new("BindableEvent")
placeSignal.Name = "PlaceCarriedSignal"
placeSignal.Parent = gui
placeSignal.Event:Connect(placeCarried)

pushFeed("Welcome to Brainrot Bay! Buy a brainrot off the belt, carry it home.", Color3.fromRGB(255, 255, 255))
pushFeed("Watch for tsunamis — only your base platform is safe!", Color3.fromRGB(120, 200, 255))
refreshMoneyLabels()
SoundClient.listen()
