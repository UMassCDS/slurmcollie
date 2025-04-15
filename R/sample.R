#' Sample Y and X variables for a site
#' 
#' 
#' 
#' @param site One or more site names, using 3 letter abbreviation. Default = all sites.
#' @param pattern Regex filtering rasters of predictor variables, case-insensitive. 
#'    Default = "" (match all). Note: only files ending in `.tif` are included in any case.
#' @param strategy Sampling strategy. One of
#'    1. all - sample all points with field data. Use this when assessing spatial 
#'       autocorrelation, or if don't believe it's a thing.
#'    2. distance - sample points with an average spacing of `distance` m. Sampling is 
#'       done by cells, so there's no guarantee points will be separated by this much.
#' @param distance Average spacing (m) between points.
#' @param classes Class or vector of classes in transects to sample. Default is all
#'    classes.
#' @param balance If TRUE, balance number of samples for each class. Points will be randomly
#'    selected to match the sparsest class.
#' @param result Name of result file. If not specified, file will be constructed from
#'    site, number of X vars, strategy, and distance.
#' @param transects Name of transects file; default is `transects`.
#' @param xy If TRUE, also get the X and Y coordinates of each sample point.
#' @importFrom terra rast global 
#' @export


sample <- function(site, pattern = '', strategy = 'all', distance = 1, 
                    classes = NULL, balance = TRUE, result = NULL, 
                    transects = NULL, xy = FALSE) {
   
   
   allsites <- read_pars_table('sites')                                          # site names from abbreviations to paths
   sites <- allsites[match(tolower(site), tolower(allsites$site)), ]
   
   f <- resolve_dir(the$fielddir, sites$site_name)                               # get field transects
   if(is.null(transects))
      transects <- 'transects.tif'
   field <- rast(file.path(f, transects))
   
   
   if(!is.null(classes))
      field <- subst(field, from = classes, to = classes, others = NA)           # select classes in transect
   
   fl <- resolve_dir(the$flightsdir, sites$site_name)
   xvars <- list.files(fl, pattern = '.tif$')
   
   
   switch(strategy,                                                              # sampling strategy
          'all' = {},                                                            # all points - don't need to do anything here
          'distance' = {                                                         # sample points within tiles
             cat('********** sampling points within tiles')
          }
   )
   
   
   n <- as.numeric(global(!is.na(field), fun = 'sum', na.rm = TRUE))             # total sample size
   z <- data.frame(matrix(NA, n, length(xvars) + 1))                             # result
   names(z) <- c('subclass', gsub('.tif$', '', xvars))
   z$subclass <- field[!is.na(field)]
   
   for(xv in xvars)                                                              # for each predictor variable,
      z[, gsub('.tif$', '', xv)] <- rast(file.path(fl, xv))[!is.na(field)]                                     #    grab it
      
      
   
   
   
   
   
   
   if(balance)                                                                   # if balancing smaples,
      cat('hmm')
          
          
}