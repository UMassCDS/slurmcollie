#' Launch batch jobs via Slurm on Unity
#' 
#' Updates jobs database, `slu$jdb` to track jobs.
#' 
#' Use `finish = 'function'` to name functions to, for example, update a parent
#' database. The finish function must take two arguments, `jobid` and `status`.
#' These functions are called by [sweep] for any newly-done jobs, whether they
#' were successful or not. Finishing functions run in the user console, so they
#' should be quick--they're intended to update databases, not do actual work.
#' You can, of course, `launch` additional batch jobs from a finishing function.
#' 
#' @param call Name of function to call
#' @param args Named list of arguments to called function
#' @param reps Vector, list, or data frame to vectorize call over. If a
#'    named list or data frame, the names must correspond to the function's
#'    arguments. If a vector or unnamed list, `argname` is used.
#' @param argname Name of `reps` argument in function to be called, used 
#'    only when `reps` is a vector or unnamed list
#' @param moreargs a named list of additional arguments to the called function,
#'    not vectorized over
#' @param resources Named list of resources, overriding defaults in 
#'    `batchtools.conf`
#' @param local If TRUE, launch job locally instead of as a batch job, tying
#'    up the console while it runs. The jobs database will be updated on 
#'    completion, so no information will be saved the job is interrupted.
#' @param regdir Directory containing `batchtools` registries
#' @param jobids ids for these jobs in jobs database. Supply existing
#'    jobs to relaunch jobs; NA or NULL will create new jobs.
#' @param comment Optional comment; will be recycled for multiple reps
#' @param finish Optional name of a function to run for completed jobs,
#'    for example `finish = 'sweep_fit'` to gather fit stats
#' @param replace If TRUE, replace existing job ids in jobs database; 
#'    otherwise throw an error for existing jobs
#' @importFrom batchtools makeRegistry batchMap submitJobs getJobTable
#' @export


launch <- function(call, args, reps = 1, argname = 'rep', moreargs = list(), 
                   resources = list(), regdir = slu$regdir, 
                   jobids = NULL, comment = '', finish = NA, replace = TRUE) {
   
   
   load_database('jdb')                                                       # load the jobs database if we don't already have it
   
   
   if(!is.list(reps))                                                         # process reps (and argname) so we end up with a named list or data frame
      reps <- list(reps)
   if(is.null(names(reps)))
      names(reps) <- argname
   
   if(!is.null(jobids))                                                       # make sure supplied jobids confrom to reps
      if(length(jobids) != length(reps[[1]]))
         stop('Supplied jobids must be the same length as reps')
   
   if(is.null(jobids))                                                        # Wrangle jobids
      jobids <- rep(NA, length(reps[[1]]))
   i <- match(jobids, slu$jdb$jobid)                                          # find jobids that are already in the database--we'll replace those if replace = TRUE
   if(any(!is.na(i)) & !replace)
      stop('Jobs are already in jobs database (and replace = FALSE) for job ids ', paste(jobids[!is.na(i)], collapse = ', '))
   if(any(is.na(jobids)))
      jobids[is.na(jobids)] <- max(slu$jdb$jobid, 0) + 1:sum(is.na(jobids))   # come up with new jobids for those not supplied
   
   
   
   if(!local) {                                                               # if running in batch mode, ----------
      if(!dir.exists(regdir))                                                 #    create registries dir if need be
         dir.create(regdir, recursive = TRUE)
      
      x <- list.files(regdir, pattern = 'reg\\d+')                            #    find existing registries
      if(length(x) == 0)                                                      #    build registry id
         regid <- 'reg001'
      else {
         regid <- (max(as.numeric(sub('reg', '', x))) + 1) |>
            formatC(width = 3, format = 'd', flag = 0)
         regid <- paste0('reg', regid)
      }
      

      config <- file.path(slu$template, 'batchtools.conf.R')
      reg <- suppressMessages(makeRegistry(file.dir = file.path(regdir, regid), 
                                           conf.file = config))               #    create batchtools registry
      
      # Note: might need to use get(call, envir = asNamespace('saltmarsh')), though this is working for now
      jobs <- suppressMessages(batchMap(fun = get(call), args = reps, 
                                        more.args = moreargs))
      jobs <- suppressMessages(submitJobs(jobs, resources = resources))       #    define and submit jobs
      
      
      
      slu$jdb[j <- nrow(slu$jdb) + (1:sum(is.na(i))), ] <- NA                 #    add rows to database if need be
      i[is.na(i)] <- j
      
      slu$jdb$jobid[i] <- jobids                                              #    add job ids to jobs database
      slu$jdb$launched[i] <- now()                                            #    launch date and time in UTC, leaving pretty formatting info() - use with_tz(now(),  'America/New_York') 
      slu$jdb$call[i] <- call                                                 #    name of called function
      slu$jdb$bjobid[i] <- jobs$job.id                                        #    and add batchtools job ids to jobs database
      slu$jdb$registry[i] <- regid
      slu$jdb$sjobid[i] <- getJobTable(slu$jdb$bjobid[i])$batch.id            #    Slurm job id (it's easier than I thought!)
      slu$jdb$status[i] <- 'queued'
      slu$jdb$done[i] <- FALSE
      slu$jdb$finish[i] <- finish
      slu$jdb$comment[i] <- rep(comment, length = length(i))                  #    job comment
   }
   else                                                                       # else, launch in local mode ----------
   {
      cat('do local launch here')
   }
   
   
   save_database('jdb')                                                       # save the database
   
   if(dim(jobs)[1] == 1)
      message(dim(jobs)[1], ' job (jobid ', i, ') submitted to ', regid)
   else
      message(dim(jobs)[1], ' jobs (jobids ', paste(i, collapse = ', '), ') submitted to ', regid)
}