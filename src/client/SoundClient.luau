-- SoundClient: the client side of the sound split. The server decides WHEN
-- a sound plays and fires the PlaySound RemoteEvent; this module owns the
-- Sound objects and plays them. All sounds are built-in Roblox assets, so
-- nothing here depends on an uploaded audio id.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundClient = {}

-- Built-in Roblox sound assets, one per game moment.
SoundClient.Sounds = {
	Buy = "rbxasset://sounds/electronicpingshort.wav",
	Place = "rbxasset://sounds/button.wav",
	Coin = "rbxasset://sounds/electronicpingshort.wav",
	StealAlarm = "rbxasset://sounds/impact_water.mp3",
	StealSuccess = "rbxasset://sounds/button.wav",
	TsunamiWarning = "rbxasset://sounds/impact_water.mp3",
	Rebirth = "rbxasset://sounds/electronicpingshort.wav",
	Error = "rbxasset://sounds/button.wav",
	Click = "rbxasset://sounds/button.wav",
}

local cache = {}
local volume = 0.7

-- Set the volume for every sound, including ones already built.
function SoundClient.setVolume(newVolume)
	volume = newVolume
	for _, sound in pairs(cache) do
		sound.Volume = volume
	end
end

-- Play one named sound. Missing names fail silently, never error.
function SoundClient.play(soundName)
	local assetId = SoundClient.Sounds[soundName]
	if not assetId then
		return
	end
	local sound = cache[soundName]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "BrainrotSound_" .. soundName
		sound.SoundId = assetId
		sound.Volume = volume
		sound.Parent = SoundService
		cache[soundName] = sound
	end
	sound:Play()
end

-- Listen for the server's PlaySound remote and play what it names.
function SoundClient.listen()
	local remote = ReplicatedStorage:WaitForChild("PlaySound", 10)
	if remote then
		remote.OnClientEvent:Connect(function(soundName)
			SoundClient.play(soundName)
		end)
	end
end

return SoundClient
