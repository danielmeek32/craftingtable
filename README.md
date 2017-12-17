# Minetest crafting table mod

Version 1.0.0

Compatible with Minetest 0.4.16

## Description

This mod adds a crafting table to Minetest and reduces the player's default crafting grid to 2x2. It is intended to be a simple and up-to-date crafting table mod for Minetest. It uses sfinv and should work flawlessly alongside other mods that use sfinv.

## Usage

Each player will have a 2x2 crafting grid in their inventory in place of the default 3x3 grid. This mod adds a crafting table that provides access to a 3x3 crafting grid. A crafting table can be crafted as follows:

    group:wood group:wood
    group:wood group:wood

After placing the crafting table in the world, any player can right-click on it to use a 3x3 crafting grid. Multiple players can use the crafting table at the same time without affecting each other. If a player closes the crafting table form while there are items in the crafting grid, those items will be dropped as entities on top of the crafting table node.

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
