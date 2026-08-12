local E, _, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local C, L = unpack(select(2, ...))
local mod = E:GetModule("DataBars")

E.Options.args.databars = {
	type = "group",
	name = L["DataBars"],
	childGroups = "tab",
	get = function(info) return E.db.databars[info[#info]] end,
	set = function(info, value) E.db.databars[info[#info]] = value end,
	args = {
		intro = {
			order = 1,
			type = "description",
			name = L["DATABAR_DESC"]
		},
		spacer = {
			order = 2,
			type = "description",
			name = ""
		},
		general = {
			order = 3,
			type = "group",
			name = L["General"],
			get = function(info) return E.db.databars[info[#info]] end,
			set = function(info, value) E.db.databars[info[#info]] = value mod:UpdateAll() end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["General"]
				},
				transparent = {
					order = 2,
					type = "toggle",
					name = L["Transparent"]
				},
				customTexture = {
					order = 3,
					type = "toggle",
					name = L["Custom StatusBar"]
				},
				statusbar = {
					order = 4,
					type = "select",
					dialogControl = "LSM30_Statusbar",
					name = L["StatusBar Texture"],
					values = AceGUIWidgetLSMlists.statusbar,
					disabled = function() return not E.db.databars.customTexture end
				}
			}
		},
		experience = {
			order = 4,
			type = "group",
			name = L["XPBAR_LABEL"],
			get = function(info) return mod.db.experience[info[#info]] end,
			set = function(info, value) mod.db.experience[info[#info]] = value mod:ExperienceBar_UpdateDimensions() end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["XPBAR_LABEL"]
				},
				enable = {
					order = 2,
					type = "toggle",
					name = L["Enable"],
					set = function(info, value) mod.db.experience[info[#info]] = value mod:ExperienceBar_Toggle() end
				},
				mouseover = {
					order = 3,
					type = "toggle",
					name = L["Mouseover"]
				},
				hideAtMaxLevel = {
					order = 4,
					type = "toggle",
					name = L["Hide At Max Level"],
					set = function(info, value) mod.db.experience[info[#info]] = value mod:ExperienceBar_Update() end
				},
				hideInVehicle = {
					order = 5,
					type = "toggle",
					name = L["Hide In Vehicle"],
					set = function(info, value) mod.db.experience[info[#info]] = value mod:ExperienceBar_Update() end
				},
				hideInCombat = {
					order = 6,
					type = "toggle",
					name = L["Hide In Combat"],
					set = function(info, value) mod.db.experience[info[#info]] = value mod:ExperienceBar_Update() end
				},
				showBubbles = {
					order = 7,
					type = "toggle",
					name = L["Show Bubbles"]
				},
				spacer = {
					order = 8,
					type = "description",
					name = " "
				},
				orientation = {
					order = 9,
					type = "select",
					name = L["Statusbar Fill Orientation"],
					desc = L["Direction the bar moves on gains/losses"],
					values = {
						["AUTOMATIC"] = L["Automatic"],
						["HORIZONTAL"] = L["Horizontal"],
						["VERTICAL"] = L["Vertical"]
					}
				},
				width = {
					order = 10,
					type = "range",
					name = L["Width"],
					min = 5, max = ceil(GetScreenWidth() or 800), step = 1
				},
				height = {
					order = 11,
					type = "range",
					name = L["Height"],
					min = 5, max = ceil(GetScreenHeight() or 800), step = 1
				},
				font = {
					order = 12,
					type = "select", dialogControl = "LSM30_Font",
					name = L["Font"],
					values = AceGUIWidgetLSMlists.font
				},
				textSize = {
					order = 13,
					type = "range",
					name = L["FONT_SIZE"],
					min = 6, max = 22, step = 1
				},
				fontOutline = {
					order = 14,
					type = "select",
					name = L["Font Outline"],
					values = C.Values.FontFlags
				},
				textFormat = {
					order = 15,
					type = "select",
					name = L["Text Format"],
					width = "double",
					values = {
						NONE = L["NONE"],
						CUR = L["Current"],
						REM = L["Remaining"],
						PERCENT = L["Percent"],
						CURMAX = L["Current - Max"],
						CURPERC = L["Current - Percent"],
						CURREM = L["Current - Remaining"],
						CURPERCREM = L["Current - Percent (Remaining)"],
					},
					set = function(info, value) mod.db.experience[info[#info]] = value mod:ExperienceBar_Update() end
				},
				displayText = {
					order = 16,
					type = "toggle",
					name = L["Display Text"]
				},
				clickThrough = {
					order = 17,
					type = "toggle",
					name = L["Click Through"]
				},
				frameLevel = {
					order = 18,
					type = "range",
					name = L["Frame Level"],
					min = 1, max = 128, step = 1
				},
				frameStrata = {
					order = 19,
					type = "select",
					name = L["Frame Strata"],
					values = C.Values.Strata
				},
				spacer2 = {
					order = 20,
					type = "description",
					name = " "
				},
				anchorPoint = {
					order = 21,
					type = "select",
					name = L["Anchor Point"],
					values = C.Values.AllPoints
				},
				xOffset = {
					order = 22,
					type = "range",
					name = L["X-Offset"],
					min = -300, max = 300, step = 1
				},
				yOffset = {
					order = 23,
					type = "range",
					name = L["Y-Offset"],
					min = -300, max = 300, step = 1
				},
				questXP = {
					order = 24,
					type = "group",
					name = L["Quest XP"],
					guiInline = true,
					get = function(info) return mod.db.experience.questXP[info[#info]] end,
					disabled = function() return not mod.db.experience.enable or not mod.db.experience.questXP.enable end,
					args = {
						enable = {
							order = 1,
							type = "toggle",
							name = L["Enable"],
							set = function(info, value)
								mod.db.experience.questXP.enable = value
								mod:ExperienceBar_QuestXPToggle()
							end,
							disabled = function() return not mod.db.experience.enable end
						},
						color = {
							order = 2,
							type = "color",
							name = L["Quest XP Color"],
							hasAlpha = true,
							get = function(info)
								local t = mod.db.experience.questXP.color
								return t.r, t.g, t.b, t.a, 0, 1, 0, 0.4
							end,
							set = function(info, r, g, b, a)
								local t = mod.db.experience.questXP.color
								t.r, t.g, t.b, t.a = r, g, b, a
								mod:ExperienceBar_UpdateDimensions()
							end
						},
						questCurrentZoneOnly = {
							order = 3,
							type = "toggle",
							name = L["Quests in Current Zone Only"],
							set = function(info, value)
								mod.db.experience.questXP.questCurrentZoneOnly = value
								mod:ExperienceBar_QuestXPUpdate()
							end
						},
						questCompletedOnly = {
							order = 4,
							type = "toggle",
							name = L["Completed Quests Only"],
							set = function(info, value)
								mod.db.experience.questXP.questCompletedOnly = value
								mod:ExperienceBar_QuestXPUpdate()
							end
						},
						tooltip = {
							order = 5,
							type = "toggle",
							name = L["Add Quest XP to Tooltip"],
							set = function(info, value) mod.db.experience.questXP.tooltip = value end
						}
					}
				}
			}
		},
		petExperience = {
			order = 5,
			type = "group",
			name = L["Pet Experience"],
			get = function(info) return mod.db.petExperience[info[#info]] end,
			set = function(info, value) mod.db.petExperience[info[#info]] = value mod:PetExperienceBar_UpdateDimensions() end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Pet Experience"]
				},
				enable = {
					order = 2,
					type = "toggle",
					name = L["Enable"],
					set = function(info, value) mod.db.petExperience[info[#info]] = value mod:PetExperienceBar_Toggle() end
				},
				mouseover = {
					order = 3,
					type = "toggle",
					name = L["Mouseover"]
				},
				hideAtMaxLevel = {
					order = 4,
					type = "toggle",
					name = L["Hide At Max Level"],
					set = function(info, value) mod.db.petExperience[info[#info]] = value mod:PetExperienceBar_Update() end
				},
				hideInVehicle = {
					order = 5,
					type = "toggle",
					name = L["Hide In Vehicle"],
					set = function(info, value) mod.db.petExperience[info[#info]] = value mod:PetExperienceBar_Update() end
				},
				hideInCombat = {
					order = 6,
					type = "toggle",
					name = L["Hide In Combat"],
					set = function(info, value) mod.db.petExperience[info[#info]] = value mod:PetExperienceBar_Update() end
				},
				showBubbles = {
					order = 7,
					type = "toggle",
					name = L["Show Bubbles"]
				},
				spacer = {
					order = 8,
					type = "description",
					name = " "
				},
				orientation = {
					order = 9,
					type = "select",
					name = L["Statusbar Fill Orientation"],
					desc = L["Direction the bar moves on gains/losses"],
					values = {
						["AUTOMATIC"] = L["Automatic"],
						["HORIZONTAL"] = L["Horizontal"],
						["VERTICAL"] = L["Vertical"]
					}
				},
				width = {
					order = 10,
					type = "range",
					name = L["Width"],
					min = 5, max = ceil(GetScreenWidth() or 800), step = 1
				},
				height = {
					order = 11,
					type = "range",
					name = L["Height"],
					min = 5, max = ceil(GetScreenHeight() or 800), step = 1
				},
				font = {
					order = 12,
					type = "select", dialogControl = "LSM30_Font",
					name = L["Font"],
					values = AceGUIWidgetLSMlists.font
				},
				textSize = {
					order = 13,
					type = "range",
					name = L["FONT_SIZE"],
					min = 6, max = 22, step = 1
				},
				fontOutline = {
					order = 14,
					type = "select",
					name = L["Font Outline"],
					values = C.Values.FontFlags
				},
				textFormat = {
					order = 15,
					type = "select",
					name = L["Text Format"],
					width = "double",
					values = {
						NONE = L["NONE"],
						CUR = L["Current"],
						REM = L["Remaining"],
						PERCENT = L["Percent"],
						CURMAX = L["Current - Max"],
						CURPERC = L["Current - Percent"],
						CURREM = L["Current - Remaining"],
						CURPERCREM = L["Current - Percent (Remaining)"],
					},
					set = function(info, value) mod.db.petExperience[info[#info]] = value mod:PetExperienceBar_Update() end
				},
				displayText = {
					order = 16,
					type = "toggle",
					name = L["Display Text"]
				},
				clickThrough = {
					order = 17,
					type = "toggle",
					name = L["Click Through"]
				},
				frameLevel = {
					order = 18,
					type = "range",
					name = L["Frame Level"],
					min = 1, max = 128, step = 1
				},
				frameStrata = {
					order = 19,
					type = "select",
					name = L["Frame Strata"],
					values = C.Values.Strata
				},
				spacer2 = {
					order = 20,
					type = "description",
					name = " "
				},
				anchorPoint = {
					order = 21,
					type = "select",
					name = L["Anchor Point"],
					values = C.Values.AllPoints
				},
				xOffset = {
					order = 22,
					type = "range",
					name = L["X-Offset"],
					min = -300, max = 300, step = 1
				},
				yOffset = {
					order = 23,
					type = "range",
					name = L["Y-Offset"],
					min = -300, max = 300, step = 1
				}
			}
		},
		reputation = {
			order = 6,
			type = "group",
			name = L["REPUTATION"],
			get = function(info) return mod.db.reputation[info[#info]] end,
			set = function(info, value) mod.db.reputation[info[#info]] = value mod:ReputationBar_UpdateDimensions() end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["REPUTATION"]
				},
				enable = {
					order = 2,
					type = "toggle",
					name = L["Enable"],
					set = function(info, value) mod.db.reputation[info[#info]] = value mod:ReputationBar_Toggle() end
				},
				mouseover = {
					order = 3,
					type = "toggle",
					name = L["Mouseover"]
				},
				hideInVehicle = {
					order = 4,
					type = "toggle",
					name = L["Hide In Vehicle"],
					set = function(info, value) mod.db.reputation[info[#info]] = value mod:ReputationBar_Update() end
				},
				hideInCombat = {
					order = 5,
					type = "toggle",
					name = L["Hide In Combat"],
					set = function(info, value) mod.db.reputation[info[#info]] = value mod:ReputationBar_Update() end
				},
				showBubbles = {
					order = 6,
					type = "toggle",
					name = L["Show Bubbles"]
				},
				spacer = {
					order = 7,
					type = "description",
					name = " "
				},
				orientation = {
					order = 8,
					type = "select",
					name = L["Statusbar Fill Orientation"],
					desc = L["Direction the bar moves on gains/losses"],
					values = {
						["AUTOMATIC"] = L["Automatic"],
						["HORIZONTAL"] = L["Horizontal"],
						["VERTICAL"] = L["Vertical"]
					}
				},
				width = {
					order = 9,
					type = "range",
					name = L["Width"],
					min = 5, max = ceil(GetScreenWidth() or 800), step = 1
				},
				height = {
					order = 10,
					type = "range",
					name = L["Height"],
					min = 5, max = ceil(GetScreenHeight() or 800), step = 1
				},
				font = {
					order = 11,
					type = "select", dialogControl = "LSM30_Font",
					name = L["Font"],
					values = AceGUIWidgetLSMlists.font
				},
				textSize = {
					order = 12,
					type = "range",
					name = L["FONT_SIZE"],
					min = 6, max = 22, step = 1
				},
				fontOutline = {
					order = 13,
					type = "select",
					name = L["Font Outline"],
					values = C.Values.FontFlags
				},
				textFormat = {
					order = 14,
					type = "select",
					name = L["Text Format"],
					width = "double",
					values = {
						NONE = L["NONE"],
						CUR = L["Current"],
						REM = L["Remaining"],
						PERCENT = L["Percent"],
						CURMAX = L["Current - Max"],
						CURPERC = L["Current - Percent"],
						CURREM = L["Current - Remaining"],
						CURPERCREM = L["Current - Percent (Remaining)"],
					},
					set = function(info, value) mod.db.reputation[info[#info]] = value mod:ReputationBar_Update() end
				},
				displayText = {
					order = 15,
					type = "toggle",
					name = L["Display Text"]
				},
				clickThrough = {
					order = 16,
					type = "toggle",
					name = L["Click Through"]
				},
				frameLevel = {
					order = 17,
					type = "range",
					name = L["Frame Level"],
					min = 1, max = 128, step = 1
				},
				frameStrata = {
					order = 18,
					type = "select",
					name = L["Frame Strata"],
					values = C.Values.Strata
				},
				spacer2 = {
					order = 19,
					type = "description",
					name = " "
				},
				anchorPoint = {
					order = 20,
					type = "select",
					name = L["Anchor Point"],
					values = C.Values.AllPoints
				},
				xOffset = {
					order = 21,
					type = "range",
					name = L["X-Offset"],
					min = -300, max = 300, step = 1
				},
				yOffset = {
					order = 22,
					type = "range",
					name = L["Y-Offset"],
					min = -300, max = 300, step = 1
				}
			}
		},
		threat = {
			order = 7,
			type = "group",
			name = L["Threat"],
			get = function(info) return mod.db.threat[info[#info]] end,
			set = function(info, value) mod.db.threat[info[#info]] = value mod:UpdateThreatDimensions() end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Threat"]
				},
				enable = {
					order = 2,
					type = "toggle",
					name = L["Enable"],
					set = function(info, value) mod.db.threat[info[#info]] = value mod:ThreatBar_Toggle() end
				},
				tankStatus = {
					order = 3,
					type = "toggle",
					name = L["Tank Colors"],
					set = function(info, value) mod.db.threat[info[#info]] = value mod:ThreatBar_Update() end
				},
				smoothbars = {
					order = 4,
					type = "toggle",
					name = L["Smooth Bars"],
					desc = L["Bars will transition smoothly."],
					set = function(info, value) mod.db.threat[info[#info]] = value mod:ThreatBar_Toggle() end
				},
				mouseover = {
					order = 5,
					type = "toggle",
					name = L["Mouseover"]
				},
				showBubbles = {
					order = 6,
					type = "toggle",
					name = L["Show Bubbles"]
				},
				spacer = {
					order = 7,
					type = "description",
					name = " "
				},
				orientation = {
					order = 8,
					type = "select",
					name = L["Statusbar Fill Orientation"],
					desc = L["Direction the bar moves on gains/losses"],
					values = {
						["AUTOMATIC"] = L["Automatic"],
						["HORIZONTAL"] = L["Horizontal"],
						["VERTICAL"] = L["Vertical"]
					}
				},
				width = {
					order = 9,
					type = "range",
					name = L["Width"],
					min = 5, max = ceil(GetScreenWidth() or 800), step = 1
				},
				height = {
					order = 10,
					type = "range",
					name = L["Height"],
					min = 5, max = ceil(GetScreenHeight() or 800), step = 1
				},
				font = {
					order = 11,
					type = "select", dialogControl = "LSM30_Font",
					name = L["Font"],
					values = AceGUIWidgetLSMlists.font
				},
				textSize = {
					order = 12,
					type = "range",
					name = L["FONT_SIZE"],
					min = 6, max = 22, step = 1
				},
				fontOutline = {
					order = 13,
					type = "select",
					name = L["Font Outline"],
					values = C.Values.FontFlags
				},
				displayText = {
					order = 14,
					type = "toggle",
					name = L["Display Text"]
				},
				clickThrough = {
					order = 16,
					type = "toggle",
					name = L["Click Through"]
				},
				frameLevel = {
					order = 17,
					type = "range",
					name = L["Frame Level"],
					min = 1, max = 128, step = 1
				},
				frameStrata = {
					order = 18,
					type = "select",
					name = L["Frame Strata"],
					values = C.Values.Strata
				},
				spacer2 = {
					order = 19,
					type = "description",
					name = " "
				},
				anchorPoint = {
					order = 20,
					type = "select",
					name = L["Anchor Point"],
					values = C.Values.AllPoints
				},
				xOffset = {
					order = 21,
					type = "range",
					name = L["X-Offset"],
					min = -300, max = 300, step = 1
				},
				yOffset = {
					order = 22,
					type = "range",
					name = L["Y-Offset"],
					min = -300, max = 300, step = 1
				}
			}
		}
	}
}