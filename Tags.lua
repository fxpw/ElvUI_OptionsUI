local E, _, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local _, L = unpack(select(2, ...))

local format = format


E.Options.args.tagGroup = {
	order = 925,
	type = "group",
	name = L["Available Tags"],
	childGroups = "tab",
	args = {
		-- link = {
		-- 	order = 1,
		-- 	type = "input",
		-- 	width = "full",
		-- 	name = L["Guide:"],
		-- 	get = function() return "https://www.tukui.org/forum/viewtopic.php?f=9&t=6" end,
		-- },
		header = {
			order = 2,
			type = "header",
			name = L["Available Tags"],
		},
		-- Colors = {
		-- 	type = "group",
		-- 	name = L["Colors"],
		-- 	args = {
		-- 		header = {
		-- 			order = 0,
		-- 			type = "header",
		-- 			name = L["Colors"],
		-- 		},
		-- 		customTagColorInfo = {
		-- 			order = 1,
		-- 			type = "input",
		-- 			width = "full",
		-- 			name = L["Custom color your Text: replace the XXXXXX with a Hex color code"],
		-- 			get = function() return "||cffXXXXXX [теги] или текст здесь ||r" end
		-- 		}
		-- 	}
		-- },
	},
}

for Tag in next, E.oUF.Tags.Methods do
	if not E.TagInfo[Tag] then
		E.TagInfo[Tag] = {category = L["Miscellaneous"], description = ""}
		--E:Print("['"..Tag.."'] = { category = 'Miscellaneous', description = '' }")
	end

	if not E.Options.args.tagGroup.args[E.TagInfo[Tag].category] then
		E.Options.args.tagGroup.args[E.TagInfo[Tag].category] = {
			type = "group",
			name = E.TagInfo[Tag].category,
			args = {
				header = {
					order = 0,
					type = "header",
					name = E.InfoColor..E.TagInfo[Tag].category,
				}
			}
		}
	end

	E.Options.args.tagGroup.args[E.TagInfo[Tag].category].args[Tag] = {
		type = "input",
		name = E.TagInfo[Tag].description,
		order = E.TagInfo[Tag].order or nil,
		width = "full",
		get = function() return format("[%s]", Tag) end,
	}
end
E.OriginalOptions = {'plugins'}
for key in pairs(E.Options.args) do
	tinsert(E.OriginalOptions, key)
end
setmetatable(E.OriginalOptions, {__newindex = E.noop})
-- фиксированный порядок разделов в левой колонке окна (раньше filters/profiles имели -10)
local orderList = {
	general = 1, actionbar = 2, auras = 3, bags = 4, chat = 5, cooldown = 6,
	databars = 7, datatexts = 8, maps = 9, nameplates = 10, skins = 11,
	tooltip = 12, unitframe = 13, styleFilters = 14, modulecontrol = 15,
	filters = 16, tagGroup = 17, sirus = 18, credits = 19, profiles = 20,
}
for key, order in pairs(orderList) do
	if E.Options.args[key] then
		E.Options.args[key].order = order
	end
end
