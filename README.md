# Cultist

Start a cult and convert others to your cause!

## Description

- Cultist drops Shrines (barrels) that non-detective innocents are called to and can pledge at to convert to the Cult
- Innocents who pledge at the Shrine convert to the Cult neutral team and are able to identify other cultists. Once pledged, they are now against other innocents as well as traitors
- Cultist win condition is similar to Killer: defeat the remaining innocents and traitors
- Detective's can see how many players have used a shrine at a glance. If a Detective uses the shrine, they will begin investigating and eventually be given the names of those who pledged at that specific shrine. Afterwards, the shrine becomes desecrated and can still be used but future pledgers will be notified a detective investigated it.


## Convars

Add the following to your server.cfg (for dedicated servers) or listenserver.cfg (for peer-to-peer servers):

```cpp
ttt_cultist_enabled             0                   // Used to enable or disable the role
ttt_cultist_spawn_weight        1                   // The weight assigned for spawning the role
ttt_cultist_min_players         0                   // The minimum number of player required to spawn the role
ttt_cultist_starting_health     100                 // The amount of health the role starts each round with
ttt_cultist_max_health          100                 // The maximum health of the role
ttt_cultist_starting_credits    1                   // The player's starting credits
ttt_cultist_pledge_time         3                   // How long it takes for someone to join the cult
ttt_cultist_shrine_ammo         3                   // How many people each shrine can convert
ttt_cultist_pledge_health       105                 // How much health the cult pledges get
ttt_cultist_convert_traitor     1                   // Whether Traitors can join the cult or not
ttt_cultist_convert_jester      0                   // Whether Jesters can join the cult or not
ttt_cultist_damage_bonus        0                   // Damage bonus that the pledges have when they are converted (e.g. 0.5 = 50% more damage)
ttt_cultist_damage_reduction    0                   // Damage reduction that the pledges take when they are converted (e.g. 0.5 = 50% less damage)
ttt_cultist_jester_like         0                   // Can the leader do damage or just the minions?
ttt_cultist_shrine_name         "The Almighty One"  // The default name of the cult

```

## Special Thanks:
- [Noxx](https://steamcommunity.com/id/noxxflame) and [Malivil](https://steamcommunity.com/id/malivil) for all their work on Custom Roles for TTT
- [[SPAYED]Bud](https://steamcommunity.com/id/swerving2kill) for the idea from their EMU CR