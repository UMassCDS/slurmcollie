#' Combine user-supplied resources with function-specific defaults
#' 
#' @param user List of user-specified resources; NULL if none
#' @param function List of function-specified resources
#' @returns Combined list of resources, with user resources taking precedence
#' @export


get_resources <- function(user, function) {
   
   
   resources <- function
   if(!is.null(user)) {
      both <- c(user, function)
      resources <- both[unique(names(both))]
   }
   
   resources
}