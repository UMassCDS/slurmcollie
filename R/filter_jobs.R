#' Filter jobs database
#'
#' @param filter Specify jobs with one of:
#'  - a vector of `jobids`
#'  - 'all' for all jobs
#'  - a named list to filter jobs. List items are `<field> = <value>`, where 
#'    `<field>` is a field in the jobs database, and `<value>` is a regex for 
#'    character fields, or an actual value (or vector of values) for logical 
#'    or numeric fields.
#' @returns A vector of rows numbers in `slu$jdb`


filter_jobs <- function(filter) {
   
   
   if(identical(filter, 'all'))                                   # if 'all', return all jobs
      return(seq_len(dim(slu$jdb)[1]))
   
   if(is.numeric(filter)) {                                       # if we have supplied jobids,
      z <- match(filter, slu$jdb$jobid)
      if(any(m <- is.na(z))) {
         message('Note: jobids ', paste(filter[m], collapse = ', '), ' don\'t exist')
         z <- z[!m]
      }
      return(z)
   }
   
   if(any(n <- !names(filter) %in% names(slu$jdb)))               # else, it's a named list of field = value
      stop('Fields not in jobs database: ', paste(names(filter)[n], collapse = ', '))
   z <- rep(TRUE, dim(slu$jdb)[1])
   for(i in seq_along(filter)) {
      col <- slu$jdb[, names(filter)[i]]
      val <- filter[[i]]
      if(is.character(col[i]))
         z <- z & ((1:length(col)) %in% grep(val, col))
      else
         z <- z & (col %in% val)
   }
   
   (seq_len(dim(slu$jdb)[1]))[z]
}