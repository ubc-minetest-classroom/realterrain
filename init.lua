-- init.lua
--------------------------------------------------------
-- 1. define variables and init function
-- 2. load files and run
-- 3. set mapgen parameters and register generate function defined in mapgen.lua
-- 4. set player privilages and status
-- 5. register chat command to emerge blocks
-- 6. call init function

-- local variables
local worldpath = minetest.get_worldpath()
local modname = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(modname)
local LIB_PATH = MOD_PATH .. "/lib/"
local RASTER_PATH = MOD_PATH .. "/rasters/"
local SCHEMS_PATH = MOD_PATH .. "/schems/" -- used in mapgen.lua
local IE = minetest.request_insecure_environment()
package.path = (MOD_PATH.."/lib/lua-imagesize-1.2/?.lua;"..package.path)
local imagesize = IE.require "imagesize"
local raster_pos1, raster_pos2 = nil -- defines the size of the map to emerge
local context = {} -- persist emerge data between callback calls
local mapdone = false
local isnewplayer = false

-- global variables
realterrain = {}
realterrain.mod_path = MOD_PATH
realterrain.lib_path = LIB_PATH
realterrain.raster_path = RASTER_PATH
realterrain.schems_path = SCHEMS_PATH
realterrain.elev = {}
realterrain.cover = {}

-- load files and run
dofile(MOD_PATH .. "/settings.lua")
dofile(LIB_PATH .. "/iohelpers.lua")
dofile(LIB_PATH .. "/imageloader.lua")
dofile(MOD_PATH .. "/height_pixels.lua")
dofile(MOD_PATH .. "/mapgen.lua")

function realterrain.init()

    -- initializes global objects elev and cover
    local rasternames = {"elev", "cover"}
    for _, rastername in ipairs(rasternames) do
    
        local raster = realterrain[rastername]
        if realterrain.settings["file"..rastername] ~= ""  then 

            --use imagesize to get the dimensions and header offset
            local width, length, format = imagesize.imgsize(RASTER_PATH..realterrain.settings["file"..rastername])
            if width and length and format then
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
                    print("Your file should be an uncompressed bmp.")
                end
                print("["..rastername.."] file: "..realterrain.settings["file"..rastername].." width: "..raster.width..", length: "..raster.length)
            end
        else
            print("no "..rastername.." selected")
            realterrain[rastername] = {}
        end
        
    end
end

-- Set mapgen parameters
minetest.register_on_mapgen_init(function()
    minetest.set_mapgen_setting("water_level", realterrain.settings.waterlevel, true)
    minetest.set_mapgen_setting("mg_flags", realterrain.settings.mgflags, true)
    minetest.set_mapgen_setting("mg_name", realterrain.settings.mgname, true)
    minetest.set_mapgen_setting("mgflat_ground_level", realterrain.settings.yoffset, true)
    minetest.set_mapgen_setting("mgflat_spflags", realterrain.settings.mgflat_spflags, true)
    minetest.set_mapgen_setting("mgflat_large_cave_depth", realterrain.settings.mgflat_lcavedep, true)
    minetest.set_mapgen_setting("mgflat_cave_width", realterrain.settings.mgflat_cwidth, true)
    minetest.set_mapgen_setting_noiseparams("mg_biome_np_heat", realterrain.settings.mgbiome_heat, true)
end)

    
-- On generated function
minetest.register_on_generated(function(minp, maxp, seed)
    realterrain.generate(minp, maxp)
end)

minetest.register_on_newplayer(function(player)
	isnewplayer = true
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
    minetest.chat_send_player(pname, "You have been granted some privs, like fast, fly, noclip, time, teleport and worldedit.")
    local ppos = player:get_pos()
    
    --local surface = realterrain.get_surface(math.floor(ppos.x+0.5), math.floor(ppos.z+0.5))
    --local pos = {x=0, y=surface+0.5, z=0}
    --if not isnewplayer then
        --surface = realterrain.get_surface(math.floor(ppos.x+0.5), math.floor(ppos.z+0.5))
        --if surface then
            --pos = {x=ppos.x, y=surface+0.5, z=ppos.z}
        --end
    --end
    --player:setpos(pos)
    --minetest.chat_send_player(pname, "You have been moved to the surface")
    return true
end)


-- registers a chat command to allow generation of the map without having to tediously walk every inch of it
-- modified from https://rubenwardy.com/minetest_modding_book/en/map/environment.html#loading-blocks
minetest.register_chatcommand("generate", {
    params = "",
    description = "generate the map",
    func = function ()
        
        local pos1 = realterrain.raster_pos1
        local pos2 = realterrain.raster_pos2
        local function sec2clock(seconds)
            local seconds = tonumber(seconds)
            if seconds <= 0 then
                return "00:00:00";
            else
                hours = string.format("%02.f", math.floor(seconds/3600));
                mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
                secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
                return hours..":"..mins..":"..secs
            end
        end
        if pos1 and pos2 and not mapdone then
        
            local map_dimensions = 0
            local x_axis = math.abs(pos1.x) + math.abs(pos2.x)
            local z_axis = math.abs(pos1.z) + math.abs(pos2.z)
            map_dimensions1 = "Map dimensions:(" .. pos1.x .. ", " .. pos1.y .. ", " .. pos1.z .. ") to (" .. pos2.x .. ", " .. pos2.y .. ", " .. pos2.z .. ")"
            map_dimensions2 = "Map has a volume of " .. x_axis * pos2.y * z_axis .. " nodes (" .. x_axis .. "*" .. pos2.y .. "*" .. z_axis .. ")"

            minetest.emerge_area (pos1, pos2, function (pos, action, num_calls_remaining, context)
                -- On first call, record number of blocks
                if not context.total_blocks then
                    context.total_blocks  = num_calls_remaining + 1
                    context.loaded_blocks = 0
                    context.start_time = os.clock()
                end

                -- Increment number of blocks loaded
                context.loaded_blocks = context.loaded_blocks + 1

                -- Send progress message
                if context.total_blocks == context.loaded_blocks then
                    local elapsed_time = os.clock()-context.start_time
                    minetest.chat_send_all("Finished loading blocks! Time elapsed:" .. sec2clock(elapsed_time))
                    minetest.chat_send_all(map_dimensions1)
                    minetest.chat_send_all(map_dimensions2)
                    context = {}
                    mapdone = true
                else
                    local perc = 100 * context.loaded_blocks / context.total_blocks
                    local msg  = string.format("Loading blocks %d/%d (%.2f%%)", context.loaded_blocks, context.total_blocks, perc)
                    minetest.chat_send_all(msg)
                end
            end, context)
        else
            minetest.chat_send_all("Map is already generated!")
        end
    end
})

realterrain.init()
