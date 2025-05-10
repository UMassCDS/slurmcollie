#' a test thingy
#' @export

batch_test <- function(reps, item = paste0('hello ', format(Sys.time())), file = '/work/pi_cschweik_umass_edu/marsh_mapping/reg/btest') {
   
   
   writeLines(item, paste0(file, reps, '.txt'))
   cat('Stuff written to ', file, '\n', sep = '')
   Sys.sleep(30)
}