#' Launch batch jobs via Slurm on Unity
#'
#' Launches one or more reps of an R function as batch jobs and updates jobs database to track jobs.
#' 
#' You can override the default resources (defined in `batchtools.conf.R` in your `slurmcollie` 
#' `template` folder) with the `resources` option. Pass a named list. It can include any of the following:
#' 
#' - `walltime` (any of `minutes`, `'mm:ss'`, `'hh:mm:ss'`, or `'days-hh:mm'`)
#' - `memory` (GB)
#' - `ncpus` (number of CPUs to request)
#' - `ngpus` (number of GPUs to request)
#' - `partition.cpu` (partitions to request, e.g., `'cpu-preempt,cpu'`)
#' 
#' Use `finish = 'function'` to name functions to, for example, update a parent database. The finish
#' function must take two arguments, `jobid` and `status`. These functions are called by [sweep_jobs] for
#' any newly-done jobs, whether they were successful or not. Finishing functions run in the user
#' console, so they should be quick--they're intended to update databases, not do actual work. You
#' can, of course, `launch` additional batch jobs from a finishing function.
#'
#' Normally, jobs are launched via Slurm, but you can use `local = TRUE` to run them in the console,
#' which means you'll have to wait for them to complete. 
#'
#' @param call Name of function to call
#' @param reps Vector, list, or data frame to vectorize call over. If a named list or data frame,
#'   the names must correspond to the function's arguments. If a vector or unnamed list, `repname`
#'   is used. If you omit the `reps` and `repname` arguments, your function will be called with 
#'   `rep = 1`. Your function must take `rep` or the value of `repname` as an argument. In some 
#'   cases, you may want to throw this away.
#' @param repname Name of `reps` argument in function to be called, used only when `reps` is a
#'   vector or unnamed list
#' @param moreargs a named list of additional arguments to the called function, not vectorized over
#' @param callerid An optional character id that allows the calling function and finish function
#'    to track jobs.
#' @param resources Named list of resources, overriding defaults in `batchtools.conf` (see Details)
#' @param jobid If TRUE, the current `slurmcollie` job id is passed to the called function as `jobid`. 
#'    You'll need to include `jobid` as an argument to your function if you include this.
#' @param local If TRUE, launch job locally instead of as a batch job, tying up the console while it
#'   runs. The jobs database will be updated on completion, so no information will be saved to the
#'   jobs database if the job is interrupted. Note that local calls will not record `cores`, `cpu`, 
#'   `cpu_pct`, nor `mem_req`. They do record mem_gb and walltime.
#' @param trap If TRUE, trap errors in local mode; if FALSE, use normal R error handling. Use this
#'   for debugging. If you get unrecovered errors, the job won't be added to the jobs database. Has
#'   no effect if local = FALSE.
#' @param regdir Directory containing `batchtools` registries; defaults to the `slurmcollie` `regdir` setting
#' @param comment Optional comment; will be recycled for multiple reps
#' @param finish Optional name of a function to run for completed jobs, for example `finish =
#'   'sweep_fit'` to gather fit stats
#' @importFrom batchtools makeRegistry batchMap submitJobs getJobTable getJobResources
#' @importFrom peakRAM peakRAM
#' @importFrom lubridate seconds_to_period minute second now
#' @export


launch <- function(call, reps = 1, repname = 'rep', moreargs = list(), callerid = '', 
                   resources = list(), jobid = FALSE, local = FALSE, trap = TRUE, 
                   regdir = slu$regdir, comment = '', finish = NA) {
   
   
   load_slu_database('jdb')                                                   # load the jobs database if we don't already have it
   
   
   if(!is.list(reps))                                                         # process reps (and repname) so we end up with a named list or data frame
      reps <- list(reps)
   if(is.null(names(reps)))
      names(reps) <- repname
   
   
   jobids <- max(slu$jdb$jobid, 0, na.rm = TRUE) + 1:length(reps[[1]])        # come up with new jobids
   
   
   if(!local) {                                                               # if running in batch mode, ----------
      if(jobid)                                                               # if jobid,
         reps <- c(reps, list(jobid = jobids))                                #    add jobid to reps so called function can see it
      
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
      
      
      config <- file.path(slu$templatedir, 'batchtools.conf.R')
      reg <- suppressMessages(makeRegistry(file.dir = file.path(regdir, regid), 
                                           conf.file = config))               #    create batchtools registry
      jobs <- suppressMessages(batchMap(fun = get(call), args = reps, 
                                        more.args = moreargs))
      jobs <- suppressMessages(submitJobs(jobs, resources = resources))       #    define and submit jobs
      
      
      
      slu$jdb[i <- nrow(slu$jdb) + (1:length(jobids)), ] <- NA                #    add rows to database 
      
      slu$jdb$jobid[i] <- jobids                                              #    add job ids to jobs database
      slu$jdb$launched[i] <- now()                                            #    launch date and time in UTC, leaving pretty formatting for info()  
      slu$jdb$call[i] <- call                                                 #    name of called function
      slu$jdb$rep[i] <- reps[[1]]                                             #    rep for each job
      slu$jdb$callerid[i] <- callerid                                         #    job's caller id
      slu$jdb$local[i] <- FALSE                                               #    not a local run
      slu$jdb$bjobid[i] <- jobs$job.id                                        #    and add batchtools job ids to jobs database
      slu$jdb$registry[i] <- regid
      slu$jdb$sjobid[i] <- getJobTable(slu$jdb$bjobid[i])$batch.id            #    Slurm job id (it's easier than I thought!)
      slu$jdb$status[i] <- 'queued'
      slu$jdb$done[i] <- FALSE
      slu$jdb$finish[i] <- finish
      slu$jdb$comment[i] <- rep(comment, length = length(i))                  #    job comment
      slu$jdb$cores[i] <- getJobResources(slu$jdb$bjobid[i])$resources[[1]]$ncpus      # we can get number of cores here
      slu$jdb$mem_req[i] <- getJobResources(slu$jdb$bjobid[i])$resources[[1]]$memory   # requested memory (GB)
      
      save_slu_database('jdb')
      
      if(dim(jobs)[1] == 1)
         message(dim(jobs)[1], ' job (jobid ', slu$jdb$jobid[i], ') submitted to ', regid)
      else
         message(dim(jobs)[1], ' jobs (jobids ', paste(slu$jdb$jobid[i], collapse = ', '), ') submitted to ', regid)
   }
   
   
   
   else                                                                       # else, launch in local mode ----------
   {
      message('Running ', call, ' locally', 
              ifelse(length(reps) > 1, paste0(' (', length(reps), ' reps)'), ''))
      launched <- now()
    

      for(j in 1:length(reps[[1]])) {                                         #    For each rep,
         r <- list(reps[[1]][j])
         names(r) <- names(reps)                                              #       named list of current rep
         if(jobid)                                                            #       if jobid,
            r <- c(r, list(jobid = jobids[j]))                                #          add jobid to reps so called function can see it
         
         if(length(reps[[1]] > 1))
            message('   Running rep ', reps[[1]][j], ', jobid ', jobids[j], '...')
         else
            message('   Running jobid ', jobids[j], '...')
         
         mem <- peakRAM(                                                      #       Capture walltime and peak RAM used
            if(trap)                                                          #          if trapping errors,
               err <- tryCatch({                                              #          trap any errors
                  do.call(call, c(r, moreargs))                               #             call the function with rep, jobid, and more args
               },
               error = function(cond)                                         #          if there was an error
                  return(cond[[1]])                                           #             capture error message
               )
            else {                                                            #       else,
               do.call(call, c(r, moreargs))                                  #          call function without error trapping
               err <- NULL
            }
         )
         
 
         if(!is.null(err))                                                    #    if there was an error,
            message('Error: ', err)                                           #       display the error on the console
         
         slu$jdb[i <- nrow(slu$jdb) + 1, ] <- NA                              #    add row to database (one rep at a time, as we'll save after each rep)
         
         slu$jdb$jobid[i] <- jobids[j]                                        #    add job ids to jobs database
         slu$jdb$launched[i] <- launched                                      #    launch date and time in UTC, leaving pretty formatting for info() 
         slu$jdb$call[i] <- call                                              #    name of called function
         slu$jdb$rep[i] <- r[[1]]                                             #    rep of this call
         slu$jdb$callerid[i] <- callerid                                      #    job's caller id
         slu$jdb$local[i] <- TRUE                                             #    it's a local run
         slu$jdb$status[i] <- ifelse(is.null(err), 'finished', 'error')
         if(!is.null(err))
            slu$jdb$error[i] <- err
         slu$jdb$done[i] <- TRUE
         slu$jdb$comment[i] <- comment                                        #    job comment
         
         slu$jdb$mem_gb[i] <- mem$Peak_RAM_Used_MiB / 1000                    #     peak RAM used (GB)
         t <- seconds_to_period(mem$Elapsed_Time_sec)
         
         slu$jdb$walltime[i] <- sprintf('%02d:%02d:%02d', t@hour, 
                                        minute(t), round(second(t)))          #    and wall time
         
         #    ***************** I want to capture all output to a log, including messages and warnings, and reliably recover on 
         #                      interrupt. This looks like quite a project, so later.
         slu$jdb$log[i] <- NA                                                 
         
         save_slu_database('jdb')                                             #    save the database after each rep
         
         if(!is.na(finish)) {                                                 #    if we have a finish function
            message('   Finishing with ', finish)
            slu$jdb$finish[i] <- 'finishing...'
            do.call(finish, list(jobid = slu$jdb$jobid[i], 
                                 status = slu$jdb$status[i]))                 #       run the finish function
            slu$jdb$finish[i] <- 'done'
            save_slu_database('jdb')                                          #       save the database again after setting finish
         }
      }
      
      message('Finished running ', length(reps), ' rep', ifelse(length(reps) != 1, 's', ''))
   }
}