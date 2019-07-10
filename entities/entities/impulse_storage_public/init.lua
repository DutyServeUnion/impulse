AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel(impulse.Config.InventoryStoragePublicModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:DrawShadow(false)

    local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableMotion(false)
	end
end

function ENT:OnTakeDamage(dmg) 
	return false
end

function ENT:Use(activator, caller)
	if activator:IsPlayer() and activator:Alive() then
		net.Start("impulseInvStorageOpen")
		net.Send(activator)

		hook.Run("PlayerOpenStorage", activator, self)

		activator.currentStorage = self
	end
end

