local E, _, V, P, G = unpack(ElvUI)
local C, L = unpack(E.Config)
local D = E:GetModule('Distributor')
local NP = E:GetModule('NamePlates')
local LibDeflate = E.Libs.Deflate
local ACH = E.Libs.ACH

local wipe, pairs, strmatch = wipe, pairs, strmatch
local next, sort, format = next, sort, format

local filters = {}
local exportList = {}
local sortedClasses = E:CopyTable({}, CLASS_SORT_ORDER)
sort(sortedClasses)

C.StyleFilterSelected = nil

local StyleFilters = E.Options.args.nameplates.args.filters.args
local StyleFallback = NP:StyleFilterCopyDefaults()

local function GetFilter(collect, profile)
	local setting = (profile and E.db.nameplates.filters[C.StyleFilterSelected]) or E.global.nameplates.filters[C.StyleFilterSelected] or StyleFallback

	if collect and setting then
		return setting.triggers, setting.actions
	else
		return setting
	end
end
C.StyleFilterGetFilter = GetFilter

local function DisabledFilter()
	local profileTriggers = GetFilter(true, true)
	return not (profileTriggers and profileTriggers.enable)
end
C.StyleFilterDisabledFilter = DisabledFilter

local function GetFilters(info)
	wipe(filters)

	local list = E.global.nameplates.filters
	if not (list and next(list)) then
		return filters
	end

	local profile, priority, name = E.db.nameplates.filters
	for filter, content in pairs(list) do
		if info[#info] == 'selectFilter' then
			priority = (content.triggers and content.triggers.priority) or '?'
			name = (content.triggers and profile[filter] and profile[filter].triggers and profile[filter].triggers.enable and filter) or (content.triggers and format('|cFF666666%s|r', filter)) or filter
			filters[filter] = format('|cFFffff00(%s)|r %s', priority, name)
		else
			filters[filter] = filter
		end
	end

	return filters
end

function C:StyleFilterSetConfig(filter)
	C.StyleFilterSelected = filter

	E.Libs.AceConfigDialog:SelectGroup('ElvUI', 'nameplates', 'filters', filter and 'triggers' or 'import')
end

local function validateString(_, value) return value and not strmatch(value, '^[%s%p]-$') end

StyleFilters.removeFilter = ACH:Select(L["Delete Filter"], L["Delete a created filter, you cannot delete pre-existing filters, only custom ones."], 3, function() wipe(filters) for filterName in next, E.global.nameplates.filters do if not G.nameplates.filters[filterName] then filters[filterName] = filterName end end return filters end, true, nil, nil, function(_, value) for profile in pairs(E.data.profiles) do if E.data.profiles[profile].nameplates and E.data.profiles[profile].nameplates.filters then E.data.profiles[profile].nameplates.filters[value] = nil end end E.global.nameplates.filters[value] = nil exportList[value] = nil NP:ConfigureAll() C:StyleFilterSetConfig() end)

-- Import / Export
local function DecodeString(text)
	local profileType, profileKey, profileData = D:Decode(text)
	if profileType == 'styleFilters' then
		local decodedText = (profileData and E:TableToLuaString(profileData)) or nil
		return D:CreateProfileExport(profileType, profileKey, decodedText)
	else
		return ''
	end
end

local function DecodeLabel(label, text)
	if not validateString(nil, text) then
		label.name = ''
		return text
	end

	local decode = DecodeString(text)
	if decode then
		return decode
	else
		label.name = L["Error decoding data. Import string may be corrupted!"]
		return text
	end
end

do
	local importText = ''
	local label = ACH:Description('', -9)
	local function Import_Set() end
	local function Import_Get() return importText end
	local function Import_TextChanged(text) if text ~= importText then importText = text end end
	local function Import_Clear() label.name = '' importText = '' end
	local function Import_Decode() importText = DecodeLabel(label, importText) end
	local function Import_Button()
		if not validateString(nil, importText) then return end
		label.name = (D:Decode(importText) == 'styleFilters' and D:ImportProfile(importText) and L["Profile imported successfully!"]) or L["Error decoding data. Import string may be corrupted!"]
	end

	StyleFilters.import = ACH:Group(L["Import"], nil, 15)
	StyleFilters.import.args.importButton = ACH:Execute(L["Import"], nil, 2, Import_Button, nil, nil, 120)
	StyleFilters.import.args.importDecode = ACH:Execute(L["Decode"], nil, 3, Import_Decode, nil, nil, 120)
	StyleFilters.import.args.importClear = ACH:Execute(L["Clear"], nil, 4, Import_Clear, nil, nil, 120)
	StyleFilters.import.args.label = label

	StyleFilters.import.args.text = ACH:Input('', nil, -10, 10, 'full', Import_Get, Import_Set)
	StyleFilters.import.args.text.disableButton = true
	StyleFilters.import.args.text.focusSelect = true
	StyleFilters.import.args.text.textChanged = Import_TextChanged
end

do
	local exportText = ''
	local EXPORT_PREFIX = '!E1!'
	local label = ACH:Description('', 10)
	local function Filters_Empty() if not next(exportList) then StyleFilters.export.args.text.hidden = true return true end end
	local function Filters_Get(_, key) Filters_Empty() return exportList[key] end
	local function Filters_Set(_, key, value) exportList[key] = value or nil end
	local function Export_Get() label.name = '' return exportText end
	local function Export_Set() end
	local function Export(which)
		local data = {nameplates = {filters = {}}}

		if Filters_Empty() then return end

		for key in pairs(exportList) do
			data.nameplates.filters[key] = E:CopyTable({}, E.global.nameplates.filters[key])
		end

		NP:StyleFilterClearDefaults(data.nameplates.filters)
		data = E:RemoveTableDuplicates(data, G, D.GeneratedKeys.global)

		local printableString
		if which == 'text' then
			local serialString = D:Serialize(data)
			local exportString = D:CreateProfileExport('styleFilters', 'styleFilters', serialString)
			local compressedData = LibDeflate:CompressDeflate(exportString, LibDeflate.compressLevel)
			local printable = LibDeflate:EncodeForPrint(compressedData)
			if printable then
				printableString = format('%s%s', EXPORT_PREFIX, printable)
			end
		elseif which == 'luaTable' then
			local exportString = E:TableToLuaString(data)
			printableString = D:CreateProfileExport('styleFilters', 'styleFilters', exportString)
		elseif which == 'luaPlugin' then
			printableString = E:ProfileTableToPluginFormat(data, 'styleFilters')
		end

		exportText = printableString or nil
		StyleFilters.export.args.text.hidden = not exportText
	end

	StyleFilters.export = ACH:Group(L["Export"], nil, 20)
	StyleFilters.export.args.filters = ACH:MultiSelect(L["Filters"], nil, 2, GetFilters, nil, nil, Filters_Get, Filters_Set, nil, nil, true)
	StyleFilters.export.args.exportButton = ACH:Execute(L["Export"], nil, 3, function() Export('text') end, nil, nil, 120)
	StyleFilters.export.args.exportDecode = ACH:Execute(L["Table"], nil, 4, function() Export('luaTable') end, nil, nil, 120)
	StyleFilters.export.args.exportPlugin = ACH:Execute(L["Plugin"], nil, 5, function() Export('luaPlugin') end, nil, nil, 120)
	StyleFilters.export.args.label = label

	StyleFilters.export.args.text = ACH:Input('', nil, -10, 10, 'full', Export_Get, Export_Set, nil, true)
	StyleFilters.export.args.text.disableButton = true
	StyleFilters.export.args.text.focusSelect = true
end
