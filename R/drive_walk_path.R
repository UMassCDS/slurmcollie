'drive_walk_path' <- function(path) {
   
   # Walk down a file path a folder at a time in the currently Google Drive. This is far, far faster than using drive_get
   # or drive_ls with a deep path on a drive with LOTS of files.
   # Arguments:
   #     path     drive path on Google Drive
   # Results: 
   #     a dribble for full path. Returns NULL if the directory does not exist.
   #
   # The following takes 6-7 min on our Google Drive, which has ~16,000 files:
   #     drive_ls(path = 'UAS Data Collection/Westport/RFM Processing Inputs/Orthomosaics/')
   #  while this call takes 6 seconds:
   #     drive_walk_path(path = 'UAS Data Collection/Westport/RFM Processing Inputs/Orthomosaics/')
   # B. Compton (with great annoyance), 5 Feb 2025
   
   
   
   library(googledrive)  
   options(googledrive_quiet = TRUE)
   
   tryCatch({
   x <- unlist(strsplit(path, '/'))
   d <- drive_get(path = paste0(x[1], '/'))
   for(i in 1:length(x)) 
      d <- drive_ls(d$id[d$name == x[i]])
   d
   }, 
   error = function(cond)
      NULL)
}