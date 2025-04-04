#' Initialize salt-marsh-mapping with user parameters
#' 
#' Reads user-set parameters for package saltmarsh.
#' 
#' User parameters are set in two distinct locations:
#' 
#' 1. The initialization file, in the user's home directory, `~/saltmarsh.yml`. 
#' This file should contain two lines:
#' 
#'    `parsdir: c:/Work/etc/saltmarsh/pars`
#'    
#'    `parsfile: pars.yml`
#' 
#'    a. `parsdir`` points to the parameter directory
#' 
#'    b. `parsfile` points to the main parameter file
#' 
#' 2. Everything else, in `parsdir`. The primary parameter file is `pars.yml`, which
#' points to other paramters (such as sites.txt).
#' 
#' This approach splits the user- and platform-dependent parameters (saltmarsh.yml)
#' from parameters that are likely to be shared among users and platforms (those in
#' `parsdir`). It allows multiple users on a shared machine (such as Unity cluster)
#' to set user-specific parameters if need be, while sharing other parameters.
#' 
#' This function reads the user parameters and sets a local environment `the` with 
#' all parameters. It is automatically run upon loading the package, and may be 
#' rerun by the user if parameter files are changed.
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
   
   p <- c('parsfile', 'parsdir') 
   if(any(t <- !p %in% names(the)))
      stop(paste0('Parameters ', paste0(p[t], collapse = ', ') , ' are missing from ', f))
   x <- yaml::read_yaml(file.path(the$parsdir, the$parsfile))
   for(i in 1:length(x)) 
      the[[names(x)[i]]] <- x[[i]]
   
   
}