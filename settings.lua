-- for trees/bushes with multiple variants, omitting the final number will randomize the selection (i.e. apple = random apple tree of three possibilities)
-- for probability values, anything but a whole number between 1-100 will default to 0, except for decimals which will be rounded to the nearest whole number
local settings_table = {
--  {"setting_name",    "type",         "value"},

    --default settings
    {"fileelev",		"string",		"dem.bmp"},                 -- raster image file describing elevation (must be .bmp)
    {"elevbits",		"number",		8},                         -- how many bits to read from elevation file (8 or 16)
    {"filecover",		"string",		"biomes.bmp"},              -- raster image file describing biomes (must be .bmp)
    {"coverbits",		"number",		8},                         -- how many bits to read from biomes file (8 or 16)
    
    {"yscale",          "number",       1},                         -- increase/decrease scale along y (vertical) axis
    {"xscale",          "number",       1},                         -- increase/decrease scale along x (east-west) axis
    {"zscale",          "number",       1},                         -- increase/decrease scale along z (north-south) axis
    {"yoffset",         "number",       0},                         -- increase/decrease offset along y (vertical) axis
    {"xoffset",         "number",       0},                         -- increase/decrease offset along x (east-west) axis (i.e. 886)
    {"zoffset",         "number",       0},                         -- increase/decrease offset along z (north-south) axis (i.e. -997)
    {"centermap",       "number",       1},                         -- boolean, if true xoffset/zoffset will be set to half of raster width/breadth

    {"alpinelevel",     "number",       150},                       -- height of alpine biome start (i.e. 150)
    {"subalpine",       "number",       30},                        -- offset for sub_alpine zone set to 0 for none
    {"waterlevel",      "number",       18},                        -- height of water level (i.e. 18)
    {"kelpmindep",      "number",       6},                         -- minimum depth required for kelp to grow (recommend 6)
    
    {"vegetation",      "number",       1},                         -- generates vegetation when set to true
    {"randomize",       "number",       1},                         -- randomizes size of grass, dry_grass, ferns and marram_grass when set to true (depends on vegetation)
    {"bugs",            "number",       1},                         -- randomly adds white butterflies or fireflies when set to true (depends on randomize)
    {"mushrooms",       "number",       1},                         -- randomly adds brown and red mushrooms to forest biomes when set to true (depends on randomize)

    --#000000 (black) beach
    {"b0ground",		"string",		"default:sand"},            -- primary ground surface node
    {"b0ground2",		"string",		""},                        -- secondary ground surface node
    {"b0gprob",		    "number",		0},                         -- probability of secondary surface node
    {"b0tree",		    "string",		""},                        -- first .mts filename
    {"b0tprob",		    "number",		0},                         -- first .mts file probability
    {"b0tree2",		    "string",		""},                        -- second .mts filename
    {"b0tprob2",		"number",		0},                         -- second .mts file probability (% of first)
    {"b0shrub",		    "string",		"default:marram_grass_1"},  -- first ground cover node
    {"b0sprob",		    "number",		30},                        -- first ground cover node probability
    {"b0shrub2",		"string",		""},                        -- secondary ground cover node
    {"b0sprob2",		"number",		0},                         -- secondary ground cover node probability (% of first)

    --#1E1E1E (gray8) grassland
    {"b3ground",		"string",		"default:dirt_with_grass"},
    {"b3ground2",		"string",		""},
    {"b3gprob",		    "number",		0},
    {"b3tree",		    "string",		"rose"},
    {"b3tprob",		    "number",		1},
    {"b3tree2",		    "string",		"bush2"},
    {"b3tprob2",		"number",		5},
    {"b3shrub",		    "string",		"default:grass_1"},
    {"b3sprob",		    "number",		20},
    {"b3shrub2",		"string",		"flowers:dandelion_yellow"},
    {"b3sprob2",		"number",		5},

    --#282828 (gray7) deciduous forest
    {"b4ground",		"string",		"default:dirt_with_coniferous_litter"},
    {"b4ground2",		"string",		"default:dirt_with_grass"},
    {"b4gprob",		    "number",		15},
    {"b4tree",		    "string",		"apple"},
    {"b4tprob",		    "number",		5},
    {"b4tree2",		    "string",		"aspen"},
    {"b4tprob2",		"number",		30},
    {"b4shrub",		    "string",		"default:fern_1"},
    {"b4sprob",		    "number",		20},
    {"b4shrub2",		"string",		"flowers:viola"},
    {"b4sprob2",		"number",		2},

    --#323232 (gray6) marsh
    {"b5ground",		"string",		"default:dirt_with_rainforest_litter"},
    {"b5ground2",		"string",		"default:water_source"},
    {"b5gprob",		    "number",		30},
    {"b5tree",		    "string",		""},
    {"b5tprob",		    "number",		0},
    {"b5tree2",		    "string",		""},
    {"b5tprob2",		"number",		0},
    {"b5shrub",		    "string",		"default:junglegrass"},
    {"b5sprob",		    "number",		30},
    {"b5shrub2",		"string",		"default:grass_5"},
    {"b5sprob2",		"number",		20},

    --#3C3C3C (gray5) jungle
    {"b6ground",		"string",		"default:dirt_with_rainforest_litter"},
    {"b6ground2",		"string",		""},
    {"b6gprob",		    "number",		0},
    {"b6tree",		    "string",		"jungletree"},
    {"b6tprob",		    "number",		15},
    {"b6tree2",		    "string",		""},
    {"b6tprob2",		"number",		0},
    {"b6shrub",		    "string",		"default:junglegrass"},
    {"b6sprob",		    "number",		30},
    {"b6shrub2",		"string",		"flowers:geranium"},
    {"b6sprob2",		"number",		5},
        
    --#464646 (gray4) savannah
    {"b7ground",		"string",		"default:dirt_with_dry_grass"},
    {"b7ground2",		"string",		""},
    {"b7gprob",		    "number",		0},
    {"b7tree",		    "string",		"acacia"},
    {"b7tprob",		    "number",		.05},
    {"b7tree2",		    "string",		""},
    {"b7tprob2",		"number",		0},
    {"b7shrub",		    "string",		"default:dry_grass_1"},
    {"b7sprob",		    "number",		60},
    {"b7shrub2",		"string",		""},
    {"b7sprob2",		"number",		0},

    --#505050 (gray3) desert
    {"b8ground",		"string",		"default:desert_sand"},
    {"b8ground2",		"string",		""},
    {"b8gprob",		    "number",		0},
    {"b8tree",		    "string",		""},
    {"b8tprob",		    "number",		0},
    {"b8tree2",		    "string",		""},
    {"b8tprob2",		"number",		0},
    {"b8shrub",		    "string",		""},
    {"b8sprob",		    "number",		0},
    {"b8shrub2",		"string",		""},
    {"b8sprob2",		"number",		0},

    --#5A5A5A (gray2) conifer forest
    {"b9ground",		"string",		"default:dirt_with_coniferous_litter"},
    {"b9ground2",		"string",		"default:dirt_with_grass"},
    {"b9gprob",		    "number",		10},
    {"b9tree",		    "string",		"pine"},
    {"b9tprob",		    "number",		5},
    {"b9tree2",		    "string",		""},
    {"b9tprob2",		"number",		0},
    {"b9shrub",		    "string",		"default:fern_1"},
    {"b9sprob",		    "number",		20},
    {"b9shrub2",		"string",		"flowers:viola"},
    {"b9sprob2",		"number",		2},
    
    --#646464 (gray1) permafrost
    {"b1ground",		"string",		"default:permafrost"},
    {"b1ground2",		"string",		"default:dirt_with_grass"},
    {"b1gprob",		    "number",		20},
    {"b1tree",		    "string",		""},
    {"b1tprob",		    "number",		0},
    {"b1tree2",		    "string",		""},
    {"b1tprob2",		"number",		0},
    {"b1shrub",		    "string",		"default:snow"},
    {"b1sprob",		    "number",		30},
    {"b1shrub2",		"string",		"flowers:viola"},
    {"b1sprob2",		"number",		1},
    
    --#FFFFFF (white) road
    {"b2ground",		"string",		"default:mossycobble"},
    {"b2ground2",		"string",		"default:dirt_with_grass"},
    {"b2gprob",		    "number",		1},
    {"b2tree",		    "string",		""},
    {"b2tprob",		    "number",		0},
    {"b2tree2",		    "string",		""},
    {"b2tprob2",		"number",		0},
    {"b2shrub",		    "string",		"default:grass_2"},
    {"b2sprob",		    "number",		20},
    {"b2shrub2",		"string",		"default:grass_3"},
    {"b2sprob2",		"number",		3},

}

local errors = {}
start = 1
finish = 0
for _ in pairs(settings_table) do finish = finish + 1 end  -- get table count

realterrain.settings = {}
for i=start, finish do
    if (settings_table[i]) then
        local setting = settings_table[i][1]
        local validate = settings_table[i][2]
        local value = settings_table[i][3]
        if validate == "number" then
            if tonumber(value) then
                realterrain.settings[setting] = tonumber(value)
            else
                if not errors then errors = {} end
                table.insert(errors, k)
            end
        else
            realterrain.settings[setting] = value
        end
    end
end