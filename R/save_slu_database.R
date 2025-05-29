#' Save the specified slurmcollie database 
#' 
#' Saves the database in directory `slu$dbdir`. Previous versions are renamed e.g., `jdb_1.RDS`,
#' `jdb_2.RDS`, etc. Will need a mechanism to delete databases more than a week old (or something).
#' 
#' @param database Name of database (should be `jdb`)
#' @importFrom tools file_path_sans_ext
#' @export


save_slu_database <- function(database) {
   
   
   if(is.null(slu[[database]]))                                                              # if don't have the database, throw an error 
      stop('Database ', database, ' isn\'t loaded, so it can\'t be saved')
   
   if(!dir.exists(slu$dbdir))                                                                # create database directory if it doesn't exist yet
      dir.create(slu$dbdir, recursive = TRUE)
   
   if(file.exists(f <- file.path(slu$dbdir, paste0(database, '.RDS')))) {                    # if a saved version already exists, 
      if(identical(slu[[database]], readRDS(f)))                                             #    and it's identical to what we've got
         return(invisible())                                                                 #       we're done
      else {                                                                                 #    else, rename it as a backup
         l <- file_path_sans_ext(list.files(slu$dbdir, pattern = database))                  #       database filenames
         n <- max(c(0, as.numeric(sub(paste0(database, '_*'), '', l))), na.rm = TRUE) + 1    #       backup file number
         file.rename(f, file.path(slu$dbdir, paste0(database, '_', n, '.RDS')))
      }
   }
   
   saveRDS(slu[[database]], f)
}