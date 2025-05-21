#' a test thingy
#' 
#' Rep 2 will throw an error, and rep 4 will blow out memory
#' 
#' @param rep Rep number
#' @param file File to write to
#' @export

batch_test <- function(rep, file = '/work/pi_cschweik_umass_edu/batch_test/btest/test_') {
   
   item <- paste0('hello ', format(Sys.time()), '\nNode: ', Sys.info()[['nodename']], '\n')
   writeLines(item, f <- paste0(file, rep, '.txt'))
   cat('Stuff written to ', f, '\n', sep = '')
   if(rep == 2)
      stop('We hate job #2')
   if(rep == 4) {
      cat('Time to blow out memory...\n')
      x <- 1:1e9
      cat('We\'re now crashed\n')
   }
   Sys.sleep(30)
}