#remotes::install_gitlab("bartk/move2")
library('move2')

library('sf')
library('adehabitatHR')
library('dplyr')
library('withr')
library('mapview')
library('zip')

## The parameter "data" is reserved for the data object passed on from the previous app

## to display messages to the user in the log file of the App in MoveApps one can use the function from the logger.R file: 
# logger.fatal(), logger.error(), logger.warn(), logger.info(), logger.debug(), logger.trace()

rFunction = function(data, percent = 95, res = 200){
  
  if(sum(class(data) %in% "move2") < 1){
    data <- mt_as_move2(data) 
    coords.sf <- st_coordinates(data) %>% na.omit
  } else
  {
    coords.sf <- st_coordinates(data) %>% na.omit
  }
  if(nrow(coords.sf) < 5)
  {
    logger.info("Data need to include at least 5 locations to run kernel UD function. Returning NULL.")
    result <- NULL
  } else
  {
  kernel <- adehabitatHR::kernelUD(SpatialPoints(coords.sf), grid = res) %>% getverticeshr(percent)
  poly <- st_as_sf(kernel) %>% st_cast("POLYGON")
  poly$area <- st_area(poly)
  ud <- poly[which.max(poly$area),] %>% st_set_crs(st_crs(data))
  names(ud)[names(ud) == "area"] <- paste0("area (km2) - ", percent, "% KUD")
  ud$id <- paste0("homerange - ", percent, "% KUD")
  
  kud.df <- st_drop_geometry(ud)
  
  write.csv(kud.df,file=appArtifactPath("KUD_areas.csv"),row.names=FALSE)
  
  # mapview
  locs <- data[seq(from = 1, to = nrow(data), by = 10),] %>% data.frame %>% st_as_sf 
  m <- mapview(ud["id"]) + mapview(locs, zcol = "track")
  
  dir.create(targetDirHtmlFiles <- tempdir())
  
  mapview::mapshot(m, url = file.path(targetDirHtmlFiles,
                                      paste0("UD_", percent, "p_", res, "m.html")))
  zip_file <- appArtifactPath(paste0("map_html_files.zip"))
  zip::zip(zip_file, 
           files = list.files(targetDirHtmlFiles, full.names = TRUE,
                              pattern="^map_"),
           mode = "cherry-pick")
  
  # zip shapefile
  temp_shp <- tempdir()
  
  zipfile <- appArtifactPath(paste0("kud_p", percent, ".zip"))
  file_zip <- basename(zipfile)
  shp_name <- paste0("kud_p", percent, ".shp")
  
  ## Temporary directory to write .shp file
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE, force = TRUE))
  
  sf::write_sf(ud, file.path(tmp, shp_name), delete_layer = TRUE)
  withr::with_dir(tmp, zip(file_zip, list.files()))
  
  file.copy(file.path(tmp, file_zip), zipfile, overwrite = T)
  }
  
  return(data)
}
