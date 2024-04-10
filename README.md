# Home range (Kernel Utilization Distribution) 

MoveApps

Github repository: https://github.com/chlobeau/moveAppsHomeRange

## Description
This app uses kernel density estimation to define the utilization distribution. See Worton (1989) to learn more about kernel density estimation.

The app generates a shapefile and an interactive plot of kernel home-range at the desired percent level estimated using the R package `adehabitatHR`. It generates a single polygon and home-range area value that includes all individuals in the dataset (population level) as well and polygons for each individual's home range.

To account for autocorrelation in the data we recommend filtering to one location per week.

### References
Worton, B. J. (1989) Kernel methods for estimating the utilization distribution in home-range studies. Ecology, 70, 164–168

Calenge, C. (2006) The package adehabitat for the R software: a tool for the analysis of space and habitat use by animals. Ecological Modelling, 197, 516-519

## Documentation
The output consists of (i) a zipped shapefile (.shp) with the home-range polygon for the population and each individual; (ii) an interactive map (.html) with the input points and home-range polygons on a background map


### Input data
Move2 object in Movebank format. App will not accept Move2 objects that have already been split as they are in a list format.

### Output data

App returns move2_loc, no additional output is produced to be used in subsequent apps.


### Artefacts

`KUD_areas.csv`: csv-file with Table of all KUD home-range area in sq. km

`KUD_p##.zip`: zipfile of shapefile of KUD polygon

`UD_##p_###m.html`: mapview interactive map
`UD_##p_###m_files`: mapview supporting files

### Settings 

`Percent` (percent): Defined percentage level to estimate KUD polygon.

`Resolution` (res): A number giving the size of the pixel over the UD should be estimated. Unit: `metres`. Default is 200.

`Extent` (ext): A number controlling the extent of the grid used for estimation. Default is 1.

### Null or error handling

App returns NULL if there are fewer than 5 locations for all individuals.

#### Common errors
ERROR: “Error in getverticeshr.estUD(X[[i]], ...): The grid is too small to allow the estimation of home-range.
You should rerun kernelUD with a larger extent parameter”. SOLUTION Gradually increase the value of the extent parameter until you no longer receive this error.
