# Real Terrain (v.0.2.1)
A Minetest mod that brings real world terrain into the game (using freely available DEM tiles). Any image can actually be used which allows for WorldPainter-style map creation using any paint program. This is a lightweight version of [bobombolo's realterrain](https://github.com/bobombolo/realterrain) mod, focusing on map generation from bitmap raster images only. 

![island-demo](https://user-images.githubusercontent.com/7158003/99186052-9b54e600-2788-11eb-8a8d-07e635942855.jpg)

### Dependencies:
- this mod works out of the box with no libraries when using color BMP rasters
- mod security needs to be disabled (close Minetest and add **secure.enable_security = false** to minetest.config)

### Mod Instructions
- download the zip file and copy the realterrain folder to /minetest/mods/ (remove **-master** suffix)
- edit the mod settings.lua file to suit your tastes (not required, default settings should work)
- launch Minetest, create a new world, enable mod and launch game to load the demo
- optionally use chat command **/generate** in game to generate all nodes defined by the DEM raster
- once map is generated from raster images, disable mod and the Minetest engine will generate the rest

### Custom Map Instructions
- use any image editing software to "paint" a custom world on two BMP files (dem.bmp and biomes.bmp)
- using gray tones is recommended, but image should be saved as RGB with 24-bit depth and Windows headers
- ensure that dem and biomes images are the same dimensions (however only dem image is required)
- dem.bmp is converted to an 8-bit heightmap with elevation range from 0 (black) to 255 (white)
- biomes.bmp is likewise read as 8-bit with pixel values rounded to one of 17 biome definitions.

![heightmap-figure](https://user-images.githubusercontent.com/7158003/95472234-5b465a80-09b5-11eb-8bbe-d0ea1f79dc14.png)
 
### Biome Definitions

Biomes are defined in settings.lua and are represented by one of 17 values between 0 and 255, and 3 extra values for hard-coded biome definitions. Using the following color values in biomes.bmp will result in the corresponding biome:

8-Bit Value | Hex Color | Biome
| ------    | ------    | ------
| 0         | #000000   | Lake / Pond
| 16        | #101010   | Beach
| 32        | #202020   | Grassland
| 48        | #303030   | Bushland
| 64        | #404040   | New Deciduous Forest
| 80        | #505050   | Old Deciduous Forest
| 96        | #606060   | New Coniferous Forest
| 112       | #707070   | Old Coniferous Forest
| 128       | #808080   | Savannah
| 144       | #909090   | Desert
| 160       | #A0A0A0   | Marsh
| 176       | #B0B0B0   | Tropical Rainforest
| 192       | #C0C0C0   | Snowy Grassland
| 208       | #D0D0D0   | Tundra
| 224       | #E0E0E0   | Boreal Forest / Tiaga
| 240       | #F0F0F0   | River / Stream
| 255       | #FFFFFF   | Mossy Cobblestone Road
| 256       | N/A       | Ocean
| 257       | N/A       | Alpine
| 258       | N/A       | Sub-alpine

![biomes-figure](https://user-images.githubusercontent.com/7158003/98916253-e612fb80-2505-11eb-985a-0ae59e677134.jpg)

### Grayscale DEM Procurement

DEM (Digital Elevation Model) maps are freely available via a variety of sources. Just searching for **grayscale DEM maps** will return plenty. I found Hi-Res grayscale DEM maps of all the planets at [Astropedia](https://astrogeology.usgs.gov/search?pmi-target=mars). Hi-Res DEM maps can be downloaded for free at [dwtkns.com](http://dwtkns.com/srtm/) and [Digital Elevation Data](http://viewfinderpanoramas.org/dem3.html). If you want to use DEM maps that are color-coded, you will need to convert them to grayscale. Here is a workflow I have used to convert the GeoTIFF files available at [dwtkns.com](http://dwtkns.com/srtm/) into grayscale DEM images:

### GeoTIFF Conversion Workflow

1. Download and Install [VTBuilder](http://vterrain.org/Doc/VTBuilder/overview.html) (basic install is enough)
2. Download the GeoTIFF file from [dwtkns.com](http://dwtkns.com/srtm/) for the area you wish to get DEM data for
3. Open VTBuilder and go to **Layer >> Import Data**
4. Select **Elevation** from the dialogue window and click OK, then select the .tif file you downloaded earlier
5. To view elevation data in greyscale, go to **View >> Options >> Rendering Options**
6. For **Color Map File** choose "greyscale_relative.cmt"
7. Under **Shading** select "none" then OK out
8. On the Toolbar select the **Area Tool** and mark out the area you wish to export
9. Go to **Elevation >> Export To** and select BMP
10. The image is exported upside down so modify as you wish in your favorite photo editing software
11. The image should render very realistic looking terrain as is, but to modify the scale on the y axis one could either: 
a. alter the **contrast** of the image (effectively normalizes/exaggerates differences in elevation throughout)
b. increase/decrease the **size** of the image (this may cause artifacts which will require a light Gaussian blur to remove. Be aware that applying a Gaussian blur will likely cause some elevation data to be lost, resulting in rounder less-jagged looking mountains and valleys.)

### Examples:

The following three examples were generated from grayscale DEM (Digital Elevation Model) maps found online. The [Skybox Mod](https://content.minetest.net/packages/sofar/skybox/) by Auke Kok was used to enhance the look of the terrain in the screenshots.

#### The Himalayas

![himalayas-maps](https://user-images.githubusercontent.com/7158003/95472925-28509680-09b6-11eb-8a16-c25f8832a847.png)

![himalayas1](https://user-images.githubusercontent.com/7158003/95472554-c6902c80-09b5-11eb-9877-9da221903ff3.png)

![himalayas2](https://user-images.githubusercontent.com/7158003/95473009-3c949380-09b6-11eb-92b4-67922863f0ea.png)

#### The Grand Canyon

![canyon-maps](https://user-images.githubusercontent.com/7158003/95473087-51712700-09b6-11eb-8e44-2ccaa4ca2de3.png)

![gcanyon1](https://user-images.githubusercontent.com/7158003/95473121-5cc45280-09b6-11eb-8dcf-a6895de4256a.png)

![gcanyon2](https://user-images.githubusercontent.com/7158003/95473165-68177e00-09b6-11eb-9e4b-2f2247939336.png)

#### The Moon

![moon-maps](https://user-images.githubusercontent.com/7158003/95473219-75cd0380-09b6-11eb-89dc-8152d4f6af19.png)

![moon1](https://user-images.githubusercontent.com/7158003/95473257-7fef0200-09b6-11eb-8fd6-c04cb5dcc1f6.png)

![moon2](https://user-images.githubusercontent.com/7158003/95473288-88dfd380-09b6-11eb-8b8d-6cadc7617a81.png)

### Changelog
#### 0.2.1
- replaced set_mapgen_params() function (depricated) with set_mapgen_setting()
- made mgflat_ground_level value equal to yoffset so that ground level is always the same for map generated by realterrain and Minetest
- added support for defining cave depth and width, as well as mg_biome_np_heat to increase offset and prevent icesheets from invading the raster map
- set default water_level to 0 and yoffset to -16 so that ocean floor generated by the Minetest engine outside the raster map will generate ocean biome (sand, coral/kelp in shallow water), rather than flooded terrestrial biomes

#### 0.2.0
fixed a few bugs/deficiencies:
1. added check that all rasters are the same dimensions
2. fixed bugs to appear/dissapear based on day/night cycle and appear at different heights
3. allowed decimal percentages up to two places for very scarce vegetation
4. fixed two errors being thrown imageloader.lua and loader_bmp.lua
5. added checks to use default nodes when biomes.bmp image is not present in rasters folder
6. rounding biomes pixel values to avoid unexpected biomes at biome boundries (in case of anti-aliasing)
    
added some additional features (mostly biome options):
1. expanded available biome slots generated from the biomes raster image from 10 to 17 (17 was chosen simply because 255 is divisible by 17 and provides enough contrast between each value that it can be distinguished easily by the human eye when represented as RGB in an image, however there is no reason it couldn't be more)
2. added several new biomes, including ocean and river (lake is the default water biome)
3. waterlily generation (with probability and max depth settings)
4. base vegetation defined by surface node type (i.e. grass appears over dirt_with_grass)
5. added generateores option to settings
6. replace the tree_force_load table with a more comprehensive table of tree schems and properties such as:
   - schems: number of schems for a particular tree type for randomly selecting from different shapes
   - radius: for placing the tree correctly with the trunk in the center
   - tradius: radius of the trunk for clearing decoration nodes that might collide with wide trunks
7. added several new tree schems for generating biomes including grove trees, papyrus, cactus, and very large tree shapes (oak, birch, japanese maple, jeffrey pine, white pine, spruce). All schems use existing nodes available in the Minetest game.
8. registered a chat command ("/generate", no quotes), which calls emerge_area to generate the entire area of the raster map, thus navigating the whole map to generate it is uneccesary. A map of size 500x500 takes about six minutes to generate

#### 0.1.2
- updated existing tree schems so that all leaf nodes param2 is set to 0 (decay). Tested all trees by digging trunk. 
- added grassy boulders and two new tree types (bonsai and marshtree).
- fixed bug occuring in marsh biome where shrubs were being generated over water
- added fireflys to marshes
- added table of trees to force load (aka overwrite all existing nodes). Included bushes and jungletree3 (emergent jungle tree has a trunk thicker than one block)

#### 0.1.1
- forked project from [realterrain](https://github.com/bobombolo/realterrain)
- removed ~~in-game interface~~
- removed ~~persistent structures~~
- removed ~~all other processing options (python, imagemagic, graphicsmagick)~~
- removed ~~analysis tools for landsat imagery and support for rendering mathematical equations graphically (polynomials, Mandelbrot set)~~
- basically removed all but native processing of grayscale DEM bitmap for elevation data and biome generation based on a second grayscale bitmap of the same dimensions (if you are interested in the removed features, check out [bobombolo's original repo](https://github.com/bobombolo/realterrain).)
- redefined biomes based more closely on vanilla Minetest biomes, rather than USGS land cover classifications
- addition of **subalpine** option which renders half the snow of alpine, and snow-covered pine trees when it occurs in biome 4 or 9 (tree biomes)
- defined water biome in-code to free up a slot for biome definitions, occurs when node is below **waterlevel** setting
- mapgen includes rendering kelp with a random length for param2, when node is below **kelpmindep** setting
- a **centermap** setting that sets xoffset/zoffset to half of raster width/breadth, so that coordinates (0,0,0) fall in the center of the map
- expanded tree schems
- randomizing of shrub length (grass, dry_grass, marram_grass, fern) and tree shape when the **randomize** setting is set to true
- random replacement of grass or ferns with bugs and mushrooms when **bugs** and/or **mushrooms** settings are set to true
