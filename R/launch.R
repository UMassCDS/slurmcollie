#' Launch batch jobs via Slurm on Unity
#' 
#' Updates jobs database, `the$jdb` to track jobs.
#' 
#' @param call Name of function to call
#' @param args Named list of arguments to called function
#' @param reps Vector, list, or data frame to vectorize call over. If a
#'    named list or data frame, the names must correspond to the fuction's
#'    arguments. If a vector or unnamed list, `argname` is used.
#' @param argname Name of `reps` argument in function to be called, used 
#'    only when `reps` is a vector or unnamed list
#' @param resources Named list of resources, overriding defaults in 
#'    `batchtools.conf`
#' @param regdir Directory containing `batchtools` registries
#' @param jobids ids for these jobs in jobs database. Supply existing
#'    jobs to relaunch jobs; NA or NULL will create new jobs.
#' @param comment Optional comment; will be recycled for multiple reps
#' @param finish Optional name of a function to run for completed jobs,
#'    for example `finish = 'sweep_fit'` to gather fit stats
#' @param replace If TRUE, replace existing job ids in jobs database; 
#'    otherwise throw an error for existing jobs
#' @importFrom batchtools makeRegistry batchMap submitJobs
#' @export


launch <- function(call, args, reps = 1, argname = 'rep', more.args = list(), 
                   resources = list(), regdir = the$regdir, 
                   jobids = NULL, comment = '', finish = NA, replace = TRUE) {
   
   
   load_database('jdb')                                                       # load the jobs database if we don't already have it
   
   
   if(!is.list(reps))                                                         # process reps (and argname) so we end up with a named list or data frame
      reps <- list(reps)
   if(is.null(names(reps)))
      names(reps) <- argname
   
   if(!is.null(jobids))                                                       # make sure supplied jobids confrom to reps
      if(length(jobids) != length(reps[[1]]))
         stop('Supplied jobids must be the same length as reps')
   
   if(!dir.exists(regdir))                                                    # create registries dir if need be
      dir.create(regdir, recursive = TRUE)
   
   x <- list.files(regdir, pattern = 'reg\\d+')                               # find existing registries
   if(length(x) == 0)                                                         # build registry id
      regid <- 'reg001'
   else {
      regid <- (max(as.numeric(sub('reg', '', x))) + 1) |>
         formatC(width = 3, format = 'd', flag = 0)
      regid <- paste0('reg', regid)
   }
   
   config <- system.file('batchtools.conf.R', package = 'saltmarsh', 
                         lib.loc = .libPaths(), mustWork = TRUE)
   reg <- makeRegistry(file.dir = file.path(regdir, regid), 
                       conf.file = config)                                    # create batchtools registry
   
   # Note: might need to use get(call, envir = asNamespace('saltmarsh')), though this is working for now
   jobs <- batchMap(fun = get(call), args = reps, more.args = more.args) |>
      submitJobs(resources = resources)                                       # definte and submit jobs
   
   
   
   ########### CREATE DATA FOR TESTING
   # the$jdb <- data.frame(jobid = 101:105, bid = c(paste0('reg001:', 1:3), paste0('reg002:', 1:2)))    # for testing
   # jobids <- c(100, 102:104, 111:112)
   # bid <- paste0('reg111:', 1:6)
   ###########
   
   
   if(is.null(jobids))                                                        # Wrangle jobids
      jobids <- rep(NA, length(reps[[1]]))
   i <- match(jobids, the$jdb$jobid)                                          # find jobids that are already in the database--we'll replace those if replace = TRUE
   if(any(!is.na(i)) & !replace)
      stop('Jobs are already in jobs database (and replace = FALSE) for job ids ', paste(jobids[!is.na(i)], collapse = ', '))
   if(any(is.na(jobids)))
      jobids[is.na(jobids)] <- max(the$jdb$jobid, 0) + 1:sum(is.na(jobids))   # come up with new jobids for those not supplied
   
   
   the$jdb[j <- nrow(the$jdb) + (1:sum(is.na(i))), ] <- NA                    # add rows to database if need be
   i[is.na(i)] <- j
   
   the$jdb$jobid[i] <- jobids                                                 # add job ids to jobs database
#   the$jdb$launch[i] <- with_tz(now(),  'America/New_York')                 # launch date and time                            *** should put time zone in pars, I guess 
   the$jdb$launch[i] <- now()                                                 # launch date and time in UTC, leaving pretty formatting to info()
   the$jdb$bjobid[i] <- jobs$job.id                                           # and add batchtools job ids to jobs database
   the$jdb$registry[i] <- regid
   the$jdb$done[i] <- FALSE
   the$jdb$finish[i] <- finish
   the$jdb$comment[i] <- rep(comment, length = length(i))                     # job comment
   
   save_database('jdb')                                                       # save the database
   
   message(dim(jobs)[1], ' jobs submitted to ', regid)
}