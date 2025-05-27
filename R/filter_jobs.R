#' Filter jobs database
#' 
#' @param filter A named list to filter jobs with. List items are `<field in
#'   jdb> = <value>`, where <value> is a regex for character fields, or an
#'   actual value (or vector of values) for logical or numeric fields.
#' @returns A logical vector corresponding to rows in `the$jdb`.


filter_jobs <- function(filter) {
   
   
   z <- rep(TRUE, dim(the$jdb)[1])
   for(i in length(filter)) {
      col <- the$jdb[, names(filter)[i]]
      val <- filter[[i]]
      if(is.character(col[1]))
         z <- z & ((1:length(col)) %in% grep(val, col))
      else
         z <- z & (col == val)
   }
   
   z
}