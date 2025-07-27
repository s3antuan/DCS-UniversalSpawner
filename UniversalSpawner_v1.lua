--[[
Universal AI Group Spawner Script

A revised version of the previous spawner script rewrote with Mist:
	- Randomized routes & templates
	- Scheduled spawn with total & on-field limit, up to 8 available preset levels
	- Option for in-game control via F10 menu
	- Support for integrating with other script

dependencies: Mist
version: v1
author: Nyako 2-1 | ginmokusei
date: Jul. 2025

example:


]]

UniversalSpawner = {}

do
	UniversalSpawner.MENU_DB = {
		[1] = {}, -- RED
		[2] = {}, -- BLUE
		[3] = {}, -- ALL
	}


	-- @param #string Name of the spawner shown in the spawned group names and in the F10 menu (if set).
	-- @param #table of #string Group names in ME set as routes for spawn.
	-- @param #table of #string Group names in ME set as templates for spawn.
	-- @param #string (optional)Name of the sub menu branch in F10 menu. Default is nil (no F10 menu will be added).
	-- @param #table/enum coalition.side (optional)Coalition in which the F10 menu will be added. Default is nil (added for all).
	-- @return #table UniversalSpawner object.
	function UniversalSpawner:New(name, routeTbl, templateTbl, subMenu, menuSide)
		local obj = {}
		obj.name = name
		obj.routeTbl = mist.utils.deepCopy(routeTbl)
		obj.templateTbl = mist.utils.deepCopy(templateTbl)
		obj.subMenu = nil or subMenu
		obj.menuSide = nil or menuSide

		obj.side = Group.getByName(templateTbl[1]):getCoalition()
		obj.category = Group.getByName(templateTbl[1]):getCategory()
		obj.isAirUnit = (obj.category == 0 or obj.category == 1) -- AIRPLANE or HELICOPTER

		obj.scheduleTbl = {nil, nil, nil, nil, nil, nil, nil, nil}
		obj.level = 1
		obj.count = 0
		obj.countScheduled = 0
		obj.limitScheduled = 0

		obj.onFieldGroupTbl = {}
		obj.limitOnField = 0

		obj.hasRouteVar = false
		obj.routeRadiusVar = 6067
		obj.routeHeightVar = 4000

		setmetatable(obj, self)
		self.__index = self

		return obj
	end


	-- @param #Group Group data of route.
	-- @param #Group Group data of template.
	-- @return #Group Group data for spawn.
	local function generateSpawnGroupData(route, template)
		local diffX = template.units[1].x - route.units[1].x
		local diffY = template.units[1].y - route.units[1].y
		local group = mist.utils.deepCopy(route)
		group.units = mist.utils.deepCopy(template.units)
		for i = 1, #group.units do
			group.units[i].x = group.units[i].x - diffX
			group.units[i].y = group.units[i].y - diffY
		end
		return group
	end


	-- @param #number X coordinate of the circle.
	-- @param #number Y coordinate of the circle.
	-- @param #number Radius of the circle.
	-- @return #number X coordinate of the point.
	-- @return #number Y coordinate of the point.
	local function getRandomPointInCircle(x, y, radius)
		local range = radius * math.random()
		local theta = 2 * math.pi * math.random()
		local newX = x + range * math.cos(theta)
		local newY = y + range * math.sin(theta)
		return newX, newY
	end


	-- @param #Group Group data to change.
	-- @param #boolean Whether the group is air unit or not.
	-- @param #number Radius variation of waypoints (in meters)
	-- @param #number Height variation of waypoints (in meters), only works for air units.
	-- @return #Group Group data for spawn.
	local function randomizeRoute(group, isAirUnit, radiusVar, heightVar)
		local newGroup = mist.utils.deepCopy(group)
		for i, v in ipairs(group.route) do
			if i ~= 1 and v.type == "Turning Point" then
				-- radius
				local newX, newY = getRandomPointInCircle(v.x, v.y, radiusVar)
				newGroup.route[i].x = newX
				newGroup.route[i].y = newY

				-- height
				if isAirUnit then
					newGroup.route[i].alt = v.alt + heightVar * math.random()
				else
					newGroup.route[i].alt = land.getHeight({x = newX, y = newY})
				end
			end
		end
		return newGroup
	end


	-- @param #table Table of scheduled spawned group names.
	-- @return #table An updated table of still alive scheduled spawned group names.
	local function checkAliveGroup(groupTbl)
		local newGroupTbl = {}
		for _, groupName in pairs(groupTbl) do
			local group = Group.getByName(groupName)
			if group then
				if group:getSize() > 0 then
					table.insert(newGroupTbl, groupName)
				end
			end
		end
		return newGroupTbl
	end


	-- @param #boolean (optional)Whether is scheduled spawn or not. Default is false.
	function UniversalSpawner:SpawnAI(scheduled)
		scheduled = scheduled or false
		if scheduled then
			if self.limitScheduled > 0 and self.countScheduled >= self.limitScheduled then
				env.info(string.format("[UniversalSpawner] %s: Scheduled spawn limit reached. No spawn.", self.name))
				return
			else
				self.onFieldGroupTbl = checkAliveGroup(self.onFieldGroupTbl)
				if self.limitOnField > 0 and #self.onFieldGroupTbl >= self.limitOnField then
					env.info(string.format("[UniversalSpawner] %s: On field scheduled spawn limit reached. No spawn.", self.name))
					return
				else
					self.countScheduled = self.countScheduled + 1
				end
			end
		end
		self.count = self.count + 1

		local err, msg = pcall(function()
			local routeName = self.routeTbl[math.random(#self.routeTbl)]
			local templateName = self.templateTbl[math.random(#self.templateTbl)]
			local route = mist.getGroupData(routeName, true)
			local template = mist.getGroupData(templateName)
			local group = generateSpawnGroupData(route, template)
			if self.hasRouteVar then
				group = randomizeRoute(group, self.isAirUnit, mist.utils.feetToMeters(self.routeRadiusVar), mist.utils.feetToMeters(self.routeHeightVar))
			end

			if self.side == coalition.side.BLUE then
				group.country = 80 -- CJTF_BLUE
			elseif self.side == coalition.side.RED then
				group.country = 81 -- CJTF_RED
			end
			group.category = self.category
			group.groupName = string.format("%s_%03d", self.name, self.count)
			group.clone = true

			mist.dynAdd(group)

			if scheduled then
				table.insert(self.onFieldGroupTbl, group.groupName)
				env.info(string.format("[UniversalSpawner] %s: Group spawned (scheduled, level %d). (%03d) ", self.name, self.level, self.count))
			else
				env.info(string.format("[UniversalSpawner] %s: Group spawned. (%03d) ", self.name, self.count))
			end
		end)
		if not err then 
			env.error(msg, true) 
			env.error(debug.traceback())
		end
	end


	-- @param #number Radius variation of waypoints (in ft.)
	-- @param #number Height variation of waypoints (in ft.) Only works for air units.
	function UniversalSpawner:SetRouteVar(radiusVar, heightVar)
		self.hasRouteVar = true
		if radiusVar < 0 then
			env.warning(string.format("[UniversalSpawner] %s: SetRouteVar: Radius variation must be positive.", self.name), true)
			return
		end
		if heightVar < 0 then
			env.warning(string.format("[UniversalSpawner] %s: SetRouteVar: height variation must be positive.", self.name), true)
			return
		end
		self.routeRadiusVar = radiusVar
		self.routeHeightVar = heightVar
	end


	-- @param #number The level of scheduleTbl to spawn (1 ~ 8).
	-- @param #boolean (optional)Show message in log and in game. Default is false.
	function UniversalSpawner:SetLevel(level, hasMessage)
		hasMessage = hasMessage or false
		if level >= 1 and level <= 8 then
			self.level = level
			if hasMessage then
				env.info(string.format("[UniversalSpawner] %s: Level set to %d.", self.name, self.level))
				if self.menuSide then
					trigger.action.outTextForCoalition(self.menuSide, string.format("%s: Level set to %d.", self.name, self.level), 10)
				else
					trigger.action.outText(string.format("%s: Level set to %d.", self.name, self.level), 10)
				end
			end
		else
			env.warning(string.format("[UniversalSpawner] %s: SetLevel: Level must be between 1 to 8. (%d)", self.name, level), true)
		end
	end


	-- @param #number The number limit of scheduled spawns. 
	function UniversalSpawner:SetScheduledSpawnLimit(limit)
		if limit > 0 then
			self.limitScheduled = limit
		else
			self.limitScheduled = 0
		end
	end


	-- @param #number The number limit of on field scheduled spawns. 
	function UniversalSpawner:SetOnFieldSpawnLimit(limit)
		if limit > 0 then
			self.limitOnField = limit
		else
			self.limitOnField = 0
		end
	end


	-- @param #number The level of scheduleTbl to spawn (1 ~ 8).
	-- @param #table See below.
	--[[
	Parameter "schedules" is a table looks like below:
	{ {A, B, C, D, E}, {A, B, C, D, E}, ... }, where:
	  A: time for the first spawn
	  B: time variation of the first spawn (0 ~ 1) i.e. actual time for the first spawn = A ± (A * B)
	  C: time interval between each subsequent spawns
	  D: time variation of subsequent spawns (0 ~ 1) i.e. actual time for the spawn = A + C * i ± (C * D) where i = 1, 2, 3, ...
	  E: time for the scheduled spawning to stop
	  all time in seconds
	Examples:
	  {A, B, nil, nil, nil} spawn only once
	  {A, B, C, D, nil}     spawn repeatly on schedule
	  {A, B, C, D, E}       spawn repeatly on schedule until stop time is reached
	]]
	function UniversalSpawner:SetScheduleTable(level, schedules)
		if level >= 1 and level <= 8 then
			self.scheduleTbl[level] = mist.utils.deepCopy(schedules)
		end
	end


	function UniversalSpawner:Run()
		-- Menu
		if self.subMenu then
			if self.menuSide then
				local menu = UniversalSpawner.MENU_DB[self.menuSide][self.subMenu]
				if not menu then
					menu = missionCommands.addSubMenuForCoalition(self.menuSide, self.subMenu)
					UniversalSpawner.MENU_DB[self.menuSide][self.subMenu] = menu
				end
				menu = missionCommands.addSubMenuForCoalition(self.menuSide, self.name, menu)

				missionCommands.addCommandForCoalition(self.menuSide, "Spawn One Group Now", menu, self.SpawnAI, self, false)
				for i = 1, 8 do
					if self.scheduleTbl[i] then
						missionCommands.addCommandForCoalition(self.menuSide, string.format("Set Level to %d", i), menu, self.SetLevel, self, i, true)
					end
				end
			else
				local menu = UniversalSpawner.MENU_DB[3][self.subMenu]
				if not menu then
					menu = missionCommands.addSubMenu(self.subMenu)
					UniversalSpawner.MENU_DB[3][self.subMenu] = menu
				end
				menu = missionCommands.addSubMenu(self.name, menu)

				missionCommands.addCommand("Spawn One Group Now", menu, self.SpawnAI, self, false)
				for i = 1, 8 do
					if self.scheduleTbl[i] then
						missionCommands.addCommand(string.format("Set Level to %d", i), menu, self.SetLevel, self, i)
					end
				end
			end
		end

		-- Schedule
		local function ScheduledSpawn(context, level, delayRange)
			if level == context.level then
				local delay = delayRange * math.random()
				mist.scheduleFunction(context.SpawnAI, {context, true}, timer.getTime() + delay)
			end
		end

		for level, schedules in ipairs(self.scheduleTbl) do
			if schedules then
				for _, schedule in pairs(schedules) do
					local A = schedule[1]
					local B = schedule[2] or 0
					local C = schedule[3]
					local D = schedule[4] or 0
					local E = schedule[5]

					if not A then
						--
					elseif C and E then
						mist.scheduleFunction(ScheduledSpawn, {self, level, A * 2 * B}, timer.getTime() + A - (A * B))
						mist.scheduleFunction(ScheduledSpawn, {self, level, C * 2 * D}, timer.getTime() + A + C - (C * D), C, timer.getTime() + E)
					elseif C then
						mist.scheduleFunction(ScheduledSpawn, {self, level, A * 2 * B}, timer.getTime() + A - (A * B))
						mist.scheduleFunction(ScheduledSpawn, {self, level, C * 2 * D}, timer.getTime() + A + C - (C * D), C)
					else
						mist.scheduleFunction(ScheduledSpawn, {self, level, A * 2 * B}, timer.getTime() + A - (A * B))
					end
				end
			end
		end
	end


	-- @param #table Table of UniversalSpawner objects. Any element not a table (data type in lua) will create a blank line for readability.
	-- @param #string (optional)Alternative text for F10 menu command.
	function MenuShowSpawnerStatus(UniversalSpawnerTbl, menuText)
		menuText = menuText or "Show Universal Spawner Status"
		local function getSpawnerStatus()
			local msg = "Universal Spawner Current Status:\n\n"
			for _, spawner in pairs(UniversalSpawnerTbl) do
				if type(spawner) == "table" then
					local name = spawner.name
					local subMenu = spawner.subMenu
					local level = spawner.level
					local count = spawner.count
					local countScheduled = spawner.countScheduled
					local limit = spawner.limitScheduled
					if subMenu then
						msg = msg .. subMenu .. " / "
					end
					msg = msg .. string.format("%s: Lv. %d ", name, level)
					if limit > 0 then
						msg = msg .. string.format("[%3d (%3d) / %3d spawned]\n", count, countScheduled, limit)
					else
						msg = msg .. string.format("[%3d spawned]\n", count)
					end
				else
					msg = msg .. "\n"
				end
			end
			return msg
		end
		missionCommands.addCommand(menuText, nil, function()
			trigger.action.outText(getSpawnerStatus(), 30)
		end)
	end
end