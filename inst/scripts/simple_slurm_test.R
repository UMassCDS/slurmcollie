# Slurm/batchtools test
# When launching RStudio, put /modules/admin-resources/ood-dev/unity-r_4.4.0.sif in the container override field


# This function is defined in https://github.com/UMass-UAS-Salt-Marsh/salt-marsh-mapping.git
# batch_test <- function(reps, file = '/work/pi_cschweik_umass_edu/batch_test/btest/test_') {
#    
#    item <- paste0('hello ', format(Sys.time()), '\nNode: ', Sys.info()[['nodename']], '\n')
#    writeLines(item, f <- paste0(file, reps, '.txt'))
#    cat('Stuff written to ', f, '\n', sep = '')
#    Sys.sleep(30)
# }


library(batchtools)
library(saltmarsh)

unlink('/work/pi_cschweik_umass_edu/batch_test/wednesday/reg01', recursive = TRUE)   # nuke old batchtools registry

makeRegistry(file.dir = "/work/pi_cschweik_umass_edu/batch_test/wednesday/reg01", conf.file = '/work/pi_cschweik_umass_edu/batch_test/wednesday/batchtools-gs.conf.R')
jobs <- batchMap(fun = saltmarsh::batch_test, reps = 4:6)
submitJobs()


getStatus()
