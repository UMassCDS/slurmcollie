'get_file' <- function(name, gd, logfile) {
   
   # Return a file name from the local drive, Google Drive, or SFTP. If reading from the Google Drive 
   # or SFTP, the file is cached on the scratch drive (gd$cache), and reused as long as it isn't
   # outdated. Get gd$dir with sister function get_dir.
   # 
   # Arguments:
   #     name        file path and name
   #     gd          Source Drive info, named list of 
   #                    dir            Google directory info, from get_dir
   #                    sourcedrive    which source drive ('local', 'google', or 'sftp')
   #                    sftp           list(url, user)
   #                    cachedir       local cache directory
   #    logfile      log file, for reporting missing directories (which don't throw an error)
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
   #     - when reading from SFTP, the entire file must be able to fit in memory. There should be plenty
   #       of room for the files in the salt marsh project.
   # 
   # B. Compton, 6 Feb 2025
   
   
   
   name <- gsub('/+', '/', name)                                                    # clean up slashes
   
   
   if(gd$sourcedrive == 'local')                                                    # if the file is on the local drive, simply return the path and name
      return(name)
   else {                                                                           # else, it's on the Google Drive or SFTP, so we'll deal with caching
      cname <- file.path(gd$cachedir, basename(name))                               #    name in cache
      if(file.exists(cname)) {                                                      #    if the file exists in the cache,
         if(gd$sourcedrive == 'google') {                                           #       if it's on the Google Drive,
            sname <- gd$dir[gd$dir$name == basename(name), ]                        #          name and id on Google Drive
            sdate <- drive_reveal(gd$dir[1,], what = 'modified_time')$modified_time #          get last modified date 
         }
         else {                                                                     #       else, it's on SFTP
            sdate <- gd$dir$date[gd$dir$name == name]                               #          last modified date on the server
         }
         cdate <- file.mtime(cname)                                                 #       last modified date in cache
         if(cdate >= sdate)                                                         #       if the cached version is up-to-date,
            return(cname)		                                                      #          we already have it, so return cached name
         
      }                                                                             #    elseish, it doesn't exist or is outdated in the cache, so gotta get it
      tname <- file.path(dirname(cname), paste0('zzz_', basename(cname)))           #    we'll use a temporary name so we don't end up with failed downloads with good names
      msg('   downloading...', logfile)
      tryCatch({
         if(sourcedrive == 'google')                                                #    if it's on the Google Drive, get it from there
            drive_download(sname, path = tname, overwrite = TRUE)    
         else {                                                                     #    else, get it from SFTP
            f <- gsub(' ', '%20', file.path(gd$sftp$url, name))                     #       clean up spaces in the name
            x <- getBinaryURL(f, userpwd = gd$sftp$user)                            #       load it into memory
            writeBin(x, tname)                                                      #       and write it to a temporary file
         }
      },
      error = function(cond)
         stop(paste0('File ', name, ' not found on remote drive'))
      )
      file.rename(tname, cname)                                                     #    rename from temporary to the final name
      return(cname)
   }
   
}
