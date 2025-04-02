

library(RCurl)

pw <- 'PW.HERE'      # DSL cluster password. Don't fucking save this, okay?


get_dir('Anthill/', sourcedrive = 'sftp', sftp = list(url = 'sftp://landeco.umass.edu/D/', user = paste0('campus\\landeco:', pw)))
gather_data(sourcedrive = 'sftp', sftp = list(url = 'sftp://landeco.umass.edu/D/', user = paste0('campus\\landeco:', pw)))



# Read file
f <- 'sftp://landeco.umass.edu/D/Anthill/computers.txt'            # read projects.txt. Works but adds an extra CRLF between lines
u <- paste0('campus\\landeco:', pw)
x <- getURL(f, userpwd = u)
write(x, 'c:/temp/computers.txt')





# attempt to read binary file.          *** fucking works!!!!!!!! ***
f <- 'sftp://landeco.umass.edu/web/ClusterGuide.pdf'
u <- paste0('campus\\landeco:', pw)
x <- getBinaryURL(f, userpwd = u)
# if necessary add connecttimeout = 60
writeBin(x, 'c:/temp/ClusterGuide.pdf')


# attempt to read BIG binary file          The biggest files I'm seeing on the Google Drive are ~5 GB, so they'll fit in memory just fine.
## f <- 'sftp://landeco.umass.edu/web/LCC/DSL/metrics/DSL_data_traffic_metric.zip'   # 3.5 GB
f <- 'sftp://landeco.umass.edu/web/LCC/DSL/metrics/DSL_data_sea_level_rise.zip'   # 173 MB
u <- paste0('campus\\landeco:', pw)
x <- getBinaryURL(f, userpwd = u, connecttimeout = 60)
# if necessary add connecttimeout = 60
writeBin(x, 'c:/temp/DSL_data_traffic_metric.zip')




# directory listing. This works!!!

f <- 'sftp://landeco.umass.edu/D/Anthill/'   
u <- paste0('campus\\landeco:', pw)
d <- getURL(f, userpwd = u, dirlistonly = TRUE) 
# d <- getURL(f, userpwd = u, dirlistonly = TRUE, ftp.use.epsv = FALSE)   #ftp.use.epsv isn't necessary for DSL cluster, but it's popular. I find it 100% opaque.
d <- strsplit(d, '\n')


# get dir with date and time                       # note that seconds are truncated. I add one minute so comparisons won't fail.
f <- 'sftp://landeco.umass.edu/D/Anthill/'   
u <- paste0('campus\\landeco:', pw)
d <- strsplit(getURL(f, userpwd = u), '\n')[[1]]        # directory info
'grab_date' <- function(x) mdy_hm(substr(sub('\\s*\\d*\\s*', '', x), 1, 18))   # pull the date out of the directory listing
'grab_name' <- function(x) substring(sub('\\s*\\d*\\s*', '', x), 20)
dir <- data.frame(name = unlist(lapply(d, FUN = grab_name)), date = as_datetime(unlist(lapply(d, FUN = grab_date)) + 60))

# failed junk
# f <- 'sftp://landeco.umass.edu/web/ClusterGuide.pdf'
# u <- paste0('campus\\landeco:', pw)
# l <- url.exists(f, userpwd = u, .header = TRUE)['Last-Modified']
# 
#  h = basicHeaderGatherer()
