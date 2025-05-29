#' Set up files for package slurmcollie
#' 
#' Creates directories and a user parameter file for the `slurmcollie` package.
#' `slurmcollie.yml` is normally created by `set_up_slurmcollie()'. It should contain the following two lines:
#' 
#'    `slurmcollie_dir = <path>` \cr
#'    `login_node = 'login1`
#' 
#' This function reads the user parameters and adds them to the environment `slu`. It is 
#' automatically run upon loading the package, and may be rerun by the user if parameter 
#' files are changed.
#' 
#' This function also creates the directory named in `directory` and subdirectories 
#' `databases`, `template`, `registries', and `logs` if they don't already exist. It's okay to share
#' these directories with other R code; for instance, the `saltmarsh` package also uses
#' `databases`.
#'
#' See README for details on how to set up ssh access to the login node, which is required
#' for launching batch jobs in Slurm from R.
#' @param directory The user directory for slurmcollie files
#' @param login_node The name of a login node with ssh access
#' @param replace If TRUE, replaces `slurmcollie.yml` and the template files if any exist
#' @export


set_up_slurmcollie <- function(directory = NULL, login_node = 'login1', replace = FALSE) {
   
   
   if(is.null(directory))
      stop('A directory must be supplied')
   
   
   yml <- file.path(path.expand('~'), 'slurmcollie.yml')
   
   tocheck <- c(yml, file.path(directory, 'templates', 'batchtools.conf.R'),
                file.path(directory, 'templates', 'slrum.tmpl'))
   
   
   if(any(e <- file.exists(tocheck)) & !replace)
      stop(paste(tocheck[e], sep = ', '), ' already exist', ifelse(sum(e) == 1, 's', ''), 
           '. Use replace = TRUE to start fresh.')
   
   x <- c('# Parameter files for R package slurmcollie', '', 
          paste0('slurmcollie_dir: ', directory), 
          paste0('login_node: ', login_node))
   writeLines(x, yml)
   message('Created ', yml)
   
   
   init_slurmcollie()
   
   
   dirs <- c(directory, slu$dbdir, slu$templatedir, slu$regdir, slu$logdir)
   
   for(i in dirs)
      if(!dir.exists(i)) {
         dir.create(i, recursive = TRUE)
         message('Created ', i)
      }
   
   templates <- system.file(c('batchtools.conf.R', 'slurm.tmpl'), package = 'saltmarsh', 
                            lib.loc = .libPaths(), mustWork = TRUE)
   x <- file.copy(templates, slu$templatedir, overwrite = TRUE)
   if(any(!x))
      stop('Failed to copy templates to ', slu$templatedir)
   
   message(paste0('Created ', templates, '\n'))
   
   
   message('slurmcollie is good to go!')
}
