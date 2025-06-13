#' Create a new jobs database for the slurmcollie package
#' 
#' Creates a new empty jobs database (`jdb`). This is a
#' drastic function, intended to be used only when initially creating a database
#' or when an existing database is a hopeless mess. Use with great care--this
#' function will destroy any existing database and backups. When creating a new
#' jobs database (`jdb`), it also deletes all logs and registries, and saves an
#' empty database to disk immediately. **This function is drastic and
#' unrecoverable.**
#' 
#' @param database Name of database (should be `jdb`)
#' @param really If TRUE, creates database, **destroying existing database**
#' @export 


new_slurmcollie_db <- function(database = 'jdb', really = FALSE) {
   
   
   if(!really)
      stop('Database ', database, ' won\'t be created unless you use really = TRUE. This will DESTROY your existing database.')
   
   switch(database,
          'db' = {
             
             
          },
          
          'jdb' = {
             slu$jdb <- data.frame(
                jobid = integer(),
                launched = as.POSIXct(character()),
                call = character(),
                rep = character(),
                local = logical(),
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
                mem_req = double(),
                mem_gb = double(),
                walltime = character(),
                cpu = character(),
                cpu_pct = character(),
                log = character(),
                comment = character()
             )
             
             unlink(file.path(slu$dbdir, paste0(database, '*.RDS')))             # delete old database and backups
             unlink(file.path(slu$logdir, 'job_*.log'))                          # delete abandoned logs
             unlink(file.path(slu$regdir, '*'), recursive = TRUE)                # delete all batchtools registries
          },
          stop('Database must be one of "db" or "jdb"')
   )
   save_slu_database(database)
   message('New jobs database ', database, ' created')
   
}