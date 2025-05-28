#' Filter jobs database
#'
#' @param filter Either a vector of `jobids` or a named list to filter jobs
#'   with. List items are `<field in jdb> = <value>`, where <value> is a regex
#'   for character fields, or an actual value (or vector of values) for logical
#'   or numeric fields.
#' @returns A vector of rows numbers in `the$jdb`


filter_jobs <- function(filter) {
   
   
   if(is.numeric(filter)) {                                       # if we have supplied jobids,
      z <- match(filter, the$jdb$jobid)
      if(any(is.na(z)))
         stop('Jobids ', paste(filter[is.na(z)], collapse = ', '), ' don\'t exist')
      return(z)
   }
   
   else {                                                         # else, it's a named list of field = value
      if(any(n <- !names(filter) %in% names(the$jdb)))
         stop('Fields not in jobs database: ', paste(names(filter)[n], collapse = ', '))
      z <- rep(TRUE, dim(the$jdb)[1])
      for(i in length(filter)) {
         col <- the$jdb[, names(filter)[i]]
         val <- filter[[i]]
         if(is.character(col[1]))
            z <- z & ((1:length(col)) %in% grep(val, col))
         else
            z <- z & (col == val)
      }
      
      (1:dim(the$jdb)[1])[z]
   }
}