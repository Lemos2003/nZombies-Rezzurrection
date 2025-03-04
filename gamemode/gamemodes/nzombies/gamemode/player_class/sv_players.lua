-- 

function nzPlayers.PlayerNoClip( ply, desiredState )
	if ply:Alive() and nzRound:InState( ROUND_CREATE ) then
		return ply:IsInCreative()
	end
end

function nzPlayers:FullSync( ply )
	-- A full sync module using the new rewrites
	if IsValid(ply) then
		ply:SendFullSync()
	end
end

local function initialSpawn( ply )
	timer.Simple(1, function()
		-- Fully Sync
		nzPlayers:FullSync( ply )
	end)
end

local function playerLeft( ply )
	-- this was previously hooked to PlayerDisconnected
	-- it will now detect leaving players via entity removed, to take kicking banning etc into account.
	if ply:IsPlayer() then
		ply:DropOut()
		if IsValid(ply.TimedUseEntity) then
			ply:StopTimedUse()
		end
	end
end

function GM:PlayerNoClip( ply, desiredState )
	return nzPlayers.PlayerNoClip(ply, desiredState)
end

hook.Add( "PlayerInitialSpawn", "nzPlayerInitialSpawn", initialSpawn )
hook.Add( "EntityRemoved", "nzPlayerLeft", playerLeft )

hook.Add("GetFallDamage", "nzFallDamage", function(ply, speed)
	if not IsValid(ply) then return end
	if ply:HasPerk("phd") then
		return 0
	end
	return (speed / 10)
end)

hook.Add("ScalePlayerDamage", "nzFriendlyFire", function(ply, hitgroup, dmginfo)
	if IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker():IsPlayer() then
		dmginfo:ScaleDamage(0)
		return true
	end
end)

hook.Add("PlayerShouldTakeDamage", "nzPlayerIgnoreDamage", function(ply, ent, dmg)
	if not ply:GetNotDowned() then
		return false
	end

	if dmg and ent:IsValidZombie() then
		if ply:HasPerk("whoswho") and ply:GetNW2Float("nz.ChuggaDelay") < CurTime() and (ply:Health() - dmg:GetDamage()) <= 0 then
			local available = ents.FindByClass("nz_spawn_zombie_special")
			local pos = ply:GetPos()
			local spawns = {}

			if IsValid(available[1]) then
				for k,v in pairs(available) do
					if v.link == nil or nzDoors:IsLinkOpened(v.link) then
						if v:IsSuitable() then
							table.insert(spawns, v)
						end
					end
				end
				if !IsValid(spawns[1]) then
					local pspawns = ents.FindByClass("player_spawns")
					if !IsValid(pspawns[1]) then
						ply:ChatPrint("Couldnt find an escape boss, sorry 'bout that.")
					else
						pos = pspawns[math.random(#pspawns)]:GetPos()
					end
				else
					pos = spawns[math.random(#spawns)]:GetPos()
				end
			else
				local pspawns = ents.FindByClass("player_spawns")
				if IsValid(pspawns[1]) then
					pos = pspawns[math.random(#pspawns)]:GetPos()
				end
			end

			ply:EmitSound("NZ.ChuggaBud.Sweet")
			ply:ViewPunch(Angle(-4, math.Rand(-6, 6), 0))
			ply:SetPos(pos)

			timer.Simple(0, function()
				if not IsValid(ply) then return end

				ply:SetPos(pos)
				ply:EmitSound("NZ.ChuggaBud.Teleport")
				ParticleEffect("bo3_qed_explode_1", ply:WorldSpaceCenter(), Angle(0,0,0))

				nzSounds:Play("WhosWhoLooper", ply)

				local damage = DamageInfo()
				damage:SetAttacker(ply)
				damage:SetInflictor(ply:GetActiveWeapon())
				damage:SetDamageType(DMG_MISSILEDEFENSE)

				for k, v in pairs(ents.FindInSphere(ply:WorldSpaceCenter(), 150)) do
					if v:IsNPC() or v:IsNextBot() then
						if v.NZBossType then continue end

						damage:SetDamage(75)
						damage:SetDamagePosition(v:WorldSpaceCenter())

						v:TakeDamageInfo(damage)
					end
				end
			end)

			ply:SetNW2Float("nz.ChuggaDelay", CurTime() + 180)
			return false
		end
	end

	if ent:IsValidZombie() and ply:HasPerk("widowswine") and ply:GetAmmoCount(GetNZAmmoID("grenade")) > 0 then
		for k, v in pairs(ents.FindInSphere(ply:GetPos(), ply:HasUpgrade("widowswine") and 300 or 200)) do
			if v:IsValidZombie() and v.BO3SpiderWeb then
				v:BO3SpiderWeb(10)
			end
		end

		local fx = EffectData()
		fx:SetOrigin(ply:GetPos())
		fx:SetEntity(ply)
		util.Effect("nz_spidernade_explosion", fx)

		local nade = GetNZAmmoID("grenade")
		ply:SetAmmo(ply:GetAmmoCount(nade) - 1, nade)

		return false
	end

	if ent:IsPlayer() then
		if ent == ply then
			return !ply:HasPerk("phd") and !ply.SELFIMMUNE
		else
			if ent:HasPerk("gum") then
				return true
			else
				return false
			end
		end
	end
end)

hook.Add("EntityTakeDamage", "nzPlayerTakeDamage", function(ply, dmginfo)
	if not IsValid(ply) then return end
	if not ply:IsPlayer() then return end

	local ent = dmginfo:GetAttacker()
	if IsValid(ent) and ent:GetClass() == "elemental_pop_effect_3" then
		dmginfo:SetAttacker(ent:GetAttacker())
		dmginfo:SetInflictor(ent:GetInflictor())

		if ply:IsPlayer() then
			dmginfo:SetDamage(0)
		end
	end

	if IsValid(ent) and ent:IsValidZombie() then
		if ply:HasPerk("winters") and (nzRound:InState(ROUND_CREATE) or ply:GetNW2Int("nz.WailCount", 0) > 0) and ply:GetNW2Float("nz.WailDelay", 0) < CurTime() and ply:Health() < ply:GetMaxHealth() then
			local freeze = ents.Create("winterswail_effect")
			freeze:SetPos(ply:WorldSpaceCenter())
			freeze:SetParent(ply)
			freeze:SetOwner(ply)
			freeze:SetAttacker(ply)
			freeze:SetInflictor(ply:GetActiveWeapon())
			freeze:SetAngles(Angle(0,0,0))
			freeze:Spawn()

			ply:SetNW2Float("nz.WailDelay", CurTime() + 30)
			ply:SetNW2Int("nz.WailCount", math.max(ply:GetNW2Int("nz.WailCount",0) - 1, 0))
		end

		if ply:HasPerk("tortoise") and (ply.GetShield and not IsValid(ply:GetShield())) then
			local dot = (ent:GetPos() - ply:GetPos()):Dot(ply:GetAimVector())

			if dot < 0 then
				local scale = math.Clamp(ply:GetNW2Int("nz.TortCount", 0) / 10, 0, 1)
				dmginfo:ScaleDamage(0.5 + (scale * 0.5))

				ply:SetNW2Int("nz.TortCount", ply:GetNW2Int("nz.TortCount",0) + 1)
				ply:SetNW2Float("nz.TortDelay", CurTime() + 10)
			end
		end
	end

	if dmginfo:IsDamageType(DMG_NERVEGAS) and ply:HasPerk("mask") then
		dmginfo:SetDamage(0)
	end

	if bit.band(dmginfo:GetDamageType(), bit.bor(DMG_BURN, DMG_SLOWBURN)) ~= 0 and ply:HasPerk("fire") then
		dmginfo:ScaleDamage(0)
	end

	if bit.band(dmginfo:GetDamageType(), bit.bor(DMG_RADIATION, DMG_POISON, DMG_SHOCK)) ~= 0 and ply:HasPerk("mask") then
		dmginfo:ScaleDamage(0.15)
	end

	if dmginfo:IsExplosionDamage() and ply:HasPerk("phd") then
		dmginfo:ScaleDamage(0)
		return false
	end

	if dmginfo:IsFallDamage() and ply:HasPerk("phd") then
		dmginfo:ScaleDamage(0)
		return false
	end
end)

hook.Add("PostEntityTakeDamage", "nzPostPlayerTakeDamage", function(ply, dmginfo, took)
	if not IsValid(ply) then return end
	if not ply:IsPlayer() then return end

	if took then
		ply:SetNW2Float("nz.LastHit", CurTime())
	end

	if took and ply:HasPerk("fire") and ply:GetNW2Float("nz.BurnDelay", 0) < CurTime() then
		local ent = dmginfo:GetAttacker()
		if IsValid(ent) and ent:IsValidZombie() then
			local fire = ents.Create("elemental_pop_effect_1")
			fire:SetPos(ply:WorldSpaceCenter())
			fire:SetParent(ply)
			fire:SetOwner(ply)
			fire:SetAttacker(ply)
			fire:SetInflictor(ply:GetActiveWeapon())
			fire:SetAngles(Angle(0,0,0))

			fire:Spawn()

			local time = (ply:HasUpgrade("fire") and 10 or 20) * math.max(ply:GetNW2Int("nz.BurnCount", 1), 1)
			ply:SetNW2Float("nz.BurnDelay", CurTime() + time)
			ply:SetNW2Int("nz.BurnCount", math.min(ply:GetNW2Int("nz.BurnCount", 0) + 1), 10)
		end
	end
end)

hook.Add("PlayerSpawn", "nzPlayerSpawnVars", function(ply, trans)
	ply:SetNW2Bool("nz.GinMod", false)
	ply:SetNW2Float("nz.DeadshotDecay", 1)

	ply:SetNW2Int("nz.TortDelay", 1)
	ply:SetNW2Int("nz.TortCount", 1)

	ply:SetNW2Int("nz.ZombShellDelay", 1)
	ply:SetNW2Int("nz.ZombShellCount", 0)

	ply:SetNW2Int("nz.EPopDelay", 1)
	ply:SetNW2Int("nz.EPopChance", 0)

	ply:SetNW2Int("nz.DeadshotChance", 0)

	ply:SetNW2Float("nz.BurnDelay", 1)
	ply:SetNW2Int("nz.BurnCount", 0)

	ply:SetNW2Int("nz.WailDelay", 1)
	ply:SetNW2Int("nz.WailCount", 3)
end)

hook.Add("PlayerDowned", "nzPlayerDown", function(ply)
	for key, perk in pairs(ply.OldPerks) do
		if tostring(perk) == "tortoise" then
			local damage = DamageInfo()
			damage:SetDamage(54000)
			damage:SetAttacker(ply)
			damage:SetInflictor(IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon() or ply)
			damage:SetDamageType(DMG_BLAST_SURFACE)

			for k, v in pairs(ents.FindInSphere(ply:GetPos(), 400)) do
				if v:IsValidZombie() and not v.NZBossType then
					damage:SetDamagePosition(v:EyePos())
					damage:SetDamageForce(v:GetUp()*8000 + (v:GetPos() - ply:GetPos()):GetNormalized()*10000)

					v:TakeDamageInfo(damage)
				end
			end

			util.ScreenShake(ply:GetPos(), 10, 255, 1.5, 600)

			ParticleEffect("grenade_explosion_01", ply:WorldSpaceCenter(), Angle(0,0,0))

			ply:EmitSound("Perk.Tortoise.Exp")
			ply:EmitSound("Perk.Tortoise.Exp_Firey")
			ply:EmitSound("Perk.Tortoise.Exp_Decay")

			break
		end
	end
end)

hook.Add("PlayerPostThink", "nzStatsResetPlayer", function(ply) //hopefully not too wastefull
	if ply:HasPerk("tortoise") then
		if ply:GetNW2Float("nz.TortDelay", 0) < CurTime() and ply:GetNW2Int("nz.TortCount", 0) > 0 then
			ply:SetNW2Int("nz.TortCount", 0)
		end
		if ply:GetNW2Float("nz.CherryDelay", 0) < CurTime() and ply:GetNW2Int("nz.CherryCount", 0) > 0 then
			ply:SetNW2Int("nz.CherryCount", 0)
		end
	end
end)

hook.Add("OnEntityCreated", "nodmglolfucku", function(ent)
	timer.Simple(0, function()
		if not IsValid(ent) then return end
		if ent:GetOwner():IsPlayer() then
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
			end
		end
	end)
end)

util.AddNetworkString("nz_WhosWhoTeleRequest")

net.Receive("nz_WhosWhoTeleRequest", function(len, ply)
	if ply:HasUpgrade("whoswho") and ply:GetNW2Float("nz.ChuggaTeleDelay",0) < CurTime() then
		local available = ents.FindByClass("nz_spawn_zombie_special")
		local pos = ply:GetPos()
		local spawns = {}

		if IsValid(available[1]) then
			for k,v in pairs(available) do
				if v.link == nil or nzDoors:IsLinkOpened(v.link) then
					if v:IsSuitable() then
						table.insert(spawns, v)
					end
				end
			end
			if !IsValid(spawns[1]) then
				local pspawns = ents.FindByClass("player_spawns")
				if !IsValid(pspawns[1]) then
					ply:ChatPrint("Couldnt find an escape boss, sorry 'bout that.")
				else
					pos = pspawns[math.random(#pspawns)]:GetPos()
				end
			else
				pos = spawns[math.random(#spawns)]:GetPos()
			end
		else
			local pspawns = ents.FindByClass("player_spawns")
			if IsValid(pspawns[1]) then
				pos = pspawns[math.random(#pspawns)]:GetPos()
			end
		end

		local moo = Entity(1) //if moo is ingame and host, 10% chance to just tp to him lol
		if ply:EntIndex() ~= moo:EntIndex() and moo:SteamID64() == "76561198162014458" and math.random(10) == 1 then
			pos = moo:GetPos()
		end

		ply:EmitSound("NZ.ChuggaBud.Sweet")
		ply:ViewPunch(Angle(-4, math.Rand(-6, 6), 0))
		ply:SetPos(pos)

		timer.Simple(0, function()
			if not IsValid(ply) then return end
			ply:SetPos(pos)
			ply:EmitSound("NZ.ChuggaBud.Teleport")
			ParticleEffect("bo3_qed_explode_1", ply:WorldSpaceCenter(), Angle(0,0,0))

			nzSounds:Play("WhosWhoLooper", ply)

			local damage = DamageInfo()
			damage:SetAttacker(ply)
			damage:SetInflictor(ply:GetActiveWeapon())
			damage:SetDamageType(DMG_MISSILEDEFENSE)

			for k, v in pairs(ents.FindInSphere(ply:GetPos(), 80)) do
				if v:IsNPC() or v:IsNextBot() then
					if v.NZBossType then continue end
					damage:SetDamage(75)
					damage:SetDamagePosition(v:WorldSpaceCenter())
					v:TakeDamageInfo(damage)
				end
			end
		end)

		ply:SetNW2Float("nz.ChuggaTeleDelay", CurTime() + 10)
	end
end)
