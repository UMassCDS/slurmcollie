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
   
   
   
   
   
}