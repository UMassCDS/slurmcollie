'get_file' <- function(name, gd = NULL) {
   
   
   # Arguments:
   #     name        file path and name
   #     gd          Google Drive info (optional), named list of 
   #                    dir         Google directory info, from get_dir
   #                    googledrive TRUE if reading from Google Drive
   #                    cachedir    local cache directory
   # Results:
   #     path to file on local drive
   # B. Compton, 6 Feb 2025

   
   
   library(googledrive)
   
   if(is.null(gd) || gd$googledrive == FALSE)            # if reading from the local drive,
      return(name)                                       #    just pass through the file path and name
   else {
      
    
      return(z)  
   }
}