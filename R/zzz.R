#' Initialize user parameters when the package is loaded
#' @param libname (required by R; not used)
#' @param pkgname (required by R; not used)
#' @keywords internal

.onLoad <- function(libname, pkgname) {
   
   
   init()
   init_slurmcollie()                                       # ************************** will drop this when I split packages
   
}