#' Append message to the log file and also write it to the display
#' 
#' Displays message to the console, writing it to the log with a timestamp
#' if a log file is provided.
#'
#' @param message text of message
#' @param logfile path and name of log file
#' @importFrom lubridate stamp now
#' @keywords internal
   

'msg' <- function(message, logfile) {       
   
   
   if(is.null(logfile)) {
      timestamp <- stamp('[17 Feb 2025, 3:22:18 pm]  ', quiet = TRUE)
      if(!file.exists(logfile))
         cat(paste0(timestamp(now()), message), sep = '\n', file = logfile)
      else
         cat(paste0(timestamp(now()), message), sep = '\n', file = logfile, append = TRUE)
   }
   cat(message, sep = '\n')
}
