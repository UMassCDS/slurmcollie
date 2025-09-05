#' Purge selected jobs from the jobs database
#'
#' Purges jobs and their logs.
#'
#' @param filter Specify jobs with one of:
#'  - a vector of `jobids`
#'  - 'all' for all jobs
#'  - a named list to filter jobs with. List items are `<field in jdb> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @param force If TRUE, purges jobs even if they're pending, queued, or running - don't
#'    do this casually!
#' @param quiet If TRUE, don't chatter
#' @export


purge <- function(filter = NULL, force = FALSE, quiet = FALSE) {
   
   
   load_slu_database('jdb')
   
   
   if(is.null(filter))
      stop('You must supply jobids or a list of fields and values')
   
   
   sweep_jobs(quiet = TRUE)                                             # make sure we're up to date
   
   
   rows <- filter_jobs(filter)
   
   if(length(rows) == 0)
      if(!quiet)
         message('No jobs specified')
   
   else {
      
      x <- slu$jdb$status[rows] %in% c('pending', 'queued', 'running')
      if(any(x) & !force)
         stop('You may not purge jobs that are pending, queued, or running--kill them first (jobs ', paste(slu$jdb$jobid[rows[x]], collapse = ', '), ')')
      
      
      for(i in rows)                                                       # delete logs
         if(!is.na(slu$jdb$log[i]))
            unlink(file.path(slu$logdir, slu$jdb$log[i]))
      
      
      slu$jdb <- slu$jdb[-rows, ]                                          # drop purged rows of database
      
      
      save_slu_database('jdb')
      
      if(!quiet)
         message('Purged ', length(rows), ' jobs')
   }
}