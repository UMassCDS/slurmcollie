'get_dir' <- function(path, sourcedrive = 'local') {
   
   # Return directory listing as a data frame from the local drive, Google Drive, or SFTP site
   # A sister function to get_file
   # 
   # Arguments:
   #     path        directory path (must end with '/' on Google Drive)
   #     sourcedrive one of 'local', 'google', or 'sftp'
   # Result:
   #     data frame with name (filenames), and id (Google Drive id, only if sourcedrive = 'google')
   #        when sourcedrive = 'local', name is full path to local files
   #        when sourcedrive = 'google', name is just the base name
   #        when sourcedrive = 'sftp', name is the full path to files on the SFTP site
   #        
   # Notes: 
   #     - paths for Google Drive are case-sensitive
   #     - initial runs with Google Drive in a session open the browser for authentication or wait
   #       for input from the console, so don't run blindly when using the Google Drive
   #        
   # B. Compton, 6 Feb 2025
   
   
   
   path <- gsub('/+', '/', paste0(path, '/'))         # clean up for Google Drive (dir must end in a slash; no doubled slashes)
   
   switch(sourcedrive, 
          'local' = data.frame(name = paste0(path, '/', list.files(path))),
          'google' = drive_walk_path(path),
          'sftp' = {
             cat('*********************** GET SFTP DIRECTORY HERE************************\n')
             NULL
          })
}
