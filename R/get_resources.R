#' Combine user-supplied resources with function-specific defaults
#' 
#' @param user List of user-specified resources; NULL if none
#' @param func List of function-specified resources
#' @returns Combined list of resources, with user resources taking precedence
#' @export


get_resources <- function(user, func) {
   
   
   resources <- function
   if(!is.null(user)) {
      both <- c(user, func)
      resources <- both[unique(names(both))]
   }
   
   resources
}