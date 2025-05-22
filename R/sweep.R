#' Sweep up finished batch jobs
#' 
#' Checks status of all jobs in all registries. Fills database with run stats, then deletes all
#' registries that have been completely swept. Reports how many jobs have been swept, how many
#' successful, how many failed, and how many are still outstanding. If all registries have been
#' swept, we'll get to start over at reg001. Saves the database, of course!
#' 
#' @importFrom batchtools loadRegistry getStatus 
#' @importFrom lubridate time_length interval now
#' @export


sweep <- function() {
   
   
   load_database('jdb')
   
   noslurmid <- (1:nrow(the$jdb))[is.na(the$jdb$sjobid)]                                              # get Slurm job ids
   for(i in noslurmid)
      the$jdb$sjobid[i] <- get_job_id(the$jdb$bjobid[i], suppressMessages(
         loadRegistry(file.path(the$regdir, the$jdb$registry[i]))))
   
   
   oldest <- ceiling(time_length(interval(min(the$jdb$launch[!the$jdb$done]), now()), 'day'))         # oldest unfinished job in days
   x <- get_job_state(days = oldest)                                                                  # get state for all jobs, reaching back far enough to get oldest unfinished job
   y <- merge(the$jdb[!the$jdb$done, 'sjobid', drop = FALSE], x, by.x = 'sjobid', by.y = 'JobID')
   the$jdb[!the$jdb$done, c('state', 'reason')] <- y[, c('State', 'Reason')]                          # set state and reason

   newdone <- (the$jdb$state == 'COMPLETED') & !the$jdb$done
   
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