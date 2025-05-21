#' Sweep up finished batch jobs
#' 
#' Checks status of all jobs in all registries. Fills database with run stats, then deletes all
#' registries that have been completely swept. Reports how many jobs have been swept, how many
#' successful, how many failed, and how many are still outstanding. If all registries have been
#' swept, we'll get to start over at reg001. Saves the database, of course!
#' 
#' @param registriesdir Directory containing `batchtools` registries
#' @importFrom batchtools loadRegistry getStatus 
#' @export


sweep <- function(registriesdir = the$registriesdir) {
   
   load_database('jdb')
   
   noslurmid <- (1:nrow(the$jdb))[is.na(the$jdb$sjobid)]                                              # get Slurm job ids
   for(i in noslurmid)
      the$jdb$sjobid[i] <- get_job_id(the$jdb$bjobid[i], suppressMessages(loadRegistry(file.path(the$regdir, the$jdb$registry[i]))))
   
   
   # find oldest outstanding job
   # get_job_status(days = ...)
   
   x <- get_job_status()
   y <- merge(the$jdb[!the$jdb$done, 'sjobid', drop = FALSE], x, by.x = 'sjobid', by.y = 'JobID')
   the$jdb[!the$jdb$done, c('status', 'reason')] <- y[, c('State', 'Reason')]

   
# for newly completed jobs, use getErrorMessages
# update my status accordingly
# set done <- TRUE
# 
# for each registry,
# 	if all jobs are done,
# 		removeRegistry
# 		clear bjobid and registry fields for these!!
# 
# if we have finish_with, call the function with ids of newly-completed jobs
# 
# display info
   
   
   
   for(i in 1:3) {
      x <- get_job_efficiency(get_job_id(i))
      x$cpu_pct <- as.numeric(sub('%.*$', '', x$cpu_efficiency))
      the$jdb[i, c('cores', 'mem_gb', 'walltime', 'cpu', 'cpu_pct')] <- x[c('cores', 'mem_gb', 'walltime', 'cpu_utilized', 'cpu_pct')]
   }
   
   
   
}