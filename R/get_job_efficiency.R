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
#' \item{`cores`}{How many cores did the job use}
#' \item{`cpu_utilized`}{How much CPU time was used}
#' \item{`cpu_efficiency`}{CPU efficiency}
#' \item{`walltime`}{ Job wall-clock time (elapsed time) in h:m:s format}
#' \item{`memory_utilized`}{Memory utilized in human readable format with (varying) units}
#' \item{`memory_efficiency`}{Memory efficiency.}
#' \item{`mem_gb`}{Utilized memory in GiB (bytes * 1024^3)}
#' \item{`wall_min`}{Job wall-clock time in decimal minutes}
#' \item{`gpu_util_pct`}{GPU utilization percentage (NA for non-GPU jobs)}
#' \item{`gpu_mem_gb`}{GPU memory used in GiB (NA for non-GPU jobs)}
#' \item{`gpu_name`}{GPU model name(s): `"l40s x4"` if all the same, `"l40s, v100, v100"` if mixed (NA for non-GPU jobs)}
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

   # Get GPU name from AllocTRES
   c$gpu_name <- NA_character_
   cmd_tres <- paste("sacct -j", id, "--format=AllocTRES", "--parsable2", "--noheader", "--allocations")
   tres_out <- batchtools::runOSCommand(cmd_tres, nodename = login_node)
   if(tres_out$exit.code == 0 && length(tres_out$output) > 0 && nzchar(tres_out$output[1])) {
      tres_pairs <- strsplit(tres_out$output[1], ",")[[1]]
      gpu_entries <- grep("^gres/gpu:[^=]+=", tres_pairs, value = TRUE)   # typed only, e.g. gres/gpu:l40s=1
      if(length(gpu_entries) > 0) {
         gpu_types  <- sub("^gres/gpu:([^=]+)=\\d+$", "\\1", gpu_entries)
         gpu_counts <- as.integer(sub("^gres/gpu:[^=]+=([0-9]+)$", "\\1", gpu_entries))
         all_gpus   <- rep(gpu_types, gpu_counts)
         if(length(unique(all_gpus)) == 1) {
            n <- length(all_gpus)
            c$gpu_name <- if(n == 1) all_gpus[1] else paste0(all_gpus[1], " x", n)
         } else {
            c$gpu_name <- paste(all_gpus, collapse = ", ")
         }
      }
   }

   return(c)
}
