SWEP.Base = "tfa_melee_base"
SWEP.Category = "nZombies Knives"
SWEP.PrintName = "Naynay"
SWEP.Author		= "Laby" --Author Tooltip
SWEP.ViewModel = "models/weapons/nz_knives/c_knife_mw.mdl"
SWEP.WorldModel = "models/weapons/tfa_mw2019/knife/w_knife.mdl"
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 70
SWEP.UseHands = true
SWEP.HoldType = "knife"
SWEP.DrawCrosshair = true

SWEP.Primary.Directional = false

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.DisableIdleAnimations = true

SWEP.Secondary.CanBash = false
SWEP.Secondary.MaxCombo = 0
SWEP.Primary.MaxCombo = 0

SWEP.VMPos = Vector(0,0,0) --The viewmodel positional offset, constantly.  Subtract this from any other modifications to viewmodel position.

-- nZombies Stuff
SWEP.NZPreventBox		= true	-- If true, this gun won't be placed in random boxes GENERATED. Users can still place it in manually.
SWEP.NZTotalBlackList	= true	-- if true, this gun can't be placed in the box, even manually, and can't be bought off a wall, even if placed manually. Only code can give this gun.


SWEP.Offset = { --Procedural world model animation, defaulted for CS:S purposes.
        Pos = {
        Up = 0,
        Right = 1.2,
        Forward = 3,
        },
        Ang = {
		Up = -90,
        Right = 0,
        Forward = 90
        },
		Scale = 1
}

SWEP.Primary.Attacks = {
	{
		['act'] = ACT_VM_MISSCENTER, -- Animation; ACT_VM_THINGY, ideally something unique per-sequence
		['len'] = 16*5, -- Trace source; X ( +right, -left ), Y ( +forward, -back ), Z ( +up, -down )
		["src"] = Vector(0, 0, 0), -- Trace source; X ( +right, -left ), Y ( +forward, -back ), Z ( +up, -down )
		["dir"] = Vector(35, 0, 10), -- Trace direction/length; X ( +right, -left ), Y ( +forward, -back ), Z ( +up, -down )
		['dmg'] = 75, --This isn't overpowered enough, I swear!!
		["dmgtype"] = bit.bor(DMG_CRUSH),  --DMG_SLASH,DMG_CRUSH, etc.
		["delay"] = 4 / 23, --Delay
		['snd_delay'] = 3 / 23,
		['spr'] = true, --Allow attack while sprinting?
		['snd'] = "weapons/tfa_mw2019/knife/melee_attack_knife_plr_01.wav","weapons/tfa_mw2019/knife/melee_attack_knife_plr_02.wav","weapons/tfa_mw2019/knife/melee_attack_knife_plr_03.wav","weapons/tfa_mw2019/knife/melee_attack_knife_plr_04.wav","weapons/tfa_mw2019/knife/melee_attack_knife_plr_05.wav", -- Sound ID
		["viewpunch"] = Angle(0, 0, 0), --viewpunch angle
		["end"] = 1.6, --time before next attack
		["hull"] = 1, --Hullsize
		['hitflesh'] = "weapons/tfa_mw2019/knife/melee_character_knife_plr_01.wav","weapons/tfa_mw2019/knife/melee_character_knife_plr_02.wav","weapons/tfa_mw2019/knife/melee_character_knife_plr_03.wav","weapons/tfa_mw2019/knife/melee_character_knife_plr_04.wav","weapons/tfa_mw2019/knife/melee_character_knife_plr_05.wav",
		['hitworld'] ="weapons/tfa_mw2019/knife/melee_world_knife_cement_plr_01.wav", "weapons/tfa_mw2019/knife/melee_world_knife_cement_plr_02.wav"
	}
}
SWEP.SequenceRateOverride = {
	[ACT_VM_MISSCENTER] = 30 / 40
}

SWEP.ImpactDecal = "ManhackCut"


if CLIENT then
	SWEP.WepSelectIconCSO = Material("vgui/killicons/tfa_cso_mastercombatknife")
	SWEP.DrawWeaponSelection = TFA_CSO_DrawWeaponSelection
end
