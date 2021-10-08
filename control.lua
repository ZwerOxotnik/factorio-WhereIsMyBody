require("util")

body={}

-- Init / Migrate
function body.on_init()
	body.on_configuration_changed()
end
function body.on_configuration_changed()
	global.players=global.players or {}
	for idx,gply in pairs(global.players)do
		for i,corpse in pairs(gply.corpses)do
			local f=game.surfaces[corpse.surface_name]
			if(not f or not f.valid)then
				gply.corpses[i]=nil
			else
				local e=f.find_entity("character-corpse",corpse.position)
				if(e and e.valid)then
					corpse.corpse=e
				else
					gply.corpses[i]=nil
				end
			end
		end
	end
end

script.on_init(body.on_init)
script.on_configuration_changed(body.on_configuration_changed)


-- When a player dies and leaves behind a corpse
function body.on_player_died(ev)
	local idx=ev.player_index
	local ply=game.players[idx]
	global.players[idx]=global.players[idx] or {corpses={}}
	local t={surface_name=ply.surface.name,position=ply.position}
	t.corpse=ply.surface.find_entity("character-corpse",ply.position)
	if(t.corpse and t.corpse.valid)then
		table.insert(global.players[idx].corpses,t)
	end
end
script.on_event(defines.events.on_player_died,body.on_player_died)


-- Rendering functions
function body.reduce_color(c,f)
	f=f or 0.1
	return {r=(c.r or 1)*f,g=(c.g or 1)*f,b=(c.b or 1)*f,a=(c.a or 1)*f}
end

function body.distance_sort(a,b)
	return a.distance>b.distance
end

function body.redraw_lines(idx)
	local gply=global.players[idx]


	if(gply and table_size(gply.corpses)>0)then
		local ply=game.players[idx]
		if(not ply.character)then return end
		local pos=ply.position

		-- draw line width based on distance
		local tDraw={}
		for i,bod in pairs(gply.corpses)do
			if(bod.surface_name==ply.surface.name)then
				local t={corpse=bod.corpse,distance=util.distance(pos,bod.position),line=bod.line,i=i}
				
				table.insert(tDraw,t)
			end
		end

		if(table_size(tDraw)>0)then
			table.sort(tDraw,body.distance_sort)
			local c=table_size(tDraw)
			for i,bod in ipairs(tDraw)do
				local fac=(i/c)
				local width=math.max(fac,0.2)*1.5
				local col=body.reduce_color(ply.color,math.max(fac,0.2))
				if(bod.line and rendering.is_valid(bod.line))then
					rendering.set_width(bod.line,width)
					rendering.set_color(bod.line,col)
				else
					local r=rendering.draw_line{color=col,width=width,from=ply.character,to=bod.corpse,surface=ply.surface,players={ply.name},only_in_alt_mode=true}
					gply.corpses[bod.i].line=r
				end
			end
		end
	end
end

script.on_event(defines.events.on_tick,function(ev)
	if(ev.tick%120==0)then
		for idx in pairs(global.players)do
			body.redraw_lines(idx)
		end
	end
end)

-- Destroy global corpse object by surface
function body.clean_surface(f)
	for idx,gply in pairs(global.players)do
		for i,corpse in pairs(gply.corpses)do
			if(corpse.surface_name==f.name)then
				if(corpse.line and rendering.is_valid(corpse.line))then
					rendering.destroy(corpse.line)
				end
				gply.corpses[i]=nil
			end
		end
	end
end

-- Destroy global corpse object by entity
function body.destroy_corpse(ent)
	for idx,gply in pairs(global.players)do
		for i,corpse in pairs(gply.corpses)do
			if(corpse.corpse==ent)then
				if(corpse.line and rendering.is_valid(corpse.line))then
					rendering.destroy(corpse.line)
				end
				gply.corpses[i]=nil
				return
			end
		end
	end
end




-- Player respawned
function body.on_player_respawned(ev)
	body.redraw_lines(ev.player_index)
end
script.on_event(defines.events.on_player_respawned,body.on_player_respawned)

-- Player changed surface
function body.on_player_changed_surface(ev)
	body.redraw_lines(ev.player_index)
end
script.on_event(defines.events.on_player_changed_surface,body.on_player_changed_surface)



-- Surface is cleared, including corpses
function body.on_pre_surface_cleared(ev)
	body.clean_surface(game.surfaces[ev.surface_index])
end
script.on_event(defines.events.on_pre_surface_cleared,body.on_pre_surface_cleared)

-- Surface deleted, be sure to check players who were teleported needing their lines redrawn
function body.on_pre_surface_deleted(ev)
	body.clean_surface(game.surfaces[ev.surface_index])

	for idx,ply in pairs(game.players)do
		if(ply.surface.index==ev.surface_index)then
			body.redraw_lines(ply.index)
		end
	end
end
script.on_event(defines.events.on_pre_surface_deleted,body.on_pre_surface_deleted)

-- When a corpse expires due to timeout or all of the items being removed from it.
function body.on_character_corpse_expired(ev)
	body.destroy_corpse(ev.corpse)
end
script.on_event(defines.events.on_character_corpse_expired,body.on_character_corpse_expired)


-- When a corpse is mined
function body.on_pre_player_mined_item(ev)
	body.destroy_corpse(ev.entity)
end
script.on_event(defines.events.on_pre_player_mined_item,body.on_pre_player_mined_item,{{filter="name",name="character-corpse"}})
