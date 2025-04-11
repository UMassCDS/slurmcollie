#' Collect raster data for each site
#' 
#' Clip to site boundary, resample and align to standard resolution. Data will be copied from various source 
#' locations (orthophotos, DEMs, canopy height models).
#' 
#' Additional parameters, set in the `gather` block in `pars.yml` (see [init()]):
#' 
#' - `sourcedrive` one of `local`, `google`, `sftp`
#'   - `local` - read source from local drive 
#'   - `google` - get source data from currently connected Google Drive (login via browser on first connection) and cache it locally. Must set `cachedir` option. 
#'   - `sftp` - get source data from SFTP site. Must set `sftp` and `cachedir` options. 
#' - `sourcedir` directory with source rasters, generally on Google Drive or SFTP site
#' - `subdirs` subdirectories to search, ending with slash. Default = orthos, DEMs, and canopy height models (okay to include empty or
#'   nonexistent directories). Use `\<site>` in subdirectories that include a site name, e.g., `\<site> Share/Photogrammetry DEMs`.
#'   WARNING: paths on the Google Drive are case-sensitive!
#' - `sftp` `list(url = <address of site>, user = <credentials>)`. Credentials are either `username:password` or `*filename` with `username:password`. Make sure 
#'   to include credential files in `.gitignore` and `.Rbuildignore` so it doesn't end up out in the world! 
#' 
#' Source data: 
#'   - geoTIFFs for each site
#'   - `sites` file, table of site abbreviation, site name, footprint shapefile, raster standard
#'
#' Results: 
#'   - flights/geoTIFFs, clipped, resampled, and aligned. ***Make sure you've closed ArcGIS/QGIS projects that point to these before running!***
#'   - models/gather_data.log
#' 
#' All source data are expected to be in `EPSG:4326`. Non-conforming rasters will be reprojected.
#' 
#' `sites.txt` must include the name of the footprint shapefile for each site.
#' 
#' `sites.txt` must include a standard geoTIFF for each site, to be used as the standard for grain and alignment; all rasters will be 
#' resampled to match. Standards MUST be in the standard projection, `EPSG:4326`. Best to use a Mica orthophoto, with 8 cm resolution.
#' 
#' Note that adding to an existing stack using a different standard will lead to sorrow. **BEST PRACTICE**: don't change the standards
#' in `standards.txt`; if you must change them, rerun with replace = TRUE to replace results that were created using the old standard.
#' 
#' Note that initial runs with Google Drive in a session open the browser for authentication or wait for input from the console, so 
#' don't run blindly when using the Google Drive
#' 
#' Remember that some SFTP servers require connection via VPN
#' 
#' ***Hanging issues for SFTP***
#' 
#'   - SFTP implementations behave differently so I'll have to revise once the NAS is up and running.
#'   - Windows dates are a mess for DST. Hopefully Linux won't be.
#' 
#' Example runs:
#' 
#'    Complete for all sites:
#' 
#'       `gather()`
#'       
#'    Run for one site, June only:
#'    
#'       `gather(site = 'oth', pattern = 'Jun')`
#' 
#'    Run for 2 sites, low tide only:
#' 
#'       `gather(site = c('oth', 'wes'), pattern = '_low_')`
#' 
#' @param site one or more site names, using 3 letter abbreviation. Default = all sites
#' @param pattern regex filtering rasters, case-insensitive. Default = "" (match all). Note: only files ending in `.tif` are included in any case.
#' Examples: 
#'   - to match all Mica orthophotos, use `mica_orth`
#'   - to match all Mica files from July, use `Jun.*mica`
#'   - to match Mica files for a series of dates, use `11nov20.*mica|14oct20.*mica`
#' @param update if TRUE, only process new files, assuming existing files are good 
#' @param replace if TRUE, deletes the existing stack and replaces it. Use with care!
#' @param check if TRUE, just check to see that source directories and files exist, but don't cache or process anything
#' @importFrom terra project rast crs writeRaster mask crop resample
#' @importFrom sf st_read 
#' @importFrom lubridate as.duration interval
#' @importFrom pkgcond suppress_warnings
#' @export


'gather' <- function(site = NULL, pattern = '', 
                     update = TRUE, replace = FALSE, check = FALSE) {
   
   
   lf <- file.path(the$modelsdir, 'gather.log')                                        # set up logging
   start <- Sys.time()
   count <- 0
   allsites <- read_pars_table('sites')                                             # site names from abbreviations to paths
   if(is.null(site))
      site <- allsites$site
   else
      sites <- allsites[match(tolower(site), tolower(allsites$site)), ]
   
   if(!the$gather$sourcedrive %in% c('local', 'google', 'sftp'))                    # make source sourcedrive is good
      stop('sourcedrive must be one of local, google, or sftp')
   if(any(is.na(sites$site_name)))                                                  # check for missing sites
      stop(paste0('Bad site names: ', paste(site[is.na(sites$site_name)], collapse = ', ')))
   if(any(t <- is.na(sites$footprint) | sites$footprint == ''))                     # check for missing standards
      stop(paste0('Missing footprints for sites ', paste(sites$footprint[t], collapse = ', ')))
   if(any(t <- is.na(sites$standard) | sites$standard == ''))                       # check for missing standards
      stop(paste0('Missing standards for sites ', paste(sites$site[t], collapse = ', ')))
   
   if((the$gather$sourcedrive %in% c('google', 'sftp')) & 
      !dir.exists(the$cachedir))                                                    #    make sure cache directory exists if needed
      dir.create(the$cachedir, recursive = TRUE)
   
   if(replace)
      msg('\n!!! BEWARE: replace = TRUE will delete all existing contents in result directories !!!\n\n')
   
   msg('', lf)
   msg('-----', lf)
   msg('', lf)
   msg(paste0('gather running for ', dim(sites)[1], ' sites...'), lf)
   msg(paste0('sourcedrive = ', the$gather$sourcedrive), lf)
   msg(paste0('site = ', paste(site, collapse = ', ')), lf)
   msg(paste0('pattern = ', pattern), lf)
   if(check)
      msg('check = TRUE, so printing but not processing files', lf)
   
   for(i in 1:dim(sites)[1]) {                                                      # for each site,
      msg(paste0('Site ', sites$site[i]), lf)
      dir <- file.path(the$gather$sourcedir, sites$site_name[i], '/')
      
      s <- c(the$gather$subdirs, dirname(sites$standard[i]))                        #    add path to standard to subdirs in case it's not there already
      s <- gsub('/+', '/', paste0(s, '/'))                                          #    clean up slashes
      s <- unique(s)                                                                #    and drop likely duplicate
      
      x <- NULL
      for(j in resolve_dir(s, sites$site_name[i]))                                  #    for each subdir (with site name replacement),
         x <- rbind(x, get_dir(file.path(dir, j), 
                               the$gather$sourcedrive,
                               sftp = the$gather$sftp, logfile = lf))               #       get directory
      x <- x[grep('.tif$', x$name), , drop = FALSE]                                 #    only want files ending in .tif
      
      t <- get_dir(file.path(dir, dirname(sites$footprint[i])), 
                   the$gather$sourcedrive, sftp = the$gather$sftp, logfile = lf)    #    Now get directory for footprint shapefile
      x <- rbind(x, t[grep('.shp$|.shx$|.prj$', t$name),])                          #    only want .shp, .shx, and .prj
      
      gd <- list(dir = x, sourcedrive = the$gather$sourcedrive, 
                 cachedir = the$cachedir, sftp = the$gather$sftp)                   #    info for Google Drive or SFTP
      
      files <- x$name[grep(tolower(pattern), tolower(x$name))]                      #    now match user's pattern - this is our definitive list of geoTIFFs to process for this site
      files <- files[grep('^bad_', files, invert = TRUE)]                           #    BUT drop files that begin with 'bad_', as they're c
      
      if(length(files) == 0)
         next
      
      if(update) {                                                                  #    if update, don't mess with files that have already been done
         sdir <- file.path(the$gather$sourcedir, sites$site_name[i])
         rdir <- resolve_dir(the$flightsdir, sites$site_name[i])
         ##    files<<-files;gd<<-gd;sdir<<-sdir;rdir<<-rdir;return()
         files <- files[!check_files(files, gd, sdir, rdir)]                        #       see which files already exist and are up to date
      }
      
      
      if(check) {                                                                   #    if check = TRUE, don't download or process anything
         msg(paste0('   ', files), lf)                                              #       but do print the source file names
         next
      }
      
      dumb_warning <- 'Sum of Photometric type-related color channels'              #    we don't want to hear about this!
      pkgcond::suppress_warnings(standard <- rast(get_file(file.path(dir, sites$standard[i]), 
                                                           gd, logfile = lf)), 
                                 pattern = dumb_warning, class = 'warning')
      msg(paste0('   Processing ', length(files), ' geoTIFFs...'), lf)
      
      if(the$gather$sourcedrive %in% c('google', 'sftp')) {                         #    if reading from Google Drive or SFTP,
         t <- get_file(file.path(dir, sub('.shp$', '.shx', sites$footprint[i])), 
                       gd, logfile = lf)                                            #       load two sidecar files for shapefile into cache
         t <- get_file(file.path(dir, sub('.shp$', '.prj', sites$footprint[i])), 
                       gd, logfile = lf)
      }
      shapefile <- st_read(get_file(file.path(dir, sites$footprint[i]), 
                                    gd, logfile = TRUE), quiet = TRUE)              #    read footprint shapefile
      
      
      rd <- resolve_dir(the$flightsdir, sites$site_name[i])                         #    prepare result directory
      if(replace & dir.exists(rd))
         unlink(rd, recursive = TRUE)
      if(!dir.exists(rd))
         dir.create(rd, recursive = TRUE)
      
      
      count <- count + length(files)
      for(j in files) {                                                             #    for each target geoTIFF in site,
         msg(paste0('      processing ', j), lf)
         
         if(tryCatch({                                                              #    read the raster, skipping bad ones
            suppressWarnings(g <- rast(get_file(j, gd, logfile = lf)))
            FALSE
         }, 
         error = function(cond) {
            msg(paste0('      ** Skipping possibly corrupted raster ', j), lf)
            TRUE
         }))
            next
         
         if(paste(crs(g, describe = TRUE)[c('authority', 'code')], collapse = ':') != 'EPSG:4326') {
            msg(paste0('         !!! Reprojecting ', g), lf)
            g <- project(g, 'epsg:4326')
         }
         
         resample(g, standard, method = 'bilinear', threads = TRUE) |>
            crop(shapefile) |>
            mask(shapefile) |>
            writeRaster(file.path(rd, basename(j)), overwrite = TRUE)               #       resample, crop, mask, and write to result directory
      }
      msg(paste0('Finished with site ', sites$site[i]), lf)
   }
   d <- as.duration(interval(start, Sys.time()))
   msg(paste0('Run finished. ', count,' geoTIFFs processed in ', round(d), ifelse(count == 0, '', paste0('; ', round(d / count), ' per file.'))), lf)
   
   
   
   if(FALSE) {                      # Calls for testing   THIS IS OUTDATED
      # local on my laptop
      gather_data(site = c('oth', 'wes'), sourcedir = 'c:/Work/etc/saltmarsh/data',
                  sourcedrive = 'local', subdirs = c('Orthomosaics/', 'Photogrammetry DEMs/', 'Canopy height models/'))
      
      # from Google Drive to my laptop
      gather_data(site = c('oth', 'wes'), sourcedir = 'UAS Data Collection/', 
                  sourcedrive = 'google', cachedir = 'c:/temp/cache/')
      
      # from landeco SFTP to my laptop. Set pw to password before calling.
      gather_data(site = c('oth', 'wes'), sourcedrive = 'sftp', 
                  sftp = list(url = 'sftp://landeco.umass.edu/D/temp/salt_marsh_test', user = paste0('campus\\landeco:', pw)), cachedir = 'c:/temp/cache/')
      
      
      # To narrow down inputs
      # pattern = 'nov.*low*.mica'
      # pattern = '27Apr2021_OTH_Low_RGB_DEM.tif|24Jun22_WES_Mid_SWIR_Ortho.tif'
      
   }
}
