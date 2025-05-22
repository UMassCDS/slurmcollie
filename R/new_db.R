#' Create a new database 
#' 
#' Creates a new empty fits database (`db`) or jobs database (`jdb`). This is a drastic
#' function, intended to be used only when initially creating a database or when an existing
#' database is a hopeless mess. Use with great care--this
#' function will destroy any existing database. It deletes the existing database and backups,
#' as well as all logs, and saves an empty database to disk immediately.
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
                jobid = integer(),
                launched = as.POSIXct(character()),
                call = character(),
                bjobid = integer(),
                registry = character(),
                sjobid = character(),
                status = character(),
                state = character(),
                reason = character(),
                done = logical(),
                error = character(),
                message = character(),
                finish  = character(),
                cores = integer(),
                mem_gb = double(),
                walltime = character(),
                cpu = character(),
                cpu_pct = character(),
                comment = character()
             )
             
             unlink(file.path(the$dbdir, paste0(database, '*.RDS')))          # delete old database and backups
             unlink(paste0(the$logdir, 'job*.txt'))                           # delete abandoned logs
          },
          stop('Database must be one of "db" or "jdb"')
   )
   save_database(database)
   message('New database ', database, ' created')
   
}