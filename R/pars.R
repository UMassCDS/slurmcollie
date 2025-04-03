#' Return path to parameter file
#' 
#' Given a file name, return path to it in user parameters directory
#' 
#' @param file Parameter file name
#' @returns Path and name of parameter file
#' @keywords internal


pars <- function(file) {
   
   
   path <- 'c:/Work/R/salt-marsh-mapping/pars'           # ***** TEMPORARY ***** this will come from package environment, set at package load or something
   file.path(path, file)
}