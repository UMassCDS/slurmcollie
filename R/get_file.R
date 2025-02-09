'get_file' <- function(name, gd = NULL) {
   
   # Return a file name from either the local drive or Google Drive. If reading from the Google Drive 
   # (gd$googledrive = TRUE), the file is cached on the scratch drive (gd$cache), as reused as long as
   # it isn't outdated. Get gd$dir with sister function get_dir.
   # 
   # Arguments:
   #     name        file path and name
   #     gd          Google Drive info (optional), named list of 
   #                    dir         Google directory info, from get_dir
   #                    googledrive TRUE if reading from Google Drive
   #                    cachedir    local cache directory
   # Results:
   #     path to file on local drive
   # 
   # Notes:
   #     - this code assumes that all files have unique names, even if from different directories. This
   #       holds true for the UAS salt marsh project, so good enough.
   #     - cached files are reused if they're not outdated. Downloads from Google Drive to Unity are
   #       wicked fast, so don't feel bad freeing up the scratch drive after a run. It's the polite thing
   #       to do.
   #     - we don't check for a full cache drive, as the Unity scratch drive has a 50 TB limit and we 
   #       have < 1 TB of data.
   #     - we protect against crashed or interrupted downloads by downloading to a temporary file that 
   #       is renamed after completion.
   # 
   # B. Compton, 6 Feb 2025
   
   
   
   library(googledrive)
   
   if(is.null(gd) || gd$googledrive == FALSE)                                    # if reading from the local drive,
      return(name)                                                               #    just pass through the file path and name
   else {                                                                        # else, it's on the Google Drive, so we'll cache it
      gname <- gd$dir[gd$dir$name == basename(name), ]                           #    name and id on Google Drive
      cname <- file.path(gd$cachedir, basename(name))                            #    name in cache
      if(file.exists(cname)) {                                                   # if the file exists in the cache,
         gdate <- drive_reveal(gd$dir[1,], what = 'modified_time')$modified_time #    get last modified date on Google Drive
         cdate <- file.mtime(cname)                                              #    and in cache
         if(cdate >= gdate)                                                      #    if the cached version is up-to-date,
            return(cname)		                                                   #       we already have it, so return cached name
      }
      else {                                                                     # else, gotta get it
         tname <- file.path(dirname(cname), paste0('zzz_', basename(cname)))
         cat('downloading...\n')
         gname<<-gname;tname<<-tname;gd<<-gd;name<<-name
         drive_download(gname, path = tname, overwrite = TRUE)                   #    download it with a temporary name (so we don't have failed downloads with good names)
         file.rename(tname, cname)                                               #    rename it
         return(cname)
      }
   }
}
