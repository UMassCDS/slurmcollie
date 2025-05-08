#' Build a geoTIFF of predictions for specified model fit
#' 
#' 
#' 
#' @param model Model ID, fit filename, or fit object - figure it out)
#' @param clip Optional clip, vector of xmin, xmax, ymin, ymax
#' @param result Optional result filename. If not provided, uses name from database if it exists. Otherwise, constructs a name.
#' @importFrom peakRam peakRAM
#' @importFrom terra predict writeRaster
#' @importFrom rasterPrep addColorTable makeNiceTif addVAT
#' @export
   
   
   
   predict <- function(fit, clip = NULL, result = NULL) {
      
      
      # if model is a scalar number,
      #    it's fit id, so pull fit from database
      # if it's a string,
      #    it's a filename, so read filename to get fit
      # if it's a fit object,
      #    we've got it
      
      
          # remotes::install_github('ethanplunkett/rasterPrep')
         
      #pull target and site out of fit object
         target <- 'subclass'                               # this will be pulled from names(fit$train)[1]
         
      
         the$fit <- readRDS('c:/work/etc/saltmarsh/models/fit_oth_2025-May-05_15-53.RDS')                           ############# FOR TESTING
         the$site <- 'oth'
           
       # change path to the$flightsdir
       # change rpath to the$predicteddir
         
         path <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/flights'
         rpath <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/predicted'
         
         
         path <- 'C:/Work/etc/saltmarsh/data/oth/gis/flights'                                                        ############## for testing
         rpath <- 'C:/Work/etc/saltmarsh/data/oth/gis/predicted'
         
         
         
         x <- names(the$fit$fit$trainingData)[-1]
         x <- sub('^X', '', x)                              # drop leading X
         x <- sub('_\\d+$', '', x)                          # drop band
         x <- unique(x)                                     # and remove dups
         
         print(x)
         
         rasters <- rast(file.path(path, paste0(x, '.tif')))
         names(rasters) <- sub('^(\\d)', 'X\\1', names(rasters))                             # files with leading digit get X prepended by R  
         
         rasters <- rasters[[names(rasters) %in% names(the$fit$fit$trainingData)[-1]]]       # drop bands we don't want
         
         #   clip <- ext(c(-70.86254419, -70.86135362, 42.77072136, 42.7717978))               # small clip
         #  clip <- ext(c(-70.86452506, -70.86040917, 42.76976948, 42.77283781))                # larger clip: 38 min, 69 GB
         #  
         
         clip <- the$clip$oth$small                                             # we'll have a clip argument, with clips from pars.yml, like this
         rasters <- crop(rasters, ext(clip))
         
         
         ts <- stamp('2025-Mar-25_13-18', quiet = TRUE)                                     # set format for timestamp in filename                         
         fx <- file.path(rpath, paste0('predict_', the$site, '_', ts(now())))               # base result filename
         f0 <- paste0(fx, '_0.tif')                                                         # preliminary result filename
         f <- paste0(fx, '.tif')                                                            # final result filename
         
         mem <- peakRAM(pred <- terra::predict(rasters, the$fit$fit, cpkgs = 'ranger', cores = 1, na.rm = TRUE))    # do a prediction for the model
         
         
         levs <- levels(pred$class)[[1]]                                                             # replace values with levels
         levs$class <- as.numeric(levs$class)
         names(levs)[2] <- target                                                                 

         
         writeRaster(pred, f0, overwrite = TRUE, datatype = 'INT1U', progress = 1, memfrac = 0.8)      # save the geoTIFF
         
         classes <- read_pars_table('classes')                                                          # read classes file
         classes <- classes[, grep(paste0('^', target), names(classes))]           # target level in classes
         vat <- merge(levs, classes, sort = TRUE)
         vat <- vat[, c(2, 1, 3:ncol(vat))]                                                               # back to the order I want, with value first
         names(vat) <- c('value', target, 'name', 'color')
         
         
         vat2 <- vat[, c('value', 'color')]
         vat2$category <-  paste0('[', vat[, target], '] ', vat$name)
         vrt.file <- addColorTable(f0, table = vat2)
         
         makeNiceTif(source = vrt.file, destination = f, overwrite = TRUE, overviewResample = 'nearest', stats = FALSE, vat = FALSE)
         
         
         addVat(f, attributes = vat)                    
         
         
         

         
         print(paste0('Done!! Results are in ', f))
         
         
         
         
         
         
      }
      
      
   