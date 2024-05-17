library('move2')

library('sf')
library('adehabitatHR')
library('plyr')
library('withr')
library('mapview')
library('webshot')
library('zip')

## The parameter "data" is reserved for the data object passed on from the previous app

## to display messages to the user in the log file of the App in MoveApps one can use the function from the logger.R file: 
# logger.fatal(), logger.error(), logger.warn(), logger.info(), logger.debug(), logger.trace()

rFunction = function(data, percent = 95, res = 200, ext = 1, hest = "href"){
  
  if(sum(class(data) %in% "move2") == 0)
  {
    logger.info("Input data must be a move2 object - check that the prior app does not output a list (did you use the split function?)")
  }
  
  # convert to simple features in metric system
  CRS = "+proj=lcc +lat_1=50 +lat_2=70 +lat_0=65 +lon_0=-120 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
  
  data_sf <- data |> mutate(id = mt_track_id(data))
  mt_track_id(data_sf) <- NULL
  data_sf_metric <- data_sf |> st_transform(crs = CRS)
  mapview(data_sf_metric)
  
  coords.sf <- st_coordinates(data_sf_metric)
  coords.sp <- SpatialPoints(coords = coords.sf)
  
  if(nrow(coords.sf) < 5)
  {
    logger.info("Data need to include at least 5 locations to run kernel UD function. Returning NULL.")
    result <- NULL
  } 
  
  if(!(hest %in% c("href", "LSCV"))){
    hest <- as.numeric(hest)
  }
  
  # population KUD
  kernel <- adehabitatHR::kernelUD(coords.sp, grid = res, h = hest, extent = ext) |> 
    adehabitatHR::getverticeshr(percent)
  poly_all <- st_as_sf(kernel) |> st_cast("POLYGON")
  poly_all$area <- st_area(poly_all)
  ud <- poly_all[which.max(poly_all$area),] |> st_set_crs(CRS)
  ud$id <- paste0("population homerange - ", percent, "% KUD")
  
  # KUD by individual
  IDs_length <- ldply(split(data, mt_track_id(data)), nrow)
  
  if(any(IDs_length$V1 < 5))
  {
    logger.info(paste("Data need to include at least 5 locations to run kernel UD function. Missing data from:",
                      (IDs_length$.id[IDs_length$V1 < 5]), "Returning NULL."))
  } 
  selIDs <- IDs_length$.id[IDs_length$V1 > 5]
  
  data_sub <- data[mt_track_id(data) %in% selIDs,] |> st_transform(CRS)
  
  data_split <- split(data_sub, mt_track_id(data_sub))
  
  coords_split <- lapply(data_split, st_coordinates)
  coords_split <- lapply(coords_split, na.omit)
  coords_split_sp <- lapply(coords_split, SpatialPoints)
  kernel_split <- lapply(coords_split_sp, adehabitatHR::kernelUD, grid = res, h = hest, extent = ext) 
  kernel_vertices <- lapply(kernel_split, getverticeshr, percent)
  kernel_vertices_list <- lapply(kernel_vertices, st_as_sf)
  kernels <- do.call(rbind, kernel_vertices_list)
  
  poly <- st_as_sf(kernels) |> st_cast("POLYGON") |> st_set_crs(CRS)
  poly$id <- row.names(poly)
  
  # make mapview
  locs <- data_sf_metric |> dplyr::group_by(id) |> 
    dplyr::summarize(do_union=FALSE) |> sf::st_cast("LINESTRING")
  
  m <- mapview(ud, layer.name = "Population KUD") + 
    mapview(poly, zcol = "id", layer.name = "Individual KUDs") + 
    mapview(locs, zcol = "id", legend = FALSE, layer.name = "Individual tracks") 
  
  # make dataframe of areas
  uds_all <- rbind(poly, ud)
  names(uds_all)[names(uds_all) == "area"] <- paste0("area (km2) - ", percent, "% KUD")
  uds.df <- st_drop_geometry(uds_all)
  
  uds_all_orig_crs <- uds_all |> st_transform(st_crs(data))
  
  # output csv
  write.csv(uds.df,file=appArtifactPath("KUD_areas.csv"),row.names=FALSE)
  
  # output html maps
  # create temporary directory
  dir.create(targetDirHtmlFiles <- tempdir())
  
  mapshot(m, url = file.path(targetDirHtmlFiles, paste0("UD_", percent, "p_", res, "m.html")))
  
  zip_file <- appArtifactPath("map_html_files.zip")
  zip::zip(zip_file, 
           files = list.files(targetDirHtmlFiles, full.names = TRUE,
                              pattern="^UD_"),
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
  
  sf::write_sf(uds_all_orig_crs, file.path(tmp, shp_name), delete_layer = TRUE)
  withr::with_dir(tmp, zip(file_zip, list.files()))
  
  file.copy(file.path(tmp, file_zip), zipfile, overwrite = TRUE)
  return(data)      
  
}
