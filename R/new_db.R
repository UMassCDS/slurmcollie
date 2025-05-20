#' Create a new database 
#' 
#' Creates a new empty fits database (`db`) or jobs database (`jbd`). Use with great care--this
#' function will destroy any existing database. It saves the results to disk immediately.
#' 
#' @param database Name of database (`jdb` or `db`)
#' @param really If TRUE, creates database, **destroying existing database**
#' @export 


new_db <- function(database, really = FALSE) {
   
   
   if(!really)
      stop('Database ', database, ' won\'t be created unless you use really = TRUE. This will DESTROY your existing database.')
   
   switch(database,
          'db' = {
             
             
          },
          'jdb' = {
             the$jdb <- data.frame(
                jobid  = integer(),
                jobname  = character(),
                bjobid  = integer(),
                registry = character(),
                sjobid  = character(),
                status  = character(),
                state  = character(),
                reason  = character(),
                error  = character(),
                done  = logical(),
                finish  = character()
             )
          },
          stop('Database must be one of "db" or "jbd"')
   )
   save_database(database)
   message('New database ', database, ' created')
   
}