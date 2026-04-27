--[[
	StyleFilters options for Sirus 3.3.5a (WotLK).
	Adapted from retail ElvUI_Options/Core/StyleFilters.lua.
	Only exposes triggers/actions that the local NamePlates engine actually evaluates
	(see ElvUI/Modules/Nameplates/StyleFilter.lua :: StyleFilterConditionCheck).
]]

local E, _, V, P, G = unpack(ElvUI)
local C, L = unpack(select(2, ...))
local NP = E:GetModule('NamePlates')
local ACH = E.Libs.ACH

local _G = _G
local wipe, pairs, next = wipe, pairs, next
local strmatch, strsplit = string.match, strsplit
local sort, tonumber, tostring, format = table.sort, tonumber, tostring, string.format

local GetSpellInfo = GetSpellInfo
local GetSpellTexture = GetSpellTexture
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local CLASS_SORT_ORDER = CLASS_SORT_ORDER
local MAX_PLAYER_LEVEL = _G.GetMaxPlayerLevel and _G.GetMaxPlayerLevel() or 80

local filters = {}
local raidTargetIcon = [[|TInterface\TargetingFrame\UI-RaidTargetingIcon_%s:0|t %s]]
local sortedClasses = E:CopyTable({}, CLASS_SORT_ORDER)
sort(sortedClasses)

C.StyleFilterSelected = nil

local function GetFilter(collect)
	local setting = E.global.nameplates.filters[C.StyleFilterSelected]
	if collect and setting then
		return setting.triggers, setting.actions
	end
	return setting
end

local function DisabledFilter()
	local triggers = GetFilter(true)
	return not (triggers and triggers.enable)
end

local function GetFilters(info)
	wipe(filters)
	local list = E.global.nameplates.filters
	if not (list and next(list)) then return filters end

	if info[#info] == 'selectFilter' then
		for filterName, content in pairs(list) do
			local triggers = content.triggers
			local priority = (triggers and triggers.priority) or '?'
			local name = (triggers and triggers.enable and filterName) or (triggers and format('|cFF666666%s|r', filterName)) or filterName
			filters[filterName] = format('|cFFffff00(%s)|r %s', priority, name)
		end
	else
		for filterName in pairs(list) do
			filters[filterName] = filterName
		end
	end
	return filters
end

local function GetSpellFilterInfo(name)
	local spell, stacks = strmatch(name, NP.StyleFilterStackPattern)
	local spellID = tonumber(spell)
	if spellID then
		local spellName = GetSpellInfo(spellID)
		if spellName then
			if DisabledFilter() then
				spell = format('%s (%d)', spellName, spellID)
			else
				spell = format('|cFFffff00%s|r |cFFffffff(%d)|r', spellName, spellID)
				if stacks ~= '' then
					spell = format('%s|cFF999999%s|r', spell, ' x'..stacks)
				end
			end
		end
	end
	local spellTexture = GetSpellTexture(spellID or spell)
	local spellDescription = spellTexture and E:TextureString(spellTexture, ':32:32:0:0:32:32:4:28:4:28')
	return spell, spellDescription
end

local spellTypes = { casting = true, debuffs = true, buffs = true, cooldowns = true }
local subTypes = { casting = 'spells', debuffs = 'names', buffs = 'names', cooldowns = 'names', names = 'list' }

local function GetFilterOption()
	local option = ACH:Toggle('', nil)
	option.textWidth = true
	return option
end

local StyleFilters

local function UpdateFilterList(which, initial, opt, add)
	local filter = GetFilter()
	if not filter then return end
	local subType = subTypes[which]
	local isSpell = spellTypes[which]
	local setting = StyleFilters.triggers.args[which].args[subType]
	local triggers = (filter.triggers[which][subType]) or filter.triggers[which]
	setting.hidden = not next(triggers)

	local spell, desc
	if initial then
		setting.args = {}
		for name in next, triggers do
			if isSpell then spell, desc = GetSpellFilterInfo(name) else spell, desc = nil, nil end
			local option = GetFilterOption()
			option.name, option.desc = spell or name, desc
			setting.args[name] = option
		end
	elseif opt then
		if isSpell then spell, desc = GetSpellFilterInfo(opt) end
		local option = GetFilterOption()
		option.name, option.desc = spell or opt, desc
		setting.args[opt] = add and option or nil
	end
end

local function UpdateFilterGroup()
	if not C.StyleFilterSelected then return end
	UpdateFilterList('names', true)
	UpdateFilterList('cooldowns', true)
	UpdateFilterList('buffs', true)
	UpdateFilterList('debuffs', true)
	UpdateFilterList('casting', true)
end

function C:StyleFilterSetConfig(filter)
	C.StyleFilterSelected = filter
	UpdateFilterGroup()
	local ACD = E.Libs.AceConfigDialog
	if ACD then
		ACD:SelectGroup('ElvUI', 'nameplates', 'stylefilters', filter and 'triggers' or 'addFilter')
	end
end

local function validateCreateFilter(_, value)
	return not (strmatch(value, '^[%s%p]-$') or E.global.nameplates.filters[value])
end
local function validateString(_, value) return not strmatch(value, '^[%s%p]-$') end

E.Options.args.nameplates.args.stylefilters = ACH:Group(L["Style Filter"], nil, 10, 'tab', nil, nil, function() return not E.NamePlates.Initialized end)
StyleFilters = E.Options.args.nameplates.args.stylefilters.args

StyleFilters.addFilter = ACH:Input(L["Create Filter"], nil, 1, nil, nil, nil,
	function(_, value)
		local new = {}
		NP:StyleFilterCopyDefaults(new)
		E.global.nameplates.filters[value] = new
		C:StyleFilterSetConfig(value)
	end, nil, nil, validateCreateFilter)

StyleFilters.selectFilter = ACH:Select(L["Select Filter"], nil, 2, GetFilters, nil, nil,
	function() return C.StyleFilterSelected end,
	function(_, value) C:StyleFilterSetConfig(value) end)
StyleFilters.selectFilter.sortByValue = true

StyleFilters.removeFilter = ACH:Select(L["Delete Filter"],
	L["Delete a created filter, you cannot delete pre-existing filters, only custom ones."], 3,
	function()
		wipe(filters)
		for filterName in next, E.global.nameplates.filters do
			if not G.nameplates.filters[filterName] then
				filters[filterName] = filterName
			end
		end
		return filters
	end, true, nil, nil,
	function(_, value)
		if E.data and E.data.profiles then
			for profile in pairs(E.data.profiles) do
				local pdata = E.data.profiles[profile]
				if pdata.nameplates and pdata.nameplates.filters then
					pdata.nameplates.filters[value] = nil
				end
			end
		end
		E.global.nameplates.filters[value] = nil
		NP:ConfigureAll()
		C:StyleFilterSetConfig()
	end)

-- =====================================================================
-- TRIGGERS
-- =====================================================================
StyleFilters.triggers = ACH:Group(L["Triggers"], nil, 5, nil, nil, nil, function() return not C.StyleFilterSelected end)

StyleFilters.triggers.args.enable = ACH:Toggle(L["Enable"], nil, 0, nil, nil, nil,
	function() local t = GetFilter(true) return t and t.enable end,
	function(_, value) local t = GetFilter(true) if t then t.enable = value NP:ConfigureAll() end end)

StyleFilters.triggers.args.priority = ACH:Range(L["Filter Priority"],
	L["Lower numbers mean a higher priority. Filters are processed in order from 1 to 100."], 1,
	{ min = 1, max = 100, step = 1 }, nil,
	function() local t = GetFilter(true) return (t and t.priority) or 1 end,
	function(_, value) local t = GetFilter(true) if t then t.priority = value NP:ConfigureAll() end end,
	DisabledFilter)

StyleFilters.triggers.args.resetFilter = ACH:Execute(L["Clear Filter"], L["Return filter to its default state."], 2,
	function()
		local fresh = {}
		NP:StyleFilterCopyDefaults(fresh)
		E.global.nameplates.filters[C.StyleFilterSelected] = E:CopyTable(fresh, G.nameplates.filters[C.StyleFilterSelected])
		UpdateFilterGroup()
		NP:ConfigureAll()
	end)

-- Names ---------------------------------------------------------------
StyleFilters.triggers.args.names = ACH:Group(L["Name"], nil, 6, nil, nil, nil, DisabledFilter)
StyleFilters.triggers.args.names.args.addName = ACH:Input(L["Add Name or NPC ID"], L["Add a Name or NPC ID to the list."], 1, nil, nil, nil,
	function(_, value) local t = GetFilter(true) t.names[value] = true UpdateFilterList('names', nil, value, true) NP:ConfigureAll() end,
	nil, nil, validateString)
StyleFilters.triggers.args.names.args.removeName = ACH:Select(L["Remove Name or NPC ID"], L["Remove a Name or NPC ID from the list."], 2,
	function() local t, v = GetFilter(true), {} for n in next, t.names do v[n] = n end return v end,
	nil, nil, nil,
	function(_, value) local t = GetFilter(true) t.names[value] = nil UpdateFilterList('names', nil, value) NP:ConfigureAll() end)
StyleFilters.triggers.args.names.args.negativeMatch = ACH:Toggle(L["Negative Match"], L["Match if Name or NPC ID is NOT in the list."], 3, nil, nil, nil,
	function(info) local t = GetFilter(true) return t[info[#info]] end,
	function(info, value) local t = GetFilter(true) t[info[#info]] = value NP:ConfigureAll() end)
StyleFilters.triggers.args.names.args.list = ACH:Group('', nil, 50, nil,
	function(info) local t = GetFilter(true) return t.names and t.names[info[#info]] end,
	function(info, value) local t = GetFilter(true) if not t.names then t.names = {} end t.names[info[#info]] = value NP:ConfigureAll() end,
	nil, true)
StyleFilters.triggers.args.names.args.list.inline = true

-- Targeting -----------------------------------------------------------
StyleFilters.triggers.args.targeting = ACH:Group(L["Targeting"], nil, 7, nil,
	function(info) local t = GetFilter(true) return t[info[#info]] end,
	function(info, value) local t = GetFilter(true) t[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.targeting.args.types = ACH:Group('', nil, 1)
StyleFilters.triggers.args.targeting.args.types.inline = true
StyleFilters.triggers.args.targeting.args.types.args.isTarget = ACH:Toggle(L["Is Targeted"], L["If enabled then the filter will only activate when you are targeting the unit."], 1)
StyleFilters.triggers.args.targeting.args.types.args.notTarget = ACH:Toggle(L["Not Targeted"], L["If enabled then the filter will only activate when you are not targeting the unit."], 2)
StyleFilters.triggers.args.targeting.args.types.args.requireTarget = ACH:Toggle(L["Require Target"], L["If enabled then the filter will only activate when you have a target."], 3)
StyleFilters.triggers.args.targeting.args.types.args.noTarget = ACH:Toggle(L["No Target"], nil, 4)

-- Casting -------------------------------------------------------------
StyleFilters.triggers.args.casting = ACH:Group(L["Casting"], nil, 8, nil,
	function(info) local t = GetFilter(true) return t.casting[info[#info]] end,
	function(info, value) local t = GetFilter(true) t.casting[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.casting.args.types = ACH:Group('', nil, 1)
StyleFilters.triggers.args.casting.args.types.inline = true
StyleFilters.triggers.args.casting.args.types.args.interruptible = ACH:Toggle(L["Interruptible"], L["If enabled then the filter will only activate if the unit is casting interruptible spells."], 1)
StyleFilters.triggers.args.casting.args.types.args.notInterruptible = ACH:Toggle(L["Non-Interruptible"], L["If enabled then the filter will only activate if the unit is casting not interruptible spells."], 2)
StyleFilters.triggers.args.casting.args.types.args.spacer1 = ACH:Spacer(3, 'full')
StyleFilters.triggers.args.casting.args.types.args.isCasting = ACH:Toggle(L["Is Casting Anything"], L["If enabled then the filter will activate if the unit is casting anything."], 4)
StyleFilters.triggers.args.casting.args.types.args.notCasting = ACH:Toggle(L["Not Casting Anything"], L["If enabled then the filter will activate if the unit is not casting anything."], 5)
StyleFilters.triggers.args.casting.args.types.args.spacer2 = ACH:Spacer(6, 'full')
StyleFilters.triggers.args.casting.args.types.args.isChanneling = ACH:Toggle(L["Is Channeling Anything"], L["If enabled then the filter will activate if the unit is channeling anything."], 7)
StyleFilters.triggers.args.casting.args.types.args.notChanneling = ACH:Toggle(L["Not Channeling Anything"], L["If enabled then the filter will activate if the unit is not channeling anything."], 8)

StyleFilters.triggers.args.casting.args.addSpell = ACH:Input(L["Add Spell ID or Name"], nil, 2, nil, nil, nil,
	function(_, value) local t = GetFilter(true) t.casting.spells[value] = true UpdateFilterList('casting', nil, value, true) NP:ConfigureAll() end,
	nil, nil, validateString)
StyleFilters.triggers.args.casting.args.removeSpell = ACH:Select(L["Remove Spell ID or Name"], L["If the aura is listed with a number then you need to use that to remove it from the list."], 3,
	function() local t, v = GetFilter(true), {} for s in next, t.casting.spells do v[s] = s end return v end,
	nil, nil, nil,
	function(_, value) local t = GetFilter(true) t.casting.spells[value] = nil UpdateFilterList('casting', nil, value) NP:ConfigureAll() end)
StyleFilters.triggers.args.casting.args.notSpell = ACH:Toggle(L["Not Spell"], L["If enabled then the filter will only activate if the unit is not casting or channeling one of the selected spells."], 4)
StyleFilters.triggers.args.casting.args.spells = ACH:Group('', nil, 50, nil,
	function(info) local t = GetFilter(true) return t.casting.spells and t.casting.spells[info[#info]] end,
	function(info, value) local t = GetFilter(true) if not t.casting.spells then t.casting.spells = {} end t.casting.spells[info[#info]] = value NP:ConfigureAll() end,
	nil, true)
StyleFilters.triggers.args.casting.args.spells.inline = true

-- Combat / Unit / Player ---------------------------------------------
StyleFilters.triggers.args.combat = ACH:Group(L["Unit Conditions"], nil, 10, nil,
	function(info) local t = GetFilter(true) return t[info[#info]] end,
	function(info, value) local t = GetFilter(true) t[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)

StyleFilters.triggers.args.combat.args.playerGroup = ACH:Group(L["Player"], nil, 1)
StyleFilters.triggers.args.combat.args.playerGroup.inline = true
StyleFilters.triggers.args.combat.args.playerGroup.args.inCombat = ACH:Toggle(L["In Combat"], L["If enabled then the filter will only activate when you are in combat."], 1)
StyleFilters.triggers.args.combat.args.playerGroup.args.outOfCombat = ACH:Toggle(L["Out of Combat"], L["If enabled then the filter will only activate when you are out of combat."], 2)
StyleFilters.triggers.args.combat.args.playerGroup.args.inVehicle = ACH:Toggle(L["In Vehicle"], nil, 3)
StyleFilters.triggers.args.combat.args.playerGroup.args.outOfVehicle = ACH:Toggle(L["Out of Vehicle"], nil, 4)
StyleFilters.triggers.args.combat.args.playerGroup.args.isResting = ACH:Toggle(L["Is Resting"], L["If enabled then the filter will only activate when you are resting at an Inn."], 5)
StyleFilters.triggers.args.combat.args.playerGroup.args.notResting = ACH:Toggle(L["Not Resting"], nil, 6)

StyleFilters.triggers.args.combat.args.unitGroup = ACH:Group(L["Unit"], nil, 2)
StyleFilters.triggers.args.combat.args.unitGroup.inline = true
StyleFilters.triggers.args.combat.args.unitGroup.args.inCombatUnit = ACH:Toggle(L["In Combat"], L["If enabled then the filter will only activate when the unit is in combat."], 1)
StyleFilters.triggers.args.combat.args.unitGroup.args.outOfCombatUnit = ACH:Toggle(L["Out of Combat"], L["If enabled then the filter will only activate when the unit is out of combat."], 2)
StyleFilters.triggers.args.combat.args.unitGroup.args.inVehicleUnit = ACH:Toggle(L["In Vehicle"], nil, 3)
StyleFilters.triggers.args.combat.args.unitGroup.args.outOfVehicleUnit = ACH:Toggle(L["Out of Vehicle"], nil, 4)

-- Faction -------------------------------------------------------------
StyleFilters.triggers.args.faction = ACH:Group(L["Unit Faction"], nil, 11, nil,
	function(info) local t = GetFilter(true) return t.faction and t.faction[info[#info]] end,
	function(info, value) local t = GetFilter(true) if not t.faction then t.faction = {} end t.faction[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.faction.args.types = ACH:Group('', nil, 2)
StyleFilters.triggers.args.faction.args.types.inline = true
StyleFilters.triggers.args.faction.args.types.args.Alliance = ACH:Toggle(L["Alliance"], nil, 1)
StyleFilters.triggers.args.faction.args.types.args.Horde = ACH:Toggle(L["Horde"], nil, 2)
StyleFilters.triggers.args.faction.args.types.args.Neutral = ACH:Toggle(L["Neutral"], nil, 3)
StyleFilters.triggers.args.faction.args.types.args.Renegade = ACH:Toggle(L["Renegade"] or "Renegade", nil, 4)

-- Class ---------------------------------------------------------------
StyleFilters.triggers.args.class = ACH:Group(L["CLASS"], nil, 12, nil, nil, nil, DisabledFilter)
for index, classTag in ipairs(sortedClasses) do
	local className = LOCALIZED_CLASS_NAMES_MALE[classTag] or classTag
	local color = E:ClassColor(classTag)
	local colorStr = (color and color.colorStr) or 'ff666666'
	StyleFilters.triggers.args.class.args[classTag] = ACH:Toggle(format('|c%s%s|r', colorStr, className), nil, index, nil, nil, nil,
		function() local t = GetFilter(true) local tag = t.class[classTag] return tag and tag.enabled end,
		function(_, value)
			local t = GetFilter(true)
			if value then
				t.class[classTag] = { enabled = true }
			else
				t.class[classTag] = nil
			end
			NP:ConfigureAll()
		end)
end

-- Role ----------------------------------------------------------------
StyleFilters.triggers.args.role = ACH:Group(L["ROLE"], nil, 15, nil,
	function(info) local t = GetFilter(true) return t.role and t.role[info[#info]] end,
	function(info, value) local t = GetFilter(true) if not t.role then t.role = {} end t.role[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.role.args.tank = ACH:Toggle(L["Tank"], nil, 1)
StyleFilters.triggers.args.role.args.healer = ACH:Toggle(L["Healer"], nil, 2)
StyleFilters.triggers.args.role.args.damager = ACH:Toggle(L["DAMAGER"], nil, 3)

-- Classification ------------------------------------------------------
StyleFilters.triggers.args.classification = ACH:Group(L["Classification"], nil, 16, nil,
	function(info) local t = GetFilter(true) return t.classification and t.classification[info[#info]] end,
	function(info, value) local t = GetFilter(true) if not t.classification then t.classification = {} end t.classification[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.classification.args.types = ACH:Group('', nil, 2)
StyleFilters.triggers.args.classification.args.types.inline = true
StyleFilters.triggers.args.classification.args.types.args.worldboss = ACH:Toggle(L["RAID_INFO_WORLD_BOSS"] or 'World Boss', nil, 1)
StyleFilters.triggers.args.classification.args.types.args.rareelite = ACH:Toggle(L["Rare Elite"], nil, 2)
StyleFilters.triggers.args.classification.args.types.args.normal = ACH:Toggle(L["Normal"], nil, 3)
StyleFilters.triggers.args.classification.args.types.args.rare = ACH:Toggle(L["Rare"], nil, 4)
StyleFilters.triggers.args.classification.args.types.args.trivial = ACH:Toggle(L["Trivial"], nil, 5)
StyleFilters.triggers.args.classification.args.types.args.elite = ACH:Toggle(L["Elite"], nil, 6)
StyleFilters.triggers.args.classification.args.types.args.minus = ACH:Toggle(L["Minus"], nil, 7)

-- Health --------------------------------------------------------------
StyleFilters.triggers.args.health = ACH:Group(L["Health Threshold"], nil, 17, nil,
	function(info) local t = GetFilter(true) return t[info[#info]] end,
	function(info, value) local t = GetFilter(true) t[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.health.args.healthThreshold = ACH:Toggle(L["Enable"], nil, 1)
StyleFilters.triggers.args.health.args.healthUsePlayer = ACH:Toggle(L["Player Health"], L["Enabling this will check your health amount."], 2, nil, nil, nil, nil, nil, function() local t = GetFilter(true) return not t.healthThreshold end)
StyleFilters.triggers.args.health.args.underHealthThreshold = ACH:Range(L["Under Health Threshold"], nil, 4, { min = 0, max = 1, step = 0.01, isPercent = true }, nil, nil, nil, function() local t = GetFilter(true) return not t.healthThreshold end)
StyleFilters.triggers.args.health.args.overHealthThreshold = ACH:Range(L["Over Health Threshold"], nil, 5, { min = 0, max = 1, step = 0.01, isPercent = true }, nil, nil, nil, function() local t = GetFilter(true) return not t.healthThreshold end)

-- Power ---------------------------------------------------------------
StyleFilters.triggers.args.power = ACH:Group(L["Power Threshold"], nil, 18, nil,
	function(info) local t = GetFilter(true) return t[info[#info]] end,
	function(info, value) local t = GetFilter(true) t[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.power.args.powerThreshold = ACH:Toggle(L["Enable"], nil, 1)
StyleFilters.triggers.args.power.args.powerUsePlayer = ACH:Toggle(L["Player Power"], nil, 2, nil, nil, nil, nil, nil, function() local t = GetFilter(true) return not t.powerThreshold end)
StyleFilters.triggers.args.power.args.underPowerThreshold = ACH:Range(L["Under Power Threshold"], nil, 4, { min = 0, max = 1, step = 0.01, isPercent = true }, nil, nil, nil, function() local t = GetFilter(true) return not t.powerThreshold end)
StyleFilters.triggers.args.power.args.overPowerThreshold = ACH:Range(L["Over Power Threshold"], nil, 5, { min = 0, max = 1, step = 0.01, isPercent = true }, nil, nil, nil, function() local t = GetFilter(true) return not t.powerThreshold end)

-- Levels --------------------------------------------------------------
StyleFilters.triggers.args.levels = ACH:Group(L["Level"], nil, 20, nil,
	function(info) local t = GetFilter(true) return t[info[#info]] end,
	function(info, value) local t = GetFilter(true) t[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.levels.args.level = ACH:Toggle(L["Enable"], nil, 1)
StyleFilters.triggers.args.levels.args.mylevel = ACH:Toggle(L["Match Player Level"], nil, 2, nil, nil, nil, nil, nil, function() local t = GetFilter(true) return not t.level end)
StyleFilters.triggers.args.levels.args.minlevel = ACH:Range(L["Minimum Level"], nil, 4, { min = -1, max = MAX_PLAYER_LEVEL + 3, step = 1 }, nil, nil, nil, function() local t = GetFilter(true) return not (t.level and not t.mylevel) end)
StyleFilters.triggers.args.levels.args.maxlevel = ACH:Range(L["Maximum Level"], nil, 5, { min = -1, max = MAX_PLAYER_LEVEL + 3, step = 1 }, nil, nil, nil, function() local t = GetFilter(true) return not (t.level and not t.mylevel) end)
StyleFilters.triggers.args.levels.args.curlevel = ACH:Range(L["Current Level"], nil, 6, { min = -1, max = MAX_PLAYER_LEVEL + 3, step = 1 }, nil, nil, nil, function() local t = GetFilter(true) return not (t.level and not t.mylevel) end)

-- Buffs / Debuffs (shared) -------------------------------------------
StyleFilters.triggers.args.buffs = ACH:Group(L["Buffs"], nil, 21, nil,
	function(info) local t = GetFilter(true) return t.buffs and t.buffs[info[#info]] end,
	function(info, value) local t = GetFilter(true) t.buffs[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.debuffs = ACH:Group(L["Debuffs"], nil, 22, nil,
	function(info) local t = GetFilter(true) return t.debuffs and t.debuffs[info[#info]] end,
	function(info, value) local t = GetFilter(true) t.debuffs[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)

do
	local stackThreshold
	for _, auraType in next, { 'buffs', 'debuffs' } do
		local opt = StyleFilters.triggers.args[auraType].args
		opt.minTimeLeft = ACH:Range(L["Minimum Time Left"], nil, 1, { min = 0, max = 10800, step = 1 })
		opt.maxTimeLeft = ACH:Range(L["Maximum Time Left"], nil, 2, { min = 0, max = 10800, step = 1 })
		opt.spacer1 = ACH:Spacer(3, 'full')
		opt.mustHaveAll = ACH:Toggle(L["Require All"], L["If enabled then it will require all auras to activate the filter. Otherwise it will only require any one of the auras to activate it."], 4)
		opt.missing = ACH:Toggle(L["Missing"], L["If enabled then it checks if auras are missing instead of being present on the unit."], 5)
		opt.fromMe = ACH:Toggle(L["From Me"], nil, 8)
		opt.fromPet = ACH:Toggle(L["From Pet"], nil, 9)
		opt.onMe = ACH:Toggle(L["On Me"], nil, 10)
		opt.onPet = ACH:Toggle(L["On Pet"], nil, 11)

		opt.changeList = ACH:Group(L["Add / Remove"], nil, 10)
		opt.changeList.inline = true
		opt.changeList.args.addSpell = ACH:Input(L["Add Spell ID or Name"], nil, 1, nil, nil, nil,
			function(_, value)
				if stackThreshold then value = value .. '\n' .. stackThreshold end
				local t = GetFilter(true)
				t[auraType].names[value] = true
				stackThreshold = nil
				UpdateFilterList(auraType, nil, value, true)
				NP:ConfigureAll()
			end, nil, nil, validateString)
		opt.changeList.args.removeSpell = ACH:Select(L["Remove Spell ID or Name"], L["If the aura is listed with a number then you need to use that to remove it from the list."], 2,
			function()
				local t, v = GetFilter(true), {}
				for n in pairs(t[auraType].names) do v[n] = format('%s (%s)', strsplit('\n', n)) end
				return v
			end, nil, nil, nil,
			function(_, value)
				local t = GetFilter(true)
				t[auraType].names[value] = nil
				UpdateFilterList(auraType, nil, value)
			end)
		opt.changeList.args.stackThreshold = ACH:Range(L["Stack Threshold"], L["Allows you to tie a stack count to an aura when you add it to the list, which allows the trigger to act when an aura reaches X number of stacks."], 3, { min = 1, max = 250, step = 1 }, nil,
			function() return stackThreshold or 1 end,
			function(_, value) stackThreshold = (value > 1 and value) or nil end)

		opt.names = ACH:Group('', nil, 50, nil,
			function(info) local t = GetFilter(true) return t[auraType].names and t[auraType].names[info[#info]] end,
			function(info, value) local t = GetFilter(true) t[auraType].names[info[#info]] = value NP:ConfigureAll() end,
			nil, true)
		opt.names.inline = true
	end
end

-- Cooldowns -----------------------------------------------------------
StyleFilters.triggers.args.cooldowns = ACH:Group(L["Cooldowns"], nil, 23, nil, nil, nil, DisabledFilter)
StyleFilters.triggers.args.cooldowns.args.addCooldown = ACH:Input(L["Add Spell ID or Name"], nil, 1, nil, nil, nil,
	function(_, value) local t = GetFilter(true) t.cooldowns.names[value] = 'ONCD' UpdateFilterList('cooldowns', nil, value, true) NP:ConfigureAll() end,
	nil, nil, validateString)
StyleFilters.triggers.args.cooldowns.args.removeCooldown = ACH:Select(L["Remove Spell ID or Name"], nil, 2,
	function() local t, v = GetFilter(true), {} for n in next, t.cooldowns.names do v[n] = n end return v end,
	nil, nil, nil,
	function(_, value) local t = GetFilter(true) t.cooldowns.names[value] = nil UpdateFilterList('cooldowns', nil, value) NP:ConfigureAll() end)
StyleFilters.triggers.args.cooldowns.args.mustHaveAll = ACH:Toggle(L["Require All"], nil, 3, nil, nil, nil,
	function() local t = GetFilter(true) return t.cooldowns and t.cooldowns.mustHaveAll end,
	function(_, value) local t = GetFilter(true) t.cooldowns.mustHaveAll = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.cooldowns.args.names = ACH:Group('', nil, 50, nil,
	function(info)
		local t = GetFilter(true)
		local v = t.cooldowns.names and t.cooldowns.names[info[#info]]
		if v == 'ONCD' then return 'ONCD' elseif v == 'OFFCD' then return 'OFFCD' else return 'DISABLED' end
	end,
	function(info, value) local t = GetFilter(true) t.cooldowns.names[info[#info]] = (value ~= 'DISABLED' and value) or nil NP:ConfigureAll() end)
StyleFilters.triggers.args.cooldowns.args.names.inline = true

-- Nameplate Type ------------------------------------------------------
StyleFilters.triggers.args.nameplateType = ACH:Group(L["Unit Type"], nil, 26, nil, nil, nil, DisabledFilter)
StyleFilters.triggers.args.nameplateType.args.enable = ACH:Toggle(L["Enable"], nil, 0, nil, nil, nil,
	function() local t = GetFilter(true) return t.nameplateType and t.nameplateType.enable end,
	function(_, value) local t = GetFilter(true) t.nameplateType.enable = value NP:ConfigureAll() end)
StyleFilters.triggers.args.nameplateType.args.types = ACH:Group('', nil, 1, nil,
	function(info) local t = GetFilter(true) return t.nameplateType[info[#info]] end,
	function(info, value) local t = GetFilter(true) t.nameplateType[info[#info]] = value NP:ConfigureAll() end,
	function() local t = GetFilter(true) return DisabledFilter() or not t.nameplateType.enable end)
StyleFilters.triggers.args.nameplateType.args.types.inline = true
for frameType, keyName in next, NP.TriggerConditions.frameTypes do
	StyleFilters.triggers.args.nameplateType.args.types.args[keyName] = ACH:Toggle(L[frameType] or frameType)
end

-- Reaction Type -------------------------------------------------------
StyleFilters.triggers.args.reactionType = ACH:Group(L["Reaction Type"], nil, 27, nil,
	function(info) local t = GetFilter(true) return t.reactionType and t.reactionType[info[#info]] end,
	function(info, value) local t = GetFilter(true) t.reactionType[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.reactionType.args.enable = ACH:Toggle(L["Enable"], nil, 0)
StyleFilters.triggers.args.reactionType.args.types = ACH:Group('', nil, 2, nil, nil, nil, function() local t = GetFilter(true) return DisabledFilter() or not t.reactionType.enable end)
StyleFilters.triggers.args.reactionType.args.types.inline = true
StyleFilters.triggers.args.reactionType.args.types.args.hostile = ACH:Toggle(L["Hostile"] or 'Hostile', nil, 1)
StyleFilters.triggers.args.reactionType.args.types.args.neutral = ACH:Toggle(L["Neutral"], nil, 2)
StyleFilters.triggers.args.reactionType.args.types.args.friendly = ACH:Toggle(L["Friendly"] or 'Friendly', nil, 3)

-- Instance Type -------------------------------------------------------
StyleFilters.triggers.args.instanceType = ACH:Group(L["Instance Type"], nil, 29, nil,
	function(info) local t = GetFilter(true) return t.instanceType and t.instanceType[info[#info]] end,
	function(info, value) local t = GetFilter(true) t.instanceType[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.instanceType.args.types = ACH:Group('', nil, 2)
StyleFilters.triggers.args.instanceType.args.types.inline = true
StyleFilters.triggers.args.instanceType.args.types.args.none = ACH:Toggle(L["None"], nil, 1)
StyleFilters.triggers.args.instanceType.args.types.args.sanctuary = ACH:Toggle(L["Sanctuary"] or 'Sanctuary', nil, 2)
StyleFilters.triggers.args.instanceType.args.types.args.party = ACH:Toggle(L["Party"], nil, 3)
StyleFilters.triggers.args.instanceType.args.types.args.raid = ACH:Toggle(L["Raid"], nil, 4)
StyleFilters.triggers.args.instanceType.args.types.args.arena = ACH:Toggle(L["Arena"], nil, 5)
StyleFilters.triggers.args.instanceType.args.types.args.pvp = ACH:Toggle(L["BATTLEFIELDS"] or 'Battlegrounds', nil, 6)

StyleFilters.triggers.args.instanceType.args.dungeonDifficulty = ACH:MultiSelect(L["DUNGEON_DIFFICULTY"] or 'Dungeon Difficulty', nil, 10,
	{ normal = L["Normal"], heroic = L["Heroic"] }, nil, nil,
	function(_, key) local t = GetFilter(true) return t.instanceDifficulty.dungeon[key] end,
	function(_, key, value) local t = GetFilter(true) t.instanceDifficulty.dungeon[key] = value NP:ConfigureAll() end,
	nil, function() local f = GetFilter() return not (f and f.triggers.instanceType.party) end)

StyleFilters.triggers.args.instanceType.args.raidDifficulty = ACH:MultiSelect(L["Raid Difficulty"], nil, 11,
	{ normal = L["Normal"], heroic = L["Heroic"] }, nil, nil,
	function(_, key) local t = GetFilter(true) return t.instanceDifficulty.raid[key] end,
	function(_, key, value) local t = GetFilter(true) t.instanceDifficulty.raid[key] = value NP:ConfigureAll() end,
	nil, function() local f = GetFilter() return not (f and f.triggers.instanceType.raid) end)

-- Raid Target ---------------------------------------------------------
StyleFilters.triggers.args.raidTarget = ACH:Group(L["BINDING_HEADER_RAID_TARGET"] or 'Raid Target', nil, 31, nil,
	function(info) local t = GetFilter(true) return t.raidTarget and t.raidTarget[info[#info]] end,
	function(info, value) local t = GetFilter(true) t.raidTarget[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.triggers.args.raidTarget.args.types = ACH:Group('')
StyleFilters.triggers.args.raidTarget.args.types.inline = true
do
	local order = { 'star', 'circle', 'diamond', 'triangle', 'moon', 'square', 'cross', 'skull' }
	for i, key in ipairs(order) do
		StyleFilters.triggers.args.raidTarget.args.types.args[key] = ACH:Toggle(format(raidTargetIcon, i, L["RAID_TARGET_"..i] or key), nil, i)
	end
end

-- =====================================================================
-- ACTIONS
-- =====================================================================
local function actionHidePlate() local _, a = GetFilter(true) return a and a.hide end

StyleFilters.actions = ACH:Group(L["Actions"], nil, 10, nil,
	function(info) local _, a = GetFilter(true) return a and a[info[#info]] end,
	function(info, value) local _, a = GetFilter(true) a[info[#info]] = value NP:ConfigureAll() end,
	DisabledFilter)
StyleFilters.actions.args.hide = ACH:Toggle(L["Hide Frame"], nil, 1)
StyleFilters.actions.args.nameOnly = ACH:Toggle(L["Name Only"], nil, 3, nil, nil, nil, nil, nil, actionHidePlate)
StyleFilters.actions.args.spacer1 = ACH:Spacer(4, 'full')
StyleFilters.actions.args.scale = ACH:Range(L["Scale"], nil, 5, { min = .25, max = 1.5, step = .01 }, nil, nil, nil, actionHidePlate)
StyleFilters.actions.args.alpha = ACH:Range(L["Alpha"], L["Change the alpha level of the frame."], 6, { min = -1, max = 100, step = 1 }, nil, nil, nil, actionHidePlate)
StyleFilters.actions.args.frameLevel = ACH:Range(L["Frame Level"], nil, 7, { min = 0, max = 255, step = 1 }, nil, nil, nil, actionHidePlate)

-- Color sub-group
local function actionColorGet(info)
	local _, a = GetFilter(true)
	local t = a and a.color and a.color[info[#info]]
	if type(t) == 'table' then return t.r, t.g, t.b, t.a end
	return t
end
local function actionColorSet(info, ...)
	local _, a = GetFilter(true)
	if not a or not a.color then return end
	local t = a.color[info[#info]]
	if type(t) == 'table' then
		local r, g, b, alpha = ...
		t.r, t.g, t.b, t.a = r, g, b, alpha
	else
		a.color[info[#info]] = (...)
	end
	NP:ConfigureAll()
end

StyleFilters.actions.args.color = ACH:Group(L["COLOR"], nil, 10, nil, actionColorGet, actionColorSet, actionHidePlate)
StyleFilters.actions.args.color.inline = true
StyleFilters.actions.args.color.args.health = ACH:Toggle(L["Health"], nil, 1)
StyleFilters.actions.args.color.args.healthClass = ACH:Toggle(L["Unit Class Color"], nil, 2)
StyleFilters.actions.args.color.args.healthColor = ACH:Color(L["Health Color"], nil, 3, true)
StyleFilters.actions.args.color.args.spacer1 = ACH:Spacer(4, 'full')
StyleFilters.actions.args.color.args.border = ACH:Toggle(L["Border"], nil, 5)
StyleFilters.actions.args.color.args.borderClass = ACH:Toggle(L["Unit Class Color"], nil, 6)
StyleFilters.actions.args.color.args.borderColor = ACH:Color(L["Border Color"], nil, 7, true)
StyleFilters.actions.args.color.args.spacer2 = ACH:Spacer(8, 'full')
StyleFilters.actions.args.color.args.name = ACH:Toggle(L["Name"], nil, 9)
StyleFilters.actions.args.color.args.nameClass = ACH:Toggle(L["Unit Class Color"], nil, 10)
StyleFilters.actions.args.color.args.nameColor = ACH:Color(L["Name Color"], nil, 11, true)

-- Texture sub-group
local function actionTexGet(info)
	local _, a = GetFilter(true)
	return a and a.texture and a.texture[info[#info]]
end
local function actionTexSet(info, value)
	local _, a = GetFilter(true)
	if not a or not a.texture then return end
	a.texture[info[#info]] = value
	NP:ConfigureAll()
end
StyleFilters.actions.args.texture = ACH:Group(L["Texture"], nil, 11, nil, actionTexGet, actionTexSet, actionHidePlate)
StyleFilters.actions.args.texture.inline = true
StyleFilters.actions.args.texture.args.enable = ACH:Toggle(L["Enable"], nil, 1)
StyleFilters.actions.args.texture.args.texture = ACH:SharedMediaStatusbar(L["Texture"], nil, 2)

-- Flash sub-group
local function actionFlashGet(info)
	local _, a = GetFilter(true)
	local t = a and a.flash and a.flash[info[#info]]
	if type(t) == 'table' then return t.r, t.g, t.b, t.a end
	return t
end
local function actionFlashSet(info, ...)
	local _, a = GetFilter(true)
	if not a or not a.flash then return end
	local t = a.flash[info[#info]]
	if type(t) == 'table' then
		local r, g, b, alpha = ...
		t.r, t.g, t.b, t.a = r, g, b, alpha
	else
		a.flash[info[#info]] = (...)
	end
	NP:ConfigureAll()
end
StyleFilters.actions.args.flash = ACH:Group(L["Flash"], nil, 12, nil, actionFlashGet, actionFlashSet, actionHidePlate)
StyleFilters.actions.args.flash.inline = true
StyleFilters.actions.args.flash.args.enable = ACH:Toggle(L["Enable"], nil, 1)
StyleFilters.actions.args.flash.args.color = ACH:Color(L["Color"], nil, 2, true)
StyleFilters.actions.args.flash.args.speed = ACH:Range(L["Speed"], nil, 3, { min = 1, max = 10, step = 1 })
