#' Return the names of the log file for a batch job
#' 
#' Logs for `slurmcollie` jobs are buried in a `batchtools` registry while the job is running,
#' and moved to the `slurmcollie` logs directory once the job is registered as done. This function
#' points to the current location of the log as well as the final location (where it may not yet 
#' be). You can use this for easy monitoring of logs via `cat` in Linux or by opening in an `SFTP`
#' client. Use [showlog] to simply print the current log.
#' 
#' @param jobid A single `slurmcollie` batch jobid
#' @returns A named list with:
#'    \item{now}{The path to the current log file for the job, which will be in the `batchtools` 
#'    registry while the job is running, and the `slurmcollie` logs folder once it's been marked as
#'    done by `slurmcollie`}
#'    \item{done}{The path to the job's log file once the job has been registered as `done` by
#'       `slurmcollie`}
#' @export


logfile <- function(jobid) {
   
   
   load_slu_database('jdb')
   i <- match(jobid, slu$jdb$jobid)
   if(is.na(i))
      stop('jobid ', jobid, ' not found')
   
   z <- list(now = '', done = '')
   z$done <- file.path(slu$logdir, paste0('job_', formatC(slu$jdb$jobid[i], width = 4, 
                                                          format = 'd', flag = 0), '.log'))  # the final location
   
   if(!slu$jdb$done[i])                                                                      # if job is still running,
      z$now <- file.path(slu$regdir, slu$jdb$registry[i], 'logs', 
                             paste0(getJobStatus(slu$jdb$bjobid[i])$job.hash, '.log'))       #    assemble logfile path
   else                                                                                      # else job is registered as done,
      z$now <- z$done                                                                        #    so there's no running path
   
   z
}