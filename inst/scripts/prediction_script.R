

if(FALSE) {
   
   devtools::load_all(".")
   library(peakRAM)
   library(terra)
   # remotes::install_github('ethanplunkett/rasterPrep')
   library(rasterPrep)
  
   
    
 ###  sample('oth', p = 0.2)
   
   
#   fit('oth', years = 2019:2020, reread = TRUE)
#   fit('oth', years = 2018:2021, reread = TRUE)                                                            # this is my favorite model at the moment. It's in fit_oth_2025-Apr-29_15-19.RDS
#   fit('oth', years = 2018:2021, reread = TRUE, vars = rownames(the$fit$import$importance)[1:20])
#   
#   
   the$fit <- readRDS('/work/pi_cschweik_umass_edu/marsh_mapping/models/fit_oth_2025-Apr-28_13-54.RDS')   # read fit for 2018-2021
   the$site <- 'oth'
   #fit('oth', years = 2018:2021, reread = TRUE, vars = rownames(the$fit$import$importance)[1:40])
#   fit('oth', years = 2018:2021, reread = TRUE, vars = 'X04Aug21_OTH_Low_SWIR_1')
   
   
###   fit('oth', reread = TRUE)
   # fit('oth', vars = pickvars(40))
   # the$fit <- readRDS('/work/pi_cschweik_umass_edu/marsh_mapping/models/fit_2025-Apr-24_16-08')
   
   
   #the$fit <- readRDS('/work/pi_cschweik_umass_edu/marsh_mapping/models/fit_oth_2025-Apr-27_18-13.RDS')
   
   
   
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
    clip <- ext(c(-70.86452506, -70.86040917, 42.76976948, 42.77283781))                # larger clip: 38 min, 69 GB
    rasters <- crop(rasters, clip)
   
    
    ts <- stamp('2025-Mar-25_13-18', quiet = TRUE)                                # and write to an RDS (this is temporary; will include in database soon)
    fx <- file.path(rpath, paste0('predict_', the$site, '_', ts(now())))
    f0 <- paste0(fx, '_0.tif')
    f <- paste0(fx, '.tif')
    
   peakRAM(terra::predict(rasters, the$fit$fit, cpkgs = 'ranger', cores = 1, filename = f0, overwrite = TRUE, na.rm = TRUE))

   
   makeNiceTif(source = f0, destination = f, overwrite = TRUE, overviewResample = 'nearest', stats = FALSE, vat = TRUE)
   
 #   f <- file.path(rpath, paste0('predict_', the$site, '_', ts(now()), '.RDS'))
 #  saveRDS(predicted, f)
   print(paste0('Done!! Results are in ', f))
 
   
   
   
   
     
}