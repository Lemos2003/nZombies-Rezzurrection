
-- Copyright (c) 2018-2020 TFA Base Devs

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

AddCSLuaFile()

--[Info]--
ENT.Type = "anim"
ENT.PrintName = "Deadwire"
ENT.Spawnable = false
ENT.AdminOnly = false

--[Parameters]--
ENT.MaxChain = 8
ENT.ZapRange = 300

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Kills")

	self:NetworkVar("Entity", 0, "Target")
	self:NetworkVar("Entity", 1, "Attacker")
	self:NetworkVar("Entity", 2, "Inflictor")
end

function ENT:Initialize()
	self:SetParent(nil)
	self:SetModel("models/dav0r/hoverball.mdl")
	self:SetNoDraw(true)
	self:DrawShadow(false)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)

	self.killtime = CurTime() + 5
	self.TargetsToIgnore = {}

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end

	if CLIENT then return end
	self:StartChain()
end

function ENT:Think()
	if SERVER then
		if self.killtime < CurTime() then
			self:Remove()
			return false
		end
	end

	self:NextThink(CurTime())
	return true
end

function ENT:StartChain()
	self:EmitSound("TFA_BO3_WAFFE.Jump")
	self:EmitSound("TFA_BO3_WAFFE.Flux")
	ParticleEffect("bo3_waffe_impact", self:GetPos(), Angle(90,0,0))

	self:SetTarget(self:FindNearestEntity(self:GetPos(), self.TargetsToIgnore))

	if not IsValid(self:GetTarget()) then
		SafeRemoveEntity(self)
		return
	end

	self:Zap(self:GetTarget())
	self:SetKills(0)

	local timername = self:EntIndex().."wunderwaffetimer"
	timer.Create(timername, 0.2, self.MaxChain, function()
		if not IsValid(self) then
			timer.Stop(timername)
			timer.Remove(timername)
			return
		end

		self:SetTarget(self:FindNearestEntityCheap(self:GetPos(), self.TargetsToIgnore))

		if not IsValid(self:GetTarget()) then
			timer.Stop(timername)
			timer.Remove(timername)
			SafeRemoveEntity(self)
			return
		end

		self.ZapRange = self.ZapRange - 15
		self:Zap(self:GetTarget())

		self:SetKills(self:GetKills() + 1)
		if self:GetKills() >= self.MaxChain then
			timer.Stop(timername)
			timer.Remove(timername)
			SafeRemoveEntity(self)
			return
		end
	end)
end

function ENT:Zap(ent)
	local att = ent:GetAttachment(2) and ent:GetAttachment(2).Pos or ent:EyePos()

	local damage = DamageInfo()
	damage:SetDamageType(DMG_SHOCK)
	damage:SetDamage(ent:Health() + 666)
	damage:SetAttacker(IsValid(self:GetAttacker()) and self:GetAttacker() or self)
	damage:SetInflictor(IsValid(self:GetInflictor()) and self:GetInflictor() or self)
	damage:SetDamagePosition(ent:EyePos())
	damage:SetDamageForce(ent:GetUp())

	util.ParticleTracerEx("bo3_waffe_jump", self:GetPos(), att, false, self:GetOwner():EntIndex(), ent:EntIndex())

	ParticleEffectAttach("bo3_waffe_electrocute", PATTACH_POINT_FOLLOW, ent, 2)
	if ent:OnGround() then
		ParticleEffectAttach("bo3_waffe_ground", PATTACH_ABSORIGIN_FOLLOW, ent, 0)
	end
	if nzombies and ent:IsValidZombie() and not ent.IsMooSpecial then
		ParticleEffectAttach("bo3_waffe_eyes", PATTACH_POINT_FOLLOW, ent, 3)
		ParticleEffectAttach("bo3_waffe_eyes", PATTACH_POINT_FOLLOW, ent, 4)
	end

	ent:EmitSound("TFA_BO3_WAFFE.Sizzle")
	ent:EmitSound("NZ.POP.Deadwire.Die")
	ent:EmitSound("NZ.POP.Deadwire.Shock")

	self:SetPos(att)

	ent:TakeDamageInfo(damage)
	self.TargetsToIgnore[self:GetKills()] = ent
end

function ENT:FindNearestEntity(pos, tab)
	local nearbyents = {}
	for k, v in pairs(ents.FindInSphere(pos, self.ZapRange)) do
		if v:IsValidZombie() and v:Health() > 0 then
			if !table.HasValue(tab, v) then
				table.insert(nearbyents, v)
			end
		end
	end

	table.sort(nearbyents, function(a, b) return a:GetPos():DistToSqr(pos) < b:GetPos():DistToSqr(pos) end)
	return nearbyents[1]
end

function ENT:FindNearestEntityCheap(pos, tab)
	local nearestent
	for k, v in pairs(ents.FindInSphere(pos, self.ZapRange)) do
		if v:IsValidZombie() and v:Health() > 0 then
			if !table.HasValue(tab, v) then
				nearestent = v
				break
			end
		end
	end

	return nearestent
end
