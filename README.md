# Home range (Kernel Utilization Distribution)

MoveApps

Github repository: https://github.com/chlobeau/moveAppsHomeRange

## Description
This app estimates home range using a kernel density estimation to define the utilization distribution (UD). The app generates area sizes, a shapefile and an interactive map of kernel home-range at the desired percent level estimated using the R package `adehabitatHR` (Calenge 2006). Results are provided for all individuals in the dataset (population level) as well and polygons for each individual's home range.

To account for autocorrelation in the data we recommend filtering to one location per week.

## Documentation
This app uses kernel density estimation to define the utilization distribution (UD). See Worton (1989) to learn more about kernel density estimation.

The app generates a shapefile and an interactive plot of kernel home-range at the desired percent level estimated using the R package `adehabitatHR` (Calenge 2006). It generates a single polygon and home-range area value that includes all individuals in the dataset (population level) as well and polygons for each individual's home range.

Preparing the workflow:
* To account for autocorrelation in the data we recommend filtering to one location per animal per week. You can do this with the [Movebank Location](https://www.moveapps.org/apps/browser/267eb5a9-41a8-4d1c-ad68-52769eac72a5) or [Thin Data by Time](https://www.moveapps.org/apps/browser/9c814c17-c61c-4cad-857d-2b44402a78b3) apps. 
* At least 5 locations per animal are needed to calculate the individual KUDs. If needed, you can use the [Filter by Track Duration App](https://www.moveapps.org/apps/browser/47bbcabf-7a0b-4749-9dcf-2252d8d17055) to identify and remove any tracks with <5 occurrences.
* To calculate KUDs for each animal, ensure the input tracks are defined by animal. If animals have multiple tracks (e.g., representing separate deployments or season-year), a KUD will be estimated for each of these segments.

The output consists of (i) a table (.csv) of home range sizes, (ii) a zipped shapefile (.shp) with the home-range polygon for the population and each individual, and (iii) an interactive map (.html) showing the input data and home-range polygons on a selection of background maps.

Understanding your results: The method used here assumes that locations represent animals from the same population in their home range, and might not exclude unavailable habitat, such as space across an impassible barrier. Interpret accordingly! You can use prior apps in the workflow to remove movements considered to be outside the home range. For example, for a population with separate summer and winter ranges, you can use the [Filter/Annotate by Season App](https://www.moveapps.org/apps/browser/5760087c-47f5-4fa7-9628-dec1cc09c4db) in the workflow to extract data for specific time periods and then use this App to estimate seasonal home ranges. Finally, the method assumes locations are independent estimates, and variation in fix rates will lead to results that incorrectly indicate more space use in areas with higher fix rates. Thinning the data to weekly locations (described above) will help mitigate this autocorrelation.

### References
Worton, B. J. (1989) Kernel methods for estimating the utilization distribution in home-range studies. Ecology, 70, 164–168. https://doi.org/10.2307/1938423

Calenge, C. (2006) The package adehabitat for the R software: a tool for the analysis of space and habitat use by animals. Ecological Modelling, 197, 516-519. https://doi.org/10.1016/j.ecolmodel.2006.03.017

### Input data
Move2 object in Movebank format. App will not accept Move2 objects that have already been split as they are in a list format.

### Output data

App returns move2_loc, no additional output is produced to be used in subsequent apps.


### Artefacts

`KUD_areas.csv`: a table of all KUD home-range areas in square kilometers, indicating the percent setting used. For example, the 95 percent UD will provide an area within which the animal/s have a 95% probability of occurring.

`KUD_p##.zip`: a folder containing a shapefile of KUD polygons. The number in the filename indicates the Percent setting used.

`map_html_files.zip`: a folder containing a mapview interactive map (`UD_##p_###m.html`)including animal movement trajectories from the input data, home-range polygons and several background maps, as well as the supporting files for this map (`UD_##p_###m_files`). Numbers in the filenames indicate the Percent (##p) and Resolution (###m) settings used. Use the legend in the upper left to change the background map and view or hide the trajectories, population KUD and individual KUDs. Hover your cursor over a KUD polygon to identify the track represented. 

### Settings

`Percent` (percent): Defined percentage level to estimate KUD polygon. For example, '95' will provide an area within which the animal/population has a 95% probability of occurring, based on the input location data set. Default is 95.

`Resolution` (res): The size of the pixels over which the UD should be estimated. Unit: `metres`. Default is 200. Appropriate values depend on the area covered by the data. For example, if all data occur in a very small number of grid cells (res too large), you may get an error or uninformative results suggesting the home range covers the entire grid. On the other hand, using a very small grid (res too small) may overfit the home range to the available locations, incorrectly implying the animal would not occur in similar nearby places.

`Extent` (ext): A unitless number controlling the extent of the area (grid) used for estimation. Default is 1. The number relates to the spatial range of the input data but is not equal to the number of pixels or a geographic distance. Increase in increments of 1 as needed to provide sufficient space for the analysis (see below). 

### Null or error handling

App returns NULL if there are fewer than 5 locations for all individuals.

#### Common errors
ERROR: “Error in getverticeshr.estUD(X[[i]], ...): The grid is too small to allow the estimation of home-range.
You should rerun kernelUD with a larger extent parameter”.  
SOLUTION: Increase the value of the extent parameter in increments of 1 until you no longer receive this error.

ERROR: ./start-process.sh: line 9:   308 Killed: This error likely arises from the resolution (grid size) being unreasonably large to estimate the UD raster (i.e. 20,000 m [20 km]).  
SOLUTION: Reduce the res value until you no longer receive this error.