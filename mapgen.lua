-- mapgen.lua
--------------------------------------------------------
-- 1. define variables & following functions:
-- 2. in_table()
-- 3. build_cids()
-- 4. is_dirt()
-- 5. randomize_trees()
-- 6. randomize_shrubs()
-- 7. height_fill_below()
-- 8. generate()

local SCHEMS_PATH = realterrain.schems_path
local alpine_level = tonumber(realterrain.settings.alpinelevel)
local sub_alpine = tonumber(realterrain.settings.subalpine)
local water_level = tonumber(realterrain.settings.waterlevel)
local kelp_min_depth = tonumber(realterrain.settings.kelpmindep)
local add_vegetation = tonumber(realterrain.settings.vegetation)
local randomize = tonumber(realterrain.settings.randomize)
local add_bugs = tonumber(realterrain.settings.bugs)
local add_mushrooms = tonumber(realterrain.settings.mushrooms)

local cids = nil
local snow = nil
local b_mushroom = nil
local r_mushroom = nil
local butterfly = nil
local firefly = nil
local junglegrass = nil

local cids_grass = {}
local cids_dry_grass = {}
local cids_fern = {}
local cids_marram_grass = {}
local tree_schems = {
--  "treename"   = [# of schems]
    acacia     = 3,
    apple      = 3,
    aspen      = 3,
    bush       = 3,
    jungletree = 2,
    pine       = 3,
    spine      = 3,
    marshtree  = 2,
    bonsai     = 2,
    boulder    = 2
}
local tree_fload = { --trees to force load (overwriting any pre-existing nodes)
    "jungletree3",
    "bush1",
    "bush2",
    "bush3"
}
local neighborhood = {
	a = {x= 1,y= 0,z= 1}, -- NW
	b = {x= 0,y= 0,z= 1}, -- N
	c = {x= 1,y= 0,z= 1}, -- NE
	d = {x=-1,y= 0,z= 0}, -- W
--	e = {x= 0,y= 0,z= 0}, -- SELF
	f = {x= 1,y= 0,z= 0}, -- E
	g = {x=-1,y= 0,z=-1}, -- SW
	h = {x= 0,y= 0,z=-1}, -- S
	i = {x= 1,y= 0,z=-1}, -- SE
}
local surface_cache = {} --used to prevent reading of DEM for skyblocks

local function in_table(items, item)
    for _,v in pairs(items) do
      if v == item then
        return true
      end
    end
    return false
end

local function build_cids()
    --turn various content ids into variables for speed
	cids = { 
		dirt = minetest.get_content_id("default:dirt"),
        dirt_with_grass = minetest.get_content_id("default:dirt_with_grass"),
        dirt_with_dry_grass = minetest.get_content_id("default:dirt_with_dry_grass"),
        dirt_with_snow = minetest.get_content_id("default:dirt_with_snow"),
        dirt_with_rainforest_litter = minetest.get_content_id("default:dirt_with_rainforest_litter"),
        dirt_with_coniferous_litter = minetest.get_content_id("default:dirt_with_coniferous_litter"),
		stone = minetest.get_content_id("default:stone"),
        desert_sand = minetest.get_content_id("default:desert_sand"),
        desert_stone = minetest.get_content_id("default:desert_stone"),
        snow = minetest.get_content_id("default:snow"),
		sand = minetest.get_content_id("default:sand"),
		water_source = minetest.get_content_id("water_source"),
        sand_with_kelp = minetest.get_content_id("default:sand_with_kelp")
	}
    
    -- load cids defined in settings.lua
    local ground_default    = minetest.get_content_id("default:desert_sand")
    local shrub_default     = nil
    
	for i = 0, 9 do
		local prefix = "b" .. i
        local ground_setting  = realterrain.settings[prefix.."ground"]
        local ground2_setting = realterrain.settings[prefix.."ground2"]
        local gprob_setting   = tonumber(realterrain.settings[prefix.."gprob"])
        local shrub_setting   = realterrain.settings[prefix.."shrub"]
        local sprob_setting   = tonumber(realterrain.settings[prefix.."sprob"])
        local shrub2_setting  = realterrain.settings[prefix.."shrub2"]
        local sprob2_setting  = realterrain.settings[prefix.."sprob2"]
        
		cids[i] = {
			ground  = (ground_setting and ground_setting ~= "") and minetest.get_content_id(ground_setting) or ground_default,
			ground2 = (ground_setting and ground2_setting ~= "" and gprob_setting > 0) and minetest.get_content_id(ground2_setting) or ground,
			shrub   = (shrub_setting and shrub_setting ~= "" and sprob_setting > 0) and minetest.get_content_id(shrub_setting) or shrub_default,
			shrub2  = (shrub2_setting and shrub2_setting ~= "" and sprob2_setting > 0) and minetest.get_content_id(shrub2_setting) or shrub
		}
	end
    
    snow = minetest.get_content_id("default:snow")
    b_mushroom = minetest.get_content_id("flowers:mushroom_brown")
    r_mushroom = minetest.get_content_id("flowers:mushroom_red")
    butterfly = minetest.get_content_id("butterflies:butterfly_white")
    firefly = minetest.get_content_id("fireflies:firefly")
    junglegrass = minetest.get_content_id("default:junglegrass")
    for i = 1, 5 do
        table.insert(cids_grass, minetest.get_content_id("default:grass_" .. i))
        table.insert(cids_dry_grass, minetest.get_content_id("default:dry_grass_" .. i))
	end
	for i = 1, 3 do
        table.insert(cids_fern, minetest.get_content_id("default:fern_" .. i))
        table.insert(cids_marram_grass, minetest.get_content_id("default:marram_grass_" .. i))
	end

end

local function is_dirt(ground, cids)
    -- returns true if ground is a dirt variant (to dermine if plain dirt should be placed below)
    return (
        ground == cids["dirt_with_grass"] or 
        ground == cids["dirt_with_dry_grass"] or 
        ground == cids["dirt_with_snow"] or 
        ground == cids["dirt_with_rainforest_litter"] or 
        ground == cids["dirt_with_coniferous_litter"]
    )
end

local function randomize_trees(tree)
    local schems = tree_schems[tree]
    if schems and schems > 0 then
        return tree .. math.random(1,schems)
    end
    return tree
end

local function randomize_shrubs(shrub, add_bugs, add_mushrooms)    

    -- insert bugs among junglegrass
    if shrub == junglegrass then
        if add_bugs and math.random(1,30) == 1 then -- 1 in 30 chance of bug
            return math.random(1,2) == 1 and butterfly or firefly -- 50/50 mix of butterflies and fireflies
        end
        return shrub
    end
    
    -- randomize grass
    if in_table(cids_grass, shrub) then
        if add_bugs and math.random(1,30) == 1 then -- 1 in 30 chance of bug
            return math.random(1,2) == 1 and butterfly or firefly -- 50/50 mix of butterflies and fireflies
        end
        return cids_grass[math.random(1, 4)] -- can do 1 to 5
    end

    -- randomize fern
    if in_table(cids_fern, shrub) then
        if add_bugs and math.random(1,50) == 1 then -- 2% chance of bug
            return firefly
        end
        if add_mushrooms and math.random(1,20) == 1 then -- 5% chance of mushroom
            if math.random(1,10) == 1 then
                return r_mushroom -- 10% chance of red mushroom
            end
            return b_mushroom
        end
        return cids_fern[math.random(1, 3)] -- can do 1 to 3
    end

    -- randomize marram_grass
    if in_table(cids_marram_grass, shrub) then
        return cids_marram_grass[math.random(1, 3)] -- can do 1 to 3
    end
    
    -- randomize dry_grass
    if in_table(cids_dry_grass, shrub) then
        return cids_dry_grass[math.random(1, 5)] -- can do 1 to 5
    end

    return shrub
end

local function height_fill_below(x,z,heightmap)
--this function gets the height needed to fill below a node

	local height = 0
	local height_in_chunk = 0
	local height_below_chunk = 0
	local below_positions = {}
	local elev = heightmap[z][x].elev
	for dir, offset in pairs(neighborhood) do
		--get elev for all surrounding nodes
		if dir == "b" or dir == "d" or dir == "f" or dir == "h" then
			
			if heightmap[z+offset.z] and heightmap[z+offset.z][x+offset.x] and heightmap[z+offset.z][x+offset.x].elev then
				local nelev = heightmap[z+offset.z][x+offset.x].elev
				-- if the neighboring height is more than one down, check if it is the furthest down
				if elev > ( nelev) and height < (elev-nelev) then
					height = elev - nelev
				end
			end
		end
	end
	--print(height)
	return height -1
end

function realterrain.generate(minp, maxp)
    -------------------------------------
    -- this section creates the heightmap
    -------------------------------------
	local t0 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z

	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	local treemap = {}
	local fillmap = {}
	--print("x0:"..x0..",y0:"..y0..",z0:"..z0..";x1:"..x1..",y1:"..y1..",z1:"..z1)
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	local data2 = vm:get_param2_data()
	local sidelen = x1 - x0 + 1
	local ystridevm = area.ystride

	--calculate the chunk coordinates
	local cx0 = math.ceil(x0 / sidelen)
	local cy0 = math.ceil(y0 / sidelen)
	local cz0 = math.ceil(z0 / sidelen)
	
	--check to see if the current chunk is above (or below) the elevation range for this footprint
	if surface_cache[cz0] and surface_cache[cz0][cx0] then
		if surface_cache[cz0][cx0].offelev then
			local chugent = math.ceil((os.clock() - t0) * 1000)
			-- print ("[OFF] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
			return
		end
		if y0 >= surface_cache[cz0][cx0].maxelev then
			local chugent = math.ceil((os.clock() - t0) * 1000)
			-- print ("[SKY] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
			vm:set_data(data)
			vm:calc_lighting()
			vm:write_to_map(data)
			vm:update_liquids()
			return
		end
	end
	
	local buffer = 0
	local heightmap = realterrain.build_heightmap(x0-buffer, x1+buffer, z0-buffer, z1+buffer) --build the heightmap
	local minelev, maxelev --calculate the min and max elevations for skipping certain blocks completely
	for z=z0, z1 do
		for x=x0, x1 do
			local elev
			if heightmap[z] and heightmap[z][x] then
				elev = heightmap[z][x].elev
				if elev then
					if not minelev then
						minelev = elev
						maxelev = elev
					else
						if elev < minelev then
							minelev = elev
						end
						if elev > maxelev then
							maxelev = elev
						end
					end
				end
			end
		end
	end

	-- if there were elevations in this footprint then add the min and max to the cache table if not already there
	if minelev then
		--print("minelev: "..minelev..", maxelev: "..maxelev)
		if not surface_cache[cz0] then
			surface_cache[cz0] = {}
		end
		if not surface_cache[cz0][cx0] then
			surface_cache[cz0][cx0] = {minelev = minelev, maxelev=maxelev}
		end
	else
		--otherwise this chunk was off the DEM raster
		if not surface_cache[cz0] then
			surface_cache[cz0] = {}
		end
		if not surface_cache[cz0][cx0] then
			surface_cache[cz0][cx0] = {offelev=true}
		end
		local chugent = math.ceil((os.clock() - t0) * 1000)
		-- print ("[OFF] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
		return
	end
	--print(dump(heightmap))
    
    -------------------------------------
    -- this section generates the map
    -------------------------------------    
	if not cids then
		build_cids()
	end
    if not alpine_level or alpine_level < 0 then
        alpine_level = 0
    end
    if not sub_alpine or sub_alpine < 0 then
        sub_alpine = 0
    end
    if not water_level or water_level < 0 then
        water_level = 0
    end
    if not kelp_min_depth or kelp_min_depth < 4 then
        kelp_min_depth = 4
    end

    local function build_subsurface(y, elev, cids, cover, alpine_level, water_level)
        
        -- default subsurface is same as surface
        local subsurface  = cids[cover].ground
        
        if is_dirt(subsurface, cids) then
            -- use plain dirt for subsurface if surface is a dirt variant
            subsurface = cids["dirt"]               
        elseif subsurface == cids["desert_sand"] then
            -- use desert_stone for subsurface if surface is desert_sand
            subsurface = cids["desert_stone"]       
        end
        
        if y > alpine_level then
            -- subsurface of stone
            return cids["stone"]
        elseif y < water_level then
            -- subsurface of sand at fixed depth over stone
            return y < (elev - 1) and cids["stone"] or cids["sand"] 
        else
            -- subsurface at fixed depth over stone (default)
            return y < (elev - 2) and cids["stone"] or subsurface 
        end
        
    end
    
    local function build_surface(y, cids, cover, alpine_level, water_level, kelp_min_depth)
        
        -- default surface
        local surface = cids[cover].ground
        
        -- use ground2 as surface (if defined) based on gprob
        local gprob = tonumber(realterrain.settings["b"..cover.."gprob"])
        if gprob and gprob >= math.random(0,100) then
            local ground2 = cids[cover].ground2
            if ground2 then
                surface = ground2
            end
        end

        if y > alpine_level then
            -- alpine surface
            return cids["dirt_with_snow"]
        elseif y < water_level then
            -- water bottom (mix of sand_with_kelp and sand)
            return (y < (water_level - kelp_min_depth) and math.random(1,5) == 1) and cids["sand_with_kelp"] or cids["sand"] 
        else
            -- surface defined in settings (default)
            return surface
        end

    end
    
    local function build_vegetation(x, y, z, cids, cover, alpine_level, sub_alpine, treemap, randomize, add_bugs, add_mushrooms)

        if y > alpine_level then
                  
            -- sub-alpine vegetation
            if y > alpine_level and y < alpine_level + sub_alpine then
                if (cover == 4 or cover == 9) and math.random(1,25) == 1 then -- cover 4 and 9 have trees
                    local tree = (math.random(1,15) == 1) and "spine2" or "spine1"
                    table.insert(treemap, {pos={x=x,y=y,z=z}, type=tree})
                    return nil
                else
                    return snow
                end
            end
            
            -- alpine level is snow two blocks deep
            table.insert(treemap, {pos={x=x,y=y,z=z}, type="snowblock2"})
            return nil

        elseif y > water_level and y < alpine_level then

            -- shrub defaults to nothing 
            local shrub = nil
            
            -- use shrub based on sprob
            local sprob = tonumber(realterrain.settings["b"..cover.."sprob"])
            if sprob and sprob > math.random(0,100) then
                shrub = cids[cover].shrub
                -- use shrub2 based on sprob2
                local sprob2 = tonumber(realterrain.settings["b"..cover.."sprob2"])
                if sprob2 and sprob2 > math.random(0,100) then
                    shrub = cids[cover].shrub2
                end
            end
            
            if shrub then
                if randomize then
                    return randomize_shrubs(shrub, add_bugs, add_mushrooms)
                else
                    return shrub
                end
            end
            
            -- tree defaults to nothing 
            local tree = nil

            -- use tree based on tprob
            local tprob = tonumber(realterrain.settings["b"..cover.."tprob"])
            if tprob and tprob > math.random(0,100) then
                tree = realterrain.settings["b"..cover.."tree"]
                -- use tree2 based on tprob2
                local tprob2 = tonumber(realterrain.settings["b"..cover.."tprob2"])
                if tprob2 and tprob2 > math.random(0,100) then
                    tree = realterrain.settings["b"..cover.."tree2"]
                end
            end

            if tree then
                table.insert(treemap, {pos={x=x,y=y,z=z}, type=randomize_trees(tree)})
            end
            return nil

        end
    end
    
	for z = z0, z1 do
	for x = x0, x1 do
		if heightmap[z] and heightmap[z][x] and heightmap[z][x]["elev"] then
			
			local height = height_fill_below(x,z,heightmap) -- get the height needed to fill_below
			local elev = heightmap[z][x].elev -- elevation in from DEM
			local cover = heightmap[z][x].cover
            local alpine_random = math.random(1,10)
            local alpine_level_random = alpine_level + alpine_random
            local sub_alpine_random = (sub_alpine > 0) and (sub_alpine + alpine_random) or 0       
            local node_data = nil
			local vi = area:index(x, y0, z) -- voxelmanip index
            local surface_is_water = false
            
            if not cover or cover < 0 or cover > 9 then
                cover = 0
            end
            
			for y = y0, y1 do
            
                -- determine the node type for every node in the y column from max depth to DEM elevation +1
				if y < elev then 
                    -- current node has a y coorinate less than elevation defined in DEM
                    node_data = build_subsurface(y, elev, cids, cover, alpine_level_random, water_level)
				elseif y == elev or (y < elev and y >= (elev - height)) then
                    -- current node has a y coordinate equal to elevation defined in DEM (or ?)
                    node_data = build_surface(y, cids, cover, alpine_level_random, water_level, kelp_min_depth)
                    surface_is_water = (node_data == cids["water_source"]) and true or false
                elseif add_vegetation and not surface_is_water and y == elev + 1 and elev >= water_level then
                    -- current node has a y coordinate one more than elevation defined in DEM and is above the water level
                    node_data = build_vegetation(x, y, z, cids, cover, alpine_level_random, sub_alpine_random, treemap, add_bugs, add_mushrooms)
                elseif y <= water_level then
                    -- any other node below the water level must be water, all other nodes above the water level must be air (nil)
					node_data = cids["water_source"]
				end
                
                -- write node if defined in ground/cover
                if node_data then
                    data[vi] = node_data
                    -- set param2 length for kelp
                    if (add_vegetation and y == elev and y <= (water_level - kelp_min_depth)) then -- narrow down to surface node less than or equal to minimum kelp depth
                        if node_data == cids["sand_with_kelp"] then
                            local kelp_max_length = water_level - y - 2 -- two nodes below the water's surface
                            local kelp_min_length = kelp_max_length / 2 -- half of kelp_max_length
                            data2[vi] = math.random(kelp_min_length, kelp_max_length) * 16
                        end
                    end
                    node_data = nil
                end
                
				vi = vi + ystridevm
			end --end y iteration
            
		end --end if pixel is in heightmap
	end -- end for x
	end -- end for z
    
	-- public function made by the default mod, to register ores and blobs
	if default then
		if default.register_ores then
			default.register_ores()
		end
		if default.register_blobs then
			default.register_blobs()
		end
	end
	vm:set_data(data)
    vm:set_param2_data(data2)
	--minetest.generate_ores(vm, minp, maxp) -- for generating a strata of stone and ores rather than stone alone
	vm:calc_lighting()
	vm:write_to_map(data)
	vm:update_liquids()
	
	--place all the trees (schems assumed to be 9x9 bases with tree in center)
	for _, tree in ipairs(treemap) do
        local radius = 4
        local force_placement = false
        if in_table(tree_fload, tree.type) then
            force_placement = true
        end
		minetest.place_schematic({x=tree.pos.x-radius,y=tree.pos.y,z=tree.pos.z-radius}, SCHEMS_PATH..tree.type..".mts", "random", nil, force_placement)
	end

end
