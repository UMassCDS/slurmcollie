#' Script to set up environment for parameters in package slurmcollie
#' 
#' The environment `slu` is used for user parameters. They
#' are assigned by `init_slurmcollie()`, which is run when the package is 
#' loaded, and also may be run by the user, e.g., which parameter
#' files are changed.


slu <- new.env(parent = emptyenv())
print('defined slu!')