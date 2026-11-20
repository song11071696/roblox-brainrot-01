-- CarryState: the one place the client keeps "what am I carrying right now".
-- HUD sets it when the server says a brainrot was bought; Game reads it
-- when the player presses E to place it. One table, one job.

local CarryState = {
	CarriedId = nil,
	CarriedCharacterId = nil,
	CarriedMutation = nil,
}

function CarryState.setCarried(recordId, characterId, mutation)
	CarryState.CarriedId = recordId
	CarryState.CarriedCharacterId = characterId
	CarryState.CarriedMutation = mutation
end

function CarryState.clearCarried()
	CarryState.CarriedId = nil
	CarryState.CarriedCharacterId = nil
	CarryState.CarriedMutation = nil
end

function CarryState.isCarrying()
	return CarryState.CarriedId ~= nil
end

-- The carried brainrot's record id, character id and mutation, or nils.
function CarryState.getCarried()
	return CarryState.CarriedId, CarryState.CarriedCharacterId, CarryState.CarriedMutation
end

return CarryState
