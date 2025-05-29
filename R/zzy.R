#' Initialize user parameters when the package slurmcollie is loaded
#' @param libname (required by R; not used)
#' @param pkgname (required by R; not used)
#' @keywords internal

.onLoad <- function(libname, pkgname) {

   
   init_slurmcollie()
   
}