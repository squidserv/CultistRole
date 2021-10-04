AddCSLuaFile()

SWEP.HoldType = "normal"

local sName = "Shrine_Name"
if ConVarExists("ttt_cultist_shrine_name") then
    sName = GetConVar("ttt_cultist_shrine_name"):GetBool()
end

if CLIENT then
    SWEP.PrintName = sName
    SWEP.Slot = 6

    SWEP.ViewModelFOV = 10
    SWEP.DrawCrosshair = false

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "shrine_desc"
    };

    SWEP.Icon = "vgui/ttt/icon_health"

end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/props_c17/oildrum001_explosive.mdl"

local clipSize = 3
if ConVarExists("ttt_cultist_shrine_ammo") then
    print("clipsize")
    clipSize = GetConVar("ttt_cultist_shrine_ammo"):GetInt()
end

SWEP.Primary.ClipSize = clipSize
SWEP.Primary.DefaultClip = clipSize

SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1.0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 1.0

-- This is special equipment
SWEP.Kind = WEAPON_ROLE
SWEP.InLoadoutFor = { ROLE_CULTIST }
SWEP.CanBuy = { ROLE_CULTIST }
SWEP.LimitedStock = false
SWEP.WeaponID = AMMO_SHRINE

SWEP.AllowDrop = false
SWEP.NoSights = true

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:ShrineDrop()
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
    self:ShrineDrop()
end

local throwsound = Sound("Weapon_SLAM.SatchelThrow")

function SWEP:ShrineDrop()
    if SERVER then
        local ply = self:GetOwner()
        if not IsValid(ply) then return end

        -- TODO Keep planted property?
        --if self.Planted then return end

        local vsrc = ply:GetShootPos()
        local vang = ply:GetAimVector()
        local vvel = ply:GetVelocity()

        local vthrow = vvel + vang * 200

        local shrine = ents.Create("ttt_cult_shrine")

        if IsValid(shrine) then

            shrine:SetPos(vsrc + vang * 10)
            shrine:Spawn()

            -- Set shrine properties
            if ConVarExists("ttt_cultist_pledge_time") then
                print("pledgeTime")
                shrine:SetTimeToPledge(GetConVar("ttt_cultist_pledge_time"):GetInt())
            end

            if ConVarExists("ttt_cultist_pledge_health") then
                print("pledgeHealth")
                shrine:SetPledgeHealth(GetConVar("ttt_cultist_pledge_health"):GetInt())
            end

            shrine:SetPlacer(ply)

            shrine:PhysWake()
            local phys = shrine:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(vthrow)
            end

            -- Consume primary ammo
            self:SetClip1(self:Clip1()-1)
            if self:Clip1() == 0 then
                self:Remove()
            end

            for k, v in pairs(player.GetAll()) do
                if not v:IsTraitorTeam() and not v:IsDetectiveTeam() and not v:IsCultist() then
                    v:PrintMessage(HUD_PRINTCENTER, sName .. " calls to you...")
                end
            end

            -- TODO Keep planted property?
            --self.Planted = true
        end
    end

    self:EmitSound(throwsound)
end

function SWEP:Reload()
    return false
end

function SWEP:OnRemove()
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
        RunConsoleCommand("lastinv")
    end
end


--local first = false
--[[ if SERVER then
	function SWEP:Initialize()
		print("$$$$$$$ INITIALIZING SHRINE WEAPON: " .. GetConVar("ttt_cultist_shrine_ammo"):GetInt() .. "$$$$$$$$$$$")
		print(self.Primary.ClipSize)
		--self.Primary.ClipSize = 5
		--self.Primary.DefaultClip = 5
		--print(self.Primary.ClipSize)

		--self:SetClip1(GetConVar("ttt_cultist_shrine_ammo"):GetInt())
		--return self.BaseClass.Initialize(self)
	end
end
--[[ function SWEP:Think()
	if not first then
		first = true
		print(">>>>>  ".. GetConVar("ttt_cultist_shrine_ammo"):GetInt().. " <<<<<<<<<")
		self:SetClip1(GetConVar("ttt_cultist_shrine_ammo"):GetInt())
	end
end ]]
if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("shrine_help", nil, true)

        return self.BaseClass.Initialize(self)
    end
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawViewModel(false)
    end
    return true
end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModelTranslucent()
end

