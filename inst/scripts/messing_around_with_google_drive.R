library(googledrive)

google <- 'https://drive.google.com/drive/u/1/folders/0B6-MI-dco6FLWkZmTDZ4MFhRU1k'
did <- as_id(google)
# dir <- drive_get(did)

subdir <- drive_get(path = 'UAS Data Collection/Westport/RFM Processing Inputs/', id = did)
drive_reveal(subdir, what = 'path')

drive_ls(subdir)

sub2 <- drive_find(pattern = 'Westport')


shape <- drive_get(path = 'UAS Data Collection/Westport/RFM Processing Inputs/Footprint/WES_100ac_Mask_24Mar23.shp', id = did)



########

google <- 'https://drive.google.com/drive/u/1/folders/0B6-MI-dco6FLWkZmTDZ4MFhRU1k'
did <- as_id(google)
subdir <- drive_get(path = 'UAS Data Collection/Westport/RFM Processing Inputs/', id = did) # takes 7 or 8 minutes



l <- drive_ls(path = subdir, recursive = TRUE)




dir <- drive_ls(path = 'UAS Data Collection/')                 # seconds
dir <- drive_ls(path = 'UAS Data Collection/Westport/')        # also seconds
dir <- drive_ls(path = 'UAS Data Collection/Westport/RFM Processing Inputs/')    # takes longer than I'm willing to wait

dir <- drive_ls(path = 'UAS Data Collection/Westport/RFM Processing Inputs/', type = 'folder')  # also does
dir <- drive_ls(path = 'UAS Data Collection/Westport/RFM Processing Inputs/', type = 'folder', n_max = 10) # does too

dir <- drive_ls(path = 'UAS Data Collection/Westport/RFM Processing Inputs/Orthomosaics')


dir <- drive_ls(path = 'UAS Data Collection/Old Town Hill/RFM Processing Inputs/Orthomosaics')



#######################
#######################
#######################
#######################

now(); dir <- drive_ls(path = 'UAS Data Collection/Westport/RFM Processing Inputs/', type = 'folder'); now()    # this works, takes 6.5 min
now(); dir <- drive_ls(path = 'UAS Data Collection/Westport/RFM Processing Inputs/Orthomosaics', type = 'folder'); now()   # this returns incorrect empty result, takes 6.5 min


now(); dir <- drive_ls(path = 'UAS Data Collection/Old Town Hill/RFM Processing Inputs/Orthomosaics', type = 'folder'); now()   # this returns incorrect empty result, takes 6.5 min
now(); dir <- drive_ls(path = 'UAS Data Collection/South River/RFM Processing Inputs/Orthomosaics', type = 'folder'); now()   # this returns incorrect empty result, takes 6.5 min

####################################################################
####################################################################


dir <- drive_get(path = 'UAS Data Collection/Westport/')                                     # OKAY!!! Here's how we walk down a directory quickly!
dir2 <- drive_ls(dir$id[1])
dir3 <- drive_ls(dir2$id[1])
dir4 <- drive_ls(dir3$id[1])           # here's the list of all files in orthomosiacs for Westport
drive_download(dir4$id[2])             # and here we're downloading one! It works and it's all pretty fast.

dirxx <- drive_get(path = 'UAS Data Collection/Westport/RFM Processing Inputs/Orthomosaics/')   # this, on the other hand, is ungodly slow. You have to walk it down. Crazy.
dirxx <- drive_ls(path = 'UAS Data Collection/Westport/RFM Processing Inputs/Orthomosaics/')   # this, on the other hand, is ungodly slow. You have to walk it down. Crazy.



### DOWNLOADING FILES. When caching, I want to replace files where downloads failed. I think checking size is the thing to do
### a reasonable alternative: add prefix zzz_ to file name, then rename it after download finishes. This is probably a better way to go.
### also want to make sure local mtime > modified_time on Google Drive

dir <- drive_walk_path(path = 'UAS Data Collection/Westport/RFM Processing Inputs/Orthomosaics/')
drive_download(dir$id[7], path = paste0('C:/Work/R/salt_marsh_mapping/zztemp/', dir$name[7]), overwrite = TRUE)

size <- drive_reveal(dir$id[7], what = 'size')$size
file.size(paste0('C:/Work/R/salt_marsh_mapping/zztemp/', dir$name[7]))               # bet the sizes won't match!  They do!!!
file.mtime(paste0('C:/Work/R/salt_marsh_mapping/zztemp/', dir$name[7]))

drive_reveal(dir$id[7], what = 'modified_time')       # time on local drive must be > than on Google Drive

drive_reveal(gd$dir[1,], what = c('modified_time', 'size'))       # time on local drive must be > than on Google Drive
drive_reveal(gd$dir[1,], what = 'modified_time')       # time on local drive must be > than on Google Drive
drive_reveal(gd$dir[1,], what = 'size')       # time on local drive must be > than on Google Drive

