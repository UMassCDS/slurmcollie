

if(FALSE) {
   devtools::load_all(".")
   library(peakRAM)
   library(terra)
   
   
   fit('oth')
   # fit('oth', vars = pickvars(40))
   # the$fit <- readRDS('/work/pi_cschweik_umass_edu/marsh_mapping/models/fit_2025-Apr-24_16-08')
   
   path <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/flights'
   rpath <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/predicted'
   
   
   x <- names(the$fit$fit$trainingData)[-1]
   x <- sub('^X', '', x)                              # drop leading X
   x <- sub('_\\d+$', '', x)                          # drop band
   x <- unique(x)                                     # and remove dups
   
   print(x)
   
   rasters <- rast(file.path(path, paste0(x, '.tif')))
   names(rasters) <- sub('^(\\d)', 'X\\1', names(rasters))                             # files with leading digit get X prepended by R  
   
   rasters <- rasters[[names(rasters) %in% names(the$fit$fit$trainingData)[-1]]]       # drop bands we don't want
   
   # clip <- ext(c(-70.86254419, -70.86135362, 42.77072136, 42.7717978))               # small clip
   clip <- ext(c(-70.86452506, -70.86040917, 42.76976948, 42.77283781))                # larger clip
   rasters <- crop(rasters, clip)
   
   peakRAM(predicted <- terra::predict(rasters, the$fit$fit, cores = 18, filename = file.path(rpath, 'predicted3.tif'), overwrite = TRUE, na.rm = TRUE))
}