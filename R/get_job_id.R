#' Get the Slurm job id for the specified batchtools job id in the specified registry. If
#' the job.id doesn't exist, returns NA.
#' 
#' In order for this to work, you must add the following line to your Slurm template 
#' (slurm.tmpl): \cr \cr
#'    `echo $SLURM_JOB_ID > <%= log.file %>.slurmjobid`
#'
#' @param job.id The job.id of a batchtools job 
#' @param reg batchtools registry object
#' @importFrom batchtools getDefaultRegistry
#' @export


get_job_id <- function(job.id, reg = getDefaultRegistry()) {
   
   
   i <- reg$status$job.id == job.id
   if(!any(i))
      return(NA)
   
   readLines(file.path(reg$file.dir, 'logs', paste0(reg$status$job.hash[i], '.log.slurmjobid')))
}