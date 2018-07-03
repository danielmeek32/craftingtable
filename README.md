# Minetest crafting table mod

Version 1.0.0

Compatible with Minetest 0.4.16

## Description

This mod adds a crafting table to Minetest and reduces the player's default crafting grid to 2x2. It is intended to be a simple and up-to-date crafting table mod for Minetest. It uses sfinv and should work flawlessly alongside other mods that use sfinv.

## Usage

Each player will have a 2x2 crafting grid in their inventory in place of the default 3x3 grid. This mod adds a crafting table that provides access to a 3x3 crafting grid. A crafting table can be crafted as follows:

    group:wood group:wood
    group:wood group:wood

After placing the crafting table in the world, any player can right-click on it to use a 3x3 crafting grid. Multiple players can use the crafting table at the same time without affecting each other.

By default, if a player closes the crafting table form while there are items in the crafting grid, those items will be dropped as entities on top of the crafting table node. If a player closes their inventory form while there are items in their own crafting grid, those items will be returned to the player's main inventory if possible or dropped on the ground if there is not enough room in the player's inventory. Both of these behaviors are configurable.

## Configuration

This mod provides the following configuration options:

* `craftingtable_crafting_table_close_behavior` - This option controls the behavior used when a player closes a crafting table form while there are items in the crafting grid. The possible values are:
  - `transfer` - The items from the crafting table will be transferred to the crafting grid shown in the player's inventory form. Any items that do not fit in the player's own crafting grid will be returned to the player's main inventory, or dropped if there is not enough room in the player's inventory.
  - `return` - The items from the crafting table will be returned to the player's inventory, or dropped if there is not enough room in the player's inventory. The crafting grid shown in the player's inventory form will be empty.
  - `drop` - The items from the crafting table will be dropped. No items will be added to the player's inventory and the crafting grid shown in the player's inventory form will be empty.
* `craftingtable_player_inventory_close_behavior` - This option controls the behavior used when a player closes their inventory form while there are items in their own crafting grid. The possible values are the same as for `craftingtable_crafting_table_close_behavior`. Note that the `transfer` behavior effectively does nothing in this case, leaving the items as they are in the player's crafting grid.

## Dependencies

* default
* sfinv

## Conflicts

This mod may be assumed to be incompatible with any mods that alter the player's inventory formspec and are not sfinv-aware or mods that alter crafting behaviour.

## Known Issues

* If the player places items in the 2x2 crafting grid and then right-clicks on a crafting table, the items from their 2x2 grid will appear in the crafting table's 3x3 grid.

## License

GPLv3

* Some parts are copied from Minetest Game  
  Copyright various Minetest developers and contributers
* Textures were originally produced by darkrose  
  Copyright Lisa Milne 2012
* All other parts  
  Copyright Daniel Meek 2017
