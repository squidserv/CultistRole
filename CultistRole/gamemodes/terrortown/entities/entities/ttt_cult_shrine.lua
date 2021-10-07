---- Cult shrine

AddCSLuaFile()

if CLIENT then

    -- this entity can be DNA-sampled so we need some display info
    ENT.Icon = "vgui/ttt/icon_health"
    ENT.PrintName = "shrine_name"

    local GetPTranslation = LANG.GetParamTranslation

    ENT.TargetIDHint = {
        name = "shrine_name",
        hint = "shrine_hint",
        fmt  = function(ent, txt)
            return GetPTranslation(txt,
                    { usekey = Key("+use", "USE") } )
        end
    };

else
    util.AddNetworkString("TTT_CultPledged")
end

ENT.Type = "anim"
ENT.Model = Model("models/props_c17/oildrum001_explosive.mdl")

ENT.CanHavePrints = true

--Number of seconds before the user converts to the cult
local timeToPledge = 3
if ConVarExists("ttt_cultist_pledge_time") then
    timeToPledge = GetConVar("ttt_cultist_pledge_time"):GetInt()
end

local pledgeHealth = 105
if ConVarExists("ttt_cultist_pledge_health") then
    pledgeHealth = GetConVar("ttt_cultist_pledge_health"):GetInt()
end

ENT.TimeToPledge = timeToPledge
ENT.PledgeHealth = pledgeHealth
-- Note: A bunch of accessors probably only useful for data related
-- activity like the health remaining in the HS
AccessorFunc(ENT, "Placer", "Placer")
AccessorFunc(ENT, "TimeToPledge", "TimeToPledge")
AccessorFunc(ENT, "PledgeHealth", "PledgeHealth")

AccessorFuncDT(ENT, "NumOfConverts", "NumOfConverts")
AccessorFuncDT(ENT, "ConvertedNicks", "ConvertedNicks")
AccessorFuncDT(ENT, "Desecrated", "Desecrated")

AccessorFunc(ENT, "Placer", "Placer")

function ENT:SetupDataTables()
    self:DTVar("Int", 0, "NumOfConverts")
    self:DTVar("String", 1, "ConvertedNicks")
    self:DTVar("Bool", 2, "Desecrated")
end

STATE_NONE, STATE_PLEDGE = 0, 1


function ENT:Initialize()
    self:SetModel(self.Model)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_BBOX)

    local b = 32
    self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b,b,b))

    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    if SERVER then
        self:SetMaxHealth(400)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(200)
        end

        self:SetUseType(CONTINUOUS_USE)
    end
    self:SetHealth(400)

    self:SetColor(Color(130, 50, 200, 255))

    self:SetPlacer(nil)

    self:SetNumOfConverts(0)
    self:SetDesecrated(false)
    self.fingerprints = {}

    if CLIENT then
        local GetPTranslation = LANG.GetParamTranslation
        if LocalPlayer():IsDetectiveTeam() then
            self.TargetIDHint = {
                name = "shrine_name",
                hint = "shrine_hint_det",
                fmt  = function(ent, txt)
                    return GetPTranslation(txt,
                            { usekey = Key("+use", "USE"),
                              num = self:GetNumOfConverts() } )
                end
            };
        else
            self.TargetIDHint = {
                name = "shrine_name",
                hint = "shrine_hint",
                fmt  = function(ent, txt)
                    return GetPTranslation(txt,
                            { usekey = Key("+use", "USE") } )
                end
            };
        end
    end
end

local shrinesound = Sound("items/medshot4.wav")
local pledged = Sound("items/smallmedkit1.wav")

function ENT:Reset(ply)
    ply:SetNWInt("PledgeState", STATE_NONE)
    ply:SetNWFloat("PledgeTime", 0)
    ply:SetNWInt("TimeToPledge", 1)
    SendFullStateUpdate()
end

function ENT:Pledge(ply)
    self:Reset(ply)

    if not ply:IsDetectiveTeam() then
        --Inform the server a player converted to cult
        net.Start("TTT_CultPledged")
        net.WriteString(ply:Nick())
        net.Broadcast()

        --Set the pledged player to cult
        ply:SetCredits(0)
        ply:SetRole(ROLE_CULTIST)
        ply:StripRoleWeapons()
        -- Make sure they are activated
        ply:SetNWBool("ActivatedCultist", true)

        -- Only set health if the player's HP is less than the pledge Health
        -- i.e. bouncer can keep their health boost
        if ply:Health() < self.PledgeHealth then
            ply:SetHealth(self.PledgeHealth)
            ply:SetMaxHealth(self.PledgeHealth)
        end

        self:SetNumOfConverts(self:GetNumOfConverts() + 1)
        self:SetConvertedNicks(self:GetConvertedNicks() .. " " .. ply:Nick())

        local sName = "The Almighty One"
        if CRVersion("1.2.7") then
            sName = GetGlobalString("ttt_cultist_shrine_name")
        end
        ply:PrintMessage(HUD_PRINTCENTER, "You have pledged your life to " .. sName .. ". Your soul has been reborn!")

        for k, v in pairs(player.GetAll()) do
            if v:IsCultist() then
                v:PrintMessage(HUD_PRINTCENTER, ply:Nick() .. " has pledged their life to the cult!")
            end
        end

    else
        self:SetDesecrated(true)
        ply:PrintMessage(HUD_PRINTCENTER, "These terrorists have betrayed you: " .. self:GetConvertedNicks())
        ply:PrintMessage(HUD_PRINTTALK, "These terrorists have betrayed you: " .. self:GetConvertedNicks())
    end

    self:EmitSound(pledged)
    SendFullStateUpdate()
end

function ENT:Use(ply, caller, useType, value)
    -- Continue to let the client know the player is pledging
    ply:SetNWInt("Pledging", STATE_PLEDGE)
end

hook.Add( "PlayerUse", "hk_shrine_used_by_player", function( ply, ent )
    local convertT = true
    if ConVarExists("ttt_cultist_convert_traitor") then
        convertT = GetConVar("ttt_cultist_convert_traitor"):GetBool()
    end
    local convertJ = false
    if ConVarExists("ttt_cultist_convert_jester") then
        convertJ = GetConVar("ttt_cultist_convert_jester"):GetBool()
    end
    if IsValid(ent) and not ent:IsPlayer() and ent.TimeToPledge ~= nil
            and (convertT or not ply:IsTraitorTeam()) and (convertJ or not ply:IsJesterTeam()) and not ply:IsCultist()
            and (not ply:IsDetectiveTeam() or (ply:IsDetectiveTeam() and not ent:GetDesecrated()))  then

        -- If Pledging has been set by Use we know they are still holding down the button
        -- Or if the first time used (Use gets called second) we have to let it pass at least once)
        if ply:GetNWInt("Pledging") == STATE_PLEDGE or ply:GetNWInt("PledgeState") == STATE_NONE then
            -- Begin pledge
            if ply:GetNWInt("PledgeState") == STATE_NONE then
                ply:SetNWInt("PledgeState", STATE_PLEDGE)
                ply:SetNWFloat("PledgeTime", CurTime())
                ply:SetNWInt("TimeToPledge", ent.TimeToPledge)
                ent:EmitSound(shrinesound)
                if ent:GetDesecrated() then
                    ply:PrintMessage(HUD_PRINTCENTER, "You notice this shrine has been desecrated...")
                end
            end

            -- Finish pledge once current time reaches pledge time
            if CurTime() >= ply:GetNWFloat("PledgeTime") + ent.TimeToPledge then
                ent:Pledge(ply)
            end

            -- Set the last pledge time so the HUD stays up
            ply:SetNWFloat("LastPledgeTime", CurTime())
            ply:SetNWInt("Pledging", STATE_NONE)
            SendFullStateUpdate()
        else
            -- The user has let go of Use prematurely, reset
            ply:SetNWInt("PledgeState", STATE_NONE)
            ply:SetNWFloat("PledgeTime", 0)
            SendFullStateUpdate()
        end
    end
end )

if SERVER then
    -- recharge
    local nextcharge = 0
    function ENT:Think()
        --[[  if nextcharge < CurTime() then
            --self:AddToStorage(self.RechargeRate)

            nextcharge = CurTime() + self.RechargeFreq
         end ]]
    end

    -- TODO Prevent damage to shrine from cultists
    --local ttt_damage_own_healthstation = CreateConVar("ttt_damage_own_healthstation", "0") -- 0 as detective cannot damage their own health station

    -- traditional equipment destruction effects
    function ENT:OnTakeDamage(dmginfo)
        -- TODO Prevent damage to shrine from cultists
        --if dmginfo:GetAttacker() == self:GetPlacer() and not ttt_damage_own_healthstation:GetBool() then return end
        if dmginfo:GetAttacker() == self:GetPlacer() then return end

        self:TakePhysicsDamage(dmginfo)

        self:SetHealth(self:Health() - dmginfo:GetDamage())

        local att = dmginfo:GetAttacker()
        local placer = self:GetPlacer()
        if IsPlayer(att) then
            DamageLog(Format("DMG: \t %s [%s] damaged cult shrine [%s] for %d dmg", att:Nick(), att:GetRoleString(),  (IsPlayer(placer) and placer:Nick() or "<disconnected>"), dmginfo:GetDamage()))
        end

        if self:Health() < 0 then
            self:Remove()

            util.EquipmentDestroyed(self:GetPos())

            if IsValid(self:GetPlacer()) then
                LANG.Msg(self:GetPlacer(), "shrine_broken")
            end
        end
    end
end