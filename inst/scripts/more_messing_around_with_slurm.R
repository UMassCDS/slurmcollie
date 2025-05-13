# Monday afternoon try...




library(batchtools)

reg_dir <- '/work/pi_cschweik_umass_edu/marsh_mapping/registry21'
resources <- list(walltime = '00:10:00', memory = 5)    # walltime is hh:mm:ss; memory is in MB
reg <- makeRegistry(file.dir = reg_dir, conf.file = file.path( "/work/pi_cschweik_umass_edu/marsh_mapping/pars", 'batchtools.conf.R'), work.dir = "/work/pi_cschweik_umass_edu/marsh_mapping/")

#batchMap(fun = saltmarsh::batch_test, reps = 3:5)
#batchMap(fun = function(x) writeLines(item, paste0('/work/pi_cschweik_umass_edu/marsh_mapping/btest/test_', x, '.txt')), x = 3:5)
batchMap(fun = function(x) z <- runif(matrix(1000, x, x)), x = 3:5)
submitJobs(resources = resources)
Sys.sleep(3)
print(getStatus())

