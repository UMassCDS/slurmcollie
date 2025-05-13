#' a test thingy
#' @export

batch_test <- function(reps, item = paste0('hello ', format(Sys.time())), file = '/work/pi_cschweik_umass_edu/marsh_mapping/btest/test_') {
   
   
  # x <- runif(matrix(1000, 1000, 1000))
   writeLines(item, f <- paste0(file, reps, '.txt'))
   cat('Stuff written to ', f, '\n', sep = '')
   Sys.sleep(30)
}