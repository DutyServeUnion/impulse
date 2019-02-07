if SERVER then
	function opsGoto(ply, pos)
		ply:ExitVehicle()
		if not ply:Alive() then ply:Spawn() end

		ply:SetPos(impulse.FindEmptyPos(pos, {ply}, 600, 30, Vector(16, 16, 64)))
	end

	function opsBring(ply, target)
		if not target:IsBot() and target:GetActiveWeapon() and target:GetActiveWeapon():GetClass() == "weapon_physgun" and target:KeyDown(IN_ATTACK) then
			target:ConCommand("-attack")
		end

		target.lastPos = target:GetPos()
		opsGoto(target, ply:GetPos())
	end
end

local gotoCommand = {
    description = "Teleports yourself to the player specified.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local name = arg[1]
		local plyTarget = impulse.FindPlayer(name)

		if plyTarget and ply != plyTarget then
			opsGoto(ply, plyTarget:GetPos())
		else
			return ply:Notify("Could not find player: "..tostring(name))
		end
    end
}

impulse.RegisterChatCommand("/goto", gotoCommand)

local bringCommand = {
    description = "Teleports the player specified to your location.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local name = arg[1]
		local plyTarget = impulse.FindPlayer(name)

		if plyTarget and ply != plyTarget then
			opsBring(ply, plyTarget)
		else
			return ply:Notify("Could not find player: "..tostring(name))
		end
    end
}

impulse.RegisterChatCommand("/bring", bringCommand)

local returnCommand = {
    description = "Returns the player specified to their last location.",
    requiresArg = true,
    adminOnly = true,
    onRun = function(ply, arg, rawText)
        local name = arg[1]
		local plyTarget = impulse.FindPlayer(name)

		if plyTarget and ply != plyTarget then
			if plyTarget.lastPos then
				opsGoto(plyTarget, plyTarget.lastPos)
				plyTarget.lastPos = nil
			else
				return ply:Notify("No old position to return the player to.")
			end
		else
			return ply:Notify("Could not find player: "..tostring(name))
		end
    end
}

impulse.RegisterChatCommand("/return", returnCommand)