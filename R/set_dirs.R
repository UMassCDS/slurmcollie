#' Set complete paths to all directories
#' 
#' Sets all directory names from `pars.yml` or defaults. Note that `basedir`, `parsdir`, 
#' and `scratchdir` are set by [init()].
#' 
#' @export


set_dirs <- function() {
   
   
   for(i in c('models', 'data', 'source', 'flights', 'field', 'samples', 'predicted', 'cache'))          # set directory name defaults
      the$dirs[[paste0(i, 'dir')]] <- ifelse(is.null(the$dirs[[i]]), i, the$dirs[[i]])
   
   the$modelsdir <- file.path(the$basedir, the$dirs$model)                                               # models
   the$datadir <- file.path(the$basedir, the$dirs$data, '<site>')                                        # data/<site>/
   the$sourcedir <- file.path(the$datadir, the$dirs$source)                                              # data/<site>/source/
   the$flightsdir <- file.path(the$sourcedir, the$dirs$flights)                                          # data/<site>/source/flights/
   the$fielddir <- file.path(the$sourcedir, the$dirs$field)                                              # data/<site>/source/field/
   the$samplesdir <- file.path(the$datadir, the$dirs$samples)                                            # data/<site>/samples/
   the$predicteddir <- file.path(the$datadir, the$dirs$predicted)                                        # data/<site>/predicted/
   
   the$cachedir <- file.path(the$scratchdir, the$dirs$cache)                                             # scratchdir/cache/
}