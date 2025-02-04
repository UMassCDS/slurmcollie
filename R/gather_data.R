'gather_data' <- function(site = NULL, pattern = '.*', 
                          subdirs = c('RFM processing inputs/Orthomosaics', 'Share/Photogrammetry DEMs', 'Share/Canopy height models'), 
                          basedir = 'c:/Work/etc/saltmarsh/data', replace = FALSE, resultbase = 'c:/Work/etc/saltmarsh/data/', resultdir = 'stacked/') {
   
   # Collect raster data from various source locations (orthophotos, DEMs, canopy height models) for each site. 
   # Clip to site boundary, resample and align to standard resolution.
   # Arguments:
   #     site           one or more site names, using 3 letter abbreviation. Default = all sites
   #     pattern        regex filtering rasters, case-insensitive. Default = '.*' (match all). Note: only files ending in .tif are included in any case.
   #        Examples: 
   #           - to match all Mica orthophotos, use pattern = 'mica_orth'
   #           - to match all Mica files from July, use pattern = 'Jun.*mica'
   #           - to match Mica files for a series of dates, use pattern = '11nov20.*mica|14oct20.*mica'
   #     subdirs        subdirectories to search, ending with slash. Default = orthos, DEMs, and canopy height models (okay to include empty or
   #                    nonexistent directories)
   #     basedir        full path to subdirs
   #     replace        if true, deletes the existing stack and replaces it. Use with care!
   #     resultbase     base name of result base directory. 
   #     resultdir      subdir for results. Default is 'stacked/'. The site name will be appended to this.
   # 
   # Source: 
   #     geoTIFFs for each site
   #     pars/sites.txt    table of site abbreviation, site name, footprint shapefile, raster standard
   #
   # Results: 
   #     geoTIFFs, clipped, resampled, and aligned   *** Make sure you've closed ArcGIS/QGIS projects that point to these before running! ***
   #     gather_data.log, in resultbase      
   # 
   # All source data are expected to be in EPSG:4326. Non-conforming rasters will be reprojected.
   # 
   # sites.txt must include the name of the footprint shapefile for each site.
   # 
   # sites.txt must include a standard geoTIFF for each site, to be used as the standard for grain and alignment; all rasters will be 
   # resampled to match. Standards MUST be in the standard projection, EPSG:4326. Use find_standards() to pick good candidates.
   # 
   # Note that adding to an existing stack using a different standard will lead to sorrow. BEST PRACTICE: don't change the standards
   # in standards.txt; if you must change them, run with replace = TRUE.
   # 
   # Example runs:
   #    Complete for all sites:
   #       gather_data()
   #    Run for 2 sites, low tide only:
   #       gather_data(sites = c('oth', 'wes'), pattern = '_low_')
   # 
   # B. Compton, 31 Jan 2025
   
   
   ### for testing on my laptop    (don't forget to change OTH in sites.txt!)
   subdirs = c('Orthomosaics/', 'Photogrammetry DEMs/', 'Canopy height models/')
   site <- c('oth', 'wes')
   pattern = 'nov.*mica'
   
   
   library(terra)
   library(sf)
   library(googledrive)                 # will need to add this, probably using cover fns. Or maybe we just copy source data before running?
   library(stringr)
   library(lubridate)
   
   
   
   lf <- file.path(resultbase, 'gather_data.log')                                   # set up logging
   'msg' <- function(message, logfile) {                                            # append message to the log file and also write it to the display
      timestamp <- stamp('[17 Feb 2025, 3:22:18 pm]  ', quiet = TRUE)
      if(!file.exists(logfile))
         cat(paste0(timestamp(now()), message), sep = '\n', file = logfile)
      else
         cat(paste0(timestamp(now()), message), sep = '\n', file = logfile, append = TRUE)
      cat(message, sep = '\n')
   }
   
   
   
   start <- Sys.time()
   count <- 0
   allsites <- read.table('pars/sites.txt', sep = '\t', header = TRUE)              # site names from abbreviations to paths
   if(is.null(site))
      site <- allsites$site
   else
      sites <- allsites[match(tolower(site), tolower(allsites$site)), ]
   if(any(is.na(sites$site_name)))                                                  # check for missing sites
      stop(paste0('Bad site names: ', paste(site[is.na(sites$site_name)], collapse = ', ')))
   
   
   if(replace)
      msg('\n!!! BEWARE: replace = TRUE will delete all existing contents in result directories !!!\n\n')
   
   msg('', lf)
   msg(paste0('gather_data running for ', dim(sites)[1], ' sites...'), lf)
   msg(paste0('site = ', paste(site, collapse = ', ')), lf)
   msg(paste0('pattern = ', pattern), lf)
   
   for(i in 1:dim(sites)[1]) {                                                      # for each site,
      msg(paste0('Site ', sites$site[i]), lf)
      dir <- file.path(basedir, sites$site_name[i], '/')
      x <- NULL
      for(j in subdirs)                                                             #    for each subdir,
         x <- c(x, paste0(j, list.files(file.path(dir, j))))                        #       get filenames ending in .tif
      x <- x[grep('.tif$', x)]
      standard <- rast(file.path(dir, sites$standard[i]))
      
      x <- x[grep(tolower(pattern), tolower(x))]                                    #    now match user's pattern - this is our definitive list of geoTIFFs for this site
      msg(paste0('   Processing ', length(x), ' geoTIFFs...'), lf)
      
      shapefile <- st_read(file.path(dir, sites$footprint[i]), quiet = TRUE)        #    read boundary shapefile
      
      
      if(!dir.exists(resultbase))                                                   #    prepare result directory
         dir.create(resultbase)
      if(!dir.exists(f <- file.path(resultbase, resultdir)))
         dir.create(f)
      rd <- file.path(f, sites$site_name[i], '/')                   
      if(replace) 
         unlink(rd, recursive = TRUE)
      if(!dir.exists(rd))
         dir.create(rd)
      
      count <- count + length(x)
      for(j in x) {                                                                 #    for each target geoTIFF in site,
         msg(paste0('      processing ', j), lf)

         g <- rast(file.path(dir, j))
         if(paste(crs(g, describe = TRUE)[c('authority', 'code')], collapse = ':') != 'EPSG:4326') {
            msg(paste0('         !!! Reprojecting ', g), lf)
            g <- project(g, 'epsg:4326')
         }

         resample(g, standard, method = 'bilinear', threads = TRUE) |>
            crop(shapefile) |>
            mask(shapefile) |>
            writeRaster(file.path(rd, basename(j)), overwrite = TRUE)
       }
      msg(paste0('Finished with site ', sites$site[i]), lf)
   }
   d <- as.duration(interval(start, Sys.time()))
   msg(paste0('Run finished. ', count,' geoTIFFs processed in ', round(d), '; ', round(d / count), ' per file.'), lf)
}
