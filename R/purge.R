#' Purge selected jobs from the jobs database
#'
#' Purges jobs and their logs.
#'
#' @param filter Either a vector of `jobids` or a named list to filter jobs
#'   with. List items are `<field in jdb> = <value>`, where <value> is a regex
#'   for character fields, or an actual value (or vector of values) for logical
#'   or numeric fields.
#' @param quiet If TRUE, don't chatter
#' @export


purge <- function(filter = NULL, quiet = FALSE) {
   
   
   load_database('jdb')
   
   
   if(is.null(filter))
      stop('You must supply jobids or a list of fields and values')
   
   rows <- filter_jobs(filter)
   
   for(i in rows)                                                       # delete logs
      if(!is.na(the$jdb$log[i]))
         unlink(file.path(the$logdir, the$jdb$log[i]))
   
   
   the$jdb <- the$jdb[-rows, ]                                          # drop purged rows of database
   
   
   save_database('jdb')
   
   if(!quiet)
      message('Purged ', length(rows), ' jobs')
}