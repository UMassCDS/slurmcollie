#' get the job efficiency of a completed job from Slurm
#'
#' `get_job_efficiency()` calls the shell command `"seff"` on the job ID
#' via [batchtools::runOSCommand()], which uses ssh to connect to a login
#' node before running the command.  The resulting output is then parsed 
#' into an R list.
#' 
#' @param id The Slurm job ID including an array suffix e.g. "_1" if
#'  appropriate.
#' @param login_node Name of a login_node with ssh access
#'
#' @return A list with items:
#' \item{`job_id`}{Slurm job id - without array suffix}
#' \item{`array_job_id`}{Slurm job id with array suffix}
#' \item{`state`}{The job state}
#' \item{`cores`}{How many cores did the job use.}
#' \item{`cpu_utilized`}{How much CPU time was used.}
#' \item{`cpu_efficiency`}{CPU efficiency}
#' \item{`walltime`}{ Job wall-clock time (elapsed time) in h:m:s format}
#' \item{`memory_utilized`}{Memory utilized in human readable format with (varying) units}
#' \item{`memory_efficiency`}{Memory efficiency.}
#' \item{`mem_gb`}{Utilized memory in GiB (bytes * 1024^3)}
#' \item{`wall_min`}{Job wall-clock time in decimal minutes}
#' \item{`gpu_util_pct`}{GPU utilization percentage (NA for non-GPU jobs)}
#' \item{`gpu_mem_gb`}{GPU memory used in GiB (NA for non-GPU jobs)}
#' @importFrom batchtools runOSCommand
#' @importFrom yaml read_yaml
#' @importFrom fs fs_bytes
#' @importFrom hms parse_hms
#' @export
#' @seealso [batchtools::findJobs()]


get_job_efficiency <- function(id, login_node = slu$login_node) {
   
   
   stopifnot(length(id) == 1)
   cmd <- paste("seff ", id, sep = "")
   a <- batchtools::runOSCommand(cmd, nodename = login_node)
   if(a$exit.code != 0) {
      message('get_job_efficency: seff command failed for job ', id)
      return(NULL)
   }
   
   b <- a$output
   c <- yaml::read_yaml(text = paste(b, collapse = "\n"))
   
   # Cleanup names
   names(c) <- gsub("[[:blank:]/]+", "_", names(c))
   names(c) <- tolower(names(c))
   c$cluster <- NULL
   c$user_group <- NULL
   names(c)[names(c) == "job_wall-clock_time"] <- "walltime"
   
   # When launched with ncpus > 1, 'cores' will be reported as 'cores_per_node'
   c$cores <- c$cores                                       # cores is either 'cores' or 'cores_per_node'
   
   bytes <- fs::fs_bytes(c$memory_utilized) |> as.numeric()
   c$mem_gb <- bytes / 1024^3
   c$wall_min <- hms::parse_hms(c$walltime) |> as.numeric() / 60

   # Get GPU metrics from sacct — the .batch step carries actual TRES usage
   c$gpu_util_pct <- NA_real_
   c$gpu_mem_gb   <- NA_real_
   cmd_gpu <- paste("sacct -j", paste0(id, ".batch"),
                    "--format=TRESUsageInMax", "--parsable2", "--noheader")
   gpu_out <- batchtools::runOSCommand(cmd_gpu, nodename = login_node)
   if(gpu_out$exit.code == 0 && length(gpu_out$output) > 0 && nzchar(gpu_out$output[1])) {
      pairs <- strsplit(gpu_out$output[1], ",")[[1]]
      kv    <- strsplit(pairs, "=")
      vals  <- setNames(
         sapply(kv, function(x) paste(x[-1], collapse = "=")),
         sapply(kv, `[`, 1)
      )
      if(!is.na(vals["gres/gpuutil"]))
         c$gpu_util_pct <- as.numeric(vals["gres/gpuutil"])
      if(!is.na(vals["gres/gpumem"]))
         c$gpu_mem_gb <- fs::fs_bytes(vals["gres/gpumem"]) |> as.numeric() / 1024^3
   }

   return(c)
}
