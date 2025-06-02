# test launch


# new_db('jdb', really = TRUE)                              # be VERY careful with this!!


launch('batch_test', reps = 7:9, comment = '7 8 9', finish = 'launch_test_finish')
# launch('batch_test', reps = 3:4, comment = '3-4', finish = 'launch_test_finish')
Sys.sleep(3)
launch('batch_test', reps = 10:11, moreargs = list(wait = 5), comment = '10 and 11, with 5 min delay up front')
Sys.sleep(63)
launch('batch_test', reps = 1:5, comment = '5 jobs, will throw errors', finish = 'launch_test_finish')   # will throw errors on purpose
Sys.sleep(125)
launch('batch_test', reps = 100, moreargs = list(wait = 30), comment = 'wait 30 min before doing anything')




launch('batch_test', reps = 20:21, comment = '20 and 21')



launch('batch_test', reps = 30:32, comment = 'A test using slurmcollie')



