#' Sweep up finished batch jobs
#' 
#' Checks status of all jobs in all registries. Fills database with run stats, then deletes all
#' registries that have been completely swept. Reports how many jobs have been swept, how many
#' successful, how many failed, and how many are still outstanding. If all registries have been
#' swept, we'll get to start over at reg001. Saves the database, of course!
#' 
#' @param registriesdir Directory containing `batchtools` registries
#' @importFrom batchtools getStatus
#' @export


sweep <- function(registriesdir = the$registriesdir) {
   
   load_database('jdb')
   
   
   
   for(i in 1:3) {
      x <- get_job_efficiency(get_job_id(i))
      x$cpu_pct <- as.numeric(sub('%.*$', '', x$cpu_efficiency))
      the$jdb[i, c('cores', 'mem_gb', 'walltime', 'cpu', 'cpu_pct')] <- x[c('cores', 'mem_gb', 'walltime', 'cpu_utilized', 'cpu_pct')]
   }
   
   
   
}