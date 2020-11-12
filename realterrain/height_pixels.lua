-- global variables
realterrain.raster_pos1 = nil
realterrain.raster_pos2 = nil
local xcenter = 0
local zcenter = 0

-- gets the closest number in threshholds table based on given num
local threshholds = realterrain.threshholds
local function closest(threshholds, num)
    local result = 0
    if num and tonumber(num) > 0 then
        local diff = nil
        local min_diff = 255
        local arr_cnt = 0
        for _ in pairs(threshholds) do arr_cnt = arr_cnt + 1 end
        for i = 1, arr_cnt do
            diff = math.abs(num - threshholds[i])
            if (diff < min_diff) then
              min_diff = diff;
              result = threshholds[i]
            end
        end
    end
    return result
end

--the raw get pixel method that uses the selected method and accounts for bit depth
local function get_raw_pixel(x,z, rastername) -- "rastername" is a string
    --print("x: "..x.." z: "..z..", rastername: "..rastername)
    local raster = realterrain[rastername]
    local colstart, rowstart = 0,0
    if raster.format == "bmp" then
        x=x+1
        z=z-1
        colstart = 1
        rowstart = -1
    end
    
    z = -z
    local r,g,b
    local width, length
    width = raster.width
    length = raster.length
    --check to see if the image is even on the raster, otherwise skip
    if width and length and ( x >= rowstart and x <= width ) and ( z >= colstart and z <= length ) then
        --print(rastername..": x "..x..", z "..z)

        local bitmap = raster.image
        local c
        if bitmap.pixels[z] and bitmap.pixels[z][x] then
            c = bitmap.pixels[z][x]
            r = c.r
            g = c.g
            b = c.b
        end
            
        return r,g,b
    end
end

--main function that builds a heightmap
function realterrain.build_heightmap(x0, x1, z0, z1)
    local heightmap = {}
    local xscale = realterrain.settings.xscale
    local zscale = realterrain.settings.zscale
    local xoffset = realterrain.settings.xoffset 
    local zoffset = realterrain.settings.zoffset 
    local yscale = realterrain.settings.yscale
    local yoffset = realterrain.settings.yoffset
    local center_map = realterrain.settings.centermap
    
    local function adjust(value, scale, offset, center)
        return math.floor((value/scale)+offset+center+0.5)
    end
    
    local xcenter = 0
    local zcenter = 0

    local rasternames = {}
    if realterrain.settings.fileelev ~= "" then table.insert(rasternames, "elev") end
    if realterrain.settings.filecover ~= "" then table.insert(rasternames, "cover")    end

    -- loop through rasters to check that they all have the same dimensions
    local x_raster_hsh = {}
    local x_raster_hsh_cnt = 0
    local z_raster_hsh = {}
    local z_raster_hsh_cnt = 0
    for _, rastername in ipairs(rasternames) do
        local raster = realterrain[rastername]
        if raster.width and raster.length then
            x_raster_hsh[raster.width] = true
            z_raster_hsh[raster.length] = true
            
            -- get centers if center_map is set to true
            if center_map then
                xcenter = (raster.width / 2)
                zcenter = -(raster.length / 2)
            end
        end
    end

    -- there should only be one width and one length in raster_hsh, if more than some raster dimensions are off
    for _ in pairs(x_raster_hsh) do x_raster_hsh_cnt = x_raster_hsh_cnt + 1 end
    if x_raster_hsh_cnt > 1 then
        error("the width (x axis) of some rasters do not match.")
        return heightmap
    end
    for _ in pairs(z_raster_hsh) do z_raster_hsh_cnt = z_raster_hsh_cnt + 1 end
    if z_raster_hsh_cnt > 1 then
        error("the height (z axis) of some rasters do not match.")
        return heightmap
    end
    
    -- set global raster x and z positions
    realterrain.raster_pos1 = { x=0-xcenter, y=0, z=0-zcenter}
    realterrain.raster_pos2 = { x=0+xcenter, y=255,z=0+zcenter}

    -- get adjusted x and z positions
    local adjusted_x0 = adjust(x0, xscale, xoffset, xcenter)
    local adjusted_x1 = adjust(x1, xscale, xoffset, xcenter)
    local adjusted_z0 = adjust(z0, zscale, zoffset, zcenter)
    local adjusted_z1 = adjust(z1, zscale, zoffset, zcenter)
    
    -- loop through rasters again to build heightmap
    for _, rastername in ipairs(rasternames) do
        local raster = realterrain[rastername]
        if raster.width and raster.length then

            -- see if we are even on the raster or that there is a raster
            if( not realterrain.settings["file"..rastername]
            or (adjusted_x1 < 0)
            or (adjusted_x0 > raster.width)
            or (adjusted_z0 > 0)
            or (-adjusted_z1 > raster.length)) then
                return heightmap
            end

            --local colstart, colend, rowstart, rowend = adjusted_x0,adjusted_x1,adjusted_z0,adjusted_z1
            local colstart, colend, rowstart, rowend = x0,x1,z0,z1
            for z=rowstart,rowend do
                if not heightmap[z] then heightmap[z] = {} end
                for x=colstart,colend do
                    local adjusted_x = adjust(x, xscale, xoffset, xcenter)
                    local adjusted_z = adjust(z, zscale, zoffset, zcenter)
                    if not heightmap[z][x] then heightmap[z][x] = {} end
                    if rastername == "elev" then
                        local value = get_raw_pixel(adjusted_x, adjusted_z, "elev")
                        if value then
                            heightmap[z][x][rastername] = math.floor(value*yscale+yoffset+0.5)
                        end
                    else
                        local cover = get_raw_pixel(adjusted_x, adjusted_z, rastername)
                        heightmap[z][x][rastername] = closest(threshholds, cover)
                    end
                end
            end
            
        end
    end    --end for rasternames
    return heightmap
end

--after the mapgen has run, this gets the surface level
function realterrain.get_surface(x,z)
    local heightmap = realterrain.build_heightmap(x,x,z,z)
    if heightmap[z] and heightmap[z][x] and heightmap[z][x]["elev"] then
        return heightmap[z][x]["elev"]
    end
end
