'gather_data' <- function(site = NULL, pattern = '.*', 
                          subdirs = c('RFM processing inputs/Orthomosaics', 'Share/Photogrammetry DEMs', 'Share/Canopy height models'), 
                          basedir = 'c:/Work/etc/saltmarsh/data', replace = FALSE, resultbase = 'c:/Work/etc/saltmarsh/data/stacked') {
   
   # Collect raster data from various source locations (orthophotos, DEMs, canopy height models) for each site. 
   # Clip to site boundary, resample and align to standard resolution.
   # Arguments:
   #     site           one or more site names, using 3 letter abbreviation. Default = all sites
   #     pattern        regex filtering rasters, case-insensitive. Default = '.*' (match all). Note: only files ending in .tif are included in any case.
   #        Examples: 
   #           - to match all Mica orthophotos, use pattern = 'mica_orth'
   #           - to match Mica files for a series of dates, use pattern = '11nov20.*mica|14oct20.*mica'
   #     subdirs        subdirectories to search, ending with slash. Default = orthos, DEMs, and canopy height models (okay to include empty or
   #                    nonexistent directories)
   #     basedir        full path to subdirs
   #     replace        if true, deletes the existing stack and replaces it. Use with care!
   #     resultbase     name of result base directory. The site name will be appended.
   # 		
   # 	Source: 
   #     geoTIFFs for each site
   #     pars/sites.txt    table of site abbreviation, site name, footprint shapefile, raster standard
   # 	   
   # 	Results: geoTIFFs, clipped, resampled, and aligned
   # 
   #  All source data are expected to be in EPSG:4326. Non-conforming rasters will be reprojected.
   # 	
   #  sites.txt must include the name of the footprint shapefile for each site.
   # 
   #  sites.txt may include a standard geoTIFF for each site, to be used as the standard for grain and alignment; all rasters will be 
   #  resampled to match. If not specified, standard for each site will be set to orthomosiacs/ Mica file with earliest date (regardless 
   #  of whether it's in the rasters specification). 
   # 	
   #  Note that adding to an existing stack using a different standard will lead to sorrow. If an stack for the site already 
   #  exists and replace = FALSE, one of the rasters in the stack will be compared with the standard for alignment, potentially 
   #  producing an error. 
   # 	
   # 	BEST PRACTICE: include standards in sites.txt and don't change them
   # 	
   # 	B. Compton, 31 Jan 2025
   
   
   ### for testing on my laptop    (don't forget to change OTH in sites.txt!)
   subdirs = c('Orthomosaics/', 'Photogrammetry DEMs/', 'Canopy height models/')
   site <- c('oth', 'wes')
   pattern = 'mica'
   
   
   library(terra)
   library(sf)
   library(googledrive)                 # will need to add this, probably using cover fns. Or maybe we just copy source data before running?
   library(stringr)
   library(lubridate)
   
   
   
   allsites <- read.table('pars/sites.txt', sep = '\t', header = TRUE)              # site names from abbreviations to paths
   if(is.null(site))
      site <- allsites$site
   else
      sites <- allsites[match(tolower(site), tolower(allsites$site)), ]
   if(any(is.na(sites$site_name)))                                               # check for missing sites
      stop(paste0('Bad site names: ', paste(site[is.na(sites$site_name)], collapse = ', ')))
   
   
   if(replace)
      cat('\n!!! BEWARE: replace = TRUE will delete all existing contents in result directories !!!\n\n')
   
   cat('Running for ', dim(sites)[1], ' sites...\n', sep = '')
   
   for(i in 1:dim(sites)[1]) {                                                      # for each site,
      cat('\nSite ', sites$site[i], '\n', sep = '')
      dir <- file.path(basedir, sites$site_name[i], '/')
      x <- NULL
      for(j in subdirs)                                                             #    for each subdir,
         x <- c(x, paste0(j, list.files(file.path(dir, j))))                        #       get filenames ending in .tif
      x <- x[grep('.tif$', x)]
      if(is.na(standard <- sites$standard[i])) {                                    #    if standard supplied for this site, use it; else take earliest Mica Orthomosaic
         d <- str_split(y <- x[grep('mica_ortho', tolower(x))], '_')         
         d <- dmy(unlist(lapply(d, '[[', 1)))
         standard <- y[order(d)[1]]
         cat('   Using standard = ', standard, '\n', sep = '')
         standard <- rast(file.path(dir, standard))
      }
      x <- x[grep(tolower(pattern), tolower(x))]                                    #    now match user's pattern - this is our definitive list of geoTIFFs for this site
      cat('   Processing ', length(x), ' geoTIFFs...\n', sep = '')
      
      shapefile <- st_read(file.path(dir, sites$footprint[i]), quiet = TRUE)        #    read boundary shapefile
      
      
      if(!dir.exists(resultbase))                                                   #    prepare result directory
         dir.create(resultbase)
      resultdir <- file.path(resultbase, sites$site_name[i], '/')                   
      if(replace) 
         unlink(resultdir, recursive = TRUE)
      if(!dir.exists(resultdir))
         dir.create(resultdir)
      
      
      for(j in x) {                                                                 #    for each target geoTIFF in site,
         cat('      processing ', j, '\n', sep = '')
         
         g <- rast(file.path(dir, j))
         if (paste(crs(g, describe = TRUE)[c('authority', 'code')], collapse = ':') != 'EPSG:4326') {
            cat('         !!! Reprojecting ', g, '\n', sep =)
            g <- project(g, 'epsg:4326')
         }
         
         resample(g, standard, method = 'bilinear', threads = TRUE) |>
            crop(shapefile) |>
            mask(shapefile) |>
            writeRaster(file.path(resultdir, basename(j)), overwrite = TRUE)
      }
   }
}
