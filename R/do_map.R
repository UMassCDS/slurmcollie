#' Build a map of geoTIFF of predictions for specified model fit
#' 
#' This function may be run at the console, but it's typically spun off as a batch job on Unity by `map`.
#' 
#' Side effects:
#' 1. writes a geoTIFF, `<result>.tif` with, and a run info file
#' 2. `<runinfo>.RDS`, with the following:
#'    1. Time taken for the run (s)
#'    2. Maximum memory used (GB)
#'    3. Raster size (M pixel)
#'    4. R error, or NULL for success
#' 
#' Requires `rasterPrep`. Install it with:
#'    `remotes::install_github('ethanplunkett/rasterPrep')`
#' 
#' @param fit Model fit object
#' @param target Target level, such as `subclass`
#' @param clip Optional clip, vector of `xmin`, `xmax`, `ymin`, `ymax`
#' @param sourcedir Source directory, probably the flights directory
#' @param result Result path and filename, sans extension
#' @param runinfo Path and filename of run info file. When the run finishes, run info 
#'    is written to this file.
#' @param cores Number of CPU cores to use
#' @importFrom peakRAM peakRAM
#' @importFrom terra ext predict levels writeRaster ncell
#' @importFrom rasterPrep addColorTable makeNiceTif addVat
#' @importFrom lubridate as.duration seconds
#' @export


do_map <- function(fit, target = 'subclass', clip = NULL, 
                   sourcedir = the$flightsdir, result = NULL,
                   cores = 1, runinfo = NULL) {
   
   
   mem <- list(Elapsed_Time_sec = NA, Peak_RAM_Used_MiB = NA)                       # in case of errors
   mpix <- NA
   
   err <- tryCatch({                                                                # trap any errors and save them to runinfo.RDS
      f0 <- paste0(result, '_0.tif')                                                #    preliminary result filename
      f0x <- paste0(result, '_0.*')                                                 #    all preliminary result files for later deletion
      f <- paste0(result, '.tif')                                                   #    final result filename
      
      
      x <- names(fit$trainingData)[-1]                                              #    get source raster names from bands
      x <- sub('^X', '', x)                                                         #    drop leading X
      x <- sub('_\\d+$', '', x)                                                     #    drop band number
      x <- unique(x)                                                                #    and remove dups
      
      
      rasters <- rast(file.path(sourcedir, paste0(x, '.tif')))                      #    get rasters with our bands
      names(rasters) <- sub('^(\\d)', 'X\\1', names(rasters))                       #    files with leading digit get X prepended by R  
      
      rasters <- rasters[[names(rasters) %in% names(fit$trainingData)[-1]]]         #    drop bands we don't want - now we have target bands
      
      if(!is.null(clip))                                                            #    if clip is provided,
         rasters <- crop(rasters, ext(clip))                                        #       clip result
      mpix <- ncell(rasters)
      
      cat('Predicting...\n')
      mem <- peakRAM(pred <- terra::predict(rasters, fit, cpkgs = fit$method, 
                                            cores = cores, na.rm = TRUE))           #    prediction for the model
      writeRaster(pred, f0, overwrite = TRUE, datatype = 'INT1U', progress = 1, 
                  memfrac = 0.8)                                                    #    save the preliminary prediction as a geoTIFF

      levs <- terra::levels(pred$class)[[1]]                                        #    get class levels from prediction
      levs$class <- as.numeric(levs$class)                                          #    make sure they're numeric
      names(levs)[2] <- target                                                      #    use target (e.g., 'subclass') as class name                                                                                 
      
      classes <- read_pars_table('classes')                                         #    read classes file
      classes <- classes[, grep(paste0('^', target), names(classes))]               #    target level in classes
      vat <- merge(levs, classes, sort = TRUE)                                      #    join levels in predict with classes
      vat <- vat[, c(2, 1, 3:ncol(vat))]                                            #    back to proper, with value first
      names(vat) <- c('value', target, 'name', 'color')                             #    drop back to generic names, except for target
      vat[, target] <- as.integer(vat[, target])                                    #    force this to be integer
      
      vat2 <- vat[, c('value', 'color')]                                            #    make a version of the vat for addColorTable
      vat2$category <-  paste0('[', vat[, target], '] ', vat$name)                  #    with labels that include numeric class and name, as e.g. [1] Low marsh
      vrt.file <- addColorTable(f0, table = vat2)                                   #    and add the standard colors
      
      makeNiceTif(source = vrt.file, destination = f, overwrite = TRUE,             #    make a nice TIFF with colors and overviews and add the VAT
                  overviewResample = 'nearest', stats = FALSE, vat = TRUE)
      addVat(f, attributes = vat)                    
      
      unlink(f0x)                                                                   #    delete preliminary files
      ''                                                                            #    no error
   },
   error = function(cond)                                                           # if there was an error anywhere
      return(cond[[1]])                                                             #    capture error message
   )
   
   
   info <- list(elapsed = mem$Elapsed_Time_sec, 
                max_mem = mem$Peak_RAM_Used_MiB / 1000, 
                Mpix = mpix / 1e6, 
                error = err)                                                        # run info
   saveRDS(info, runinfo)
   
   if(err == '')
   cat('do_map finished with no errors in ', 
       format(as.duration(round(seconds(info$elapsed), 0))), 
       ' using ', round(info$max_mem, 2), ' GB\n', sep = '')
   else
      cat('error: ', err, '\n', sep = '')
}


