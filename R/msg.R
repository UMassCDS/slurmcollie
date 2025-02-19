'msg' <- function(message, logfile) {                                            
   
   # Apppend message to the log file and also write it to the display
   # Arguments:
   #     message     test of message
   #     logfile     path and name of log file
   # B. Compton, 18 Feb 2025
   
   
   if(is.null(logfile)) {
      timestamp <- stamp('[17 Feb 2025, 3:22:18 pm]  ', quiet = TRUE)
      if(!file.exists(logfile))
         cat(paste0(timestamp(now()), message), sep = '\n', file = logfile)
      else
         cat(paste0(timestamp(now()), message), sep = '\n', file = logfile, append = TRUE)
   }
   cat(message, sep = '\n')
}
