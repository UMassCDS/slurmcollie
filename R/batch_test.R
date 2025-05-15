#' a test thingy
#' @export

batch_test <- function(reps, file = '/work/pi_cschweik_umass_edu/batch_test/btest/test_') {
   
   item <- paste0('hello ', format(Sys.time()), '\nNode: ', Sys.info()[['nodename']], '\n')
   writeLines(item, f <- paste0(file, reps, '.txt'))
   cat('Stuff written to ', f, '\n', sep = '')
   Sys.sleep(30)
}