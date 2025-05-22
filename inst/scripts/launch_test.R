# test launch


# new_db('jdb', really = TRUE)                              # be careful with this!!


launch('batch_test', reps = 7:9, comment = '7 8 9')
Sys.Sleep(63)
launch('batch_test', reps = 1:5, comment = '5 jobs, will throw errors')   # will throw errors on purpose
Sys.Sleep(125)
launch('batch_test', reps = 100, comment = 'one more')
