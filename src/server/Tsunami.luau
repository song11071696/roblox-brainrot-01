-- Tsunami: the wave that sweeps Brainrot Bay on a timer.
-- Every couple of minutes the HUD warns "TSUNAMI INCOMING", a giant wall
-- of water rises at the far end of the map and rolls across it. Players
-- caught in the open take damage and get shoved toward the sea; players
-- standing on their base platform (the raised high ground at the back of
-- every plot) or on the spawn hill ride it out safe. The dash home is the
-- game's second threat, after stealing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local Tsunami = {}

local warningEvent = nil
local wavePart = nil
local waveActive = false
local waveX = 0

-- Build the wave itself: one huge translucent blue wall, hidden until it runs.
function Tsunami.buildWave()
	wavePart = Instance.new("Part")
	wavePart.Name = "TsunamiWave"
	wavePart.Size = Vector3.new(12, Config.TsunamiWaveHeight, 260)
	wavePart.Position = Vector3.new(-160, Config.TsunamiWaveHeight / 2, 0)
	wavePart.Color = Color3.fromRGB(30, 140, 255)
	wavePart.Material = Enum.Material.Neon
	wavePart.Transparency = 0.35
	wavePart.Anchored = true
	wavePart.CanCollide = false
	wavePart.Parent = workspace
end

-- Warn every player, then run the wave after the warning window.
function Tsunami.startCycle()
	task.spawn(function()
		while true do
			task.wait(Config.TsunamiInterval)
			Tsunami.warnAndStrike()
		end
	end)
end

function Tsunami.warnAndStrike()
	if warningEvent then
		warningEvent:FireAllClients(Config.TsunamiWarningSeconds, "🌊 TSUNAMI INCOMING! Get to your base platform or high ground!")
	end
	task.wait(Config.TsunamiWarningSeconds)
	Tsunami.strike()
end

-- Roll the wave from west to east across the whole map.
function Tsunami.strike()
	if waveActive then
		return
	end
	waveActive = true
	waveX = -160
	if warningEvent then
		warningEvent:FireAllClients(0, "🌊 TSUNAMI! RUN TO HIGH GROUND!")
	end
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		waveX += Config.TsunamiWaveSpeed * dt
		if wavePart then
			wavePart.Position = Vector3.new(waveX, Config.TsunamiWaveHeight / 2, 0)
		end
		Tsunami.sweepPlayers(waveX)
		if waveX >= 180 then
			connection:Disconnect()
			waveActive = false
			if wavePart then
				wavePart.Position = Vector3.new(-160, Config.TsunamiWaveHeight / 2, 0)
			end
			if warningEvent then
				warningEvent:FireAllClients(0, "The wave has passed. The bay is safe... for now.")
			end
		end
	end)
end

-- Anyone near the wave front, and not standing on high ground, takes
-- damage and gets shoved east. High ground = base platforms (y >= 8) or
-- the spawn hill (y >= 8).
function Tsunami.sweepPlayers(waveFrontX)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local onHighGround = root.Position.Y >= 8
			local nearWave = math.abs(root.Position.X - waveFrontX) < 14
			if nearWave and not onHighGround then
				humanoid:TakeDamage(Config.TsunamiDamage)
				root.AssemblyLinearVelocity = Vector3.new(Config.TsunamiKnockback, 20, 0)
			end
		end
	end
end

-- Is a wave running right now? (The client uses this for its warning banner.)
function Tsunami.isWaveActive()
	return waveActive
end

-- Create the warning remote and the wave, then start the cycle.
function Tsunami.start()
	warningEvent = Instance.new("RemoteEvent")
	warningEvent.Name = "TsunamiWarning"
	warningEvent.Parent = ReplicatedStorage
	Tsunami.buildWave()
	Tsunami.startCycle()
end

return Tsunami
