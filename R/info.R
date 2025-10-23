#' Give info on batch jobs
#'
#' Provides information on jobs in the batch jobs database. Options allow for
#' selecting columns, filtering, sorting, and displaying a brief summary or a
#' complete table. Normally, `sweep_jobs` is called up front to update the database,
#' so there may be a delay of a second or two.
#' 
#' Note that memory is always reported in GB.
#' 
#' Also note that local calls will not record `cores`, `cpu`, `cpu_pct`, nor `mem_req`.
#' They do record mem_gb and walltime.
#'
#' @param rows Specify jobs with one of:
#'  - a vector of `jobids`
#'  - 'all' for all jobs
#'  - a named list to filter jobs with. List items are `<field in jdb> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @param cols Specifies which columns to include in the jobs table. May be
#'   one of
#'   - *brief* (1) includes `jobid`, `status`, `error`, `comment`
#'   - *normal* (2)  includes `jobid`, `launched`, `called_fn`, `rep`, `local`, `status`, 
#'      `error`, `cores`, `cpu_pct`, `mem_gb`, `walltime`, `comment`
#'   - *long* (3) includes `jobid`, `launched`, `called_fn`, `rep`, `local`, `sjobid`, `status`, 
#'      `state`, `reason`, `error`, `message`, `done`, `cores`, `mem_req`, `mem_gb`, `walltime`, 
#'      `cpu`, `cpu_pct`, `log`, `comment`, `call`
#'   - *all* (4) includes all columns
#'   - 1, 2, 3, or 4 is a shortcut for the above column sets
#'   - A vector of column names to include
#' @param sort The name of the column to be used to sort the table
#' @param decreasing If TRUE, sort in descending order
#' @param nrows Number of rows to display in the jobs table. Positive numbers
#'   display the first *n* rows, and negative numbers display the last *n* rows.
#'   Use `nrows = NA` to display all rows.
#' @param summary If TRUE, displays jobs summary
#' @param table If TRUE, displays jobs table
#' @param sweep If TRUE, call `sweep_jobs` to update jobs database first
#' @param timezone Time zone for launch time; use NULL to leave times in native UTC
#' @returns The processed jobs table, invisibly
#' @importFrom lubridate with_tz
#' @export


info <- function(rows = 'all', cols = 'normal', sort = 'jobid', decreasing = FALSE, nrows = NA, 
                 summary = TRUE, table = TRUE, sweep = TRUE, timezone = 'America/New_York') {
   
   if(sweep)
      sweep_jobs(quiet = TRUE)
   else
      load_slu_database('jdb')
   
   if(dim(slu$jdb)[1] == 0) {
      message('No jobs in database')
      return(invisible())
   }
   
   
   if(summary) {
      x <- data.frame(table(slu$jdb$status))
      x <- data.frame(cbind(status = as.character(x[, 1]), jobs = x[, 2]))
      ordering <- data.frame(status = c('pending', 'queued', 'running', 'finished', 'error', 'killed', 'timeout', 'failed'), order = 1:8)
      y <- x[order(merge(x, ordering, by = 'status')$order), ]
      
      if(any(!slu$jdb$done))
         message(sum(!slu$jdb$done), ' job', ifelse(sum(!slu$jdb$done) != 1, 's', ''), ' not done\n')
      else
         message('All jobs done\n')
      
      print(y, row.names = FALSE)
   }
   
   # Now put together jobs table, whether we print it or not, as it's also returned
   
   z <- slu$jdb[filter_jobs(rows), ]                                                                  # jobs database, filtered
   z <- z[order(z[, sort], decreasing = decreasing), ]                                                # and sorted
   
   z$mem_gb <- round(z$mem_gb, 3)
   
   if(!is.na(nrows)) {                                                                                # display just selected rows
      if(nrows > 0)
         z <- z[1:nrows, ]
      else
         z <- z[(dim(z)[1] + nrows + 1):(dim(z)[1]), ] 
   }
   
   
   if(!is.null(timezone))                                                                             # if time zone supplied,
      z$launched <- with_tz(z$launched, timezone)                                                     #    format launch time in eastern time zone
   
   
   z$local <- ifelse(is.na(z$local), '', ifelse(z$local, 'local', 'remote'))                          # prettier formatting for local, error, and done
   z$error <- ifelse(is.na(z$error), '', ifelse(z$error, 'error', 'ok'))  
   z$done <- ifelse(is.na(z$done), '', ifelse(z$done, 'done', '...'))  
   
   
   if(is.numeric(cols))                                                                               # print only requested columns
      if(cols %in% 1:4)
         cols <- c('brief', 'normal', 'long', 'all')[cols]
   if(!identical(cols, 'all')) {
      if(cols[1] %in% c('brief', 'normal', 'long', 'all'))
      cols <- switch(cols,
                   brief = c('jobid', 'status', 'error', 'comment'),
                   normal = c('jobid', 'launched', 'called_fn', 'rep', 'local', 'status', 'error', 
                              'cores', 'cpu_pct', 'mem_gb', 'walltime', 'comment'),
                   long = c('jobid', 'launched', 'called_fn', 'rep', 'local', 'sjobid', 'status', 'state', 
                            'reason', 'error', 'message', 'done', 'cores', 'cpu', 'cpu_pct', 
                            'mem_req', 'mem_gb', 'walltime', 'log', 'comment', 'callerid', 'call')
      )
      
      if(any(!cols %in% names(z)))
         stop('Undefined column names requested: ', paste(cols[!cols %in% names(z)], collapse = ', '))
      
      z <- z[, c(setdiff('jobid', cols), cols), drop = FALSE]                                         # always include job id
   }
   
   if(summary & table)
      cat('\n')
   
   if(table) {
      mp <- getOption('max.print')
      on.exit(options(max.print = mp))
      options(max.print = 20000)
      
      print(z, row.names = FALSE, na.print = '')
   }
   
   return(invisible(z))
}
