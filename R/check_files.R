'check_files' <- function(files, gd, sourcedir, resultdir) {
   
   # Check that each source file exists on the result directory and is up to date
   # Arguments:
   #     files       list of files to check
   #     gd          Google Drive info (optional), named list of 
   #                    dir         Google directory info, from get_dir
   #                    googledrive TRUE if reading from Google Drive
   #     sourcedir   origin directory of files
   #     resultdir   target directory of files - see if origin files are here and up to date
   # Result:
   #     a vector corresponding to files, TRUE for those that are up to date
   # B. Compton, 10 Feb 2025
   
   
   
   z <- rep(FALSE, length(files))
   
   for(i in 1:length(files))                                                        #    for each file,
      if(file.exists(f <- file.path(resultdir, file.path(basename(files[i]))))) {        # if the file exists in the results directory,
         if(gd$googledrive)                                                         #    if we're usin the Google Drive,
            sdate <- drive_reveal(gd$dir[1,], what = 'modified_time')$modified_time #       get last modified date on Google Drive
         else                                                                       #    else
            sdate <- file.mtime(f)                                                  #       get it from local source drive 
         rdate <- file.mtime(f)                                                     #   date on result drive
         z[i] <- rdate >= sdate
      }
   z
}