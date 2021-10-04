local ROLE = {}

ROLE.nameraw = "cultist"
ROLE.name = "Cultist"
ROLE.nameplural = "Cultists"
ROLE.nameext = "a Cultist"
ROLE.nameshort = "clt"

ROLE.desc = [[You are {role}!
Create shrines to help convert your enemies to your cause!
The more people you can entice, the easier it will be!
Press {menukey} to receive your special equipment!]]

ROLE.team = ROLE_TEAM_INDEPENDENT

ROLE.shop = {EQUIP_RADAR,EQUIP_ARMOR,"weapon_ttt_health_station"}
ROLE.loadout = {"weapon_clt_shrine"}

ROLE.startingcredits = 1

ROLE.startinghealth = nil
ROLE.maxhealth = nil

ROLE.isactive = nil
ROLE.selectionpredicate = nil

if SERVER then
    print("Loading convars")
    CreateConVar("ttt_cultist_pledge_time", 3, FCVAR_NONE, "How long it takes for someone to join the cult", 0, 120)
    CreateConVar("ttt_cultist_shrine_ammo", 3, FCVAR_NONE, "How many people each shrine can convert", 0, 15)
    CreateConVar("ttt_cultist_pledge_health", 105, FCVAR_NONE, "The health of cult pledges", 0, 200)
    -- TODO CreateConVar("ttt_cultist_jester_like", 0, FCVAR_NONE, "Can they do damage?")
    CreateConVar("ttt_cultist_shrine_name", "The Almighty One", FCVAR_REPLICATED, "The name of the shrines")

    hook.Add("TTTSyncGlobals", "CultistGlobals", function()
        print("syncing globals")
        SetGlobalString("ttt_cultist_shrine_name", GetConVar("ttt_cultist_shrine_name"):GetString())
    end)
end

ROLE.shouldactlikejester = nil
--[[function()
    print("Is jester like function ".. GetConVar("ttt_cultist_jester_like"):GetBool())
    return GetConVar("ttt_cultist_jester_like"):GetBool()
end
--]]

ROLE.translations = {}

ROLE.convars = {}
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_pledge_time",
    type = ROLE_CONVAR_TYPE_NUM,
})
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_shrine_ammo",
    type = ROLE_CONVAR_TYPE_NUM
})
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_pledge_health",
    type = ROLE_CONVAR_TYPE_NUM
})
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_jester_like",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_shrine_name",
    type = ROLE_CONVAR_TYPE_TEXT
})

print("Registered role")
RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    -- Print a message to tell the T's that there is a cultist
    hook.Add("TTTBeginRound", "CultistAlertMessage", function()
        print("round begin")
        local isCultist
        for i, ply in ipairs(player.GetAll()) do
            if ply:IsCultist() then
                isCultist = true
                break
            end
        end

        if isCultist then
            for i, p in ipairs(player.GetAll()) do
                if p:IsTraitorTeam() then
                    p:PrintMessage(HUD_PRINTCENTER, "There is ".. ROLE_STRINGS_EXT[ROLE_CULTIST])
                end
            end
        end
    end)
end