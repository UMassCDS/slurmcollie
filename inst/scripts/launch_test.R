# test launch


new_db('jdb', really = TRUE)


launch('batch_test', reps = 7:9, comment = '7 8 9')
launch('batch_test', reps = 1:5, comment = '5 jobs, will throw errors')   # will throw errors on purpose
