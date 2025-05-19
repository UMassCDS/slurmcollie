#' Load the specified database unless we've already got it
#' 
#' Loads the database from directory `the$dbdir` into environment `the` if it hasn't 
#' already been loaded or if `force = TRUE`.
#' 
#' @param database Name of database (`jdb` or `db`)
#' @param force If TRUE, always loads the database, replacing the current one if it exists
#' @export


load_database <- function(database, force = FALSE) {
   
   
   if(is.null(the[[database]]) | force)                         # if don't have the database or force = TRUE,
      if(!file.exists(f <- file.path(the$dbdir, paste0(database, '.RDS'))))
         stop('Database ', f, ' doesn\'t exist. Use new(database) to create it.')
      the[[database]] <- readRDS(f)
}