# Modified from BirdFlowPipeline:batchtools.conf.R (https://github.com/birdflow-science/BirdFlowPipeline/blob/main/inst/batchtools.conf.R)



cluster.functions <- makeClusterFunctionsSlurm(template = system.file('slurm.tmpl', package = 'saltmarsh', mustWork = TRUE),
                             array.jobs = TRUE,
                             nodename = saltmarsh:::the$login_node)


default.resources <- list(
   ncpus = 1,
   chunks.as.arrayjobs = TRUE,
   max.arrayjobs.gpu = 0,
   max.arrayjobs.cpu = 250,
   partition.gpu = 'gpu-preempt,gpu',
   partition.cpu = 'cpu-preempt,cpu',
   constraint.gpu = 'rtx8000|1080ti',
   prefer.gpu = '2080|2080ti|v100'
)
