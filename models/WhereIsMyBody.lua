
---@class WhereIsMyBody : module
local M = {}


--#region Global data
---@type table<integer, table> # [render id, corpse entity]
local players_data
---@type table<integer, LuaEntity>
local corpses_queue
--#endregion


--#region Constants
local pcall, next = pcall, next
local draw_line = rendering.draw_line
local set_color = rendering.set_color
local rendering_destroy = rendering.destroy
local remove = table.remove
local DEFAULT_COLOR = {1, 0.8, 0, 0.9}
local DEFAULT_WIDTH = 0.2
--#endregion


--#region Settings
local update_tick = settings.global["WHMB_update_tick"].value
--#endregion


--#region Utils

local color_data = {0, 0, 0, 0}
local min_color_data = {0.19, 0.8 * 0.19, 0, 0.19}
local max_color_data = {0.9, 0.8 * 0.9, 0, 0.9}
---@param player table #LuaEntity
---@param id integer
---@param corpse table #LuaEntity
local function update_color(player, id, corpse)
	local stop = corpse.position
	local start = player.position
	local xdiff = start.x - stop.x
	local ydiff = start.y - stop.y
	local distance = (xdiff * xdiff + ydiff * ydiff)^0.5

	if distance > 450 then
		set_color(id, min_color_data)
	elseif distance < 95 then
		set_color(id, max_color_data)
	else
		local r = 1 - distance / 500
		color_data[1] = r
		color_data[2] = 0.8 * r
		color_data[4] = r
		set_color(id, color_data)
	end
end

--#endregion

--#region Functions of events

-- TODO: perhaps, it should be improved...
local function check_render()
	local get_player = game.get_player
	for player_index, all_corpses_data in pairs(players_data) do
		local player = get_player(player_index)
		local character = player.character
		if character and character.valid then
			for i=#all_corpses_data, 1, -1 do
				local death_data = all_corpses_data[i]
				local id = death_data[1]
				local corpse = death_data[2]
				if not pcall(update_color, player, id, corpse) then
					remove(all_corpses_data, i)
				end
			end
			if next(all_corpses_data) == nil then
				players_data[player_index] = nil
			end
		end
	end
end

local function on_player_left_game(event)
	local player_index = event.player_index
	local player_data = players_data[player_index]
	for i=1, #player_data do
		rendering_destroy(player_data[i][1])
	end
	players_data[player_index] = nil
end

local function on_pre_player_removed(event)
	local player_index = event.player_index
	players_data[player_index] = nil
	corpses_queue[player_index] = nil
end

local function on_console_command(event)
	if event.command ~= "editor" then return end
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not (player and player.valid) then return end
	local character = player.character
	if not (character and character.valid) then return end
	local player_data = players_data[player_index]
	if player_data == nil then return end

	local line_data = {
		color = DEFAULT_COLOR,
		width = DEFAULT_WIDTH,
		from = character,
		surface = player.surface,
		players = {player_index},
		draw_on_ground = true,
		only_in_alt_mode = true
	}

	for i=#player_data, 1, -1 do
		local data = player_data[i]
		local entity = data[2]
		if entity.valid then
			line_data.to = data[2]
			data[1] = draw_line(line_data)
		else
			remove(player_data, i)
		end
	end
	if next(player_data) == nil then
		players_data[player_index] = nil
	end
end

local function on_player_respawned(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	local surface = player.surface

	players_data[player_index] = players_data[player_index] or {}
	local player_data = players_data[player_index]
	local line_data = {
		color = DEFAULT_COLOR,
		width = DEFAULT_WIDTH,
		from = player.character,
		surface = surface,
		players = {player_index},
		draw_on_ground = true,
		only_in_alt_mode = true
	}
	for i=#player_data, 1, -1 do
		local data = player_data[i]
		local entity = data[2]
		if entity.valid then
			line_data.to = data[2]
			data[1] = draw_line(line_data)
		else
			remove(player_data, i)
		end
	end

	local corpse = corpses_queue[player_index]
	corpses_queue[player_index] = nil
	if not (corpse and corpse.valid) then return end
	if surface ~= corpse.surface then return end
	line_data.to = corpse
	local id = draw_line(line_data)
	player_data[#player_data+1] = {id, corpse}
	corpses_queue[player_index] = nil
end

local function on_player_died(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if player.mod_settings["WHMB_create_lines"].value == false then return end
	local surface = player.surface
	local corpse = surface.find_entity("character-corpse", player.position)
	if not (corpse and corpse.valid) then return end
	corpses_queue[player_index] = corpse
end

local function on_runtime_mod_setting_changed(event)
	if event.setting == "WHMB_update_tick" then
		local value = settings.global[event.setting].value
		script.on_nth_tick(update_tick, nil)
		update_tick = value
		script.on_nth_tick(value, check_render)
	end
end

--#endregion


--#region Pre-game stage

local function link_data()
	players_data = global.players
	corpses_queue = global.corpses_queue
end

local function update_global_data()
	global.players = global.players or {}
	global.corpses_queue = global.corpses_queue or {}

	link_data()

	for player_index, corpse in pairs(corpses_queue) do
		if corpse.valid == false then
			corpses_queue[player_index] = nil
		end
	end

	for player_index, all_corpses_data in pairs(players_data) do
		local player = game.get_player(player_index)
		if not player or player.valid == false then
			players_data[player_index] = nil
		else
			for i=#all_corpses_data, 1, -1 do
				local death_data = data[i]
				if type(death_data) ~= "table" then
					remove(all_corpses_data, i)
				else
					local corpse = death_data[2]
					if not (corpse and corpse.valid) then
						remove(all_corpses_data, i)
					end
				end
			end
			if next(all_corpses_data) == nil then
				players_data[player_index] = nil
			end
		end
	end
end


M.on_init = update_global_data
M.on_configuration_changed = function(event)
	local mod_changes = event.mod_changes["m_WhereIsMyBody"]
	if not (mod_changes and mod_changes.old_version) then return end

	update_global_data()
end
M.on_load = link_data

--#endregion


M.events = {
	-- [defines.events.on_game_created_from_scenario] = on_game_created_from_scenario,
	-- [defines.events.on_pre_player_mined_item] = on_pre_player_mined_item,
	-- [defines.events.on_character_corpse_expired] = on_character_corpse_expired,
	-- [defines.events.on_pre_surface_cleared] = on_pre_surface_cleared,
	-- [defines.events.on_pre_surface_deleted] = on_pre_surface_deleted,
	[defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
	[defines.events.on_player_respawned] = function(event)
		pcall(on_player_respawned, event)
	end,
	[defines.events.on_pre_player_removed] = on_pre_player_removed,
	[defines.events.on_player_died] = function(event)
		pcall(on_player_died, event)
	end,
	[defines.events.on_player_left_game] = function(event)
		pcall(on_player_left_game, event)
	end,
	[defines.events.on_player_changed_surface] = function(event)
		pcall(on_player_left_game, event)
	end,
	[defines.events.on_console_command] = function(event)
		pcall(on_console_command, event)
	end -- on_player_toggled_map_editor event seems doesn't work
}

M.on_nth_tick = {
	[update_tick] = check_render,
}

return M
