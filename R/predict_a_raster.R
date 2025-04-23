# predict a raster

library(peakRAM)
# peakRAM(fit('oth'))

path <- '/work/pi_cschweik_umass_edu/marsh_mapping/data/oth/gis/flights'
x <- list.files(path)
                                            

rasters <- rast(file.path(path, x))
names(rasters) <- sub('^(\\d)', 'X\\1', names(rasters))                         # files with leading digit get X prepended by R  
                
predicted <- terra::predict(rasters, zz)
