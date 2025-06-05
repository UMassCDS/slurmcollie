#' a test finish function for launch and sweep_jobs
#' 
#' @param jobid Job ids to finish for
#' @param status Job status

launch_test_finish <- function(jobid, status) {
   
   
   message('launch_test_finish called for job ', paste0(jobid, collapse = ', '), ', and status ', paste0(status, collapse = ', '))
}