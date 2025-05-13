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

the$login_id <- 'login3'

# reg_dir <- '/work/pi_cschweik_umass_edu/marsh_mapping/reg/'                                                                                                     # it won't let me use this; dk why
reg_dir <- NA                                                                                                                                                     # does work with a temporary registry
regist <- batchtools::makeRegistry(file.dir = reg_dir, conf.file = system.file('batchtools.conf.R', package = 'saltmarsh'))                                       # make registry - works
# jobs <- batchtools::batchMap(fun = batch_test, reps = 6:11, reg = batchtools::makeRegistry(file.dir = reg_dir,
#                                                                                   conf.file = system.file('batchtools.conf.R', package = 'saltmarsh')))           # set up jobs - works
jobs <- batchtools::batchMap(fun = batch_test, reps = 6:11, reg = regist)           # set up jobs - works

findNotDone()                                                                                                                                                     # list jobs not done yet
findJobs()                                                                                                                                                        # list 'em all
findNotStarted()

# probably want to set resources list here
submitJobs(jobs$job.id, reg = regist)                                                                                                                             # should launch jobs, but fails




# Okay, this section works!!!!!!!!!    But I can't get Slurm job ids, thus can't call get_job_efficiency. Plus, it's not using my slurm template
library(batchtools)

the$login_id <- 'login3'

tmp = makeRegistry(file.dir = NA, make.default = FALSE)
jobs <- batchMap(fun = batch_test, reps = 2:5, reg = tmp)           # set up jobs - works

submitJobs(reg = tmp)
findJobs(reg = tmp)
getStatus(reg = tmp)
getErrorMessages(reg = tmp)

# clearRegistry(tmp)
# 
##########################################################

# This one uses a slimmed down Slurm template. I renamed the old one as slurm_big.tmpl. I still don't get job ids. Ethan obviously can. Dig in next week.

library(batchtools)
reg <- makeRegistry(file.dir = "my_registry", conf.file = system.file('slurm.tmpl', package = 'saltmarsh', mustWork = TRUE))
jobs <- batchMap(fun = batch_test, reps = 2:5, reg = reg)           # set up jobs - works
submitJobs(reg = reg)
status <- getStatus(reg = reg)
print(status)
# Look for column 'batch.id'
# 
# 
# 
# 
########################################################## Let's get this right
########################################################## Remember: slurm.tmpl comes from the built package, so must rebuild after changing
########################################################## Once the registry is created, it can be accessed with loadRegistry
########################################################## Huh. Need a new registry every time you submit jobs. WTF?
########################################################## 
########################################################## use testJob() to test before launching lots
########################################################## consider using chunk() for many quick tasks
library(batchtools)

reg_dir <- '/work/pi_cschweik_umass_edu/marsh_mapping/registry/'
reg <- makeRegistry(file.dir = reg_dir, conf.file = system.file('slurm.tmpl', package = 'saltmarsh', mustWork = TRUE))        # I think this only happens once


loadRegistry(file.dir = reg_dir, writeable = TRUE)                                                                            # subsequent runs
clearRegistry()
jobs <- batchMap(fun = batch_test, reps = 43:45)                                                                              # uses default registry
submitJobs()
getStatus()
getErrorMessages()
findDone()
j <- getJobTable()                                                                                                            # holds a bunch of info, but not Slurm job id
