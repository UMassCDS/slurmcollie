#' Build a map of geoTIFF of predictions for specified model fit
#' 
#' This funciton may be run at the console, but it's typically spun off as a batch job on Unity by `map`.
#' 
#' It writes a geoTIFF, `<result>.tif`, and a run info file, `<runinfo>.RDS`, with the following:
#' 1. Time taken for the run (s)
#' 2. Maximum memory used (GB)
#' 3. Raster size (M pixel)
#' 4. R error, or NULL for success
#' 
#' 
#' You'll need to install rasterPrep with 
#'    remotes::install_github('ethanplunkett/rasterPrep')
#' 
#' @param fit Model fit object
#' @param site Three-letter site abbreviation
#' @param target Target level, such as `subclass`
#' @param clip Optional clip, vector of xmin, xmax, ymin, ymax
#' @param sourcedir Source directory, probably the flights directory
#' @param result Result path and filename, sans extension
#' @param runinfo Path and filename of run info file. When the run finishes, run info 
#'    is written to this file.
#' @param cores Number of CPU cores to use
#' @importFrom peakRam peakRAM
#' @importFrom terra predict writeRaster
#' @importFrom rasterPrep addColorTable makeNiceTif addVAT
#' @export
   
   
   
   do_map <- function(fit, site, target = 'subclass', clip = NULL, 
                      sourcedir = the$flightsdir, result = NULL,
                      cores = 1) {
      
         

            
         
         
         x <- names(the$fit$fit$trainingData)[-1]
         x <- sub('^X', '', x)                              # drop leading X
         x <- sub('_\\d+$', '', x)                          # drop band
         x <- unique(x)                                     # and remove dups
         
         print(x)
         
         rasters <- rast(file.path(sourcedir, paste0(x, '.tif')))
         names(rasters) <- sub('^(\\d)', 'X\\1', names(rasters))                             # files with leading digit get X prepended by R  
         
         rasters <- rasters[[names(rasters) %in% names(the$fit$fit$trainingData)[-1]]]       # drop bands we don't want
         
         #   clip <- ext(c(-70.86254419, -70.86135362, 42.77072136, 42.7717978))               # small clip
         #  clip <- ext(c(-70.86452506, -70.86040917, 42.76976948, 42.77283781))                # larger clip: 38 min, 69 GB
         #  
         
         if(!is.null(clip))                                                                  # if clip is provided,
         rasters <- crop(rasters, ext(clip))                                                 #    clip result
         
         
         f0 <- paste0(result, '_0.tif')                                                         # preliminary result filename
         f <- paste0(result, '.tif')                                                            # final result filename
         
         mem <- peakRAM(pred <- terra::predict(rasters, fit, cpkgs = fit$method, cores = cores, na.rm = TRUE))    # do a prediction for the model
         
         
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
      
      
   