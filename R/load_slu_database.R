#' Load the specified slurmcollie database unless we've already got it
#' 
#' Loads the database from directory `slu$dbdir` into environment `slu` if it hasn't 
#' already been loaded or if `force = TRUE`.
#' 
#' @param database Name of database (should be `jdb`)
#' @param force If TRUE, always loads the database, replacing the current one if it exists
#' @export


load_slu_database <- function(database = 'jdb', force = FALSE) {
   
   
   f <- file.path(slu$dbdir, paste0(database, '.RDS'))
   if(is.null(slu[[database]]) | force)                         # if don't have the database or force = TRUE,
      if(!file.exists(f))
         stop('Database ', f, ' doesn\'t exist. Use new_db(\'',database,'\') to create it.')
      slu[[database]] <- readRDS(f)
}