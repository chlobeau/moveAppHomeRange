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
  
  coords.sf <- st_coordinates(data) %>% na.omit
  
  if(nrow(coords.sf) < 5)
  {
    logger.info("Data need to include at least 5 locations to run kernel UD function. Returning NULL.")
    result <- NULL
  } else
  {
    # population KUD
    kernel <- adehabitatHR::kernelUD(SpatialPoints(coords.sf), grid = res) %>% getverticeshr(percent)
    poly_all <- st_as_sf(kernel) %>% st_cast("POLYGON")
    poly_all$area <- st_area(poly_all)
    ud <- poly_all[which.max(poly_all$area),] %>% st_set_crs(st_crs(data))
    ud$id <- paste0("population homerange - ", percent, "% KUD")
    
    # KUD by individual
    data_split <- split(data, mt_track_id(data))
    
    if(any(lapply(data_split, nrow) < 5))
    {
      logger.info(paste("Data need to include at least 5 locations to run kernel UD function. Missing data from:",
                  names(lapply(data_split, nrow) < 5), "Returning NULL."))
      result <- NULL
      
    } else{
      coords_split <- lapply(data_split, st_coordinates)
      coords_split <- lapply(coords_split, na.omit)
      coords_split_sp <- lapply(coords_split, SpatialPoints)
      kernel_split <- lapply(coords_split_sp, adehabitatHR::kernelUD, grid = 200) 
      kernel_vertices <- lapply(kernel_split, getverticeshr, percent = 95)
      kernel_vertices_list <- lapply(kernel_vertices, st_as_sf)
      kernels <- do.call(rbind, kernel_vertices_list)
      
      poly <- st_as_sf(kernels) %>% st_cast("POLYGON") %>% st_set_crs(st_crs(data))
      poly$id <- row.names(poly)
      
      # make mapview
      locs <- data[seq(from = 1, to = nrow(data), by = 10),] %>% as.data.frame %>% st_as_sf 
      m <- mapview(ud, layer.name = "Population KUD") + 
        mapview(poly, zcol = "id", layer.name = "Individual KUDs") + 
        mapview(locs, zcol = mt_track_id_column(data), legend = FALSE, layer.name = "Individual tracks") 
      
      # make dataframe of areas
      uds_all <- rbind(poly, ud)
      names(uds_all)[names(uds_all) == "area"] <- paste0("area (km2) - ", percent, "% KUD")
      uds.df <- st_drop_geometry(uds_all)
      
      # output csv
      write.csv(uds.df,file=appArtifactPath("KUD_areas.csv"),row.names=FALSE)
      
      # output html maps
      # create temporary directory
      dir.create(targetDirHtmlFiles <- tempdir())
      
      mapshot(m, url = file.path(targetDirHtmlFiles, paste0("UD_", percent, "p_", res, "m.html")))
      
      zip_file <- appArtifactPath(paste0("map_html_files.zip"))
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
      
      sf::write_sf(uds_all, file.path(tmp, shp_name), delete_layer = TRUE)
      withr::with_dir(tmp, zip(file_zip, list.files()))
      
      file.copy(file.path(tmp, file_zip), zipfile, overwrite = TRUE)
      
    }
    
    
  }
  return(data)
}
