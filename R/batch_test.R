#' a test thingy
#' @export

batch_test <- function(rep, item = 'hello ', file = '/work/pi_cschweik_umass_edu/marsh_mapping/reg/btest') {
   
   
   writeLines(item, paste0(file, rep, '.txt'))
   cat('Stuff written to ', file, '\n', sep = '')
}