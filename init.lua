local open_crafting_tables = {}

local open_crafting_table = function(player, pos)
	-- set large crafting inventory size
	local inv = player:get_inventory()
	inv:set_width("craft", 3)
	inv:set_size("craft", 9)

	-- rearrange items in the player's crafting inventory to match the crafting table size while keeping them in the same visual arrangement
	inv:set_stack("craft", 5, inv:get_stack("craft", 4))
	inv:set_stack("craft", 4, inv:get_stack("craft", 3))
	inv:set_stack("craft", 3, ItemStack(nil))

	-- show crafting table formspec (copied from default player formspec)
	local formspec = "size[8,8.5]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"list[current_player;main;0,4.25;8,1;]" ..
		"list[current_player;main;0,5.5;8,3;8]" ..
		"list[current_player;craft;1.75,0.5;3,3;]" ..
		"list[current_player;craftpreview;5.75,1.5;1,1;]" ..
		"image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..
		"listring[current_player;main]" ..
		"listring[current_player;craft]" ..
		default.get_hotbar_bg(0, 4.25)
	minetest.show_formspec(player:get_player_name(), "craftingtable:" .. minetest.pos_to_string(pos), formspec)

	-- add player to the list of open crafting tables
	open_crafting_tables[player:get_player_name()] = pos
end

local handle_crafting_table_close = function(player, pos)
	local inv = player:get_inventory()

	-- drop all items on the crafting table
	for index, stack in ipairs(inv:get_list("craft")) do
		if not stack:is_empty() then
			local item_pos = { x = pos.x, y = pos.y + 0.75, z = pos.z }

			-- offset the dropped item position based on its location in the crafting grid and the player's direction
			local grid_x = (index - 1) % 3
			local grid_y = math.floor((index - 1) / 3)
			local grid_x_offset = grid_x * 0.3 - 0.3
			local grid_y_offset = grid_y * 0.3 - 0.3
			local player_dir = minetest.dir_to_facedir(player:get_look_dir(), false)
			if player_dir == 0 then
				item_pos.x = item_pos.x + grid_x_offset
				item_pos.z = item_pos.z - grid_y_offset
			elseif player_dir == 1 then
				item_pos.x = item_pos.x - grid_y_offset
				item_pos.z = item_pos.z - grid_x_offset
			elseif player_dir == 2 then
				item_pos.x = item_pos.x - grid_x_offset
				item_pos.z = item_pos.z + grid_y_offset
			elseif player_dir == 3 then
				item_pos.x = item_pos.x + grid_y_offset
				item_pos.z = item_pos.z + grid_x_offset
			end

			-- add dropped item
			minetest.add_item(item_pos, stack)

			-- remove item from player's crafting inventory
			stack:clear()
			inv:set_stack("craft", index, stack)
		end
	end

	-- restore small crafting inventory size
	inv:set_width("craft", 2)
	inv:set_size("craft", 4)

	-- remove player from the list of open crafting tables
	open_crafting_tables[player:get_player_name()] = nil
end

-- override crafting page with smaller crafting grid
sfinv.override_page("sfinv:crafting", {
	title = "Crafting",
	get = function(self, player, context)
		return sfinv.make_formspec(player, context, [[
				list[current_player;craft;2.75,1.0;2,2;]
				list[current_player;craftpreview;5.75,1.5;1,1;]
				image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]
				listring[current_player;main]
				listring[current_player;craft]
				image[0,4.75;1,1;gui_hb_bg.png]
				image[1,4.75;1,1;gui_hb_bg.png]
				image[2,4.75;1,1;gui_hb_bg.png]
				image[3,4.75;1,1;gui_hb_bg.png]
				image[4,4.75;1,1;gui_hb_bg.png]
				image[5,4.75;1,1;gui_hb_bg.png]
				image[6,4.75;1,1;gui_hb_bg.png]
				image[7,4.75;1,1;gui_hb_bg.png]
			]], true)
	end
})

minetest.register_on_joinplayer(function(player)
	-- set small crafting inventory size
	local inv = player:get_inventory()
	inv:set_width("craft", 2)
	inv:set_size("craft", 4)
end)

minetest.register_on_leaveplayer(function(player)
	local pos = open_crafting_tables[player:get_player_name()]
	if pos ~= nil then
		handle_crafting_table_close(player, pos)
	end
end)

minetest.register_on_dieplayer(function(player)
	local pos = open_crafting_tables[player:get_player_name()]
	if pos ~= nil then
		handle_crafting_table_close(player, pos)
	end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if string.sub(formname, 0, string.len("craftingtable:")) == "craftingtable:" then
		if fields.quit then
			local pos = minetest.string_to_pos(string.sub(formname, string.len("craftingtable:") + 1))
			handle_crafting_table_close(player, pos)
		end
	end
end)

minetest.register_node("craftingtable:table", {
	description = "Crafting Table",
	tile_images = {"craftingtable_top.png", "craftingtable_bottom.png", "craftingtable_side.png"},
	paramtype2 = "facedir",
	groups = { choppy = 2, oddly_breakable_by_hand = 2 },
	sounds = default.node_sound_wood_defaults(),

	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		open_crafting_table(player, pos)
	end,
})

minetest.register_craft({
	output = "craftingtable:table",
	recipe = {
		{"group:wood", "group:wood"},
		{"group:wood", "group:wood"},
	}
})
