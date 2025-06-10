#' Return the names of the log file for a batch job
#' 
#' @param jobid A single `slurmcollie` batch jobid
#' @returns A named list with:
#'    \item{running}{The path to the job's log file while it's running, before `slurmcollie` has
#'       marked it as `done`}
#'    \item{done}{The path to the job's log file once the job has been registered as `done` by
#'       `slurmcollie`}
#' @export


logfile <- function(jobid) {
   
   
    
   
}