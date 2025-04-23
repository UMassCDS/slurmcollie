# predict a raster


if(FALSE) {
   
   library(peakRAM)
   # peakRAM(fit('oth'))
   
   path <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/flights'
   rpath <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/predicted'
   x <- list.files(path)
   
   
   rasters <- rast(file.path(path, x))
   names(rasters) <- sub('^(\\d)', 'X\\1', names(rasters))                         # files with leading digit get X prepended by R  
   
   peakRAM(predicted <- terra::predict(rasters, zz, cores = 20, filename = file.path(rpath, 'predicted.tif')))
}