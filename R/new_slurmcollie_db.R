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
                jobid = integer(),                          # slurmcollie job id
                launched = as.POSIXct(character()),         # date and time job was launched
                call = character(),                         # name of called function
                rep = character(),                          # Vector, list, or data frame to vectorize call over
                callerid = character(),                     # Optional character id allowing caller to track jobs on its terms
                local = logical(),                          # TRUE if calling as a local job, FALSE if batch
                bjobid = integer(),                         # batchtools job id
                registry = character(),                     # batchtools registry file name
                sjobid = character(),                       # Slurm job id
                status = character(),                       # slurmcollie job status
                state = character(),                        # Slurm job state
                reason = character(),                       # Slurm job reason
                done = logical(),                           # TRUE if job is complete
                error = character(),                        # TRUE if there was an error
                message = character(),                      # error message
                finish  = character(),                      # name of function to be called by info when job is finished
                cores = integer(),                          # number of CPU cores to request
                cpu = character(),                          # CPU time used (hh:mm:ss)
                cpu_pct = character(),                      # percent CPU used
                mem_req = double(),                         # memory requested (GB)
                mem_gb = double(),                          # memory used (GB)
                walltime = character(),                     # elapsed job time (hh:mm:ss)
                log = character(),                          # name of log file
                comment = character()                       # user or generated job comment
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