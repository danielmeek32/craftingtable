local config = {}
config.crafting_table_close_behavior = minetest.setting_get("craftingtable_crafting_table_close_behavior") or "drop"
config.player_inventory_close_behavior = minetest.setting_get("craftingtable_player_inventory_close_behavior") or "return"

local open_crafting_tables = {}

-- drop a stack at the specified index on a crafting table at the specified position, unless the crafting table position is nil in which case the item is dropped from the player
local drop_item_from_player_or_crafting_table = function(stack, player, crafting_table_pos, index)
	if crafting_table_pos ~= nil then
		local item_pos = { x = crafting_table_pos.x, y = crafting_table_pos.y + 0.75, z = crafting_table_pos.z }

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
	else
		-- drop the item on the ground
		minetest.item_drop(stack, player, player:get_pos())
	end
end

-- transfer as many items from the crafting table to the player's crafting grid as possible, returning those that don't fit to the player's inventory and dropping items if there is not enough space in the player's inventory
local transfer_items_where_possible = function(player, crafting_table_pos)
	local inv = player:get_inventory()

	if crafting_table_pos ~= nil then
		-- find the corners of a square encompassing all the items in the crafting inventory while counting the number of item stacks
		local stack_count = 0
		local first_x = 4
		local first_y = 4
		local last_x = 0
		local last_y = 0
		for index, stack in ipairs(inv:get_list("craft")) do
			if not stack:is_empty() then
				local x = ((index - 1) % 3) + 1
				local y = math.ceil(index / 3)

				if x < first_x then
					first_x = x
				end
				if y < first_y then
					first_y = y
				end
				if x > last_x then
					last_x = x
				end
				if y > last_y then
					last_y = y
				end

				stack_count = stack_count + 1
			end
		end
		local width = last_x - first_x + 1
		local height = last_y - first_y + 1

		if stack_count > 0 then
			if width <= 2 and height <= 2 then
				-- gather the items from the relevant area of the crafting inventory into a list, preserving their visual arrangement
				local stacks = {}
				for y = first_y, last_y do
					for x = first_x, last_x do
						table.insert(stacks, inv:get_stack("craft", (y - 1) * 3 + x))
					end
				end

				-- clear the player's crafting inventory
				for index = 1, 9 do
					inv:set_stack("craft", index, ItemStack(nil))
				end

				-- put the items back into the crafting inventory
				for y = 1, height do
					for x = 1, width do
						inv:set_stack("craft", (y - 1) * 2 + x, stacks[(y - 1) * width + x])
					end
				end
			else
				-- gather all the stacks from the crafting inventory into a list
				local stacks = {}
				for index, stack in ipairs(inv:get_list("craft")) do
					table.insert(stacks, stack)

					-- remove item from crafting inventory (for now)
					inv:set_stack("craft", index, ItemStack(nil))
				end

				-- save crafting inventory size and resize it to the smaller size (ugly hack so that we can use inv:add_item to automatically handle adding the items to the crafting inventory)
				local crafting_inventory_size = inv:get_size("craft")
				inv:set_size("craft", 4)

				-- try to return as many items as possible to the player's crafting inventory
				for index, stack in ipairs(stacks) do
					if not stack:is_empty() then
						-- try to add the item to the player's crafting inventory
						local left_over = inv:add_item("craft", stack)

						-- try to add the item to the player's main inventory
						if left_over ~= nil and not left_over:is_empty() then
							local left_over = inv:add_item("main", left_over)

							-- drop any left over item
							if left_over ~= nil and not left_over:is_empty() then
								drop_item_from_player_or_crafting_table(left_over, player, crafting_table_pos, index)
							end
						end
					end
				end

				-- restore saved crafting inventory size
				inv:set_size("craft", crafting_inventory_size)
			end
		end
	end
end

-- return items from a crafting table or the player's crafting grid to the player's inventory where possible, dropping items if there is not enough space in the player's inventory
local return_items_where_possible = function(player, crafting_table_pos)
	local inv = player:get_inventory()

	for index, stack in ipairs(inv:get_list("craft")) do
		if not stack:is_empty() then
			-- try to add the item to the player's main inventory
			local left_over = inv:add_item("main", stack)

			-- drop any left over item
			if left_over ~= nil and not left_over:is_empty() then
				drop_item_from_player_or_crafting_table(left_over, player, crafting_table_pos, index)
			end

			-- remove item from crafting inventory
			inv:set_stack("craft", index, ItemStack(nil))
		end
	end
end

-- drop all items from a crafting table or the player's crafting grid
local drop_all_items = function(player, crafting_table_pos)
	local inv = player:get_inventory()

	for index, stack in ipairs(inv:get_list("craft")) do
		if not stack:is_empty() then
			-- drop the item
			drop_item_from_player_or_crafting_table(stack, player, crafting_table_pos, index)

			-- remove item from crafting inventory
			inv:set_stack("craft", index, ItemStack(nil))
		end
	end
end

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
	-- execute configured close behavior
	if config.crafting_table_close_behavior == "transfer" then
		transfer_items_where_possible(player, pos)
	elseif config.crafting_table_close_behavior == "return" then
		return_items_where_possible(player, pos)
	elseif config.crafting_table_close_behavior == "drop" then
		drop_all_items(player, pos)
	end

	-- restore small crafting inventory size
	local inv = player:get_inventory()
	inv:set_width("craft", 2)
	inv:set_size("craft", 4)

	-- remove player from the list of open crafting tables
	open_crafting_tables[player:get_player_name()] = nil
end

local handle_player_inventory_close = function(player)
	-- execute configured close behavior
	if config.player_inventory_close_behavior == "transfer" then
		transfer_items_where_possible(player, nil)
	elseif config.player_inventory_close_behavior == "return" then
		return_items_where_possible(player, nil)
	elseif config.player_inventory_close_behavior == "drop" then
		drop_all_items(player, nil)
	end
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
	else
		handle_player_inventory_close(player)	-- it's safe to always call this function even if the player's inventory wasn't actually open
	end
end)

minetest.register_on_dieplayer(function(player)
	local pos = open_crafting_tables[player:get_player_name()]
	if pos ~= nil then
		handle_crafting_table_close(player, pos)
	else
		handle_player_inventory_close(player)	-- it's safe to always call this function even if the player's inventory wasn't actually open
	end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.quit then
		if string.sub(formname, 0, string.len("craftingtable:")) == "craftingtable:" then
			-- crafting table has been closed
			local pos = minetest.string_to_pos(string.sub(formname, string.len("craftingtable:") + 1))
			handle_crafting_table_close(player, pos)
		elseif formname == "" then
			-- player inventory has been closed
			-- TODO: is it safe to assume that an empty formname always refers to the player's inventory? I don't think this matters anyway as it's always safe to call handle_player_inventory_close even when it's not necessary
			handle_player_inventory_close(player)
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
