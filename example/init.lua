--
--

do
	local routeTable_G = {"RG-1", "RG-2", "RG-3", "RG-4", "RG-5"}
	local templateTable_G = {"TG-1", "TG-2"}
	local spawner_G = UniversalSpawner:New("Ground", routeTable_G, templateTable_G, "SubMenuNameHere", coalition.side.BLUE)
	spawner_G:SetScheduleTable(1, {})
	spawner_G:SetScheduleTable(2, {{150, 0.2, 150, 0.2}})
	spawner_G:SetScheduleTable(3, {{90, 0.2, 90, 0.4}})
	spawner_G:SetScheduleTable(4, {{45, 0.4, 45, 0.4, 6000}})
	spawner_G:SetRouteVar(2000, 0)
	spawner_G:SetLevel(4)
	spawner_G:SetOnFieldSpawnLimit(3)
	spawner_G:SetScheduledSpawnLimit(20)
	spawner_G:Run()

	-- mist.scheduleFunction(spawner_G.SpawnAI, {spawner_G}, timer.getTime() + 300)


	local routeTable_A = {"RA-1", "RA-2", "RA-3", "RA-4", "RA-5"}
	local templateTable_A = {"TA-1", "TA-2", "TA-3"}
	local spawner_A = UniversalSpawner:New("Aircraft", routeTable_A, templateTable_A, "SubMenuNameHere", coalition.side.BLUE)
	spawner_A:SetScheduleTable(1, {})
	spawner_A:SetScheduleTable(2, {{150, 0.2, 150, 0.2}})
	spawner_A:SetScheduleTable(3, {{300, 0.2, 300, 0.4}})
	spawner_A:SetScheduleTable(4, {{600, 0.4, 600, 0.4, 6000}})
	spawner_A:SetRouteVar(36000, 4000)
	spawner_A:SetLevel(2)
	spawner_A:SetScheduledSpawnLimit(6)
	spawner_A:Run()


	MenuShowSpawnerStatus({spawner_G, "-----", spawner_A})

	trigger.action.outText("Demo script successfully loaded.", 10)
end