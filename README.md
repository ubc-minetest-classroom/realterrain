# RealTerrain Lite (v.0.1.2)
A Minetest mod that brings real world Terrain into the game (using freely available DEM tiles). Any image can actually be used which allows for WorldPainter-style map creation using any paint program. This is a lightweight version of [bobombolo's realterrain](https://github.com/bobombolo/realterrain) mod, focusing on map generation from bitmap raster images only. 

### Examples:

The following three examples were generated from grayscale DEM (Digital Elevation Model) maps found online. The [Skybox Mod](https://content.minetest.net/packages/sofar/skybox/) by Auke Kok was used to enhance the look of the terrain.

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

### Dependencies:
- this mod works out of the box with no libraries when using color BMP source rasters
- bitmap images should be grayscale, but saved with RGB color and 24-bit depth with Windows headers (color images will work, but results are likely to differ from what is expected)
- mod security needs to be disabled (close Minetest and add **secure.enable_security = false** to minetest.config)

### Instructions
- install the mod as usual and launch the game with mod enabled to view demo
- if you encounter errors, check that **enable_security** is false and the **mod path** is /realterrain not /realterrain-master
- edit the mod settings.lua file to suit your needs (not required, default settings should work)
- create grayscale images for heightmap and biomes that are the same length and width (only heightmap is required).
- dem.bmp is converted to an 8-bit heightmap with elevation range from 0 (black) to 255 (white)
- biomes.bmp is likewise read as 8-bit with pixel values rounded to one of 10 biome definitions.

![heightmap-figure](https://user-images.githubusercontent.com/7158003/95472234-5b465a80-09b5-11eb-8bbe-d0ea1f79dc14.png)
 
### Biome Definitions

Biomes are defined in settings.lua and can be modified to your taste. Using the following hexadecimal color values in biomes.bmp will result in the corresponding biome:

| Hex Color | Color   | Biome
| ------    | ------  | ------
| #000000   | Black   | Beach
| #1E1E1E   | Gray 8  | Grassland
| #282828   | Gray 7  | Deciduous Forest
| #323232   | Gray 6  | Marsh
| #3C3C3C   | Gray 5  | Jungle
| #464646   | Gray 4  | Savannah
| #505050   | Gray 3  | Desert
| #5A5A5A   | Gray 2  | Conifer Forest
| #646464   | Gray 1  | Permafrost
| #FFFFFF   | White   | Cobblestone Road

![biomes-figure](https://user-images.githubusercontent.com/7158003/95472378-89c43580-09b5-11eb-9d03-173efc13ec08.png)

### Grayscale DEM Procurement

DEM (Digital Elevation Model) maps are freely available via a variety of sources. Just googling **grayscale DEM maps** will return plenty. I found Hi-Res grayscale DEM maps of all the planets at [Astropedia](https://astrogeology.usgs.gov/search?pmi-target=mars). Hi-Res DEM maps can be downloaded for free at [dwtkns.com](http://dwtkns.com/srtm/) and [Digital Elevation Data](http://viewfinderpanoramas.org/dem3.html). If you want to use DEM maps that are color-coded, you will need to convert them to grayscale. Here is a workflow I have used to convert the GeoTIFF files available at [dwtkns.com](http://dwtkns.com/srtm/) into grayscale DEM images:

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

### Changelog
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
