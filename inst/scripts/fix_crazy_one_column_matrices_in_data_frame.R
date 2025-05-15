fix <- function(z) {
   
   
   t <- data.frame(apply(z, MARGIN = 2, FUN = as.vector))                        # fix crazy shit with one-column matrices ending up in data frame. I don't understand what happened.
   names(t) <- names(z)
   t
   
}