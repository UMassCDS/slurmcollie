#' Sweep up finished batch jobs
#' 
#' Checks status of all jobs in all registries. Fills database with run stats, then deletes all
#' registries that have been completely swept. Reports how many jobs have been swept, how many
#' successful, how many failed, and how many are still outstanding. If all registries have been
#' swept, we'll get to start over at reg001. Saves the database, of course!
#' 
#' @importFrom batchtools loadRegistry getStatus getLog
#' @importFrom lubridate time_length interval now
#' @export


sweep <- function() {
   
   
   load_database('jdb')
   
   if(all(the$jdb$done))                                                                                 # if all jobs are done, we've nothing to do                                                                          
      return(invisible())
   
   
   if(!dir.exists(the$logdir))                                                                           # create log dir if need be
      dir.create(the$logdir, recursive = TRUE)
   
   
   noslurmid <- (1:nrow(the$jdb))[is.na(the$jdb$sjobid)]                                                 # get Slurm job ids
   for(i in noslurmid)
      the$jdb$sjobid[i] <- get_job_id(the$jdb$bjobid[i], suppressMessages(
         loadRegistry(file.path(the$regdir, the$jdb$registry[i]))))
   
   
 ###  the$jdb$status[!the$jdb$done & !is.na(the$jdb$sjobid)] <- 'unqueued' 
 ###  I have a job that I killed that has no Slurm job id according to batchtools, but I somehow got a COMPLETED state. That doesn't seem possible.
   
   
   trying <- (1:nrow(the$jdb))[!the$jdb$done & !is.na(the$jdb$sjobid)]                                   # jobs that aren't done yet, but did get a Slurm job id
   oldest <- ceiling(time_length(interval(min(
      the$jdb$launched[trying], na.rm = TRUE), now()), 'day'))                                           # oldest unfinished job in days
   x <- get_job_state(days = oldest)                                                                     # get state for all jobs, reaching back far enough to get oldest unfinished job
   y <- merge(the$jdb[trying, 'sjobid', drop = FALSE], x, 
              by.x = 'sjobid', by.y = 'JobID', all.x = TRUE)
   the$jdb[trying, c('state', 'reason')] <- y[, c('State', 'Reason')]                                    # set state and reason
   
   
   newdone <- (1:nrow(the$jdb))[(the$jdb$state == 'COMPLETED') & !the$jdb$done]                          # newly-completed jobs
   for(i in newdone) {
      the$jdb[i, c('error', 'message')] <- getErrorMessages(the$jdb$bjobid[i], reg = suppressMessages(
         loadRegistry(file.path(the$regdir, the$jdb$registry[i]))))[, c('error', 'message')]             # get error messages
      
      f <- paste0('log_', formatC(i, width = 4, format = 'd', flag = 0, '.txt'))
      writeLines(getLog(i), file.path(the$logdir, f))                                                    # save log file
   }
   the$jdb$message[newdone] <- sub('^.*: \\n  ', '', the$jdb$message[newdone])                           # we just want juicy part of error message
   
   
   
   for(i in newdone) {                                                                                   # get job stats
      x <- get_job_efficiency(get_job_id(i))
      x$cpu_pct <- as.numeric(sub('%.*$', '', x$cpu_efficiency))
      the$jdb[i, c('cores', 'mem_gb', 'walltime', 'cpu', 'cpu_pct')] <- 
         x[c('cores', 'mem_gb', 'walltime', 'cpu_utilized', 'cpu_pct')]
   }
   
   notdone <- (1:nrow(the$jdb))[!the$jdb$done]                                                           # now, all jobs that aren't yet finished
   for(i in notdone) {                                                                                   # for each unfinished job, put together status message
      if(is.null(the$jdb$sjobid[i])) 
         the$jdb$status[i] <- 'pending'
      else { 
         if(the$jdb$state[i] == 'PENDING') 
            the$jdb$status[i] <- 'queued'
         else { 
            if(the$jdb$state[i] == 'TIMEOUT') 
               the$jdb$status[i] <- 'timeout'
            else {
               if(the$jdb$state[i] %in% c('RUNNING', 'COMPLETING')) 
                  the$jdb$status[i] <- 'running'
               else {
                  if(the$jdb$state[i] == 'COMPLETED') {
                     if(error)
                        the$jdb$status[i] <- 'error'
                     else
                        the$jdb$status[i] <- 'finished'
                  }
                  else 
                     the$jdb$status[i] <- 'failed'
               }
            }
         }
      }
   }
   
   the$jdb$done[newdone] <- TRUE                                                                         # mark newly-finished jobs as done
   
   
   # for each registry,
   # 	if all jobs are done,
   # 	   copy log files to logsdir, renamed by joid   (*** new_db clears logs directory, I think)
   # 		removeRegistry
   # 		clear bjobid and registry fields for these!!
   
   
   # if we have finish_with, call the function with ids of newly-completed jobs  
   
   
   # display info
   
   
   
   # debugging: check logs, stats, state, status
   
   
   
   
}