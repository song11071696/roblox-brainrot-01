-- Brainrot Bay server bootstrap: wire every system together and start the game.
-- One job: require the modules in dependency order, hand each system the
-- systems it talks to, then start the loops. State lives in Economy (money)
-- and BaseManager (plots); nothing else keeps its own copy of either.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(script.Economy)
local BaseManager = require(script.BaseManager)
local Conveyor = require(script.Conveyor)
local StealSystem = require(script.StealSystem)
local Tsunami = require(script.Tsunami)
local Rebirth = require(script.Rebirth)
local SoundServer = require(script.SoundServer)

print("[Brainrot Bay] Starting server...")

-- Sanity check: the world must hold exactly as many plot folders as the
-- config promises, or players would join with nowhere to build.
local plotsFolder = workspace:FindFirstChild("Plots")
if plotsFolder then
	local plotCount = 0
	for _, child in ipairs(plotsFolder:GetChildren()) do
		if child:IsA("Folder") then
			plotCount += 1
		end
	end
	if plotCount ~= Config.PlotCount then
		warn("[Brainrot Bay] Plot mismatch: world has " .. plotCount .. " plots, Config expects " .. Config.PlotCount)
	end
end

-- Remotes first, so clients connecting mid-boot can find them.
Economy.createRemotes()
SoundServer.createRemotes()

-- Hand each system the neighbours it needs.
Conveyor.init(Economy, BaseManager)
StealSystem.init(Economy, BaseManager)
Rebirth.init(Economy, BaseManager)
Rebirth.createRemotes()

-- Steal prompts on placed brainrots fire through this injection, so
-- BaseManager never requires StealSystem.
BaseManager.onStealPrompt = function(thief, victim, slotIndex)
	StealSystem.startSteal(thief, victim, slotIndex)
end

-- Start the loops: conveyor spawns and rides, earnings tick every second,
-- steal watchdog, tsunami cycle.
Conveyor.start()
Economy.startEarningsLoop(BaseManager)
StealSystem.start()
Tsunami.start()

print("[Brainrot Bay] Server ready: conveyor, 8 bases, steals, tsunami, rebirths.")
