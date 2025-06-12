#' Initialize user parameters for package slurmcollie
#' 
#' Reads user-set parameters from `~/slurmcollie.yml` and sets them in the
#' slurmcollie environment `slu`. 
#'
#' `slurmcollie.yml` is normally created by `set_up_slurmcollie()'. It should contain the following two lines:
#' 
#'    `slurmcollie_dir = <path>` \cr
#'    `login_node = 'login1`
#' 
#' This function reads the user parameters and adds them to the environment `slu`. It is 
#' automatically run upon loading the package, and may be rerun by the user if parameter 
#' files are changed.
#'
#' See `README` for details on how to set up ssh access to the login node, which is required
#' for launching batch jobs in Slurm from R.
#' @export
#' @export slu


init_slurmcollie <- function() {
   
   
   # Note: 'slu' is created as an environment by aab.R
   
   f <- file.path(path.expand('~'), 'slurmcollie.yml')
   if(!file.exists(f)) {
      message('User parameter file ', f, ' not found. Run set_up_slurmcollie() to initialize this package.')
      return(invisible())
   }
      
   x <- yaml::read_yaml(f)
   for(i in 1:length(x)) 
      slu[[names(x)[i]]] <- x[[i]]
   
   
   slu$dbdir <- file.path(slu$slurmcollie_dir, 'databases')
   slu$templatedir <- file.path(slu$slurmcollie_dir, 'template')
   slu$regdir <- file.path(slu$slurmcollie_dir, 'registries')
   slu$logdir <- file.path(slu$slurmcollie_dir, 'logs')

    
   packageStartupMessage('slurmcollie parameters initialized\n')
}