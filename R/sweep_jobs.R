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
#' Since `info` calls `sweep_jobs` by default, `info` is the normal user-facing function for updating
#' the jobs database, though calling `sweep_jobs` is functionally equivalent to calling `info()`, so 
#' take your pick.
#' 
#' @param stats If TRUE, fills in run stats
#' @param quiet If TRUE, don't say anything; otherwise does info('summary') at the end
#' @importFrom batchtools loadRegistry getStatus getLog getErrorMessages
#' @importFrom lubridate time_length interval now
#' @importFrom stringr word
#' @export


sweep_jobs <- function(stats = TRUE, quiet = FALSE) {
   
   
   load_slu_database('jdb')
   
   if(!all(slu$jdb$done)) {                                                                                 # if all jobs are done, we've nothing to do                                                                          
      if(!dir.exists(slu$logdir))                                                                           # create log dir if need be
         dir.create(slu$logdir, recursive = TRUE)
      
      
      trying <- (1:nrow(slu$jdb))[!slu$jdb$done & !is.na(slu$jdb$sjobid)]                                   # jobs that aren't done yet, but did get a Slurm job id
      if(length(trying) > 0) {
         oldest <- ceiling(time_length(interval(min(
            slu$jdb$launched[trying], na.rm = TRUE), now()), 'day'))                                        # oldest unfinished job in days
         x <- get_job_state(days = oldest)                                                                  # get state for all jobs, reaching back far enough to get oldest unfinished job
         y <- merge(slu$jdb[trying, 'sjobid', drop = FALSE], x, 
                    by.x = 'sjobid', by.y = 'JobID', all.x = TRUE)
         slu$jdb[trying, c('state', 'reason')] <- y[, c('State', 'Reason')]                                 # set state and reason
      }
      
      
      over <- c('COMPLETED', 'CANCELLED', 'DEADLINE', 'FAILED', 'NODE_FAIL', 
                'OUT_OF_MEMORY', 'PREEMPTED', 'SUSPENDED', 'TIMEOUT')
      newdone <- (1:nrow(slu$jdb))[!slu$jdb$done & !is.na(slu$jdb$state) & (slu$jdb$state %in% over)]       # newly-completed jobs
      

      for(i in newdone) {
         slu$jdb[i, c('error', 'message')] <- getErrorMessages(slu$jdb$bjobid[i], reg = suppressMessages(
            loadRegistry(file.path(slu$regdir, slu$jdb$registry[i]))))[, c('error', 'message')]             # get error messages
         
         f <- paste0('job_', formatC(slu$jdb$jobid[i], width = 4, format = 'd', flag = 0), '.log')
         
         err <- tryCatch({
            suppressWarnings(writeLines(getLog(slu$jdb$bjobid[i]), file.path(slu$logdir, f)))               # save log file
            slu$jdb$log[i] <- f
         },
         error = function(cond)                                                                             # if no log file, just save ''
            slu$jdb$log[i] <- ''
         )
      }
      slu$jdb$message[newdone] <- sub('^.*: \\n  ', '', slu$jdb$message[newdone])                           # we just want juicy part of error message
      
      
      if(stats) {
         for(i in newdone) {                                                                                # get job stats
            x <- get_job_efficiency(slu$jdb$sjobid[i], slu$login_node)
            if(!is.null(x)) {
               x$cpu_pct <- as.numeric(sub('%.*$', '', x$cpu_efficiency))
               slu$jdb[i, c('mem_gb', 'walltime', 'cpu', 'cpu_pct')] <- 
                  x[c('mem_gb', 'walltime', 'cpu_utilized', 'cpu_pct')]
            }
         }
      }
      
      notdone <- (1:nrow(slu$jdb))[!slu$jdb$done]                                                           # now, all jobs that aren't yet finished
      for(i in notdone) {                                                                                   # for each unfinished job, put together status message
         if(is.na(slu$jdb$state[i]))
            slu$jdb$status[i] <- 'pending'
         else
            switch(stringr::word(slu$jdb$state[i]),
                   'PENDING' = 
                      slu$jdb$status[i] <- 'queued',
                   'TIMEOUT' = 
                      slu$jdb$status[i] <- 'timeout',
                   'CANCELLED' = {
                      slu$jdb$status[i] <- 'killed'
                      newdone <- c(newdone, i)
                   },
                   'RUNNING' = 
                      slu$jdb$status[i] <- 'running',
                   'COMPLETING' = 
                      slu$jdb$status[i] <- 'running',
                   'COMPLETED' = {
                      if(slu$jdb$error[i])
                         slu$jdb$status[i] <- 'error'
                      else
                         slu$jdb$status[i] <- 'finished'
                   },
                   slu$jdb$status[i] <- 'failed'
            )
      }
      
      
      rows <- newdone[!is.na(slu$jdb$finish[newdone])]                                                      # we'll call finish functions for these newly-completed jobs, which include errors and other failures
      
      slu$jdb$done[newdone] <- TRUE                                                                         # mark newly-finished jobs as done
      save_slu_database('jdb')                                                                              # save the database before calling finish functions or deleting registries
      
      
      finrows <- rows[!is.na(slu$jdb$finish[rows])]                                                         # if any of these jobs have finish functions,
      if(length(finrows) > 0) {
         for(i in rows)                                                                                     #    call finish functions
            do.call(slu$jdb$finish[i], list(jobid = slu$jdb$jobid[i], status = slu$jdb$status[i]))
         slu$jdb$finish[rows] <- 'done'
         save_slu_database('jdb')                                                                           #    set finish to 'done' and save the database, yet again
      }
      
      
      x <- aggreg(slu$jdb$done, slu$jdb$registry, FUN = 'all', drop_by = FALSE)
      dropreg <- x$Group.1[x$x]                                                                             # registries that we're done with
      
      if(length(dropreg) > 0) {                                                                             # if any registries to delete
         rows <- slu$jdb$registry %in% dropreg                                                              #    rows to drop bjobid and registry from 
         slu$jdb[rows, c('bjobid', 'registry')] <- NA                                                       #    we're done with these
         
         unlink(file.path(slu$regdir, dropreg), recursive = TRUE)                                           #    nuke the registry directories
         
         save_slu_database('jdb')                                                                           #    save the database again
      }
   }
   
   
   if(!quiet)
      info(sweep = FALSE)                                                                                   # display info
}
