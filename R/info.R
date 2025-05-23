#' Give info on batch jobs
#' 
#' This is a stub for now. See notes in Obsidian, and compare with Anthill INFO/info()
#' 
#' @param what One of `summary`, ...
#' @param sweep If TRUE, call `sweep` to update jobs database first
#' @export


info <- function(what = 'summary', sweep = TRUE) {
   
   if(sweep)
      sweep(quiet = TRUE)
   else
      load_database('jdb')
   
   z <- switch(what,
          summary = {
             x <- data.frame(table(the$jdb$status))
             x <- data.frame(cbind(status = as.character(x[, 1]), jobs = x[, 2]))
             ordering <- data.frame(status = c('pending', 'queued', 'running', 'finished', 'error', 'killed', 'timeout', 'failed'), order = 1:8)
             x[order(merge(x, ordering, by = 'status')$order), ]
          })
   
   if(any(!the$jdb$done))
      message(sum(!the$jdb$done), ' jobs not yet done\n')
   else
      message('All jobs done\n')
   
   print(z, row.names = FALSE)
}
