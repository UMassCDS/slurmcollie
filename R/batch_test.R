batch_test <- function(item, file) {
   
   
   writeLines(item, file)
   cat('Stuff written to ', file, '\n', sep = '')
}