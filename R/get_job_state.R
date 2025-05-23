#' Get the state of Slurm jobs
#' 
#' Gets the Slurm State and Reason codes for a specific job or all jobs launched
#' in the past n days.
#'
#' Either specify the `jobid` with the Slurm `JobID` to get the state for a
#' single job, or `days` to get the state for all jobs run in the past `days`
#' days. If you don't specify either, you'll get the Slurm default: jobs you
#' launched today.
#'
#' There is overhead for the Slurm call, so if processing several jobs, best to
#' use an adequate value for days and pull info on your jobs from the result.
#'
#' Only the primary `JobID`s are returned; `_batch`, `_extern`, and other
#' sidecar jobs are dropped.
#'
#' `get_job_state` uses the Slurm `sacct` command, and results differ slightly
#' from those returned by `squeue`. Interacting with Slurm requires setting up
#' `ssh` to connect to a login node.
#' 
#' @param jobid Slurm `JobID`
#' @param days Number of days to look back
#' @returns Data frame with `jobID`, `State`, and `Reason`
#' @importFrom batchtools runOSCommand
#' @export


get_job_state <- function(jobid = NULL, days = NULL) {
   
   
   cmd <- 'sacct -p -o JobID -o State -o Reason '
   
   if(!is.null(jobid))
      cmd <- paste0(cmd, '--job ', jobid)
   
   if(!is.null(days))
      cmd <- paste0(cmd, '--start=now-', days, 'days')
  
   
   a <- batchtools::runOSCommand(cmd, nodename = 'login1')
   if(a$exit.code != 0)
      stop('Slurm sacct call failed with exit code ', a$exit.code)
   
   x <- strsplit(a$output, '|', fixed = TRUE)
   x <- matrix(unlist(x), length(x), 3, byrow = TRUE)
   y <- data.frame(x[-1, , drop = FALSE])
   names(y) <- x[1, ]
   y <- y[grep('^\\d*$', y$JobID), ]
   y
}