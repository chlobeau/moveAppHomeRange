# Kernel Home Range 

MoveApps

Github repository: https://github.com/chlobeau/moveAppsHomeRange

## Description
The app generates a shapefile and an interactive plot of kernel home-range at the desired percent level estimated using the R package `adehabitatHR`.

## Documentation
The output consists of (i) a zipped shapefile (.jpeg) with the home-range polygon; (ii) an interactive map (.html) with the input points and home-range polygon on a background map


### Input data
MoveStack in Movebank format

### Output data

No output is produced to be used in subsequent apps.


### Artefacts

`KUD_areas.csv`: csv-file with Table of all KUD home-range area in sq. km

`KUD_p##.zip`: zipfile of shapefile of KUD polygon

`UD_##p_###m.html`: mapview interactive map
`UD_##p_###m_files`: mapview supporting files

### Settings 

`Percent` (percent): Defined percentage level to estimate KUD polygon.

`Resolution` (res): A number giving the size of the pixel over the UD should be estimated. Unit: `metres`.


