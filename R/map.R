#' Build a geoTIFF map of predictions for specified model fit
#' 
#' Console command to launch a prediction run via `do_map`, typically in a batch job on Unity.
#' 
#' @param model Model ID, fit filename, or fit object - figure it out)
#' @param clip Optional clip, vector of xmin, xmax, ymin, ymax
#' @param result Optional result filename. If not provided, uses name from database if it exists. Otherwise, constructs a name.
#' @export



map <- function(fit, clip = NULL, result = NULL) {
   

   
   # if model is a scalar number,
   #    it's fit id, so pull fit from database
   # if it's a string,
   #    it's a filename, so read filename to get fit
   # if it's a fit object,
   #    we've got it
   
 
   
   
   
   ts <- stamp('2025-Mar-25_13-18', quiet = TRUE)                                     # set format for timestamp in filename                         
   fx <- file.path(resultdir, paste0('predict_', the$site, '_', ts(now())))               # base result filename
   
     
   
 
   # Run info file returns some stats; I get others from https://github.com/birdflow-science/BirdFlowPipeline/blob/main/R/get_job_efficiency.R  
   
   
}