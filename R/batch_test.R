#' a test thingy
#' 
#' Rep 2 will throw an error, and rep 4 will blow out memory
#' 
#' @param rep Rep number
#' @param wait Minutes to wait before doing anything
#' @param file File to write to
#' @param jobid Get the job id
#' @importFrom stats runif
#' @export

batch_test <- function(rep, wait = 0, file = '/work/pi_cschweik_umass_edu/batch_test/btest/test_', jobid = 'none') {
   
   Sys.sleep(wait * 60)
   
   item <- paste0('hello ', format(Sys.time()), '\nNode: ', Sys.info()[['nodename']], '\nJob id: ', jobid, '\n')
   writeLines(item, f <- paste0(file, rep, '.txt'))
   cat('Stuff written to ', f, '\n', sep = '')
   cat(item, '\n')
   if(rep == 2)
      stop('We hate job #2')
   if(rep == 4) {
      cat('Time to blow out memory...\n')
      x <- sum(1:1e12)
      cat('We\'re now crashed\n')
   }

   Sys.sleep(10 * 6 * runif(6))              # random wait up to 1 minute before finishing
}