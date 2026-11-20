-- SoundServer: the server side of the sound split. The server decides
-- WHEN a sound plays (a purchase, a steal, the tsunami warning) and fires
-- one RemoteEvent; the client owns the actual Sound objects and plays them.
-- No sound asset ids are baked into server code, so the split stays clean.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundServer = {}

local playSoundEvent = nil

-- Sound names the client knows how to play. Keep this list in sync with
-- the client's SoundClient table.
SoundServer.Sounds = {
	Buy = "Buy",
	Place = "Place",
	Coin = "Coin",
	StealAlarm = "StealAlarm",
	StealSuccess = "StealSuccess",
	TsunamiWarning = "TsunamiWarning",
	Rebirth = "Rebirth",
	Error = "Error",
	Click = "Click",
}

-- Create the remote the server uses to tell a client to play a sound.
function SoundServer.createRemotes()
	playSoundEvent = Instance.new("RemoteEvent")
	playSoundEvent.Name = "PlaySound"
	playSoundEvent.Parent = ReplicatedStorage
end

-- Play a named sound for one player. Unknown names are ignored, so a
-- stale call from another system can never error the server.
function SoundServer.playFor(player, soundName)
	if not SoundServer.Sounds[soundName] then
		return
	end
	if playSoundEvent then
		playSoundEvent:FireClient(player, soundName)
	end
end

-- Play a named sound for everyone in the game (tsunami, rebirth fanfare).
function SoundServer.playForAll(soundName)
	if not SoundServer.Sounds[soundName] then
		return
	end
	if playSoundEvent then
		playSoundEvent:FireAllClients(soundName)
	end
end

return SoundServer
