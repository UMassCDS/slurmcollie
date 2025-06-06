# Set up Slurm template. Pass this file to makeRegistry as conf.file.
# To run properly on Unity, you must include the following line in the "Override Rstudio image location" field
#    /modules/admin-resources/ood-dev/unity-r_4.4.0.sif
# Authors: Ehtan Plunkett, Georgia Stuart, Bradley Compton
# 21 May 2025


cluster.functions <- makeClusterFunctionsSlurm(
   template = slurmcollie::get_slurm_template())


default.resources <- list(                # Set defaults. These may be overridden by passing resources to submitJobs.
   walltime = '00:10:00',                 #    max time to run (hh:mm:ss)
   memory = 1,                            #    max memory (GB); minimum should be 1 GB (slurm.tmpl changes this from default MB to GB)
   measure.memory = FALSE,                #    enable memory measurement for getJobStatus; not needed if using get_job_efficiency
   ncpus = 1,                             #    number of CPUs
   chunks.as.arrayjobs = FALSE,           #    group selected jobs sequentially; must set up chunks in submitJobs; see help(submitJobs)
   partition.cpu = 'cpu-preempt,cpu'      #    which partitions jobs can run on
)
