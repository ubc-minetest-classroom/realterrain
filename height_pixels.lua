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

		if raster.format == "bmp" then
			local bitmap = raster.image
			local c
			if bitmap.pixels[z] and bitmap.pixels[z][x] then
				c = bitmap.pixels[z][x]
				r = c.r
				g = c.g
				b = c.b
				--print("r: ".. r..", g: "..g..", b: "..b)
			end
		elseif raster.format == "png" then
			local bitmap = raster.image
			local c
			if bitmap.pixels[z] and bitmap.pixels[z][x] then
				c = bitmap.pixels[z][x]
				r = c.r
				g = c.g
				b = c.b
			end
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
    local xcenter = 0
    local zcenter = 0
	local scaled_x0 = math.floor(x0/xscale+xoffset+0.5)
	local scaled_x1 = math.floor(x1/xscale+xoffset+0.5)
	local scaled_z0 = math.floor(z0/zscale+zoffset+0.5)
	local scaled_z1 = math.floor(z1/zscale+zoffset+0.5)

	local rasternames = {}
	if realterrain.settings.fileelev ~= "" then table.insert(rasternames, "elev") end
	if realterrain.settings.filecover ~= "" then table.insert(rasternames, "cover")	end

	for _, rastername in ipairs(rasternames) do
		local raster = realterrain[rastername]
        -- redefine offsets based on raster if center_map set to true
        if center_map then
            xcenter     = (raster.width / 2)
            zcenter     = -(raster.length / 2)
            scaled_x0   = math.floor((x0/xscale)+xcenter+xoffset+0.5)
            scaled_x1   = math.floor((x1/xscale)+xcenter+xoffset+0.5)
            scaled_z0   = math.floor((z0/zscale)+zcenter+zoffset+0.5)
            scaled_z1   = math.floor((z1/zscale)+zcenter+zoffset+0.5)
        end
		-- see if we are even on the raster or that there is a raster
		if( not realterrain.settings["file"..rastername]
		or (scaled_x1 < 0)
		or (scaled_x0 > raster.width)
		or (scaled_z0 > 0)
		or (-scaled_z1 > raster.length)) then
			--print("off raster request: scaled_x0: "..scaled_x0.." scaled_x1: "..scaled_x1.." scaled_z0: "..scaled_z0.." scaled_z1: "..scaled_z1)
			return heightmap
		end
			
		--local colstart, colend, rowstart, rowend = scaled_x0,scaled_x1,scaled_z0,scaled_z1
		local colstart, colend, rowstart, rowend = x0,x1,z0,z1
		for z=rowstart,rowend do
			if not heightmap[z] then heightmap[z] = {} end
			for x=colstart,colend do
				local scaled_x = math.floor((x/xscale)+xcenter+xoffset+0.5)
				local scaled_z = math.floor((z/zscale)+zcenter+zoffset+0.5)
				if not heightmap[z][x] then heightmap[z][x] = {} end
				if rastername == "elev" then
					local value = get_raw_pixel(scaled_x,scaled_z, "elev")
					if value then
						heightmap[z][x][rastername] = math.floor(value*yscale+yoffset+0.5)
					end
				else
                    local cover = get_raw_pixel(scaled_x, scaled_z, rastername)
                    cover = (not cover or cover < 1) and 0 or tonumber(string.sub(tostring(cover),1,1))
					heightmap[z][x][rastername] = cover
				end
			end
		end

	end	--end for rasternames
	return heightmap
end

--after the mapgen has run, this gets the surface level
function realterrain.get_surface(x,z)
	local heightmap = realterrain.build_heightmap(x,x,z,z)
	if heightmap[z] and heightmap[z][x] and heightmap[z][x]["elev"] then
		return heightmap[z][x]["elev"]
	end
end