# Read a predict grid and plot it nicely

plot_predict <- function(tiff = 'C:/Work/etc/saltmarsh/data/oth/gis/predicted/predict_oth_2025-Apr-28_13-54.tif',
                         pal = 'ggsci::category20b_d3') {
   
   
   library(terra)
   library(paletteer)
   
   pal <- paletteer::paletteer_d(pal)
   
   x <- rast(tiff)
   terra::plot(x, col = pal)
   
}