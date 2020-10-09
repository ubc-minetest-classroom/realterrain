-- init.lua
--------------------------------------------------------
-- 1. define variables and init function
-- 2. load files and run
-- 3. set mapgen variables
-- 4. register generate function defined in mapgen.lua
-- 5. set player privilages and status
-- 6. call init function

-- local variables
local MOD_PATH = minetest.get_modpath("realterrainlite")
local LIB_PATH = MOD_PATH .. "/lib/"
local RASTER_PATH = MOD_PATH .. "/rasters/"
local SCHEMS_PATH = MOD_PATH .. "/schems/" -- used in mapgen.lua
local IE = minetest.request_insecure_environment()
package.path = (MOD_PATH.."/lib/lua-imagesize-1.2/?.lua;"..package.path)
local imagesize = IE.require "imagesize"

-- global variables
realterrain = {}
realterrain.mod_path = MOD_PATH
realterrain.lib_path = LIB_PATH
realterrain.raster_path = RASTER_PATH
realterrain.schems_path = SCHEMS_PATH
realterrain.elev = {}
realterrain.cover = {}

function realterrain.init()

    -- initializes global objects elev and cover
	local rasternames = {"elev", "cover"}
	for _, rastername in ipairs(rasternames) do
    
        local raster = realterrain[rastername]
        if realterrain.settings["file"..rastername] ~= ""  then 

			--use imagesize to get the dimensions and header offset
			local width, length, format = imagesize.imgsize(RASTER_PATH..realterrain.settings["file"..rastername])
			print(rastername..": format: "..format.." width: "..width.." length: "..length)
			if string.sub(format, -3) == "bmp" or string.sub(format, -6) == "bitmap" then
				dofile(MOD_PATH.."/lib/loader_bmp.lua")
				local bitmap, e = imageloader.load(RASTER_PATH..realterrain.settings["file"..rastername])
				if e then print(e) end
				raster.image = bitmap
				raster.width = width
				raster.length = length
				raster.bits = realterrain.settings[rastername.."bits"]
				raster.format = "bmp"
			else
				print("your file should be an uncompressed bmp")
			end

            print("["..rastername.."] file: "..realterrain.settings["file"..rastername].." width: "..raster.width..", length: "..raster.length)
        else
            print("no "..rastername.." selected")
            realterrain[rastername] = {}
        end
        
    end
end

-- load files and run
dofile(LIB_PATH .. "/iohelpers.lua")
dofile(LIB_PATH .. "/imageloader.lua")
dofile(MOD_PATH .. "/settings.lua")
dofile(MOD_PATH .. "/mapgen.lua")
dofile(MOD_PATH .. "/height_pixels.lua")

-- Set mapgen parameters
minetest.register_on_mapgen_init(function(mgparams)
    -- mgnames: v5, v6, v7, valleys, carpathian, fractal, flat, singlenode
    -- flags: nolight, nodecorations, nosnowbiomes
    -- use this when generating realterrain map: minetest.set_mapgen_params({mgname="singlenode", flags="nolight"})
    -- use this after map is generated to auto-generate the rest of the world: minetest.set_mapgen_params({mgname="flat", flags="nodecorations, nosnowbiomes"})
	minetest.set_mapgen_params({mgname="singlenode", flags="nolight"})
end)

-- On generated function
minetest.register_on_generated(function(minp, maxp, seed)
	realterrain.generate(minp, maxp)
end)

-- Set player privilages and status
minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	local privs = minetest.get_player_privs(pname)
	privs.fly = true
	privs.fast = true
	privs.noclip = true
	privs.time = true
	privs.teleport = true
	privs.worldedit = true
	minetest.set_player_privs(pname, privs)
	minetest.chat_send_player(pname, "you have been granted some privs, like fast, fly, noclip, time, teleport and worldedit")
	local ppos = player:getpos()
	local surface = realterrain.get_surface(math.floor(ppos.x+0.5), math.floor(ppos.z+0.5))
	if surface then
		player:setpos({x=ppos.x, y=surface+0.5, z=ppos.z})
		minetest.chat_send_player(pname, "you have been moved to the surface")
	end
	return true
end)

realterrain.init()