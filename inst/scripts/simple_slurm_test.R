# Slurm/batchtools test
# When launching RStudio, put /modules/admin-resources/ood-dev/unity-r_4.4.0.sif in the container override field




library(batchtools)
library(saltmarsh)

unlink('/work/pi_cschweik_umass_edu/batch_test/wednesday/reg02', recursive = TRUE)   # nuke old batchtools registry


makeRegistry(file.dir = "/work/pi_cschweik_umass_edu/batch_test/wednesday/reg02", 
             conf.file = system.file('batchtools.conf.R', package = 'saltmarsh', lib.loc = .libPaths(), mustWork = TRUE))


jobs <- batchMap(fun = saltmarsh::batch_test, rep = 7:8)
submitJobs()


getStatus()
