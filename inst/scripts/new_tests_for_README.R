launch('batch_test', reps = 1:5, comment = 'Five reps of batch_test')
info()
kill(3)
Sys.sleep(10)
info()
Sys.sleep(10)
info()
Sys.sleep(30)
info()


kill('all')
sweep()
purge('all')


launch('big_test', comment = 'this will take longer')

purge(list(done = TRUE))
info()
