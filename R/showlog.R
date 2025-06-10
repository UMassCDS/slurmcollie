#' Prints the contents log file for a batch job
#' 
#' Logs for `slurmcollie` jobs are buried in a `batchtools` registry while the job is running,
#' and moved to the `slurmcollie` logs directory once the job is registered as done. This function
#' prints the current log file the job. Use [logfile] to get the current and final path for the
#' job's log file.
#' 
#' @param jobid A single `slurmcollie` batch jobid
#' @export


showlog <- function(jobid) {
   
   
   print_oneperline <- function(x)                                         # helper function to print one line per line with nice line numbers
      cat(sprintf(paste0('% ', floor(log10(length(x))) + 3,'s "%s"\n'), 
                  paste0("[", seq_along(x), "]"), x), sep = "")
   
   
   if(file.exists(f <- logfile(jobid)$now)) {
      x <- readLines(f)
      print_oneperline(x)
   }
   else
      message('Job is still queued')
}