#' Resolve directory with embedded `<site>` 
#' 
#' @param dir Directory path
#' @param site Site code (3 letter abbreviation)
#' @returns Directory path including specified site.
#' @keywords internal


resolve_dir <- function(dir, site) 
   
   
   sub('<site>', tolower(site), dir, fixed = TRUE)