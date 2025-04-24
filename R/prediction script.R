

if(FALSE) {
   devtools::load_all(".")
   library(peakRAM)
   fit('oth')
   fit('oth', vars = pickvars(40))
   
   
   path <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/flights'
   rpath <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/predicted'

   
   x <- names(the$fit$fit$trainingData)[-1]
   x <- sub('^X', '', x)                              # drop leading X
   x <- sub('_\\d+$', '', x)                          # drop band
   
   print(x)
   
   rasters <- rast(file.path(path, paste0(x, '.tif')))
   names(rasters) <- sub('^(\\d)', 'X\\1', names(rasters))                          # files with leading digit get X prepended by R  
   
   rasters <- rasters[[names(rasters) %in% names(the$fit$fit$trainingData)[-1]]]      # drop bands we don't want
   
   peakRAM(predicted <- terra::predict(rasters, zz, cores = 20, filename = file.path(rpath, 'predicted.tif'), overwrite = TRUE))
   
}