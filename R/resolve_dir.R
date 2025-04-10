#' Resolve directory with embedded `<site>` 
#' 
#' @param dir Directory path
#' @param site Site name
#' @returns Directory path including specified site.
#' @keywords internal


resolve_dir <- function(dir, site) 
   
   
   sub('<site>', site, dir, fixed = TRUE)