-- Game.client: the player-side bootstrap for Brainrot Bay.
-- Replaces the starter's grey-square demo. It does three things: a short
-- opening camera sweep over the bay so the player sees the 3D world first,
-- the E key to place a carried brainrot (bound with ContextActionService,
-- so Roblox's default camera keys never swallow it), and the welcome
-- sounds. The HUD itself lives in HUD.client.luau.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CarryState = require(script.Parent.CarryState)

local player = Players.LocalPlayer

-- E places the brainrot you are carrying on your base.
local function onPlaceCarried(_actionName, inputState, _inputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if not CarryState.isCarrying() then
		return Enum.ContextActionResult.Pass
	end
	local gui = player:WaitForChild("PlayerGui"):FindFirstChild("BrainrotBayGui")
	local placeSignal = gui and gui:FindFirstChild("PlaceCarriedSignal")
	if placeSignal then
		placeSignal:Fire()
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("PlaceCarriedBrainrot", onPlaceCarried, false, Enum.KeyCode.E)

-- Opening sweep: fly the camera over the conveyor and the bases, then hand
-- control back to the player. Skipped if the player moves first.
local camera = Workspace.CurrentCamera
local function openingSweep()
	if not camera then
		return
	end
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local startPos = Vector3.new(-120, 45, -110)
	local endPos = Vector3.new(0, 30, 120)
	local lookAt = Vector3.new(0, 2, -40)
	local steps = 90
	for i = 1, steps do
		local t = i / steps
		camera.CFrame = CFrame.lookAt(startPos:Lerp(endPos, t), lookAt)
		task.wait(0.03)
		-- Player is moving; cut the sweep short after the opening beat.
		if i > 20 then
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.MoveDirection.Magnitude > 0 then
				break
			end
		end
	end
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = character:FindFirstChildOfClass("Humanoid")
end

task.spawn(openingSweep)
-- Sounds are owned by HUD.client.luau (SoundClient.listen), so this script
-- never listens for PlaySound itself: one listener, no double playback.
print("[Brainrot Bay] Client ready. Buy a brainrot, carry it home, get rich.")
