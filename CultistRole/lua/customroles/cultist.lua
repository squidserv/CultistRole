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

ROLE.shop = {EQUIP_RADAR,EQUIP_ARMOR,"weapon_ttt_health_station","weapon_clt_shrine"}
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
    CreateConVar("ttt_cultist_convert_traitor", 1, FCVAR_NONE, "Can you convert T's")
    -- TODO CreateConVar("ttt_cultist_jester_like", 0, FCVAR_NONE, "Can they do damage?")
    CreateConVar("ttt_cultist_shrine_name", "The Almighty One", FCVAR_REPLICATED, "The name of the shrines")

    hook.Add("TTTSyncGlobals", "CultistGlobals", function()
        SetGlobalString("ttt_cultist_shrine_name", GetConVar("ttt_cultist_shrine_name"):GetString())
    end)
end

ROLE.shouldactlikejester = nil
--[[function()
    print("Is jester like function ".. GetConVar("ttt_cultist_jester_like"):GetBool())
    return GetConVar("ttt_cultist_jester_like"):GetBool()
end
--]]

ROLE.translations = {
    ["english"] = {
        ["shrine_name"] = "Cult Shrine"
        ["shrine_hint"] = "Hold {usekey} to pledge yourself to the cult"
        ["shrine_hint_det"] = "This shrine has converted: {num} Innocents. Hold {usekey} to investigate"
        ["shrine_broken"] = "One of your shrines has been destroyed!"
        ["shrine_help"] = "{primaryfire} places the Shrine"
    }
}

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
    cvar = "ttt_cultist_convert_traitor",
    type = ROLE_CONVAR_TYPE_BOOL
})
--[[
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_jester_like",
    type = ROLE_CONVAR_TYPE_BOOL
})
--]]
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_shrine_name",
    type = ROLE_CONVAR_TYPE_TEXT
})

RegisterRole(ROLE)

hook.Add("Initialize", "CultistInitialize", function()
    -- Use 323 if we're on Custom Roles for TTT earlier than version 1.2.5
    -- 323 is summation of the ASCII values for the characters "C", "L", and "T"
    WIN_CULTIST = GenerateNewWinID and GenerateNewWinID() or 323

    if CLIENT then
        LANG.AddToLanguage("english", "win_cultist", "The {role} and their minions have overwhelmed their enemies!")
        LANG.AddToLanguage("english", "ev_win_cultist", "The {role} and their army of minions has won them the round!")
    end
end)

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

    hook.Add("TTTCheckForWin", "CultistCheckForWin", function()
        local cultistAlive = false
        local otherAlive = false
        for _, v in ipairs(player.GetAll()) do
            if v:Alive() and v:IsTerror() then
                if v:IsCultist() then
                    cultistAlive = true
                elseif CRVersion("1.2.5") and v:ShouldActLikeJester() then
                    otherAlive = true
                elseif not v:IsJesterTeam() or (v:IsClown() and v:IsRoleActive()) then
                    otherAlive = true
                end
            end
        end

        if cultistAlive then
            if not otherAlive then
                return WIN_CULTIST
            else
                return WIN_NONE
            end
        end
    end)

    hook.Add("TTTPrintResultMessage", "CultistPrintResultMessage", function(type)
        if type == WIN_CULTIST then
            LANG.Msg("win_cultist", { role = ROLE_STRINGS[ROLE_CULTIST] })
            ServerLog("Result: " .. ROLE_STRINGS[ROLE_CULTIST] .. " wins.\n")
            return true
        end
    end)
end

if CLIENT then
    hook.Add("TTTEventFinishText", "CultistEventFinishText", function(e)
        if e.win == WIN_CULTIST then
            return LANG.GetParamTranslation("ev_win_cultist", { role = ROLE_STRINGS[ROLE_CULTIST]:lower() })
        end
    end)

    hook.Add("TTTEventFinishIconText", "CultistEventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_CULTIST then
            return win_string, ROLE_STRINGS_PLURAL[ROLE_CULTIST]
        end
    end)

    hook.Add("TTTScoringWinTitle", "CultistScoringWinTitle", function(wintype, wintitles, title, secondaryWinRole)
        if wintype == WIN_CULTIST then
            return { txt = "hilite_win_role_singular", params = { role = ROLE_STRINGS[ROLE_CULTIST]:upper() }, c = ROLE_COLORS[ROLE_CULTIST] }
        end
    end)

    hook.Add("TTTTutorialRoleText", "CultistTutorialRoleText", function(role, titleLabel, roleIcon)
        if role == ROLE_CULTIST then
            local roleColor = ROLE_COLORS[ROLE_CULTIST]
            return "The " .. ROLE_STRINGS[ROLE_CULTIST] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent role</span> who must convince fellow players to join their team."
        end
    end)
end