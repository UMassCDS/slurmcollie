#' Kill launched Slurm jobs
#'
#' Uses Slurm `scancel` to kill jobs. This can't be done via `batchtools`, as
#' there may be registry conflicts between running jobs and attempts to load the
#' registry for `killJobs`, so we're going directly to Slurm.
#'
#' @param filter Specify jobs with one of:
#'  - a vector of `jobids`
#'  - 'all' for all jobs
#'  - a named list to filter jobs
#'    with. List items are `<field in jdb> = <value>`, where <value> is a regex
#'    for character fields, or an actual value (or vector of values) for logical
#'    or numeric fields.
#' @param quiet If TRUE, don't complain about jobs not found nor report on
#'   killed jobs
#' @importFrom batchtools runOSCommand
#' @export


kill <- function(filter = NULL, quiet = FALSE) {
   
   
   load_database('jdb')
   
   
   if(is.null(filter))
      stop('You must supply jobids or a list of fields and values')
   
   rows <- filter_jobs(filter)
   
   
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
   rows <- match(sjobids, the$jdb$sjobid)                                                          # jobs we can actually cancel
   
   cmd <- paste(c('scancel', sjobids), collapse = ' ')
   a <- batchtools::runOSCommand(cmd, nodename = the$login_node)
   if(a$exit.code != 0) {
      stop("scancel command failed")
   }
   
   
   for(i in rows) {                                                                                # get log files for killed jobs
      suppressMessages(loadRegistry(file.path(the$regdir, the$jdb$registry[i])))
      f <- paste0('job_', formatC(the$jdb$jobid[i], width = 4, format = 'd', flag = 0), '.log')
      x <- suppressWarnings(try(writeLines(getLog(the$jdb$bjobid[i]), 
                                      file.path(the$logdir, f)), silent = TRUE))                   # get log if it's available; it may not be for early kills
      if(!inherits(x, "try-error"))
         the$jdb$log[i] <- f
   }
   
   
   save_database('jdb')
   
   if(!quiet)
      message('Killed ', length(rows), ' jobs (jobs ', paste(the$jdb$jobid[rows], collapse = ', '), ')')
}