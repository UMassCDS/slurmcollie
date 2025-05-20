#' Launch batch jobs via Slurm on Unity
#' 
#' Updates jobs database, `the$jdb` to track jobs.
#' 
#' @param call Name of function to call
#' @param args Named list of arguments to called function
#' @param reps Vector, list or data frame to vectorize call over
#' @param resources Named list of resources, overriding defaults in 
#'    `batchtools.conf`
#' @param regdir Directory containing `batchtools` registries
#' @param jobids ids for these jobs in jobs database
#' @param replace If TRUE, replace existing job ids in jobs database; 
#'    otherwise throw an error for existing jobs
#' @importFrom batchtools makeRegistry batchMap submitJobs
#' @export


launch <- function(call, args, reps, resources, regdir = the$regdir, jobids, replace = TRUE) {
   
   
   load_database('jdb')                                                       # load the jobs database if we don't already have it
   
   if(!dir.exists(regdir))                                                    # create registries dir if need be
      dir.create(regdir, recursive = TRUE)
   
   x <- list.files(regdir, pattern = 'reg\\d+')                               # find existing registries
   if(length(x) == 0)                                                         # build registry id
      regid <- 'reg001'
   else
      regid <- (max(as.numeric(sub('reg', '', x))) + 1) |>
      formatC(width = 3, format = 'd', flag = 0)
   regid <- paste0('reg', regid)
   
   
   reg <- makeRegistry(file.dir = file.path(regdir, regid), 
                       conf.file = system.file('batchtools.conf.R', 
                                               package = 'saltmarsh'))        # create batchtools registry
   
   jobs <- batchMap(fun = call, args = reps, more.args = args) |>
      submitJobs(resources = resources)                                       # definte and submit jobs
   
   
   bid <- paste0(regid, ':', jobs$job.id)                                     # batchtools id (registry:job.id)
   
   
   ########### CREATE DATA FOR TESTING
   # the$jdb <- data.frame(jobid = 101:105, bid = c(paste0('reg001:', 1:3), paste0('reg002:', 1:2)))    # for testing
   # jobids <- c(100, 102:104, 111:112)
   # bid <- paste0('reg111:', 1:6)
   ###########
   
   
   i <- match(jobids, the$jdb$jobid)                                          # find jobids that are already in the database--we'll replace those if replace = TRUE
   if(any(!is.na(i)) & !replace)
      stop('Jobs are already in jobs database (and replace = FALSE) for job ids ', paste(jobids[!is.na(i)], collapse = ', '))
   
   the$jdb[j <- nrow(the$jdb) + (1:sum(is.na(i))), ] <- NA                    # add rows to database if need be
   i[is.na(i)] <- j
   
   the$jdb$jobid[i] <- jobids                                                 # add job ids to jobs database
   the$jdb$bid[i] <- bid                                                      # and add batchtools job ids to jobs database
   
  
   save_database('jdb')                                                       # save the database
   
   message(dim(jobs)[1], ' jobs submitted to ', regid)
}