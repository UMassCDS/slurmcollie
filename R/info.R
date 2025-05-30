#' Give info on batch jobs
#'
#' Provides information on jobs in the batch jobs database. Options allow for
#' selecting columns, filtering, sorting, and displaying a brief summary or a
#' complete table. Normally, `sweep` is called up front to update the database,
#' so there may be a delay of a second or two.
#'
#' @param columns Specifies which columns to include in the jobs table. May be
#'   one of
#'   - *brief* (1) includes `jobid`, `status`, `error`, `comment`
#'   - *normal* (2)  includes `jobid`, `status`, `message`, `comment`
#'   - *long* (3) includes `jobid`, `sjobid`, `status`, `state`, `reason`, `error`, `message`,
#'      `done`, `cores`, `gb`, `walltime`, `cpu`, `cpu_pct`, `log`, `comment`
#'   - *all* (4) includes all columns
#'   - 1, 2, 3, or 4 is a shortcut for the above column sets
#'   - A vector of column names to include
#' @param filter Specify jobs with one of:
#'  - a vector of `jobids`
#'  - 'all' for all jobs
#'  - a named list to filter jobs with. List items are `<field in jdb> = <value>`, 
#'    where `<value>` is a regex for character fields, or an actual value (or vector of 
#'    values) for logical or numeric fields.
#' @param sort The name of the column to be used to sort the table
#' @param decreasing If TRUE, sort in descending order
#' @param nrows Number of rows to display in the jobs table. Positive numbers
#'   display the first *n* rows, and negative numbers display the last *n* rows.
#'   Use `nrows = NA` to display all rows.
#' @param summary If TRUE, displays jobs summary
#' @param table If TRUE, displays jobs table
#' @param sweep If TRUE, call `sweep` to update jobs database first
#' @param timezone Time zone for launch time; use NULL to leave times in native UTC
#' @returns The processed jobs table, invisibly
#' @importFrom lubridate with_tz
#' @export


info <- function(columns = 'normal', filter = 'all', sort = 'jobid', decreasing = FALSE, nrows = NA, 
                 summary = TRUE, table = TRUE, sweep = TRUE, timezone = 'America/New_York') {
   
   if(sweep)
      sweep(quiet = TRUE)
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
   
   z <- slu$jdb[filter_jobs(filter), ]                                                                # jobs database, filtered
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
   
   
   if(is.numeric(columns))                                                                            # print only requested columns
      if(columns %in% 1:4)
         columns <- c('brief', 'normal', 'long', 'all')[columns]
   if(columns != 'all') {
      co <- switch(columns,
                   brief = c('jobid', 'status', 'error', 'comment'),
                   normal = c('jobid', 'status', 'error', 'message', 'cores', 'mem_gb', 'walltime', 'cpu', 'cpu_pct', 'comment'),
                   long = c('jobid', 'sjobid', 'status', 'state', 'reason', 'error', 'message', 'done', 'cores', 'mem_gb', 'walltime', 'cpu', 'cpu_pct', 'log', 'comment')
      )
      z <- z[, co]
   }
   
   if(summary & table)
      cat('\n')
   
   if(table)
      print(z, row.names = FALSE, na.print = '')
   
   return(invisible(z))
}
