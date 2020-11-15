-- mapgen.lua
--------------------------------------------------------
-- 1. define variables & following functions:
-- 2. build_cids()
-- 3. build_biomes()
-- 4. build_shafts()
-- 5. get_shaft()
-- 6. get_tree()
-- 7. generate()

local SCHEMS_PATH       = realterrain.schems_path
local threshholds       = realterrain.threshholds

-- flags defined in settings
local alpine_level      = realterrain.settings.alpinelevel
local sub_alpine        = realterrain.settings.subalpine
local filler_depth      = realterrain.settings.fillerdepth
local water_level       = realterrain.settings.waterlevel
local kelp_min_depth    = realterrain.settings.kelpmindep
local wlily_max_depth   = realterrain.settings.wlilymaxdep
local wlily_prob        = realterrain.settings.wlilyprob
local bug_max_height    = realterrain.settings.bugmaxheight
local no_decoration     = realterrain.settings.nodecoration
local no_biomes         = realterrain.settings.nobiomes
local generate_ores     = realterrain.settings.generateores
local trees             = realterrain.trees

-- defaults for biome generation
local stone             = nil
local water             = nil
local air               = nil

-- tables
local surface_cache     = {} -- used to prevent reading of DEM for skyblocks
local cids_grass        = {} -- content ids for the 5 grass nodes
local cids_dry_grass    = {} -- content ids for the 5 grass nodes
local cids_fern         = {} -- content ids for the 3 grass nodes
local cids_marram_grass = {} -- content ids for the 3 grass nodes
local cids_bugs         = {} -- content ids for bugs
local cids_bugs_ct      = 0  -- table count for cids_bugs
local cids_mushrooms    = {} -- content ids for mushrooms
local cids_mushrooms_ct = 0  -- table count for cids_mushrooms
local cids_misc         = {} -- content ids for miscellaneous decorations
local cids_nodeco       = {} -- content ids for nodes that should have no decoraction above it
local biomes            = {} -- biome definitions defined in settings
local shafts            = {} -- defines all nodes for a given y coordinate
local treemap           = {} -- table of tree schems and their positions
local bugmap            = {} -- table of bug positions for adding timers
local fillmap           = {} -- table of x/z positions already occupied with some decoration

local function build_cids()
    -- default nodes
    stone = minetest.get_content_id("default:stone")
    water = minetest.get_content_id("default:water_source")
    air   = minetest.get_content_id("air")
    -- cids for grasses
    for i = 1, 5 do
        table.insert(cids_grass, minetest.get_content_id("default:grass_" .. i))
        table.insert(cids_dry_grass, minetest.get_content_id("default:dry_grass_" .. i))
    end
    for i = 1, 3 do
        table.insert(cids_fern, minetest.get_content_id("default:fern_" .. i))
        table.insert(cids_marram_grass, minetest.get_content_id("default:marram_grass_" .. i))
    end
    -- cids_bugs
    table.insert(cids_bugs, minetest.get_content_id("butterflies:butterfly_white"))
    --table.insert(cids_bugs, minetest.get_content_id("butterflies:butterfly_violet"))
    --table.insert(cids_bugs, minetest.get_content_id("butterflies:butterfly_red"))
    table.insert(cids_bugs, minetest.get_content_id("fireflies:firefly"))
    for _ in pairs(cids_bugs) do cids_bugs_ct = cids_bugs_ct + 1 end
    -- cids_mushrooms
    table.insert(cids_mushrooms, minetest.get_content_id("flowers:mushroom_brown"))
    table.insert(cids_mushrooms, minetest.get_content_id("flowers:mushroom_brown")) -- adding brown 2x to make it more common than red
    table.insert(cids_mushrooms, minetest.get_content_id("flowers:mushroom_red"))
    for _ in pairs(cids_mushrooms) do cids_mushrooms_ct = cids_mushrooms_ct + 1 end
    -- cids_miscellaneous
    cids_misc = {
        -- stone = minetest.get_content_id("default:stone"),
        -- water = minetest.get_content_id("default:water_source"),
        -- air = minetest.get_content_id("default:air"),
        waterlily = minetest.get_content_id("flowers:waterlily_waving"),
        sand_with_kelp = minetest.get_content_id("default:sand_with_kelp"),
        junglegrass = minetest.get_content_id("default:junglegrass"),
        dry_shrub = minetest.get_content_id("default:dry_shrub"),
        snowblock = minetest.get_content_id("default:snowblock"),
        snow = minetest.get_content_id("default:snow"),
    }
    -- cids_nodeco
    cids_nodeco[minetest.get_content_id("default:water_source")] = true
    cids_nodeco[minetest.get_content_id("default:stone")] = true
    cids_nodeco[minetest.get_content_id("default:desert_stone")] = true
    cids_nodeco[minetest.get_content_id("default:sandstone")] = true
    cids_nodeco[minetest.get_content_id("default:desert_sandstone")] = true
    cids_nodeco[minetest.get_content_id("default:silver_sandstone")] = true
end
local function build_biomes()

    local threshhold_cnt    = 0
    local ground_default    = "default:stone"
    local shrub_default     = nil
    local tree_default      = nil
    local function isempty(s)
        return s == nil or s == ''
    end
    for _ in pairs(threshholds) do threshhold_cnt = threshhold_cnt + 1 end
    for i = 1, threshhold_cnt do
        
        local threshhold      = threshholds[i]
        local prefixnum = i <= 10 and "0" .. i-1 or i-1
        local prefix = "b" .. prefixnum
        local ground1_setting = realterrain.settings[prefix.."ground1"]
        local ground2_setting = realterrain.settings[prefix.."ground2"]
        local gprob_setting   = realterrain.settings[prefix.."gprob"]
        local shrub1_setting  = realterrain.settings[prefix.."shrub1"]
        local sprob1_setting  = realterrain.settings[prefix.."sprob1"]
        local shrub2_setting  = realterrain.settings[prefix.."shrub2"]
        local sprob2_setting  = realterrain.settings[prefix.."sprob2"]
        local tree1_setting   = realterrain.settings[prefix.."tree1"]
        local tprob1_setting  = realterrain.settings[prefix.."tprob1"]
        local tree2_setting   = realterrain.settings[prefix.."tree2"]
        local tprob2_setting  = realterrain.settings[prefix.."tprob2"]
        
        local ground1 = (ground1_setting) and ground1_setting or ground_default
        local ground2 = (ground2_setting and gprob_setting > 0) and ground2_setting or ground1
        local shrub1  = (shrub1_setting and sprob1_setting > 0) and shrub1_setting or shrub_default
        local shrub2  = (shrub2_setting and sprob2_setting > 0) and shrub2_setting or shrub1
        local tree1  = (tree1_setting and tprob1_setting > 0) and tree1_setting or tree_default
        local tree2  = (tree2_setting and tprob2_setting > 0) and tree2_setting or tree1
        
        biomes[threshhold] = {
            
            ground1 = minetest.get_content_id(ground1),
            ground2 = minetest.get_content_id(ground2),
            gprob   = gprob_setting,
            shrub1  = shrub1 and minetest.get_content_id(shrub1) or nil,
            sprob1  = sprob1_setting,
            shrub2  = shrub2 and minetest.get_content_id(shrub2) or nil,
            sprob2  = sprob2_setting,
            tree1   = tree1,
            tprob1  = tprob1_setting,
            tree2   = tree2,
            tprob2  = tprob2_setting,
        }
    end
end
local function build_shafts()
    for _, shaft in ipairs(realterrain.shafts) do
        table.insert(shafts, {
            surface     = minetest.get_content_id(shaft[1]),
            filler      = minetest.get_content_id(shaft[2]),
            bedrock     = minetest.get_content_id(shaft[3]),
            shrub       = shaft[4],
            sprob       = tonumber(shaft[5]),
            bprob       = tonumber(shaft[6]),
            mprob       = tonumber(shaft[7]),
        })
    end
end
local function get_shaft(cover, elev)

    -- defines y shaft of bedrock, filler, surface, and decoration based on biome
    local bedrock       = stone
    local filler        = stone
    local surface       = stone
    local tree          = nil   -- 1 block above surface
    local shrub         = nil   -- 1 block above surface
    local waterlily     = nil   -- 1 block above lake water_level
    local bug           = nil   -- 2 or more blocks above the surface
    local bug_ht        = 2     -- minimum 2 blocks above the surface
    local param2        = 0
    
    -- internal variables
    local randnum       = math.random(1,5)
    local shaft         = nil
    local bprob         = 0 -- bug probability
    local mprob         = 0 -- mushroom probability
    local wdepth        = elev < water_level and water_level-elev or 0 -- water depth

    if not no_biomes and cover then
    
        -- get biome based on cover (0:lake, 16:beach, 256:ocean, 257:alpine, 258:subalpine)
        if elev > (alpine_level + randnum) then
            cover = (sub_alpine > 0 and elev < (alpine_level + sub_alpine + randnum)) and 258 or 257
        elseif cover > 0 and elev < water_level - kelp_min_depth then
            cover = 256 -- use ocean biome if no lake biome present and elev is less than kelp_min_depth
        elseif cover == 0 and elev >= water_level and elev <= water_level+1 then
            cover = 16 -- if lake biome falls at or over water_level use beach biome instead
        elseif cover == 16 and elev > water_level+1 then
            cover = 32 -- if beach has elevation 2 or more nodes higher than water_level then use grassland
        end
        
        local biome = biomes[cover]
        surface = (not no_decoration and biome.gprob >= math.random(1,100)) and biome.ground2 or biome.ground1

        if not no_decoration and not cids_nodeco[surface] then -- define decorations based on biome first
        
            -- check settings for tree schems first
            if biome.tree1 and (biome.tprob1 * 100) >= math.random(1,10000) then -- tprob1 can be x.x%
                if biome.tree2 and biome.tprob2 >= math.random(1,100) then -- tprob2 can be x%
                    tree = biome.tree2
                else
                    tree = biome.tree1
                end
            end
            -- check settings for shrubs if no tree and surface allows
            if not tree then
                if biome.shrub1 and (biome.sprob1 * 100) >= math.random(1,10000) then -- sprob1 can be x.x%
                    if biome.shrub2 and biome.sprob2 >= math.random(1,100) then -- sprob2 can be x%
                        shrub = biome.shrub2
                    else
                        shrub = biome.shrub1
                    end
                end
            end
            
            -- if no tree or shrub from biome, get from shaft
            if not tree and not shrub then
                for _, p in pairs(shafts) do
                    if p.surface == surface then
                        shaft = p
                        break
                    end
                end
                if shaft then
                    bedrock = shaft.bedrock
                    filler  = shaft.filler
                    -- if no decoration and surface allows, then use shrub/bug/mushroom defined in shaft
                    if not shrub then
                        if shaft.shrub and shaft.sprob >= math.random(1,100) then -- sprob can be x%
                            -- try for shrub defined in shaft first
                            if shaft.shrub == "grass" then
                                shrub = cids_grass[math.random(1, 5)]
                            elseif shaft.shrub == "dry_grass" then
                                shrub = cids_dry_grass[math.random(1, 5)]
                            elseif shaft.shrub == "fern" then
                                shrub = cids_fern[math.random(1, 3)]
                            elseif shaft.shrub == "marram_grass" then
                                shrub = cids_marram_grass[math.random(1, 3)]
                            else
                                shrub = cids_misc[shaft.shrub]
                            end
                        elseif shaft.mprob * 100 >= math.random(1,10000) then
                            -- try for mushroom second
                            shrub = cids_mushrooms[math.random(1, cids_mushrooms_ct)]
                        end
                        if shaft.bprob * 100 >= math.random(1,10000) then
                            -- if a bug shows up, determine how high it's flying
                            bug = cids_bugs[math.random(1, cids_bugs_ct)]
                            bug_ht = math.random(2, bug_max_height)
                        end
                    end
                end
            end
            
            if wdepth > 0 then
                -- get waterlily and param2 for kelp and waterlily
                if cover == 256 and surface == cids_misc["sand_with_kelp"] then
                    local kelp_max_length = wdepth - 2 -- two nodes below the water's surface
                    local kelp_min_length = kelp_max_length / 2 -- half of kelp_max_length
                    param2 = math.random(kelp_min_length, kelp_max_length) * 16 -- param2 for kelp length
                elseif cover == 0 and wdepth <= wlily_max_depth then
                    local calc_wlily_prob = wdepth < wlily_max_depth and ((wlily_max_depth - wdepth) / wlily_max_depth) * wlily_prob or 1 -- reduce probability the deeper you go
                    if calc_wlily_prob >= math.random(1,100) then
                        waterlily = cids_misc["waterlily"]
                        param2 = math.floor(math.random(0,3))
                    end
                end
            end
        
        end -- end not nodecoration
    end -- end not nobiomes
    
    return {
        bedrock     = bedrock,
        filler      = filler,
        surface     = surface,
        tree        = tree,
        shrub       = shrub,
        bug         = bug,
        bug_ht      = bug_ht,
        waterlily   = waterlily,
        param2      = param2
    }
end
local function get_tree(pos, name)
    -- checks the trees table for tree name and returns a tree object
    local properties = nil
    local order = 1 -- default order 1 is to be overwritten be all subsequent schems (use for wide trees with lots of foliage)
    local radius = 3 -- default to 7x?x7 for tree schems not in trees table (i.e. a specific tree shape like pine2)
    local tradius = 0
    local rotation = math.floor(math.random(0,3)) * 90
    for tname, tproperties in pairs(trees) do
        if name == tname then
            properties = tproperties
            break
        end
    end
    if properties then
        local schems = properties.schems
        if schems and schems > 1 then
            local rnumber = math.random(1, schems)
            if name == "bush" or name == "bbush" or name == "pbush" or name == "spbush" then
                order = 1
            else
                order = rnumber
            end
            name  = name .. rnumber
        end
        radius  = properties.radius
        tradius = properties.tradius
    end
    
    -- if trunk radius is greater than 0, add positions to fillmap to avoid having trunk overwritten by decoration
    if tradius > 0 then
        local pos1 = {x=pos.x-tradius, y=pos.y, z=pos.z-tradius}
        local pos2 = {x=pos.x+tradius, y=pos.y+bug_max_height, z=pos.z+tradius}
        table.insert(fillmap, {pos1=pos1,pos2=pos2} )
    end
    
    return {order = order, pos = pos, name = name, radius = radius, rotation = rotation}
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
    
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new { MinEdge = emin, MaxEdge = emax }
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
            return
        end
        if y0 >= surface_cache[cz0][cx0].maxelev then
            local chugent = math.ceil((os.clock() - t0) * 1000)
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
        return
    end
    --print(dump(heightmap))
    
    -------------------------------------
    -- this section generates the map
    -------------------------------------
    if cids_grass[1] == nil then
        build_cids()
    end
    if biomes[1] == nil then
        build_biomes()
    end
    if shafts[1] == nil then
        build_shafts()
    end
    
    for z = z0, z1 do
        for x = x0, x1 do
            if heightmap[z] and heightmap[z][x] and heightmap[z][x]["elev"] then
                
                local vi    = area:index(x, y0, z) -- voxelmanip index
                local elev  = heightmap[z][x].elev -- elevation in from DEM
                local cover = heightmap[z][x].cover -- cover in from BIOMES
                local shaft = get_shaft(cover, elev)

                for y = y0, y1 do

                    local node = nil
                    
                    -- determine the node type for every node in the y column
                    if y < elev-filler_depth then
                        node = shaft.bedrock
                    elseif y < elev then
                        node = shaft.filler
                    elseif y == elev then
                        node = shaft.surface
                    elseif y <= water_level then
                        node = water
                    elseif y > water_level then
                        -- everything else is decoration (kelp and coral are surface nodes)
                        if y == water_level+1 and shaft.waterlily then
                            node = shaft.waterlily
                        elseif y == elev+1 then
                            if shaft.tree then
                                table.insert(treemap, get_tree({x=x,y=y,z=z}, shaft.tree))
                            else
                                node = shaft.shrub
                            end
                        elseif y == elev+shaft.bug_ht and not shaft.tree then
                            node = shaft.bug
                            table.insert(bugmap, {pos = {x=x,y=y,z=z}})
                        end
                    end
                    
                    if node then
                        data[vi] = node
                        data2[vi] = shaft.param2
                        node = nil
                    end
                    vi = vi + ystridevm
                end --end y iteration
                
            end --end if pixel is in heightmap
        end -- end for x
    end -- end for z

    -- set decorations in fillmap to air to avoid collisions with tree schems
    for _, trunk in ipairs(fillmap) do
        for i in area:iterp(trunk.pos1, trunk.pos2) do
           data[i] = air
        end
    end


    vm:set_data(data)
    vm:set_param2_data(data2)

    if generate_ores then
        minetest.generate_ores(vm, minp, maxp)
    end
    
    vm:calc_lighting()
    vm:write_to_map(data)
    vm:update_liquids()

    -- sort trees based on foliage height (shortest first) then place all the trees
    -- a.order > b.order results in ordering of 3,2,1,0 with items at the beginning of the list (high foliage) overwriting those at the end (low foliage)
    table.sort(treemap, function(a,b) return a.order > b.order end)
    for _, tree in ipairs(treemap) do
        --minetest.place_schematic_on_vmanip(vm, {x=tree.pos.x-tree.radius,y=tree.pos.y,z=tree.pos.z-tree.radius}, SCHEMS_PATH..tree.name..".mts", tree.rotation, nil, false)
        minetest.place_schematic({x=tree.pos.x-tree.radius,y=tree.pos.y,z=tree.pos.z-tree.radius}, SCHEMS_PATH..tree.name..".mts", tree.rotation, nil, false)
    end
    
    -- set node_timer for all bugs in bugmap
    for _, bug in ipairs(bugmap) do
        minetest.get_node_timer(bug.pos):start(1)
    end
    
    -- reset chunk specific cache between each chunk
    fillmap = {}
    treemap = {}
    bugmap = {}
    
end