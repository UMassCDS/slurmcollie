#reg_dir <- 

#batchtools::makeRegistry(file.dir = 'registry', conf.file = system.file('batchtools.conf.R', package = 'saltmarsh'))

                         



# # Modified from Ethan's batchtools.conf.R
# makeClusterFunctionsSlurm(template = system.file('slurm.tmpl', package = 'saltmarsh', mustWork = TRUE),
#                           array.jobs = TRUE,
#                           nodename = saltmarsh:::the$login_node)
#                           


# makeClusterFunctionsSlurm(template = "/work/pi_cschweik_umass_edu/marsh_mapping/salt-marsh-mapping/inst/slurm.tmpl",
#                           array.jobs = TRUE,
#                           nodename = 'login1')



#batch_test(format(Sys.time()), '/work/pi_cschweik_umass_edu/marsh_mapping/reg/test1.txt')




############# HERE WE GO..... 

library(batchtools)

# reg_dir <- '/work/pi_cschweik_umass_edu/marsh_mapping/reg/'
reg_dir <- NA
regist <- batchtools::makeRegistry(file.dir = reg_dir, conf.file = system.file('batchtools.conf.R', package = 'saltmarsh'))                                                 # make registry - works
jobs <- batchtools::batchMap(fun = batch_test, reps = 6:11, reg = batchtools::makeRegistry(file.dir = reg_dir,
                                                                                  conf.file = system.file('batchtools.conf.R', package = 'saltmarsh')))           # set up jobs - works

batchtools::findNotDone()                                                                                                                                         # list jobs not done yet
findJobs()                                                                                                                                                        # list 'em all
findNotStarted()

submitJobs(jobs$job.id, reg = regist)
