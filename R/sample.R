#' Sample Y and X variables for a site
#' 
#' There are three mutually available sampling strategies (n, p, and distance). You
#' must choose exactly one.
#' 
#' @param site One or more site names, using 3 letter abbreviation. Default = all sites.
#' @param pattern Regex filtering rasters of predictor variables, case-insensitive. 
#'    Default = "" (match all). Note: only files ending in `.tif` are included in any case.
#' @param n Number of total samples to return.
#' @param p Proportion of total samples to return. Use p = 1 to sample all.
#' @param distance Sample points with an average spacing of `distance` m. Sampling is
#'    done in cells, so there's no guarantee points will be separated by this much.
#' @param classes Class or vector of classes in transects to sample. Default is all
#'    classes.
#' @param balance If TRUE, balance number of samples for each class. Points will be randomly
#'    selected to match the sparsest class.
#' @param balance_excl Vector of classes to exclude when determining sample size when 
#'    balancing. Include classes with low samples we don't care much about.
#' @param result Name of result file. If not specified, file will be constructed from
#'    site, number of X vars, strategy, and distance.
#' @param transects Name of transects file; default is `transects`.
#' @param xy If TRUE, also get the X and Y coordinates of each sample point.
#' @returns Sampled data table (invisibly)
#' @importFrom terra rast global 
#' @importFrom progressr progressor
#' @importFrom dplyr group_by slice_sample
#' @export


sample <- function(site, pattern = '', n = NULL, p = NULL, distance = NULL, 
                   classes = NULL, balance = TRUE, balance_excl = c(7, 33), result = NULL, 
                   transects = NULL, xy = FALSE) {
   
   
   handlers(global = TRUE)
   lf <- file.path(the$modelsdir, 'gather.log')                                  # set up logging
   
   
   if(sum(!is.null(n), !is.null(p), !is.null(distance)) != 1)
      stop('You must choose exactly one of the n, p, and distance options')
   
   
   msg('', lf)
   msg('-----', lf)
   msg('', lf)
   msg('Running sample', lf)
   msg(paste0('site = ', paste(site, collapse = ', ')), lf)
   msg(paste0('pattern = ', pattern), lf)
   if(!is.null(n))
      msg(paste0('n = ', n), lf)
   if(!is.null(p))
      msg(paste0('p = ', p), lf)
   if(!is.null(distance))
      msg(paste0('distance = ', distance), lf)
   
   
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
   msg(paste0('Sampling ', length(xvars), ' variables'), lf)
   
   sel <- !is.na(field)                                                          # cells with field samples
   nrows <- as.numeric(global(sel, fun = 'sum', na.rm = TRUE))                   # total sample size
   z <- data.frame(subclass = field[sel])                                        # result is expected to be ~4 GB for 130 variables
   

   pr <- progressor(along = xvars)
   for(xv in xvars) {                                                            # for each predictor variable,
      pr()
      x <- rast(file.path(fl, xv))
      z[, names(x)] <- x[sel]
   }
   
   z <- round(z, 2)                                                              # round to 2 digits, which seems like plenty
   
   result <- 'data'   # will tart this up
   
   sd <- resolve_dir(the$samplesdir, sites$site_name)
   if(!dir.exists(sd))
      dir.create(sd, recursive = TRUE)
   write.table(z, f <- file.path(sd, paste0(result, '_all.txt')), sep = '\t', quote = FALSE, row.names = FALSE)
   msg(paste0('Complete dataset saved to ', f), logfile = lf)
   
   
   if(balance) {                                                                 # if balancing smaples,
      counts <- table(z$subclass)
      counts <- counts[!as.numeric(names(counts)) %in% balance_excl]             #    excluding classe in balance_ex,l
      target_n <- min(counts)
      
      z <- group_by(z, subclass) |>
         slice_sample(n = target_n)                                              #    take minimum subclass n for every class
   }
   
   if(!is.null(p))                                                               #    if sampling by proportion,
      n <- p * dim(z)[1]                                                         #       set n to proportion
   
   if(!is.null(n))
      z <- z[base::sample(dim(z)[1], size = n, replace = FALSE), ]               #    sample points
   else {
      # do distance here. I'll have to reproject to square cells. I think I'll create 2 rasters matching field, one of rows and one of columns, 
      # in terms of distance, and then sample them into z.
      # This may throw off balance. Not sure if I should rebalance?
   }
   
   write.table(z, f <- file.path(sd, paste0(result, '.txt')), sep = '\t', quote = FALSE, row.names = FALSE)
   msg(paste0('Sampled dataset saved to ', f), logfile = lf)
   
   invisible(z)
}