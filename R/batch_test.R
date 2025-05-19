#' a test thingy
#' 
#' @param rep Rep number
#' @param file File to write to
#' @export

batch_test <- function(rep, file = '/work/pi_cschweik_umass_edu/batch_test/btest/test_') {
   
   item <- paste0('hello ', format(Sys.time()), '\nNode: ', Sys.info()[['nodename']], '\n')
   writeLines(item, f <- paste0(file, rep, '.txt'))
   cat('Stuff written to ', f, '\n', sep = '')
   Sys.sleep(30)
}