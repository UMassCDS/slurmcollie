#' Kill launched Slurm jobs
#' 
#' Uses Slurm `scancel` to kill jobs. This won't work for jobs that haven't reported a Slurm JobID yet,
#' so you'll need to run `sweep` before running this. It also fail for jobs that haven't reported back
#' to batchtools.
#' 
#' This can't be done via `batchtools`, as there may be registry conflicts between running jobs and
#' attempts to load the registry for `killJobs`, so we're going directly to Slurm.
#' 
#' @param jobids One or more job ids
#' @param quiet If TRUE, don't complain about jobs not found nor report on killed jobs
#' @importFrom batchtools runOSCommand
#' @export


kill <- function(jobids, quiet = FALSE) {
   
   
   load_database('jdb')
   
   rows <- match(jobids, the$jdb$jobid)                                                            # get rows of jobids in database
   if(!quiet & any(is.na(rows)))                                                                   # deal with missing jobs
      message('Jobids ', paste(jobids[is.na(rows)], collapse = ', '), ' don\'t exist')
   rows <- rows[!is.na(rows)]
   if(length(rows) == 0)
      return(invisible())
   
   
   alreadydone <- rows[the$jdb$done[rows]]
   if(!quiet & any(alreadydone))                                                                   # are any of these jobs already done?
      message('Job ', paste(alreadydone, collapse = ', '), ' already done')
   rows <- rows[!rows %in% alreadydone]
   if(length(rows) == 0)
      return(invisible())
   
   
   sjobids <- the$jdb$sjobid[rows]                                                                 # get Slurm job ids
   if(!quiet & any(is.na(sjobids)))                                                                # deal with missing jobs
      message('We don\'t have Slurm ids for jobs ', 
              paste(the$jdb$jobid[rows[is.na(sjobids)]], collapse = ', '), 
              '--try running sweep() first')
   sjobids <- sjobids[!is.na(sjobids)]
   if(length(sjobids) == 0)
      return(invisible())
   
   rows <- match(sjobids, the$jdb$sjobid)                                                          # jobs we can actually cancel
   
   cmd <- paste(c('scancel', sjobids), collapse = ' ')
   a <- batchtools::runOSCommand(cmd, nodename = the$login_node)
   if(a$exit.code != 0) {
      stop("scancel command failed")
   }
   
   the$jdb$status[rows] <- 'killed'                                                                # update database
   the$jdb$done[rows] <- TRUE
   the$jdb$state[rows] <- 'CANCELLED'                                                              # cheating here, as this is what Slurm will set state too, and we're calling it done
   
   for(i in rows) {                                                                                # get log files for killed jobs
      suppressMessages(loadRegistry(file.path(the$regdir, the$jdb$registry[i])))
      f <- paste0('job_', formatC(the$jdb$jobid[i], width = 4, format = 'd', flag = 0), '.log')
      writeLines(getLog(the$jdb$bjobid[i]), file.path(the$logdir, f))                        
   }
   
   
   save_database('jdb')
   
   if(!quiet)
      message('Killed ', length(rows), ' jobs (jobs ', paste(the$jdb$jobid[rows], collapse = ', '), ')')
}