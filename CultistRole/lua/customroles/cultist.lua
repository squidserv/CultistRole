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

if SERVER then
    CreateConVar("ttt_cultist_pledge_time", 3, FCVAR_NONE, "How long it takes for someone to join the cult", 0, 120)
    CreateConVar("ttt_cultist_shrine_ammo", 3, FCVAR_NONE, "How many people each shrine can convert", 0, 15)
    CreateConVar("ttt_cultist_pledge_health", 105, FCVAR_NONE, "The health of cult pledges", 0, 200)
    CreateConVar("ttt_cultist_convert_traitor", 1, FCVAR_NONE, "Can you convert T's")
    CreateConVar("ttt_cultist_pledge_credits", 0, FCVAR_NONE, "The amount of credits pledges start with")
    CreateConVar("ttt_cultist_jester_like", 0, FCVAR_NONE, "Can they do damage?")
    CreateConVar("ttt_cultist_convert_jester", 0, FCVAR_NONE, "Can jesters join?")
    CreateConVar("ttt_cultist_damage_bonus", 0, FCVAR_NONE, "Damage bonus for the pledges")
    CreateConVar("ttt_cultist_damage_reduction", 0, FCVAR_NONE, "Damage reduction against the pledges")
    CreateConVar("ttt_cultist_shrine_name", "The Almighty One", FCVAR_REPLICATED, "The name of the shrines")

    hook.Add("TTTSyncGlobals", "CultistGlobals", function()
        SetGlobalString("ttt_cultist_shrine_name", GetConVar("ttt_cultist_shrine_name"):GetString())
        SetGlobalBool("ttt_cultist_convert_traitor", GetConVar("ttt_cultist_convert_traitor"):GetBool())
        SetGlobalBool("ttt_cultist_convert_jester", GetConVar("ttt_cultist_convert_traitor"):GetBool())
    end)
end

ROLE.isactive = function(ply)
    return ply:GetNWBool("ActivatedCultist", false)
end
ROLE.selectionpredicate = nil

ROLE.shouldactlikejester = function(ply)
    return not ply:IsRoleActive()
end

ROLE.onroleassigned = function(ply)
    ply:SetNWBool("ActivatedCultist", not GetConVar("ttt_cultist_jester_like"):GetBool())
end

ROLE.translations = {
    ["english"] = {
        ["shrine_name"] = "Cult Shrine",
        ["shrine_hint"] = "Hold {usekey} to pledge yourself to the cult",
        ["shrine_hint_det"] = "This shrine has converted: {num} Innocents. Hold {usekey} to investigate",
        ["shrine_broken"] = "One of your shrines has been destroyed!",
        ["shrine_help"] = "{primaryfire} places the Shrine",
        ["shrine_desc"] = "Places a shrine that can be used to convert people to your cause"
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
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_jester_like",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_convert_jester",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_damage_bonus",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_damage_reduction",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE.convars, {
    cvar = "ttt_cultist_shrine_name",
    type = ROLE_CONVAR_TYPE_TEXT
})

RegisterRole(ROLE)

hook.Add("Initialize", "CultistInitialize", function()
    if SERVER then
        -- Use 323 if we're on Custom Roles for TTT earlier than version 1.2.5
        -- 323 is summation of the ASCII values for the characters "C", "L", and "T"
        WIN_CULTIST = GenerateNewWinID and GenerateNewWinID(ROLE_CULTIST) or 323
    end

    if CLIENT then
        LANG.AddToLanguage("english", "win_cultist", "The {role} and their minions have overwhelmed their enemies!")
        LANG.AddToLanguage("english", "ev_win_cultist", "The {role} and their army of minions has won them the round!")
    end
end)

if SERVER then
    AddCSLuaFile()

    -- Print a message to tell the T's that there is a cultist
    hook.Add("TTTBeginRound", "CultistAlertMessage", function()
        local livingCultist = player.IsRoleLiving(ROLE_CULTIST)
        if livingCultist then
            if CRVersion("1.3.1") then
                player.ExecuteAgainstTeamPlayers(ROLE_TEAM_TRAITOR, false, false, function(p)
                    p:PrintMessage(HUD_PRINTCENTER, "There is ".. ROLE_STRINGS_EXT[ROLE_CULTIST])
                end)
            else
                for _, p in ipairs(player.GetAll()) do
                    if p:IsTraitorTeam() then
                        p:PrintMessage(HUD_PRINTCENTER, "There is ".. ROLE_STRINGS_EXT[ROLE_CULTIST])
                    end
                end
            end
        end

        if CRVersion("1.3.1") and player.LivingCount() <= 2 and livingCultist then
            player.GetLivingRole(ROLE_CULTIST):SetNWBool("ActivatedCultist", true)
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

    hook.Add("ScalePlayerDamage", "CultistDamage", function(ply, hitgroup, dmginfo)
        local att = dmginfo:GetAttacker()
        if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE and dmginfo:IsBulletDamage()then
            if att:IsActiveCultist() and att:IsRoleActive() then
                local bonus = GetConVar("ttt_cultist_damage_bonus"):GetFloat()
                dmginfo:ScaleDamage(1 + bonus)
            end

            if ply:IsActiveCultist() and ply:IsRoleActive() then
                local reduction = GetConVar("ttt_cultist_damage_reduction"):GetFloat()
                dmginfo:ScaleDamage(1 - reduction)
            end
        end
    end)

    hook.Add("PlayerDeath", "ActivateLoneCultistPlayerDeath", function(victim, inflictor, attacker)
        if CRVersion("1.3.1") and player.LivingCount() <= 2 and player.IsRoleLiving(ROLE_CULTIST) then
            local ply = player.GetLivingRole(ROLE_CULTIST)
            if not ply:IsRoleActive() then
                ply:SetNWBool("ActivatedCultist", true)
            end
        end
    end)
end

if CLIENT then
    -- Show the cultist role icon to other cultists
    hook.Add("TTTTargetIDPlayerRoleIcon", "Cultist_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
        if ply:IsCultist() then
            if cli:IsCultist() then
                return ROLE_CULTIST
            end
            return false
        end
    end)
    hook.Add("TTTTargetIDPlayerRing", "Cultist_TTTTargetIDPlayerRing", function(ply, cli, ringVisible)
        if IsPlayer(ply) and ply:IsCultist() then
            return cli:IsCultist(), ROLE_COLORS[ROLE_CULTIST]
        end
    end)
    hook.Add("TTTTargetIDPlayerText", "Cultist_TTTTargetIDPlayerText", function(ply, cli, text, clr, second)
        if IsPlayer(ply) and ply:IsCultist() then
            if cli:IsCultist() then
                return ROLE_STRINGS[ROLE_CULTIST]:upper(), ROLE_COLORS[ROLE_CULTIST]
            end
            return false
        end
    end)
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

    hook.Add("TTTScoreboardPlayerRole", "CultistScoreboard", function(ply, cli, color, role)
        if ply:IsCultist() and cli:IsCultist() then
            return ROLE_COLORS[ROLE_CULTIST], ROLE_STRINGS_SHORT[ROLE_CULTIST]
        end
    end)

    hook.Add("TTTScoringSummaryRender", "Cultist_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, nameLabel, startingRole, finalRole)
        if finalRole == ROLE_CULTIST then
            return ROLE_STRINGS_SHORT[startingRole], startingRole
        end
    end)

    hook.Add("TTTTutorialRoleText", "CultistTutorialRoleText", function(role, titleLabel, roleIcon)
        if role == ROLE_CULTIST then
            local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
            local html = "The " .. ROLE_STRINGS[ROLE_CULTIST] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent role</span> who must convince fellow players to join their team."
            html = html .. "<ul style='position: relative; top: -15px;'>"
            local roleColorInno = ROLE_COLORS[ROLE_INNOCENT]
            local roleColorD = ROLE_COLORS[ROLE_DETECTIVE]
            html = html .. "<li>Drops Shrines (barrels) that non-detective <span style='color: rgb(" .. roleColorInno.r .. ", " .. roleColorInno.g .. ", " .. roleColorInno.b .. ")'>innocents</span> are called to and can pledge at to convert to the Cult"
            html = html .. "<li><span style='color: rgb(" .. roleColorInno.r .. ", " .. roleColorInno.g .. ", " .. roleColorInno.b .. ")'>Innocents</span> who pledge at the Shrine convert to the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent Cult team</span> and are able to identify other cultists. Once pledged, they are now against other innocents as well as traitors"
            local roleColorT = ROLE_COLORS[ROLE_TRAITOR]
            html = html .. "<li><span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Cultist</span> win condition is to defeat the remaining <span style='color: rgb(" .. roleColorInno.r .. ", " .. roleColorInno.g .. ", " .. roleColorInno.b .. ")'>innocents</span> and <span style='color: rgb(" .. roleColorT.r .. ", " .. roleColorT.g .. ", " .. roleColorT.b .. ")'>traitors</span>"
            html = html .. "<li><span style='color: rgb(" .. roleColorD.r .. ", " .. roleColorD.g .. ", " .. roleColorD.b .. ")'>Detectives</span> can see how many players have used a shrine at a glance. If a <span style='color: rgb(" .. roleColorD.r .. ", " .. roleColorD.g .. ", " .. roleColorD.b .. ")'>Detective</span> uses the shrine, they will begin investigating and eventually be given the names of those who pledged at that specific shrine. Afterwards, the shrine becomes desecrated and can still be used but future pledgers will be notified a <span style='color: rgb(" .. roleColorD.r .. ", " .. roleColorD.g .. ", " .. roleColorD.b .. ")'>detective</span> investigated it."
            return html .. "</ul>"
        end
    end)

    hook.Add("TTTSyncWinIDs", "CultistTTTWinIDsSynced", function()
        WIN_CULTIST = WINS_BY_ROLE[ROLE_CULTIST]
    end)
end