#' Sweep up finished batch jobs
#' 
#' Checks status of all jobs in all registries. Fills database with run stats, then deletes all
#' registries that have been completely swept. Reports how many jobs have been swept, how many
#' successful, how many failed, and how many are still outstanding. If all registries have been
#' swept, we'll get to start over at reg001. Saves the database, of course!
#' 
#' Calls `finish` functions passed to `launch`, to, for example, update a parent database. These
#' are called for any newly-done jobs, whether they were successful or not. See [launch] for 
#' details.
#' 
#' Getting run stats (memory, CPU time, etc.) take about 75% of the execution time, so if you
#' don't need them and are impatient, use `stats = FALSE`.
#' 
#' Since `info` calls `sweep` by default, `info` is the normal user-facing function for updating
#' the jobs database, though calling `sweep` is functionally equivalent to calling `info()`, so 
#' take your pick.
#' 
#' @param stats If TRUE, fills in run stats
#' @param quiet If TRUE, don't say anything; otherwise does info('summary') at the end
#' @importFrom batchtools loadRegistry getStatus getLog getErrorMessages
#' @importFrom lubridate time_length interval now
#' @importFrom stringr word
#' @export


sweep <- function(stats = TRUE, quiet = FALSE) {
   
   
   load_database('jdb')
   
   if(!all(the$jdb$done)) {                                                                                 # if all jobs are done, we've nothing to do                                                                          
      if(!dir.exists(the$logdir))                                                                           # create log dir if need be
         dir.create(the$logdir, recursive = TRUE)
      
      
      trying <- (1:nrow(the$jdb))[!the$jdb$done & !is.na(the$jdb$sjobid)]                                   # jobs that aren't done yet, but did get a Slurm job id
      if(length(trying) > 0) {
         oldest <- ceiling(time_length(interval(min(
            the$jdb$launched[trying], na.rm = TRUE), now()), 'day'))                                        # oldest unfinished job in days
         x <- get_job_state(days = oldest)                                                                  # get state for all jobs, reaching back far enough to get oldest unfinished job
         y <- merge(the$jdb[trying, 'sjobid', drop = FALSE], x, 
                    by.x = 'sjobid', by.y = 'JobID', all.x = TRUE)
         the$jdb[trying, c('state', 'reason')] <- y[, c('State', 'Reason')]                                 # set state and reason
      }
      
      
      newdone <- (1:nrow(the$jdb))[!the$jdb$done & !is.na(the$jdb$state) & (the$jdb$state == 'COMPLETED')]  # newly-completed jobs
      for(i in newdone) {
         the$jdb[i, c('error', 'message')] <- getErrorMessages(the$jdb$bjobid[i], reg = suppressMessages(
            loadRegistry(file.path(the$regdir, the$jdb$registry[i]))))[, c('error', 'message')]             # get error messages
         
         f <- paste0('job_', formatC(the$jdb$jobid[i], width = 4, format = 'd', flag = 0), '.log')
         writeLines(getLog(the$jdb$bjobid[i]), file.path(the$logdir, f))                                    # save log file
         the$jdb$log[i] <- f
      }
      the$jdb$message[newdone] <- sub('^.*: \\n  ', '', the$jdb$message[newdone])                           # we just want juicy part of error message
      
      
      if(stats) {
         for(i in newdone) {                                                                                # get job stats
            x <- get_job_efficiency(the$jdb$sjobid[i])
            x$cpu_pct <- as.numeric(sub('%.*$', '', x$cpu_efficiency))
            the$jdb[i, c('cores', 'mem_gb', 'walltime', 'cpu', 'cpu_pct')] <- 
               x[c('cores', 'mem_gb', 'walltime', 'cpu_utilized', 'cpu_pct')]
         }
      }
      
      notdone <- (1:nrow(the$jdb))[!the$jdb$done]                                                           # now, all jobs that aren't yet finished
      for(i in notdone) {                                                                                   # for each unfinished job, put together status message
         if(is.na(the$jdb$state[i]))
            the$jdb$status[i] <- 'pending'
         else
            switch(stringr::word(the$jdb$state[i]),
                   'PENDING' = the$jdb$status[i] <- 'queued',
                   'TIMEOUT' = the$jdb$status[i] <- 'timeout',
                   'CANCELLED' = {
                      the$jdb$status[i] <- 'killed'
                      newdone <- c(newdone, i)
                   },
                   'RUNNING' = the$jdb$status[i] <- 'running',
                   'COMPLETING' = the$jdb$status[i] <- 'running',
                   'COMPLETED' = {
                      if(the$jdb$error[i])
                         the$jdb$status[i] <- 'error'
                      else
                         the$jdb$status[i] <- 'finished'
                   },
                   the$jdb$status[i] <- 'failed'
            )
      }
      
      
      rows <- newdone[!is.na(the$jdb$finish[newdone])]                                                      # we'll call finish functions for these newly-completed jobs, which include errors and other failures
      
      the$jdb$done[newdone] <- TRUE                                                                         # mark newly-finished jobs as done
      save_database('jdb')                                                                                  # save the database before calling finish functions or deleting registries
      
      
      finrows <- rows[!is.na(the$jdb$finish[rows])]                                                         # if any of these jobs have finish functions,
      if(length(finrows) > 0) {
         for(i in rows)                                                                                     #    call finish functions
            do.call(the$jdb$finish[i], list(jobid = the$jdb$jobid[i], status = the$jdb$status[i]))
         the$jdb$finish[rows] <- 'done'
         save_database('jdb')                                                                               #    set finish to 'done' and save the database, yet again
      }
      
      
      x <- aggreg(the$jdb$done, the$jdb$registry, FUN = 'all', drop_by = FALSE)
      dropreg <- x$Group.1[x$x]                                                                             # registries that we're done with
      
      if(length(dropreg) > 0) {                                                                             # if any registries to delete
         rows <- the$jdb$registry %in% dropreg                                                              #    rows to drop bjobid and registry from 
         the$jdb[rows, c('bjobid', 'registry')] <- NA                                                       #    we're done with these
         
         unlink(file.path(the$regdir, dropreg), recursive = TRUE)                                           #    nuke the registry directories
         
         save_database('jdb')                                                                               #    save the database again
      }
   }
   
   
   if(!quiet)
      info(what = 'summary', sweep = FALSE)                                                                 # display info
}
