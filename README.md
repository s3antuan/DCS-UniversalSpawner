# DCS-UniversalSpawner
DCS Universal AI Group Spawner Script

## Description
A revised version of the previous [spawner script](https://github.com/s3antuan/DCS-Randomized-Spawner) rewrote with [MIST](https://github.com/mrSkortch/MissionScriptingTools). 

### Key Features
- Spawn AI group with:
  - Random routes
  - Random unit templates
  - Variation in waypoint location within a radius
  - Variation in waypoint height (for airborne unit only)
- Scheduled spawn with:
  - 8 available preset levels
  - Multiple schedules can be set within each level
  - Now only the preset schedules within the currently level is active (unlike the previous version script)
  - Limit for number of groups spawned by schedule in total
  - Limit for number of groups spawned by schedule currently on the map at any given time
- Option for in-game spawner control via F10 menu:
  - Spawn one group instantly
  - Change scheduled spawn level
  - Additional helper function for checking spawners' status
- Redesign to better support for integration with other scripts

## Setup in Mission Editor
### Script Setup
**This script requires MIST version [4.5.128](https://github.com/mrSkortch/MissionScriptingTools/tree/development) or above.** 

First, in the trigger tab, load MIST at mission start via DO SCRIPT FILE.

Second, load UniversalSpawner via DO SCRIPT FILE.

Last, load your own script containing the settings for spawners either via DO SCRIPT FILE or DO SCRIPT `assert(loadfile("PATH-TO-YOUR-SCRIPT"))()` if you want to avoid reload everytime after making a change.

![image]()

### Placing Routes and Templates
Routes and templates are groups placed in mission editor for the spawner to take informations from.

**_Routes_** are where the spawner will choose to spawn units from. Set as late activation and things below: 
- Waypoints
- Tasks
- Addvance waypoint options
- AI difficulty

**_Templates_** can be placed anywhere on the map. Set as late activation and things below: 
- Vehicle type
- Number of vehicles per group
- Loadout
- Livery

Some notes:
- Each spawner includes ONLY ONE unit category (airplane, helicopter, ground unit, or ship).
- Each spawner corresponds to ONLY ONE task (e.g. CAP, CAS, ground attack, etc.)
- Routes and templates can be shared between different spawners as long as they have the same unit category and task.
- Name the group name of routes and templates accordingly! This will make your life easier later.

### Spawner Setup
First, create two tables containing the group names of routes and templates respectively.
```lua
local routeTbl = {"route_001", "route_002", "route_003", "route_004"}
local templateTbl = {"template_001", "template_002", "template_003"}
```
Second, create an UniversalSpawner instance.
```lua
-- Create a spawner with a name "MySpawner" without F10 menu
local spawner = UniversalSpawner:New("MySpawner", routeTbl, templateTbl)

-- OR
-- Create a spawner with F10 menu options for the blue side, situated inside the submenu "MySubMenu"
local spawner = UniversalSpawner:New("MySpawner", routeTbl, templateTbl, "MySubMenu", coalition.side.BLUE)
```
Then, add some settings to the spawner and call the function `UniversalSpawner:Run()` last. The spawner will start working.
```lua
-- Add some settings
-- Set the schedules for some levels
spawner:SetScheduleTable(1, {})
spawner:SetScheduleTable(2, {{600, 0.5}, {900, 0.5}})
spawner:SetScheduleTable(3, {{240, 0.2, 240, 0.2}})
spawner:SetScheduleTable(4, {{120, 0.4, 120, 0.4, 3000}})

-- Set variation for waypoints
spawner:SetRouteVar(36000, 4000)

-- Set initial level at start
spawner:SetLevel(2)

-- Last
spawner:Run()
```
Additionally, to add a F10 menu sommand to show the status of your spawners:
```lua
-- Create a table of all your spawners you want to check
local spawnerTbl = {spawner_1, spawner_2, spawner_3, spawner_4}

-- The helper function
MenuShowSpawnerStatus(spawnerTbl)
```
## Examples


## Documents

