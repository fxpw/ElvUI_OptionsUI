local E, _, V, P, G = unpack(ElvUI)
local C, L = unpack(select(2, ...))
local NP = E:GetModule('NamePlates')
local ACD = E.Libs.AceConfigDialog
local ACH = E.Libs.ACH

-- local _G = _G
local max, strfind, wipe = math.max, string.find, wipe
local pairs, type, strsplit = pairs, type, strsplit
local next, tonumber, format = next, tonumber, string.format

local GetCVarBool = GetCVarBool
local SetCVar = SetCVar

local carryFilterFrom, carryFilterTo

local ORDER = 100

local function BlizzardL(key)
	return _G[key] or L[key] or key
end

local function EngineGetKey(key)
	return function()
		return NP:GetEngineCVar(key)
	end
end

local function EngineSetKey(key)
	return function(_, value)
		if not E.db.nameplates.engine then
			E.db.nameplates.engine = E:CopyTable(P.nameplates.engine)
		end
		E.db.nameplates.engine[key] = value
		NP:ApplyEngineOption(key)
		if NP.Initialized then
			NP:ConfigureAll()
		end
		E:RefreshGUI()
	end
end

local showOnlyNamesValues = {
	['0'] = BlizzardL('NAMEPLATE_SHOW_ONLY_NAMES_OPTION_0'),
	['1'] = BlizzardL('NAMEPLATE_SHOW_ONLY_NAMES_OPTION_1'),
	['2'] = BlizzardL('NAMEPLATE_SHOW_ONLY_NAMES_OPTION_2'),
	['3'] = BlizzardL('NAMEPLATE_SHOW_ONLY_NAMES_OPTION_3'),
}

local targetRadialValues = {
	['0'] = BlizzardL('NAMEPLATE_TARGET_RADIAL_POSITION_OPTION_0'),
	['1'] = BlizzardL('NAMEPLATE_TARGET_RADIAL_POSITION_OPTION_1'),
}

local personalShowWithTargetValues = {
	['0'] = BlizzardL('DISPLAY_PERSONAL_SHOW_WITH_TARGET_OPTION_0'),
	['1'] = BlizzardL('DISPLAY_PERSONAL_SHOW_WITH_TARGET_OPTION_1'),
	['2'] = BlizzardL('DISPLAY_PERSONAL_SHOW_WITH_TARGET_OPTION_2'),
}
local filters = {}

local minHeight, minWidth = 2, 40

local function MaxHeight(unit)
	local heightType = strfind(unit, 'FRIENDLY') and 'friendlyHeight' or 'enemyHeight'
	return max(NP.db and NP.db.plateSize and NP.db.plateSize[heightType] or 0, 20)
end

local function MaxWidth(unit)
	local widthType = strfind(unit, 'FRIENDLY') and 'friendlyWidth' or 'enemyWidth'
	return max(NP.db and NP.db.plateSize and NP.db.plateSize[widthType] or 0, 250)
end

local function BuildAuraGroup(unit, auraType, name, order)
	local aura                                                    = ACH:Group(name, nil, order, nil,
		function(info) return E.db.nameplates.units[unit][auraType][info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit][auraType][info[#info]] = value
			NP:ConfigureAll()
		end)

	aura.args.enable                                              = ACH:Toggle(L["Enable"], nil, 1)
	aura.args.stackAuras                                          = ACH:Toggle(L["Stack Auras"],
		L["This will join auras together which are normally separated."], 2)
	aura.args.desaturate                                          = ACH:Toggle(L["Desaturate Icon"],
		L["Set auras that are not from you to desaturated."], 3)
	aura.args.keepSizeRatio                                       = ACH:Toggle(L["Keep Size Ratio"], nil, 4)
	aura.args.size                                                = ACH:Range(
		function() return E.db.nameplates.units[unit][auraType].keepSizeRatio and L["Size"] or L["Width"] end, nil, 5,
		{ min = 6, max = 60, step = 1 })
	aura.args.height                                              = ACH:Range(L["Height"], nil, 6,
		{ min = 6, max = 60, step = 1 }, nil, nil, nil, nil,
		function() return E.db.nameplates.units[unit][auraType].keepSizeRatio end)
	aura.args.numAuras                                            = ACH:Range(L["Per Row"], nil, 7,
		{ min = 1, max = 20, step = 1 })
	aura.args.numRows                                             = ACH:Range(L["Num Rows"], nil, 8,
		{ min = 1, max = 5, step = 1 })
	aura.args.spacing                                             = ACH:Range(L["Spacing"], nil, 9,
		{ min = 0, max = 60, step = 1 })
	aura.args.xOffset                                             = ACH:Range(L["X-Offset"], nil, 10,
		{ min = -100, max = 100, step = 1 })
	aura.args.yOffset                                             = ACH:Range(L["Y-Offset"], nil, 11,
		{ min = -100, max = 100, step = 1 })
	aura.args.anchorPoint                                         = ACH:Select(L["Anchor Point"],
		L["What point to anchor to the frame you set to attach to."], 12, C.Values.Anchors)

	aura.args.growthX                                             = ACH:Select(L["Growth X-Direction"], nil, 14,
		{ LEFT = L["Left"], RIGHT = L["Right"] })
	aura.args.growthY                                             = ACH:Select(L["Growth Y-Direction"], nil, 15,
		{ UP = L["Up"], DOWN = L["Down"] })
	aura.args.sortMethod                                          = ACH:Select(L["Sort By"], L["Method to sort by."], 16,
		{
			TIME_REMAINING = L["Time Remaining"],
			DURATION = L["Duration"],
			NAME = L["Name"],
			INDEX = L["Index"],
			PLAYER =
				L["Player"]
		})
	aura.args.sortDirection                                       = ACH:Select(L["Sort Direction"],
		L["Ascending or Descending order."], 17, { ASCENDING = L["Ascending"], DESCENDING = L["Descending"] })

	aura.args.stacks                                              = ACH:Group(L["Stack Counter"], nil, 20)
	aura.args.stacks.inline                                       = true
	aura.args.stacks.args.countFont                               = ACH:SharedMediaFont(L["Font"], nil, 1)
	aura.args.stacks.args.countFontSize                           = ACH:Range(L["Font Size"], nil, 2,
		{ min = 4, max = 60, step = 1 })
	aura.args.stacks.args.countFontOutline                        = ACH:FontFlags(L["Font Outline"], nil, 3)
	aura.args.stacks.args.countPosition                           = ACH:Select(L["Position"], nil, 4, C.Values.AllPoints)
	aura.args.stacks.args.countXOffset                            = ACH:Range(L["X-Offset"], nil, 5,
		{ min = -100, max = 100, step = 1 })
	aura.args.stacks.args.countYOffset                            = ACH:Range(L["Y-Offset"], nil, 6,
		{ min = -100, max = 100, step = 1 })

	aura.args.duration                                            = ACH:Group(L["Duration"], nil, 25)
	aura.args.duration.inline                                     = true
	aura.args.duration.args.cooldownShortcut                      = ACH:Execute(L["Cooldowns"], nil, 1,
		function() ACD:SelectGroup('ElvUI', 'cooldown', 'nameplates') end)
	aura.args.duration.args.durationPosition                      = ACH:Select(L["Position"], nil, 2, C.Values.AllPoints)

	aura.args.filtersGroup                                        = ACH:Group(L["FILTERS"], nil, 30)
	aura.args.filtersGroup.inline                                 = true
	aura.args.filtersGroup.args.minDuration                       = ACH:Range(L["Minimum Duration"],
		L["Don't display auras that are shorter than this duration (in seconds). Set to zero to disable."], 1,
		{ min = 0, max = 10800, step = 1 })
	aura.args.filtersGroup.args.maxDuration                       = ACH:Range(L["Maximum Duration"],
		L["Don't display auras that are longer than this duration (in seconds). Set to zero to disable."], 2,
		{ min = 0, max = 10800, step = 1 })
	aura.args.filtersGroup.args.jumpToFilter                      = ACH:Execute(L["Filters Page"],
		L["Shortcut to global filters."], 3, function() ACD:SelectGroup('ElvUI', 'filters') end)

	aura.args.filtersGroup.args.specialFilters                    = ACH:Select(L["Add Special Filter"],
		L
		["These filters don't use a list of spells like the regular filters. Instead they use the WoW API and some code logic to determine if an aura should be allowed or blocked."],
		4,
		function()
			wipe(filters)
			local list = E.global.unitframe.specialFilters
			if not (list and next(list)) then return filters end
			for filter in pairs(list) do filters[filter] = L[filter] end
			return filters
		end,
		nil, nil, nil,
		function(_, value)
			C.SetFilterPriority(E.db.nameplates.units, unit, auraType, value)
			NP:ConfigureAll()
		end)
	aura.args.filtersGroup.args.specialFilters.sortByValue        = true

	aura.args.filtersGroup.args.filter                            = ACH:Select(L["Add Regular Filter"],
		L
		["These filters use a list of spells to determine if an aura should be allowed or blocked. The content of these filters can be modified in the Filters section of the config."],
		5,
		function()
			wipe(filters)
			local list = E.global.unitframe.aurafilters
			if not (list and next(list)) then return filters end
			for filter in pairs(list) do filters[filter] = L[filter] end
			return filters
		end,
		nil, nil, nil,
		function(_, value)
			C.SetFilterPriority(E.db.nameplates.units, unit, auraType, value)
			NP:ConfigureAll()
		end)

	aura.args.filtersGroup.args.resetPriority                     = ACH:Execute(L["Reset Priority"],
		L["Reset filter priority to the default state."], 7,
		function()
			E.db.nameplates.units[unit][auraType].priority = P.nameplates.units[unit][auraType].priority
			NP:ConfigureAll()
		end)

	aura.args.filtersGroup.args.filterPriority                    = ACH:MultiSelect(L["Filter Priority"], nil, 8,
		function()
			local str = E.db.nameplates.units[unit][auraType].priority
			if str == '' then return {} end
			return { strsplit(',', str) }
		end,
		nil, nil,
		function(_, value)
			local str = E.db.nameplates.units[unit][auraType].priority
			if str == '' then return end
			local tbl = { strsplit(',', str) }
			return tbl[value]
		end,
		function() NP:ConfigureAll() end)
	aura.args.filtersGroup.args.filterPriority.dragdrop           = true
	aura.args.filtersGroup.args.filterPriority.dragOnLeave        = E.noop
	aura.args.filtersGroup.args.filterPriority.dragOnEnter        = function(info) carryFilterTo = info.obj.value end
	aura.args.filtersGroup.args.filterPriority.dragOnMouseDown    = function(info)
		carryFilterFrom, carryFilterTo =
			info.obj.value, nil
	end
	aura.args.filtersGroup.args.filterPriority.dragOnMouseUp      = function()
		C.SetFilterPriority(E.db.nameplates.units, unit, auraType, carryFilterTo, nil, carryFilterFrom)
		carryFilterFrom, carryFilterTo = nil, nil
	end
	aura.args.filtersGroup.args.filterPriority.dragOnClick        = function()
		C.SetFilterPriority(E.db.nameplates.units,
			unit, auraType, carryFilterFrom, true)
	end
	aura.args.filtersGroup.args.filterPriority.stateSwitchGetText = C.StateSwitchGetText
	aura.args.filtersGroup.args.filterPriority.stateSwitchOnClick = function()
		C.SetFilterPriority(E.db.nameplates.units,
			unit, auraType, carryFilterFrom, nil, nil, true)
	end
	aura.args.filtersGroup.args.spacer1                           = ACH:Description(
		L["Use drag and drop to rearrange filter priority or right click to remove a filter."] .. '\n' ..
		L
		["Use Shift+LeftClick to toggle between friendly or enemy or normal state. Normal state will allow the filter to be checked on all units. Friendly state is for friendly units only and enemy state is for enemy units."],
		9)

	return aura
end

local function GetUnitSettings(unit, name)
	local copyValues = {}
	for x, y in pairs(NP.db.units) do
		if type(y) == 'table' and x ~= unit and x ~= 'TARGET' then
			copyValues[x] = L[x]
		end
	end

	local group                                                                      = ACH:Group(name, nil, ORDER, 'tree',
		function(info) return E.db.nameplates.units[unit][info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit][info[#info]] = value
			NP:ConfigureAll()
		end)

	group.args.enable                                                                = ACH:Toggle(L["Enable"], nil, -10)
	group.args.showTestFrame                                                         = ACH:Execute(
		L["Show/Hide Test Frame"], nil, -9, function() NP:TogleTestFrame(unit) end)
	group.args.defaultSettings                                                       = ACH:Execute(L["Default Settings"],
		L["Set Settings to Default"], -8, function()
			NP:ResetSettings(unit)
			NP:ConfigureAll()
		end)
	group.args.copySettings                                                          = ACH:Select(
		L["Copy settings from"], L["Copy settings from another unit."], -7, copyValues, nil, nil, C.Blank,
		function(_, value)
			NP:CopySettings(value, unit)
			NP:ConfigureAll()
		end)

	local function CreateCustomTextGroup(objectName)
		if group.args.customText.args[objectName] then return end

		group.args.customText.args[objectName] = {
			order = -1,
			type = 'group',
			name = objectName,
			get = function(info) return E.db.nameplates.units[unit].customTexts[objectName][info[#info]] end,
			set = function(info, value)
				E.db.nameplates.units[unit].customTexts[objectName][info[#info]] = value
				NP:ConfigureAll()
			end,
			args = {
				header = { order = 1, type = 'header', name = objectName },
				delete = {
					order = 2,
					type = 'execute',
					name = L["DELETE"],
					func = function()
						group.args.customText.args[objectName] = nil
						if E.db.nameplates.units[unit].customTexts then
							E.db.nameplates.units[unit].customTexts[objectName] = nil
						end
						NP:ConfigureAll()
					end
				},
				enable = ACH:Toggle(L["Enable"], nil, 3),
				font = ACH:SharedMediaFont(L["Font"], nil, 4),
				size = ACH:Range(L["FONT_SIZE"], nil, 5, { min = 6, max = 32, step = 1 }),
				fontOutline = ACH:FontFlags(L["Font Outline"], nil, 6),
				justifyH = ACH:Select(L["JustifyH"], nil, 7, { CENTER = L["Center"], LEFT = L["Left"], RIGHT = L["Right"] }),
				xOffset = ACH:Range(L["X-Offset"], nil, 8, { min = -400, max = 400, step = 1 }),
				yOffset = ACH:Range(L["Y-Offset"], nil, 9, { min = -400, max = 400, step = 1 }),
				text_format = ACH:Input(L["Text Format"], L["TEXT_FORMAT_DESC"], 100, nil, 'full'),
			},
		}
	end

	-- General
	group.args.general                                                               = ACH:Group(L["General"], nil, 1,
		nil,
		function(info) return E.db.nameplates.units[unit][info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit][info[#info]] = value
			NP:UpdateCVars()
			NP:ConfigureAll()
		end)
	group.args.general.args.nameOnly                                                 = ACH:Toggle(L["Name Only"], nil,
		101)
	group.args.general.args.smartAuraPosition                                        = ACH:Select(
		L["Smart Aura Position"],
		L["Will show Buffs in the Debuff position when there are no Debuffs active, or vice versa."], 104,
		C.Values.SmartAuraPositions)

	-- Health
	group.args.healthGroup                                                           = ACH:Group(L["Health"], nil, 10,
		nil,
		function(info) return E.db.nameplates.units[unit].health[info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit].health[info[#info]] = value
			NP:ConfigureAll()
		end)
	group.args.healthGroup.args.enable                                               = ACH:Toggle(L["Enable"], nil, 1)
	group.args.healthGroup.args.useClassColor                                        = ACH:Toggle(L["Use Class Color"], nil, 2)
	group.args.healthGroup.args.height                                               = ACH:Range(L["Height"], nil, 3,
		{ min = minHeight, max = MaxHeight(unit), step = 1 })
	group.args.healthGroup.args.width                                                = ACH:Execute(L["Width"], nil, 4,
		function() ACD:SelectGroup('ElvUI', 'nameplates', 'generalGroup', 'clickableRange') end)

	group.args.healthGroup.args.textGroup                                            = ACH:Group(L["Text"], nil, 200, nil,
		function(info) return E.db.nameplates.units[unit].health.text[info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit].health.text[info[#info]] = value
			NP:ConfigureAll()
		end)
	group.args.healthGroup.args.textGroup.inline                                     = true
	group.args.healthGroup.args.textGroup.args.enable                                = ACH:Toggle(L["Enable"], nil, 1)
	group.args.healthGroup.args.textGroup.args.format                                = ACH:Input(L["Text Format"], nil, 2,
		nil, 'full')
	group.args.healthGroup.args.textGroup.args.position                              = ACH:Select(L["Position"], nil, 3,
		C.Values.AllPoints)
	group.args.healthGroup.args.textGroup.args.xOffset                               = ACH:Range(L["X-Offset"], nil, 5,
		{ min = -100, max = 100, step = 1 })
	group.args.healthGroup.args.textGroup.args.yOffset                               = ACH:Range(L["Y-Offset"], nil, 6,
		{ min = -100, max = 100, step = 1 })
	group.args.healthGroup.args.textGroup.args.fontGroup                             = ACH:Group('', nil, 7)
	group.args.healthGroup.args.textGroup.args.fontGroup.inline                      = true
	group.args.healthGroup.args.textGroup.args.fontGroup.args.font                   = ACH:SharedMediaFont(L["Font"], nil,
		1)
	group.args.healthGroup.args.textGroup.args.fontGroup.args.fontSize               = ACH:Range(L["Font Size"], nil, 2,
		{ min = 4, max = 60, step = 1 })
	group.args.healthGroup.args.textGroup.args.fontGroup.args.fontOutline            = ACH:FontFlags(L["Font Outline"],
		nil, 3)

	-- Heal Prediction (incoming heals + absorbs)
	group.args.healthGroup.args.healPrediction                                       = ACH:Group(L["Heal Prediction"],
		nil, 300, nil,
		function(info) return E.db.nameplates.units[unit].health.healPrediction[info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit].health.healPrediction[info[#info]] = value
			NP:ConfigureAll()
		end)
	group.args.healthGroup.args.healPrediction.inline                                = true
	group.args.healthGroup.args.healPrediction.args.enable                           = ACH:Toggle(L["Enable"],
		L["Show incoming heal and absorb bars on the nameplate health."], 1)
	group.args.healthGroup.args.healPrediction.args.absorbStyle                      = ACH:Select(L["Absorb Style"], nil,
		2,
		{
			NORMAL = L["Normal"],
			REVERSED = L["Reversed"],
			WRAPPED = L["Wrapped"],
			STACKED = L["Stacked"],
			OVERFLOW = L
				["Overflow"],
			NONE = L["None"]
		})
	group.args.healthGroup.args.healPrediction.args.anchorPoint                      = ACH:Select(L["Anchor Point"], nil,
		3, { TOP = L["Top"], BOTTOM = L["Bottom"], CENTER = L["Center"] })
	group.args.healthGroup.args.healPrediction.args.absorbTexture                    = ACH:SharedMediaStatusbar(
		L["Absorb Texture"], nil, 4)
	group.args.healthGroup.args.healPrediction.args.height                           = ACH:Range(L["Height"],
		L["Height of the prediction bars. Set to -1 to match the health bar."], 5, { min = -1, max = 60, step = 1 })
	group.args.healthGroup.args.healPrediction.args.maxOverflow                      = ACH:Range(L["Max Overflow"],
		L["Max amount of overflow past the end of the health bar (used for OVERFLOW absorb style)."], 6,
		{ min = 0, max = 1, step = 0.01, isPercent = true })

	group.args.healthGroup.args.healPrediction.args.colorsGroup                      = ACH:Group(L["Colors"], nil, 10,
		nil,
		function(info)
			local t = E.db.nameplates.units[unit].health.healPrediction.colors[info[#info]]
			return t.r, t.g, t.b, t.a
		end,
		function(info, r, g, b, a)
			local t = E.db.nameplates.units[unit].health.healPrediction.colors[info[#info]]
			t.r, t.g, t.b, t.a = r, g, b, a
			NP:ConfigureAll()
		end)
	group.args.healthGroup.args.healPrediction.args.colorsGroup.inline               = true
	group.args.healthGroup.args.healPrediction.args.colorsGroup.args.myBar           = ACH:Color(L["Personal"], nil, 1,
		true)
	group.args.healthGroup.args.healPrediction.args.colorsGroup.args.otherBar        = ACH:Color(L["Others"], nil, 2,
		true)
	group.args.healthGroup.args.healPrediction.args.colorsGroup.args.absorbs         = ACH:Color(L["Absorbs"], nil, 3,
		true)
	group.args.healthGroup.args.healPrediction.args.colorsGroup.args.healAbsorbs     = ACH:Color(L["Heal Absorbs"], nil,
		4, true)
	group.args.healthGroup.args.healPrediction.args.colorsGroup.args.overabsorbs     = ACH:Color(L["Over Absorbs"], nil,
		5, true)
	group.args.healthGroup.args.healPrediction.args.colorsGroup.args.overhealabsorbs = ACH:Color(L["Over Heal Absorbs"],
		nil, 6, true)

	-- Power
	group.args.powerGroup                                                            = ACH:Group(L["Power"], nil, 15, nil,
		function(info) return E.db.nameplates.units[unit].power[info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit].power[info[#info]] = value
			NP:ConfigureAll()
		end)
	group.args.powerGroup.args.enable                                                = ACH:Toggle(L["Enable"], nil, 1)
	group.args.powerGroup.args.hideWhenEmpty                                         = ACH:Toggle(L["Hide When Empty"],
		nil, 2)
	group.args.powerGroup.args.width                                                 = ACH:Range(L["Width"], nil, 3,
		{ min = minWidth, max = MaxWidth(unit), step = 1 })
	group.args.powerGroup.args.height                                                = ACH:Range(L["Height"], nil, 4,
		{ min = minHeight, max = MaxHeight(unit), step = 1 })
	group.args.powerGroup.args.xOffset                                               = ACH:Range(L["X-Offset"], nil, 5,
		{ min = -100, max = 100, step = 1 })
	group.args.powerGroup.args.yOffset                                               = ACH:Range(L["Y-Offset"], nil, 6,
		{ min = -100, max = 100, step = 1 })
	group.args.powerGroup.args.classColor                                            = ACH:Toggle(L["Use Class Color"],
		nil, 7)

	group.args.powerGroup.args.textGroup                                             = ACH:Group(L["Text"], nil, 200, nil,
		function(info) return E.db.nameplates.units[unit].power.text[info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit].power.text[info[#info]] = value
			NP:ConfigureAll()
		end)
	group.args.powerGroup.args.textGroup.inline                                      = true
	group.args.powerGroup.args.textGroup.args.enable                                 = ACH:Toggle(L["Enable"], nil, 1)
	group.args.powerGroup.args.textGroup.args.format                                 = ACH:Input(L["Text Format"], nil, 2,
		nil, 'full')
	group.args.powerGroup.args.textGroup.args.position                               = ACH:Select(L["Position"], nil, 3,
		C.Values.AllPoints)
	group.args.powerGroup.args.textGroup.args.xOffset                                = ACH:Range(L["X-Offset"], nil, 5,
		{ min = -100, max = 100, step = 1 })
	group.args.powerGroup.args.textGroup.args.yOffset                                = ACH:Range(L["Y-Offset"], nil, 6,
		{ min = -100, max = 100, step = 1 })
	group.args.powerGroup.args.textGroup.args.fontGroup                              = ACH:Group('', nil, 7)
	group.args.powerGroup.args.textGroup.args.fontGroup.inline                       = true
	group.args.powerGroup.args.textGroup.args.fontGroup.args.font                    = ACH:SharedMediaFont(L["Font"], nil,
		1)
	group.args.powerGroup.args.textGroup.args.fontGroup.args.fontSize                = ACH:Range(L["Font Size"], nil, 2,
		{ min = 4, max = 60, step = 1 })
	group.args.powerGroup.args.textGroup.args.fontGroup.args.fontOutline             = ACH:FontFlags(L["Font Outline"],
		nil, 3)

	-- Cast Bar
	group.args.castGroup                                                             = ACH:Group(L["Cast Bar"], nil, 20,
		nil,
		function(info) return E.db.nameplates.units[unit].castbar[info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit].castbar[info[#info]] = value
			NP:ConfigureAll()
		end)
	group.args.castGroup.args.enable                                                 = ACH:Toggle(L["Enable"], nil, 1)
	group.args.castGroup.args.sourceInterrupt                                        = ACH:Toggle(
		L["Display Interrupt Source"], L["Display the unit name who interrupted a spell on the castbar."], 2)
	group.args.castGroup.args.sourceInterruptClassColor                              = ACH:Toggle(
		L["Class Color Source"], nil, 3, nil, nil, nil, nil, nil,
		function() return not E.db.nameplates.units[unit].castbar.sourceInterrupt end)
	group.args.castGroup.args.timeToHold                                             = ACH:Range(L["Time To Hold"],
		L["How many seconds the castbar should stay visible after the cast failed or was interrupted."], 5,
		{ min = 0, max = 5, step = .1 })
	group.args.castGroup.args.width                                                  = ACH:Range(L["Width"], nil, 6,
		{ min = minWidth, max = MaxWidth(unit), step = 1 })
	group.args.castGroup.args.height                                                 = ACH:Range(L["Height"], nil, 7,
		{ min = minHeight, max = MaxHeight(unit), step = 1 })
	group.args.castGroup.args.xOffset                                                = ACH:Range(L["X-Offset"], nil, 8,
		{ min = -100, max = 100, step = 1 })
	group.args.castGroup.args.yOffset                                                = ACH:Range(L["Y-Offset"], nil, 9,
		{ min = -100, max = 100, step = 1 })

	group.args.castGroup.args.textGroup                                              = ACH:Group(L["Text"], nil, 20)
	group.args.castGroup.args.textGroup.inline                                       = true
	group.args.castGroup.args.textGroup.args.hideSpellName                           = ACH:Toggle(L["Hide Spell Name"],
		nil, 1)
	group.args.castGroup.args.textGroup.args.hideTime                                = ACH:Toggle(L["Hide Time"], nil, 2)
	group.args.castGroup.args.textGroup.args.textPosition                            = ACH:Select(L["Position"], nil, 3,
		{ ONBAR = L["Cast Bar"], ABOVE = L["Above"], BELOW = L["Below"] })
	group.args.castGroup.args.textGroup.args.castTimeFormat                          = ACH:Select(L["Cast Time Format"],
		nil, 4,
		{
			CURRENT = L["Current"],
			CURRENTMAX = L["Current / Max"],
			REMAINING = L["Remaining"],
			REMAININGMAX = L
				["Remaining / Max"]
		})
	group.args.castGroup.args.textGroup.args.channelTimeFormat                       = ACH:Select(
		L["Channel Time Format"], nil, 5,
		{
			CURRENT = L["Current"],
			CURRENTMAX = L["Current / Max"],
			REMAINING = L["Remaining"],
			REMAININGMAX = L
				["Remaining / Max"]
		})

	group.args.castGroup.args.iconGroup                                              = ACH:Group(L["Icon"], nil, 21)
	group.args.castGroup.args.iconGroup.inline                                       = true
	group.args.castGroup.args.iconGroup.args.showIcon                                = ACH:Toggle(L["Show Icon"], nil, 1)
	group.args.castGroup.args.iconGroup.args.iconPosition                            = ACH:Select(L["Position"], nil, 2,
		{ LEFT = L["Left"], RIGHT = L["Right"] })
	group.args.castGroup.args.iconGroup.args.iconSize                                = ACH:Range(L["Icon Size"], nil, 3,
		{ min = 4, max = 40, step = 1 })
	group.args.castGroup.args.iconGroup.args.iconOffsetX                             = ACH:Range(L["X-Offset"], nil, 8,
		{ min = -100, max = 100, step = 1 })
	group.args.castGroup.args.iconGroup.args.iconOffsetY                             = ACH:Range(L["Y-Offset"], nil, 9,
		{ min = -100, max = 100, step = 1 })

	group.args.castGroup.args.fontGroup                                              = ACH:Group(L["Font"], nil, 30)
	group.args.castGroup.args.fontGroup.inline                                       = true
	group.args.castGroup.args.fontGroup.args.font                                    = ACH:SharedMediaFont(L["Font"], nil,
		1)
	group.args.castGroup.args.fontGroup.args.fontSize                                = ACH:Range(L["Font Size"], nil, 2,
		{ min = 4, max = 60, step = 1 })
	group.args.castGroup.args.fontGroup.args.fontOutline                             = ACH:FontFlags(L["Font Outline"],
		nil, 3)

	-- Buffs / Debuffs
	group.args.buffsGroup                                                            = BuildAuraGroup(unit, 'buffs',
		L["Buffs"], 25)
	group.args.debuffsGroup                                                          = BuildAuraGroup(unit, 'debuffs',
		L["Debuffs"], 30)

	-- Portrait
	group.args.portraitGroup                                                         = ACH:Group(L["Portrait"], nil, 40,
		nil,
		function(info) return E.db.nameplates.units[unit].portrait[info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit].portrait[info[#info]] = value
			NP:ConfigureAll()
		end)
	group.args.portraitGroup.args.enable                                             = ACH:Toggle(L["Enable"], nil, 1)
	group.args.portraitGroup.args.classicon                                          = ACH:Toggle(L["Class Icon"],
		L["Display the class icon for players instead of the unit portrait."], 1.5)
	group.args.portraitGroup.args.width                                              = ACH:Range(L["Width"], nil, 2,
		{ min = 12, max = 64, step = 1 })
	group.args.portraitGroup.args.height                                             = ACH:Range(L["Height"], nil, 3,
		{ min = 12, max = 64, step = 1 })
	group.args.portraitGroup.args.position                                           = ACH:Select(L["Position"], nil, 4,
		C.Values.AllPositions)
	group.args.portraitGroup.args.xOffset                                            = ACH:Range(L["X-Offset"], nil, 5,
		{ min = -100, max = 100, step = 1 })
	group.args.portraitGroup.args.yOffset                                            = ACH:Range(L["Y-Offset"], nil, 6,
		{ min = -100, max = 100, step = 1 })

	-- Level
	group.args.levelGroup                                                            = ACH:Group(L["Level"], nil, 45, nil,
		function(info) return E.db.nameplates.units[unit].level[info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit].level[info[#info]] = value
			NP:ConfigureAll()
		end)
	group.args.levelGroup.args.enable                                                = ACH:Toggle(L["Enable"], nil, 1)
	group.args.levelGroup.args.textFormat                                            = ACH:Input(L["Text Format"], nil, 2,
		nil, 'full')
	group.args.levelGroup.args.position                                              = ACH:Select(L["Position"], nil, 3,
		C.Values.AllPoints)
	group.args.levelGroup.args.xOffset                                               = ACH:Range(L["X-Offset"], nil, 5,
		{ min = -100, max = 100, step = 1 })
	group.args.levelGroup.args.yOffset                                               = ACH:Range(L["Y-Offset"], nil, 6,
		{ min = -100, max = 100, step = 1 })
	group.args.levelGroup.args.fontGroup                                             = ACH:Group('', nil, 7)
	group.args.levelGroup.args.fontGroup.inline                                      = true
	group.args.levelGroup.args.fontGroup.args.font                                   = ACH:SharedMediaFont(L["Font"], nil,
		1)
	group.args.levelGroup.args.fontGroup.args.fontSize                               = ACH:Range(L["Font Size"], nil, 2,
		{ min = 4, max = 60, step = 1 })
	group.args.levelGroup.args.fontGroup.args.fontOutline                            = ACH:FontFlags(L["Font Outline"],
		nil, 3)

	-- Name
	group.args.nameGroup                                                             = ACH:Group(L["Name"], nil, 50, nil,
		function(info) return E.db.nameplates.units[unit].name[info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit].name[info[#info]] = value
			NP:ConfigureAll()
		end)
	group.args.nameGroup.args.enable                                                 = ACH:Toggle(L["Enable"], nil, 1)
	group.args.nameGroup.args.textFormat                                             = ACH:Input(L["Text Format"], nil, 2,
		nil, 'full')
	group.args.nameGroup.args.position                                               = ACH:Select(L["Position"], nil, 3,
		C.Values.AllPoints)
	group.args.nameGroup.args.xOffset                                                = ACH:Range(L["X-Offset"], nil, 5,
		{ min = -100, max = 100, step = 1 })
	group.args.nameGroup.args.yOffset                                                = ACH:Range(L["Y-Offset"], nil, 6,
		{ min = -100, max = 100, step = 1 })
	group.args.nameGroup.args.fontGroup                                              = ACH:Group('', nil, 7)
	group.args.nameGroup.args.fontGroup.inline                                       = true
	group.args.nameGroup.args.fontGroup.args.font                                    = ACH:SharedMediaFont(L["Font"], nil,
		1)
	group.args.nameGroup.args.fontGroup.args.fontSize                                = ACH:Range(L["Font Size"], nil, 2,
		{ min = 4, max = 60, step = 1 })
	group.args.nameGroup.args.fontGroup.args.fontOutline                             = ACH:FontFlags(L["Font Outline"],
		nil, 3)

	-- Raid Target Indicator
	group.args.raidTargetIndicator                                                   = ACH:Group(L["Target Marker Icon"],
		nil, 65, nil,
		function(info) return E.db.nameplates.units[unit].raidTargetIndicator[info[#info]] end,
		function(info, value)
			E.db.nameplates.units[unit].raidTargetIndicator[info[#info]] = value
			NP:ConfigureAll()
		end)
	group.args.raidTargetIndicator.args.enable                                       = ACH:Toggle(L["Enable"], nil, 1)
	group.args.raidTargetIndicator.args.size                                         = ACH:Range(L["Size"], nil, 3,
		{ min = 12, max = 64, step = 1 })
	group.args.raidTargetIndicator.args.position                                     = ACH:Select(L["Position"], nil, 4,
		C.Values.AllPositions)
	group.args.raidTargetIndicator.args.xOffset                                      = ACH:Range(L["X-Offset"], nil, 5,
		{ min = -100, max = 100, step = 1 })
	group.args.raidTargetIndicator.args.yOffset                                      = ACH:Range(L["Y-Offset"], nil, 6,
		{ min = -100, max = 100, step = 1 })

	if unit == 'FRIENDLY_PLAYER' or unit == 'ENEMY_PLAYER' then
		group.args.pvpindicator                   = ACH:Group(L["PvP Indicator"], L["Horde / Alliance / Renegade"], 60,
			nil,
			function(info) return E.db.nameplates.units[unit].pvpindicator[info[#info]] end,
			function(info, value)
				E.db.nameplates.units[unit].pvpindicator[info[#info]] = value
				NP:ConfigureAll()
			end)
		group.args.pvpindicator.args.enable       = ACH:Toggle(L["Enable"], nil, 1)
		group.args.pvpindicator.args.size         = ACH:Range(L["Size"], nil, 3, { min = 12, max = 64, step = 1 })
		group.args.pvpindicator.args.position     = ACH:Select(L["Position"], nil, 4, C.Values.AllPositions)
		group.args.pvpindicator.args.xOffset      = ACH:Range(L["X-Offset"], nil, 5, { min = -100, max = 100, step = 1 })
		group.args.pvpindicator.args.yOffset      = ACH:Range(L["Y-Offset"], nil, 6, { min = -100, max = 100, step = 1 })

		group.args.general.args.markHealers       = ACH:Toggle(L["Healer Icon"],
			L["Display a healer icon over known healers inside battlegrounds or arenas."], 105)
		group.args.general.args.markTanks         = ACH:Toggle(L["Tank Icon"],
			L["Display a tank icon over known tanks inside battlegrounds or arenas."], 106)
		group.args.healthGroup.args.useClassColor = ACH:Toggle(L["Use Class Color"], nil, 10)
	end

	if unit == 'ENEMY_NPC' or unit == 'FRIENDLY_NPC' then
		group.args.eliteIcon                    = ACH:Group(L["Elite Icon"], nil, 75, nil,
			function(info) return E.db.nameplates.units[unit].eliteIcon[info[#info]] end,
			function(info, value)
				E.db.nameplates.units[unit].eliteIcon[info[#info]] = value
				NP:ConfigureAll()
			end)
		group.args.eliteIcon.args.enable        = ACH:Toggle(L["Enable"], nil, 1)
		group.args.eliteIcon.args.size          = ACH:Range(L["Size"], nil, 3, { min = 12, max = 64, step = 1 })
		group.args.eliteIcon.args.position      = ACH:Select(L["Position"], nil, 4, C.Values.AllPositions)
		group.args.eliteIcon.args.xOffset       = ACH:Range(L["X-Offset"], nil, 5, { min = -100, max = 100, step = 1 })
		group.args.eliteIcon.args.yOffset       = ACH:Range(L["Y-Offset"], nil, 6, { min = -100, max = 100, step = 1 })

		group.args.castGroup.args.displayTarget = ACH:Toggle(L["Display Target"],
			L["Display the target of current cast."], 4)
	end

	group.args.customText = ACH:Group(L["Custom Texts"], nil, 90)
	group.args.customText.args.header = ACH:Header(L["Custom Texts"], 1)
	group.args.customText.args.createCustomText = ACH:Input(L["Create Custom Text"], nil, 2, nil, 'full',
		function() return '' end,
		function(_, textName)
			if not textName or textName == '' then return end

			for object in pairs(E.db.nameplates.units[unit]) do
				if object:lower() == textName:lower() then
					E:Print(L["The name you have selected is already in use by another element."])
					return
				end
			end

			E.db.nameplates.units[unit].customTexts = E.db.nameplates.units[unit].customTexts or {}
			for key in pairs(E.db.nameplates.units[unit].customTexts) do
				if key:lower() == textName:lower() then
					E:Print(L["The name you have selected is already in use by another element."])
					return
				end
			end

			E.db.nameplates.units[unit].customTexts[textName] = {
				text_format = '',
				size = E.db.nameplates.fontSize,
				font = E.db.nameplates.font,
				xOffset = 0,
				yOffset = 0,
				justifyH = 'CENTER',
				fontOutline = E.db.nameplates.fontOutline,
				attachTextTo = 'Health',
				enable = true,
			}

			CreateCustomTextGroup(textName)
			NP:ConfigureAll()
		end)

	if E.db.nameplates.units[unit].customTexts then
		for objectName in pairs(E.db.nameplates.units[unit].customTexts) do
			CreateCustomTextGroup(objectName)
		end
	end

	ORDER = ORDER + 2
	return group
end

-- ============================================================
-- Main Nameplates Options Entry Point
-- ============================================================

E.Options.args.nameplates                                                     = ACH:Group(L["NamePlates"], nil, 2, 'tab',
	function(info) return E.db.nameplates[info[#info]] end,
	function(info, value)
		E.db.nameplates[info[#info]] = value
		NP:ConfigureAll()
	end)
local NamePlates                                                              = E.Options.args.nameplates.args

NamePlates.intro                                                              = ACH:Description(L["NAMEPLATE_DESC"], 0)
NamePlates.reloadHint                                                         = ACH:Description(L["NAMEPLATE_ENABLE_RELOAD"], 2, nil, nil, nil, nil, nil, 'full',
	function() return not E.private.nameplates.enable or NP.Initialized end)
NamePlates.enable                                                             = ACH:Toggle(L["Enable"], nil, 1, nil, nil,
	nil,
	function(info) return E.private.nameplates[info[#info]] end,
	function(info, value)
		E.private.nameplates[info[#info]] = value
		E:StaticPopup_Show('PRIVATE_RL')
	end)
NamePlates.statusbar                                                          = ACH:SharedMediaStatusbar(
	L["StatusBar Texture"], nil, 2)
NamePlates.resetFilters                                                       = ACH:Execute(L["Reset Aura Filters"], nil,
	3, function() E:StaticPopup_Show('RESET_NP_AF') end)

-- ============================================================
-- General Group
-- ============================================================

NamePlates.generalGroup                                                       = ACH:Group(L["General"], nil, 5, nil,
	function(info) return E.db.nameplates[info[#info]] end,
	function(info, value)
		E.db.nameplates[info[#info]] = value
		NP:UpdateCVars()
		NP:ConfigureAll()
	end)

NamePlates.generalGroup.args.motionType                                       = ACH:Select(L["UNIT_NAMEPLATES_TYPES"],
	L["Set to either stack nameplates vertically or allow them to overlap."], 1,
	{
		STACKED = L["UNIT_NAMEPLATES_TYPE_2"],
		OVERLAP = L["UNIT_NAMEPLATES_TYPE_1"],
		OVERLAP_STACK = L["UNIT_NAMEPLATES_TYPE_3"],
	})
NamePlates.generalGroup.args.smoothbars                                       = ACH:Toggle(L["Smooth Bars"],
	L["Bars will transition smoothly."], 4)
NamePlates.generalGroup.args.spacer1                                          = ACH:Spacer(6, 'full')
NamePlates.generalGroup.args.overlapV                                         = ACH:Range(L["Overlap Vertical"],
	L["Percentage amount for vertical overlap of Nameplates."], 10, { min = 0, max = 3, step = .1 })
NamePlates.generalGroup.args.overlapH                                         = ACH:Range(L["Overlap Horizontal"],
	L["Percentage amount for horizontal overlap of Nameplates."], 10, { min = 0, max = 3, step = .1 })

local function IsOverlapStackMode()
	return E.db.nameplates.motionType == 'OVERLAP_STACK'
end

NamePlates.generalGroup.args.stacking                                         = ACH:Group(L["Nameplate Soft Stacking"], nil, 11, nil,
	function(info)
		E.db.nameplates.stacking = E.db.nameplates.stacking or E:CopyTable(P.nameplates.stacking)
		return E.db.nameplates.stacking[info[#info]]
	end,
	function(info, value)
		E.db.nameplates.stacking = E.db.nameplates.stacking or E:CopyTable(P.nameplates.stacking)
		E.db.nameplates.stacking[info[#info]] = value
		NP:UpdateStackingState()
	end,
	nil, nil, IsOverlapStackMode)
NamePlates.generalGroup.args.stacking.inline                                  = true
NamePlates.generalGroup.args.stacking.args.xspace                             = ACH:Range(L["Horizontal Detection"], L["Horizontal distance within which plates affect each other."], 1, { min = 40, max = 220, step = 1 })
NamePlates.generalGroup.args.stacking.args.yspace                             = ACH:Range(L["Vertical Gap"], L["Desired minimum vertical gap between overlapping enemy nameplates."], 2, { min = 8, max = 80, step = 1 })
NamePlates.generalGroup.args.stacking.args.speed                              = ACH:Range(L["Base Speed"], L["Global movement speed multiplier for soft stacking."], 3, { min = 0.1, max = 2, step = 0.05 })
NamePlates.generalGroup.args.stacking.args.speedraise                         = ACH:Range(L["Raise Speed"], nil, 4, { min = 0.1, max = 2, step = 0.05 })
NamePlates.generalGroup.args.stacking.args.speedlower                         = ACH:Range(L["Lower Speed"], nil, 5, { min = 0.1, max = 2, step = 0.05 })
NamePlates.generalGroup.args.stacking.args.speedreset                         = ACH:Range(L["Reset Speed"], nil, 6, { min = 0.2, max = 3, step = 0.05 })
NamePlates.generalGroup.args.stacking.args.maxOffset                          = ACH:Range(L["Maximum Raise"], L["Maximum vertical raise in pixels to prevent too large gaps."], 7, { min = 20, max = 220, step = 1 })
NamePlates.generalGroup.args.stacking.args.upperborder                        = ACH:Range(L["Top Screen Clamp"], L["Top screen inset while stacking is active."], 8, { min = -40, max = 80, step = 1 })
NamePlates.generalGroup.args.stacking.args.originpos                          = ACH:Range(L["Origin Offset"], L["Additional offset relative to the base plate position."], 9, { min = -80, max = 80, step = 1 })
NamePlates.generalGroup.args.fadeIn                                           = ACH:Toggle(L["Alpha Fading"], nil, 13)

NamePlates.generalGroup.args.useTargetScale                                   = ACH:Toggle(L["Use Target Scale"],
	L["Scale up the targeted nameplate."], 16)
NamePlates.generalGroup.args.targetScale                                      = ACH:Range(L["Target Scale"], nil, 17,
	{ min = 1, max = 2, step = 0.1 }, nil, nil, nil,
	function() return not E.db.nameplates.useTargetScale end)
NamePlates.generalGroup.args.nonTargetTransparency                            = ACH:Range(L["Non-Target Alpha"],
	L["Alpha of nameplates that are not your current target."], 18,
	{ min = 0.05, max = 1, step = 0.05 }, nil,
	function() return E.db.nameplates.nonTargetTransparency end,
	function(_, value)
		E.db.nameplates.nonTargetTransparency = value
		NP:ApplyEngineOption('notSelectedAlpha')
	end)

NamePlates.generalGroup.args.spacer2                                          = ACH:Spacer(20, 'full')

NamePlates.generalGroup.args.clickThrough                                     = ACH:Group(L["Click Through"], nil, 65,
	nil, function(info) return E.db.nameplates.clickThrough[info[#info]] end)
NamePlates.generalGroup.args.clickThrough.args.friendly                       = ACH:Toggle(L["Friendly"], nil, 1, nil,
	nil, nil, nil,
	function(info, value)
		E.db.nameplates.clickThrough[info[#info]] = value
		NP:ConfigureAll()
	end)
NamePlates.generalGroup.args.clickThrough.args.enemy                          = ACH:Toggle(L["Enemy"], nil, 2, nil, nil,
	nil, nil,
	function(info, value)
		E.db.nameplates.clickThrough[info[#info]] = value
		NP:ConfigureAll()
	end)

NamePlates.generalGroup.args.clickableRange                                   = ACH:Group(L["Clickable Size"], nil, 70,
	nil,
	function(info) return E.db.nameplates.plateSize[info[#info]] end,
	function(info, value)
		E.db.nameplates.plateSize[info[#info]] = value
		NP:ConfigureAll()
	end)
NamePlates.generalGroup.args.clickableRange.args.friendly                     = ACH:Group(L["Friendly"], nil, 1)
NamePlates.generalGroup.args.clickableRange.args.friendly.inline              = true
NamePlates.generalGroup.args.clickableRange.args.friendly.args.friendlyWidth  = ACH:Range(L["Clickable Width / Width"],
	L["Change the width and controls how big of an area on the screen will accept clicks to target unit."], 1,
	{ min = 50, max = 250, step = 1 })
NamePlates.generalGroup.args.clickableRange.args.friendly.args.friendlyHeight = ACH:Range(L["Clickable Height"],
	L["Controls how big of an area on the screen will accept clicks to target unit."], 2,
	{ min = 10, max = 75, step = 1 })
NamePlates.generalGroup.args.clickableRange.args.enemy                        = ACH:Group(L["Enemy"], nil, 2)
NamePlates.generalGroup.args.clickableRange.args.enemy.inline                 = true
NamePlates.generalGroup.args.clickableRange.args.enemy.args.enemyWidth        = ACH:Range(L["Clickable Width / Width"],
	L["Change the width and controls how big of an area on the screen will accept clicks to target unit."], 1,
	{ min = 50, max = 250, step = 1 })
NamePlates.generalGroup.args.clickableRange.args.enemy.args.enemyHeight       = ACH:Range(L["Clickable Height"],
	L["Controls how big of an area on the screen will accept clicks to target unit."], 2,
	{ min = 10, max = 75, step = 1 })

NamePlates.generalGroup.args.clickableRange.args.personal                     = ACH:Group(L["Personal"], nil, 3)
NamePlates.generalGroup.args.clickableRange.args.personal.inline              = true
NamePlates.generalGroup.args.clickableRange.args.personal.args.personalWidth  = ACH:Range(L["Clickable Width / Width"],
	L["Width of your own (personal) nameplate."], 1, { min = 50, max = 250, step = 1 })
NamePlates.generalGroup.args.clickableRange.args.personal.args.personalHeight = ACH:Range(L["Clickable Height"],
	L["Height of your own (personal) nameplate."], 2, { min = 10, max = 75, step = 1 })

NamePlates.generalGroup.args.cutaway                                          = ACH:Group(L["Cutaway Bars"], nil, 75)
NamePlates.generalGroup.args.cutaway.args.health                              = ACH:Group(L["Health"], nil, 1, nil,
	function(info) return E.db.nameplates.cutaway.health[info[#info]] end,
	function(info, value)
		E.db.nameplates.cutaway.health[info[#info]] = value
		NP:ConfigureAll()
	end)
NamePlates.generalGroup.args.cutaway.args.health.inline                       = true
NamePlates.generalGroup.args.cutaway.args.health.args.enabled                 = ACH:Toggle(L["Enable"], nil, 1)
NamePlates.generalGroup.args.cutaway.args.health.args.forceBlankTexture       = ACH:Toggle(L["Blank Texture"], nil, 2)
NamePlates.generalGroup.args.cutaway.args.health.args.lengthBeforeFade        = ACH:Range(L["Fade Out Delay"],
	L["How much time before the cutaway health starts to fade."], 3, { min = .1, max = 1, step = .1 }, nil, nil, nil,
	function() return not E.db.nameplates.cutaway.health.enabled end)
NamePlates.generalGroup.args.cutaway.args.health.args.fadeOutTime             = ACH:Range(L["Fade Out"],
	L["How long the cutaway health will take to fade out."], 4, { min = .1, max = 1, step = .1 }, nil, nil, nil,
	function() return not E.db.nameplates.cutaway.health.enabled end)
NamePlates.generalGroup.args.cutaway.args.power                               = ACH:Group(L["Power"], nil, 2, nil,
	function(info) return E.db.nameplates.cutaway.power[info[#info]] end,
	function(info, value)
		E.db.nameplates.cutaway.power[info[#info]] = value
		NP:ConfigureAll()
	end)
NamePlates.generalGroup.args.cutaway.args.power.inline                        = true
NamePlates.generalGroup.args.cutaway.args.power.args.enabled                  = ACH:Toggle(L["Enable"], nil, 1)
NamePlates.generalGroup.args.cutaway.args.power.args.forceBlankTexture        = ACH:Toggle(L["Blank Texture"], nil, 2)
NamePlates.generalGroup.args.cutaway.args.power.args.lengthBeforeFade         = ACH:Range(L["Fade Out Delay"],
	L["How much time before the cutaway power starts to fade."], 3, { min = .1, max = 1, step = .1 }, nil, nil, nil,
	function() return not E.db.nameplates.cutaway.power.enabled end)
NamePlates.generalGroup.args.cutaway.args.power.args.fadeOutTime              = ACH:Range(L["Fade Out"],
	L["How long the cutaway power will take to fade out."], 4, { min = .1, max = 1, step = .1 }, nil, nil, nil,
	function() return not E.db.nameplates.cutaway.power.enabled end)

NamePlates.generalGroup.args.threatGroup                                      = ACH:Group(L["Threat"], nil, 80, nil,
	function(info) return E.db.nameplates.threat[info[#info]] end,
	function(info, value)
		E.db.nameplates.threat[info[#info]] = value
		NP:ConfigureAll()
	end)
NamePlates.generalGroup.args.threatGroup.args.enable                          = ACH:Toggle(L["Enable"], nil, 0)
NamePlates.generalGroup.args.threatGroup.args.goodScale                       = ACH:Range(L["Good Scale"], nil, 1,
	{ min = .5, max = 1.5, step = .01, isPercent = true }, nil, nil, nil,
	function() return not E.db.nameplates.threat.enable end)
NamePlates.generalGroup.args.threatGroup.args.badScale                        = ACH:Range(L["Bad Scale"], nil, 2,
	{ min = .5, max = 1.5, step = .01, isPercent = true }, nil, nil, nil,
	function() return not E.db.nameplates.threat.enable end)
NamePlates.generalGroup.args.threatGroup.args.useThreatColor                  = ACH:Toggle(L["Use Threat Color"], nil, 3)
NamePlates.generalGroup.args.threatGroup.args.beingTankedByTank               = ACH:Toggle(L["Off Tank"],
	L["Use Off Tank Color when another Tank has threat."], 4, nil, nil, nil, nil, nil,
	function() return not E.db.nameplates.threat.useThreatColor end)
NamePlates.generalGroup.args.threatGroup.args.indicator                       = ACH:Toggle(L["Show Icon"], nil, 5, nil,
	nil, nil, nil, nil, function() return not E.db.nameplates.threat.enable end)

-- ============================================================
-- Blizzard Engine / CVar Group (Interface Options NamePlate panel)
-- ============================================================

NamePlates.engineGroup                                                        = ACH:Group(L["Nameplate Engine"], nil, 4,
	L["Client nameplate engine settings (CVar). Replaces the default Interface > Names panel."])

local Engine                                                                    = NamePlates.engineGroup.args

Engine.intro                                                                    = ACH:Description(L["NAMEPLATE_ENGINE_HELP"], 0)
Engine.resetDefaults                                                            = ACH:Execute(L["Restore Engine Defaults"], nil, 1,
	function()
		NP:ResetEngineDefaults()
		E:RefreshGUI()
	end)
Engine.spacerIntro                                                              = ACH:Spacer(2, 'full')

Engine.core                                                                     = ACH:Group(BlizzardL('NAMEPLATE_LABEL'), nil, 2)
Engine.core.args.predictedHealthAndPower                                        = ACH:Toggle(
	BlizzardL('NAMEPLATE_PREDICTED_HEALTH_AND_POWER'), nil, 1, nil, nil, nil, EngineGetKey('predictedHealthAndPower'),
	EngineSetKey('predictedHealthAndPower'))
Engine.core.args.loadDistance                                                   = ACH:Range(BlizzardL('NAMEPLATE_MAX_DISTANCE'),
	L["Maximum distance (yards) at which nameplates are loaded."], 2, { min = 41, max = 79, step = 1 }, nil,
	EngineGetKey('loadDistance'), EngineSetKey('loadDistance'))
Engine.core.args.dynamicScale                                                   = ACH:Toggle(
	BlizzardL('NAMEPLATES_MAKE_DYNAMIC_SCALE'), nil, 3, nil, nil, nil, EngineGetKey('dynamicScale'),
	EngineSetKey('dynamicScale'))
Engine.core.args.dynamicAlpha                                                   = ACH:Toggle(
	BlizzardL('NAMEPLATES_MAKE_DYNAMIC_ALPHA'), nil, 4, nil, nil, nil, EngineGetKey('dynamicAlpha'),
	EngineSetKey('dynamicAlpha'))
Engine.core.args.offsetY                                                        = ACH:Range(BlizzardL('NAMEPLATE_OFFSET_Y'),
	nil, 5, { min = -25, max = 25, step = 1 }, nil, EngineGetKey('offsetY'), EngineSetKey('offsetY'))
Engine.core.args.showOnlyNames                                                  = ACH:Select(
	BlizzardL('NAMEPLATE_SHOW_ONLY_NAMES'), nil, 6, showOnlyNamesValues, nil, nil,
	function() return tostring(NP:GetEngineCVar('showOnlyNames')) end,
	function(_, value) EngineSetKey('showOnlyNames')(nil, tonumber(value)) end)

Engine.friendly                                                                 = ACH:Group(L["Friendly"], nil, 3)
Engine.friendly.args.showClassColorFriendly                                     = ACH:Toggle(
	BlizzardL('SHOW_CLASS_COLOR_IN_FRIENDLY_NAMEPLATE'), nil, 1, nil, nil, nil, EngineGetKey('showClassColorFriendly'),
	EngineSetKey('showClassColorFriendly'))
Engine.friendly.args.showNameClassColorFriendly                                 = ACH:Toggle(
	BlizzardL('SHOW_NAME_CLASS_COLOR_IN_FRIENDLY_NAMEPLATE'), nil, 2, nil, nil, nil,
	EngineGetKey('showNameClassColorFriendly'), EngineSetKey('showNameClassColorFriendly'))
Engine.friendly.args.showDebuffsOnFriendly                                      = ACH:Toggle(
	BlizzardL('NAMEPLATE_SHOW_DEBUFF_ON_FRIENDLY'), nil, 3, nil, nil, nil, EngineGetKey('showDebuffsOnFriendly'),
	EngineSetKey('showDebuffsOnFriendly'))
Engine.friendly.args.otherAtBase                                                = ACH:Toggle(
	BlizzardL('NAMEPLATE_OTHER_AT_BASE'), nil, 4, nil, nil, nil, EngineGetKey('otherAtBase'),
	EngineSetKey('otherAtBase'))
Engine.friendly.args.targetRadialPosition                                       = ACH:Select(
	BlizzardL('NAMEPLATE_TARGET_RADIAL_POSITION'), nil, 5, targetRadialValues, nil, nil,
	function() return tostring(NP:GetEngineCVar('targetRadialPosition')) end,
	function(_, value) EngineSetKey('targetRadialPosition')(nil, tonumber(value)) end)

Engine.scaleAlpha                                                               = ACH:Group(L["Scale & Alpha"], nil, 4)
Engine.scaleAlpha.args.horizontalScale                                          = ACH:Range(
	BlizzardL('NAMEPLATE_HORIZONTAL_SCALE'), nil, 1, { min = 0, max = 2, step = 0.05 }, nil,
	EngineGetKey('horizontalScale'), EngineSetKey('horizontalScale'))
Engine.scaleAlpha.args.verticalScale                                            = ACH:Range(
	BlizzardL('NAMEPLATE_VERTICAL_SCALE'), nil, 2, { min = 0, max = 2, step = 0.05 }, nil,
	EngineGetKey('verticalScale'), EngineSetKey('verticalScale'))
Engine.scaleAlpha.args.globalScale                                              = ACH:Range(
	BlizzardL('NAMEPLATE_GLOBAL_SCALE'), nil, 3, { min = 0.5, max = 1.5, step = 0.1 }, nil,
	EngineGetKey('globalScale'), EngineSetKey('globalScale'))
Engine.scaleAlpha.args.selectedScale                                            = ACH:Range(BlizzardL('NAMEPLATE_SELECTED_SCALE'),
	L["Used when |cff1784d1Use Target Scale|r is disabled in General."], 4, { min = 1, max = 2, step = 0.1 }, nil,
	EngineGetKey('selectedScale'), EngineSetKey('selectedScale'), nil,
	function() return E.db.nameplates.useTargetScale end)
Engine.scaleAlpha.args.occludedAlphaMult                                        = ACH:Range(
	BlizzardL('NAMEPLATE_OCCLUDED_ALPHA_MULT'), nil, 10, { min = 0.05, max = 1, step = 0.05 }, nil,
	EngineGetKey('occludedAlphaMult'), EngineSetKey('occludedAlphaMult'))
Engine.scaleAlpha.args.selectedAlpha                                            = ACH:Range(
	BlizzardL('NAMEPLATE_SELECTED_ALPHA'), nil, 11, { min = 0.05, max = 1, step = 0.05 }, nil,
	EngineGetKey('selectedAlpha'), EngineSetKey('selectedAlpha'))
Engine.personal                                                                 = ACH:Group(L["Personal"], nil, 5)
Engine.personal.args.showSelf                                                     = ACH:Toggle(
	BlizzardL('DISPLAY_PERSONAL_RESOURCE'), nil, 1, nil, nil, nil, EngineGetKey('showSelf'), EngineSetKey('showSelf'))
Engine.personal.args.personalClickThrough                                       = ACH:Toggle(
	BlizzardL('PERSONAL_RESOURCE_CLICK_THROUGH'), nil, 2, nil, nil, nil, EngineGetKey('personalClickThrough'),
	EngineSetKey('personalClickThrough'))
Engine.personal.args.selfAlpha                                                  = ACH:Range(
	BlizzardL('PERSONAL_RESOURCE_ALPHA'), nil, 3, { min = 0.05, max = 1, step = 0.05 }, nil, EngineGetKey('selfAlpha'),
	EngineSetKey('selfAlpha'))
Engine.personal.args.personalShowAlways                                         = ACH:Toggle(
	BlizzardL('DISPLAY_PERSONAL_SHOW_ALWAYS'), nil, 4, nil, nil, nil, EngineGetKey('personalShowAlways'),
	EngineSetKey('personalShowAlways'))
Engine.personal.args.personalShowInCombat                                       = ACH:Toggle(
	BlizzardL('DISPLAY_PERSONAL_SHOW_IN_COMBAT'), nil, 5, nil, nil, nil, EngineGetKey('personalShowInCombat'),
	EngineSetKey('personalShowInCombat'))
Engine.personal.args.personalShowWithTarget                                     = ACH:Select(
	BlizzardL('DISPLAY_PERSONAL_SHOW_WITH_TARGET'), nil, 6, personalShowWithTargetValues, nil, nil,
	function() return tostring(NP:GetEngineCVar('personalShowWithTarget')) end,
	function(_, value) EngineSetKey('personalShowWithTarget')(nil, tonumber(value)) end)
Engine.personal.args.personalOffsetY                                            = ACH:Range(
	BlizzardL('NAMEPLATE_PERSONAL_OFFSET_Y'), nil, 7, { min = -25, max = 25, step = 1 }, nil,
	EngineGetKey('personalOffsetY'), EngineSetKey('personalOffsetY'))
Engine.personal.args.resourceOnTarget                                           = ACH:Toggle(
	BlizzardL('DISPLAY_PERSONAL_RESOURCE_ON_ENEMY'), nil, 8, nil, nil, nil, EngineGetKey('resourceOnTarget'),
	EngineSetKey('resourceOnTarget'))
Engine.personal.args.classResourceTopInset                                      = ACH:Range(
	BlizzardL('NAMEPLATE_PERSONAL_RESOURCE_TOP_INSET'), nil, 9, { min = 0, max = 0.5, step = 0.01 }, nil,
	EngineGetKey('classResourceTopInset'), EngineSetKey('classResourceTopInset'))

-- ============================================================
-- Colors Group
-- ============================================================

NamePlates.colorsGroup                                                        = ACH:Group(L["Colors"], nil, 20)

NamePlates.colorsGroup.args.general                                           = ACH:Group(L["General"], nil, 1, nil,
	function(info)
		local t, d = E.db.nameplates.colors[info[#info]], P.nameplates.colors[info[#info]]
		return t.r, t.g, t.b, t.a, d.r, d.g, d.b, d.a
	end,
	function(info, r, g, b, a)
		local t = E.db.nameplates.colors[info[#info]]
		t.r, t.g, t.b, t.a = r, g, b, a
		NP:ConfigureAll()
	end)
NamePlates.colorsGroup.args.general.inline                                    = true

do
	local function GetToggle(info) return E.db.nameplates.colors[info[#info]] end
	local function SetToggle(info, value)
		E.db.nameplates.colors[info[#info]] = value
		NP:ConfigureAll()
	end
	NamePlates.colorsGroup.args.general.args.preferGlowColor = ACH:Toggle(L["Prefer Target Color"],
		L["When this is enabled, Low Health Threshold colors will not be displayed while targeted."], 1, nil, nil, nil,
		GetToggle, SetToggle)
	NamePlates.colorsGroup.args.general.args.auraByDispels   = ACH:Toggle(L["Borders By Dispel"], nil, 2, nil, nil, nil,
		GetToggle, SetToggle)
	NamePlates.colorsGroup.args.general.args.auraByType      = ACH:Toggle(L["Borders By Type"], nil, 3, nil, nil, nil,
		GetToggle, SetToggle)
end
NamePlates.colorsGroup.args.general.args.spacer1                   = ACH:Spacer(5, 'full')
NamePlates.colorsGroup.args.general.args.glowColor                 = ACH:Color(L["Target Indicator Color"], nil, 6, true)
NamePlates.colorsGroup.args.general.args.lowHealthColor            = ACH:Color(L["Low Health Color"],
	L["Color when at Low Health Threshold"], 7, true)
NamePlates.colorsGroup.args.general.args.lowHealthHalf             = ACH:Color(L["Low Health Half"],
	L["Color when at half of the Low Health Threshold"], 8, true)

NamePlates.colorsGroup.args.threat                                 = ACH:Group(L["Threat"], nil, 2, nil,
	function(info)
		local t, d = E.db.nameplates.colors.threat[info[#info]], P.nameplates.colors.threat[info[#info]]
		return t.r, t.g, t.b, t.a, d.r, d.g, d.b, d.a
	end,
	function(info, r, g, b, a)
		local t = E.db.nameplates.colors.threat[info[#info]]
		t.r, t.g, t.b, t.a = r, g, b, a
		NP:ConfigureAll()
	end,
	function() return not E.db.nameplates.threat.useThreatColor end)
NamePlates.colorsGroup.args.threat.inline                          = true
NamePlates.colorsGroup.args.threat.args.goodColor                  = ACH:Color(L["Good Color"], nil, 1)
NamePlates.colorsGroup.args.threat.args.goodTransition             = ACH:Color(L["Good Transition Color"], nil, 2)
NamePlates.colorsGroup.args.threat.args.badTransition              = ACH:Color(L["Bad Transition Color"], nil, 3)
NamePlates.colorsGroup.args.threat.args.badColor                   = ACH:Color(L["Bad Color"], nil, 4)
NamePlates.colorsGroup.args.threat.args.offTankColor               = ACH:Color(L["Off Tank"], nil, 5, nil, nil, nil, nil,
	nil, function() return not E.db.nameplates.threat.beingTankedByTank or not E.db.nameplates.threat.useThreatColor end)
NamePlates.colorsGroup.args.threat.args.offTankColorGoodTransition = ACH:Color(L["Off Tank Good Transition"], nil, 6, nil,
	nil, nil, nil,
	function() return not E.db.nameplates.threat.beingTankedByTank or not E.db.nameplates.threat.useThreatColor end)
NamePlates.colorsGroup.args.threat.args.offTankColorBadTransition  = ACH:Color(L["Off Tank Bad Transition"], nil, 7, nil,
	nil, nil, nil,
	function() return not E.db.nameplates.threat.beingTankedByTank or not E.db.nameplates.threat.useThreatColor end)

NamePlates.colorsGroup.args.castGroup                              = ACH:Group(L["Cast Bar"], nil, 3, nil,
	function(info)
		local t, d = E.db.nameplates.colors[info[#info]], P.nameplates.colors[info[#info]]
		return t.r, t.g, t.b, t.a, d.r, d.g, d.b
	end,
	function(info, r, g, b)
		local t = E.db.nameplates.colors[info[#info]]
		t.r, t.g, t.b = r, g, b
		NP:ConfigureAll()
	end)
NamePlates.colorsGroup.args.castGroup.inline                       = true
NamePlates.colorsGroup.args.castGroup.args.castColor               = ACH:Color(L["Interruptible"], nil, 1)
NamePlates.colorsGroup.args.castGroup.args.castNoInterruptColor    = ACH:Color(L["Non-Interruptible"], nil, 2)
NamePlates.colorsGroup.args.castGroup.args.castInterruptedColor    = ACH:Color(L["Interrupted"], nil, 3)
NamePlates.colorsGroup.args.castGroup.args.castbarDesaturate       = ACH:Toggle(L["Desaturated Icon"],
	L["Show the castbar icon desaturated if a spell is not interruptible."], 4, nil, nil, nil,
	function(info) return E.db.nameplates.colors[info[#info]] end,
	function(info, value)
		E.db.nameplates.colors[info[#info]] = value
		NP:ConfigureAll()
	end)

NamePlates.colorsGroup.args.reactions                              = ACH:Group(L["Reaction Colors"], nil, 5, nil,
	function(info)
		local t, d = E.db.nameplates.colors.reactions[info[#info]], P.nameplates.colors.reactions[info[#info]]
		return t.r, t.g, t.b, t.a, d.r, d.g, d.b
	end,
	function(info, r, g, b)
		local t = E.db.nameplates.colors.reactions[info[#info]]
		t.r, t.g, t.b = r, g, b
		NP:ConfigureAll()
	end)
NamePlates.colorsGroup.args.reactions.inline                       = true
NamePlates.colorsGroup.args.reactions.args.bad                     = ACH:Color(L["Enemy"], nil, 1)
NamePlates.colorsGroup.args.reactions.args.neutral                 = ACH:Color(L["Neutral"], nil, 2)
NamePlates.colorsGroup.args.reactions.args.good                    = ACH:Color(L["Friendly"], nil, 3)
NamePlates.colorsGroup.args.reactions.args.friendlyPlayer          = ACH:Color(L["Friendly Player"], nil, 4)

NamePlates.colorsGroup.args.misc                                   = ACH:Group(L["Misc"], nil, 6, nil,
	function(info)
		local t, d = E.db.nameplates.colors[info[#info]], P.nameplates.colors[info[#info]]
		return t.r, t.g, t.b, t.a, d.r, d.g, d.b
	end,
	function(info, r, g, b)
		local t = E.db.nameplates.colors[info[#info]]
		t.r, t.g, t.b = r, g, b
		NP:ConfigureAll()
	end)
NamePlates.colorsGroup.args.misc.inline                            = true
NamePlates.colorsGroup.args.misc.args.tapped                       = ACH:Color(L["Tapped"], nil, 1)

-- ============================================================
-- Per-Unit Settings
-- ============================================================

NamePlates.unitsGroup                                              = ACH:Group(L["Units"], nil, 15, 'tree')
local Units                                                        = NamePlates.unitsGroup.args

Units.FRIENDLY_PLAYER                                              = GetUnitSettings('FRIENDLY_PLAYER',
	L["FRIENDLY_PLAYER"])
Units.ENEMY_PLAYER                                                 = GetUnitSettings('ENEMY_PLAYER', L["ENEMY_PLAYER"])
Units.FRIENDLY_NPC                                                 = GetUnitSettings('FRIENDLY_NPC', L["FRIENDLY_NPC"])
Units.ENEMY_NPC                                                    = GetUnitSettings('ENEMY_NPC', L["ENEMY_NPC"])
Units.PLAYER                                                       = GetUnitSettings('PLAYER', L["Player"])

-- Player unit: classpower (combo points under the player's own nameplate, Rogue/Druid only)
Units.PLAYER.args.classpower                                       = ACH:Group(L["Class Power"], nil, 10, nil,
	function(info) return E.db.nameplates.units.PLAYER.classpower[info[#info]] end,
	function(info, value)
		E.db.nameplates.units.PLAYER.classpower[info[#info]] = value
		NP:ClassPower_UpdateRuneFrameVisibility()
		NP:ConfigureAll()
	end)
Units.PLAYER.args.classpower.args.enable                           = ACH:Toggle(L["Enable"], nil, 1)
Units.PLAYER.args.classpower.args.onlyInCombat                     = ACH:Toggle(L["Only In Combat"], nil, 2, nil, nil,
	nil, nil, nil, function() return not E.db.nameplates.units.PLAYER.classpower.enable end)
Units.PLAYER.args.classpower.args.width                            = ACH:Range(L["Width"], nil, 3,
	{ min = 20, max = 300, step = 1 })
Units.PLAYER.args.classpower.args.height                          = ACH:Range(L["Height"], nil, 4,
	{ min = 2, max = 30, step = 1 })
Units.PLAYER.args.classpower.args.xOffset                         = ACH:Range(L["X-Offset"], nil, 5,
	{ min = -200, max = 200, step = 1 })
Units.PLAYER.args.classpower.args.yOffset                         = ACH:Range(L["Y-Offset"], nil, 6,
	{ min = -100, max = 100, step = 1 })

-- Target unit: classpower (combo points for Rogue/Druid, DK runes on the targeted nameplate)
Units.TARGET                                                       = ACH:Group(L["TARGET"], nil, 10, 'tree')
Units.TARGET.args.classpower                                       = ACH:Group(L["Class Power"], nil, 1, nil,
	function(info) return E.db.nameplates.units.TARGET.classpower[info[#info]] end,
	function(info, value)
		E.db.nameplates.units.TARGET.classpower[info[#info]] = value
		NP:ClassPower_UpdateRuneFrameVisibility()
		NP:ConfigureAll()
	end)
Units.TARGET.args.classpower.args.enable                           = ACH:Toggle(L["Enable"], nil, 1)
Units.TARGET.args.classpower.args.onlyInCombat                     = ACH:Toggle(L["Only In Combat"], nil, 2, nil, nil,
	nil, nil, nil, function() return not E.db.nameplates.units.TARGET.classpower.enable end)
Units.TARGET.args.classpower.args.width                            = ACH:Range(L["Width"], nil, 3,
	{ min = 20, max = 300, step = 1 })
Units.TARGET.args.classpower.args.height                           = ACH:Range(L["Height"], nil, 4,
	{ min = 2, max = 30, step = 1 })
Units.TARGET.args.classpower.args.xOffset                          = ACH:Range(L["X-Offset"], nil, 5,
	{ min = -200, max = 200, step = 1 })
Units.TARGET.args.classpower.args.yOffset                          = ACH:Range(L["Y-Offset"], nil, 6,
	{ min = -100, max = 100, step = 1 })

