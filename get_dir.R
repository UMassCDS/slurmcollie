'get_dir' <- function(path, googledrive = FALSE) {
   
   # Return directory listing as a data frame from either local drive or Google Drive
   # Arguments:
   #     path        directory path (must end with '/' on Google Drive)
   #     googledrive TRUE if reading from Google Drive
   # Result:
   #     data frame with name (filenames), and id (Google Drive id, only if googledrive = TRUE)
   #        when googledrive = FALSE, name is full path to local files
   #        when googledrive = TRUE, name is just the base name
   #        
   # Note: paths for Google Drive are case-sensitive
   #        
   # B. Compton, 6 Feb 2025
   
   
   
   library(googledrive)
   
   path <- gsub('/+', '/', paste0(path, '/'))         # clean up for Google Drive (dir must end in a slash; no doubled slashes)
   
   if(googledrive)                                    # If reading from Google Drive,
      return(drive_walk_path(path))
   else                                               # else, local drive
      return(data.frame(name = paste0(path, '/', list.files(path))))
}
