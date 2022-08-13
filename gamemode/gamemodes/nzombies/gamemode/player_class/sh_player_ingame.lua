DEFINE_BASECLASS( "player_default" )

local PLAYER = {}

--
-- See gamemodes/base/player_class/player_default.lua for all overridable variables
--
PLAYER.WalkSpeed 			= 200
PLAYER.Health 			= nzMapping.Settings.hp
PLAYER.RunSpeed				= 325
PLAYER.CanUseFlashlight     = true

function PLAYER:SetupDataTables()
	self.Player:NetworkVar("Bool", 0, "UsingSpecialWeapon")
end

function PLAYER:Init()
	-- Don't forget Colours
	-- This runs when the player is first brought into the game and when they die during a round and are brought back

end

if not ConVarExists("nz_failsafe_preventgrenades") then CreateConVar("nz_failsafe_preventgrenades", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY}) end

function PLAYER:Loadout()
	-- Give ammo and guns

	if nzMapping.Settings.startwep then
		self.Player:Give( nzMapping.Settings.startwep )
	else
		-- A setting does not exist, give default starting weapons
			self.Player:Give("robotnik_bo1_1911" )
	end
	self.Player:GiveMaxAmmo()

	if !GetConVar("nz_papattachments"):GetBool() and FAS2_Attachments != nil then
		for k,v in pairs(FAS2_Attachments) do
			self.Player:FAS2_PickUpAttachment(v.key)
		end
	end
	if nzMapping.Settings.knife then
		self.Player:Give( nzMapping.Settings.knife )
	else
		-- A setting does not exist, give default starting weapons
			self.Player:Give("nz_knife_boring" )
	end
	
	-- We need this to disable the grenades for those that it causes problems with until they've been remade :(
	if !GetConVar("nz_failsafe_preventgrenades"):GetBool() then
		self.Player:Give("nz_grenade")
	end

end
function PLAYER:Spawn()
	
	if nzMapping.Settings.startpoints then
		if !self.Player:CanAfford(nzMapping.Settings.startpoints) then
			self.Player:SetPoints(nzMapping.Settings.startpoints)
		end
	else
		if !self.Player:CanAfford(500) then -- Has less than 500 points
			-- Poor guy has no money, lets start him off
			self.Player:SetPoints(500)
		end
	end
	if nzMapping.Settings.hp then
	self.Player:SetHealth( nzMapping.Settings.hp )
	self.Player:SetMaxHealth( nzMapping.Settings.hp )
	else
	self.Player:SetHealth(100 )
	self.Player:SetMaxHealth( 100 )
	end
	-- Reset their perks
	self.Player:RemovePerks()
	nzPerks.PlayerUpgrades[self] = {}
	-- activate zombie targeting
	self.Player:SetTargetPriority(TARGET_PRIORITY_PLAYER)

	local spawns = ents.FindByClass("player_spawns")
	-- Get player number
	for k,v in pairs(player.GetAll()) do
		if v == self.Player then
			if IsValid(spawns[k]) then
				v:SetPos(spawns[k]:GetPos())
			else
				print("No spawn set for player: " .. v:Nick())
			end
		end
	end
	
	self.Player:SetUsingSpecialWeapon(false)
end

function PLAYER:OnTakeDamage( dmginfo )

			if dmginfo:IsDamageType( 64 ) and self.Player:HasPerk("phd")then
		dmginfo:ScaleDamage( 0 )
			end
			
			if  self.Player:HasPerk("mask")then
			if dmginfo:IsDamageType( 65536 ) or dmginfo:IsDamageType( 1048576 ) then
		dmginfo:ScaleDamage( 0 )
			end
			end
			if dmginfo:IsDamageType( 8388608 ) then
		dmginfo:ScaleDamage( 0 )
			end
			
			
			
			
			if (dmginfo:IsDamageType( 8 ) or dmginfo:IsDamageType( 2097152 )) and self.Player:HasPerk("fire")then
		dmginfo:ScaleDamage( 0 )
			end
			
end

player_manager.RegisterClass( "player_ingame", PLAYER, "player_default" )
