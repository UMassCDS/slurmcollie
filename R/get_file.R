'get_file' <- function(name, gd) {
   
   # Return a file name from the local drive, Google Drive, or SFTP. If reading from the Google Drive 
   # or SFTP, the file is cached on the scratch drive (gd$cache), and reused as long as it isn't
   # outdated. Get gd$dir with sister function get_dir.
   # 
   # Arguments:
   #     name        file path and name
   #     gd          Source Drive info, named list of 
   #                    dir            Google directory info, from get_dir
   #                    sourcedrive    which source drive ('local', 'google', or 'sftp')
   #                    cachedir       local cache directory
   # Results:
   #     path to file on local drive
   # 
   # Notes:
   #     - this code assumes that all files have unique names, even if from different directories. This
   #       holds true for the UAS salt marsh project, so good enough. *** IF REPURPOSING THIS CODE, beware! ***
   #     - cached files are reused if they're not outdated. Downloads from Google Drive or SFTP to Unity are
   #       wicked fast, so don't feel bad freeing up the scratch drive after a run. It's the polite thing
   #       to do.
   #     - we don't check for a full cache drive, as the Unity scratch drive has a 50 TB limit and we 
   #       have < 1 TB of data. Again, IF REPURPOSING, beware!
   #     - we protect against crashed or interrupted downloads by downloading to a temporary file that 
   #       is renamed after completion.
   # 
   # B. Compton, 6 Feb 2025
   
   
   
   name <- gsub('/+', '/', name)                                                 # clean up slashes
   
   sdate <- switch(gd$sourcedrive,
                   'local' = name,                                                               # if the file is on the local drive, simply return the path and name
                   'google' = {                                                                  # if it's on the Google Drive, deal with caching
                      gname <- gd$dir[gd$dir$name == basename(name), ]                           #    name and id on Google Drive
                      cname <- file.path(gd$cachedir, basename(name))                            #    name in cache
                      if(file.exists(cname)) {                                                   #    if the file exists in the cache,
                         gdate <- drive_reveal(gd$dir[1,], what = 'modified_time')$modified_time #       get last modified date on Google Drive
                         cdate <- file.mtime(cname)                                              #       and in cache
                         if(cdate >= gdate)                                                      #       if the cached version is up-to-date,
                            return(cname)		                                                    #          we already have it, so return cached name
                      }
                      else {                                                                     #    else, gotta get it
                         tname <- file.path(dirname(cname), paste0('zzz_', basename(cname)))
                         cat('downloading...\n')
                         tryCatch({
                            drive_download(gname, path = tname, overwrite = TRUE)                #       download it with a temporary name (so we don't have failed downloads with good names)
                         },
                         error = function(cond)
                            stop(paste0('File ', name, ' not found on Google Drive'))
                         )
                         file.rename(tname, cname)                                               #       rename it
                         return(cname)
                      }
                   },
                   'sftp' = '*************** get file from SFTP **************'                  # if it's on an SFTP site, deal with caching    **** maybe share with Google Drive here ****
   )
}
