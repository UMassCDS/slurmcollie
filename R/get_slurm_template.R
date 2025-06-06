#' Get the path for the slurm template
#' 
#' @returns The path to the slurm template
#' @export


get_slurm_template <- function() {
   
   
   file.path(slu$templatedir, 'slurm.tmpl')
   
}