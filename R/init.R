#' Initialize salt-marsh-mapping with user parameters
#' 
#' Reads user-set parameters for package saltmarsh.
#' 
#' User parameters are set in two distinct locations:
#' 
#' 1. The initialization file, in the user's home directory, `~/saltmarsh.yml`. 
#' This file should contain four lines:
#' 
#'    `basedir: c:/Work/etc/saltmarsh` \cr
#'    `parsdir: pars` \cr
#'    `parsfile: pars.yml` \cr
#'    `scratchdir: c:/Work/etc/saltmarsh/data/scratch`
#' 
#'    a. `basedir` points to the base directory
#'    
#'    b. `parsdir` is the parameters subdirectory. It should be `pars` unless you have 
#'       a good reason to change it.
#' 
#'    c. `parsfile` points to the main parameter file. It should be `pars.yml`.
#'    
#'    d. `scratchdir` points to the scratch drive, where the `cache` directory will be located.
#' 
#' 2. Everything else, in `<basedir>/<parsdir>`. The primary parameter file is 
#' `pars.yml`, which points to other parameters (such as `sites.txt`).
#' 
#' This approach splits the user- and platform-dependent parameters (`saltmarsh.yml`)
#' from parameters that are likely to be shared among users and platforms (those in
#' `parsdir`). It allows multiple users on a shared machine (such as Unity cluster)
#' to set user-specific parameters if need be, while sharing other parameters.
#' 
#' This function reads the user parameters and sets a local environment `the` with 
#' all parameters. It is automatically run upon loading the package, and may be 
#' rerun by the user if parameter files are changed.
#' 
#' You can change standard directory names (`data`, `models`, `source`, `flights`, `field`, `samples`, 
#' `predicted`, and `cache`) by setting each within a `dirs:` block in `pars.yml`.
#' Directories default to standard names, which is usually what you want.
#' 
#' To change parameters on the fly, you can set the components of `the`. If you change any elements of 
#' `dirs`, you'll have to run [set_dirs()] afterwards. Note
#' that parameters changed on the fly will only persist until the next call to `init()`, 
#' which can be called on demand but also happens automatically when the package is loaded.
#' 
#' For example:
#' 
#' `the$sites <- 'newsites'`  \cr
#' `the$dirs$cache <- 'newcache'` \cr
#' `the$dirs$samples <- 'samples99'` \cr
#' `set_dirs()`
#' 
#' @export


init <- function() {
   
   
   # Note: 'the' is created as an environment by aaa.R
   
   f <- file.path(path.expand('~'), 'saltmarsh.yml')
   if(!file.exists(f))
      stop(paste0('User parameter file ', f, ' not found'))
   x <- yaml::read_yaml(f)
   for(i in 1:length(x)) 
      the[[names(x)[i]]] <- x[[i]]
   
   
   p <- c('basedir', 'parsdir', 'parsfile', 'scratchdir') 
   if(any(t <- !p %in% names(the)))
      stop(paste0('Parameters ', paste0(p[t], collapse = ', ') , ' are missing from ', f))
   
   the$parsdir <- file.path(the$basedir, the$parsdir)                                                    # path to parameter files
   
   x <- yaml::read_yaml(file.path(the$parsdir, the$parsfile))
   for(i in 1:length(x)) 
      the[[names(x)[i]]] <- x[[i]]
   
   
   set_dirs()                                                                                            # and create all full paths
   
   packageStartupMessage('User parameters initialized\n')
}