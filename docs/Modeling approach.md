Draft salt marsh vegetation modeling approach.
# Source data
## Predictors
All in UAS data collection\\***site***\\
- Orthomosaics: RFM processing inputs\\Orthomosaics\\
- Canopy height model:  ***site***\\Share\\Canopy height models\\
  (Old Town Hill only so far)
- Ortho-based DEMs: ***site***\\Share\\Photogrammetry DEMs\\
- LiDAR-based DTMs: (not available yet)
## Field data
All in UAS data collection\\***site***\\
- **Transects**: RFM processing inputs\\Ground Truth Data\\ (need to be recreated for all sites but Old Town Hill)
## Footprints
- footprint/\*.shp or site footprint/\*.shp (paths inconsistent)
## Text parameter files
- pars\\sites.txt - contains site, site_name, footprint, and standard for each site. 
	- site - 3 letter code
	- site_name - name used in directory paths on Google Drive
	- footprint - path to footprint shapefile, including subdir
	- standard - name of geoTIFF to treat as the standard for grain and alignment. These should be fine-grained files, such as Mica files. *Do not change these without recreating stack from gather.data.R!*
## Relevant docs
- [Flight log](UAS Data Collection\UAS Data Log_Salt Marsh_2018-2024)
# Results
TBD
# Notes
## Pooling across sites
Although we plan to run models for individual sites, we want to try pooling across sites, in the hopes we can come up with a general model for Massachusetts salt marshes (or perhaps by region within Massachusetts). We'll cross-validate by site. An alternative to pooling is a stacking approach: build a separate model for each site and combine results at the end.
## Target classification
- Total of 27 subclasses
- We're most interested in vegetation, lumping water and bare ground to class. This gives us 17 (sub)classes.
- ICS_V4 lumping includes 6 classes:
	1. Water
	2. Low Marsh or Intermediate Marsh
	3. Transitional Marsh
	4. High Marsh
	5. Border Marsh
	6. Other Vegetation or Bare Ground
- Scott is highly interested in distinguishing among the three Transitional Marsh classes--that would be super-useful.
## Sampling strategy
- Transect polys are 2 m wide, varying lengths
- Previous runs used all 8 cm pixels within polys (transects are 25 pixels wide). We believe the resulting spatial autocorrelation contaminated the OOB estimates, and expect it would also contaminate true holdouts if they were simply randomly-selected points.
- One approach is to subsample these points to make them far more sparse. 
- Another approach is to cut them into blocks (2x2 m, perhaps), retaining all points but using blocks as the units for OOB and holdout data. We won't have enough blocks to treat each block as a sample point. 
- Another consideration is we want to try upscaling input data to reduce spatial heterogeneity. This would result in fewer (perhaps far fewer) points in each block.
# Data prep and modeling overview
1. Copy geoTIFFs from the Google Drive for each site, resample and align, clip, and put separate geoTIFFs in a single folder on Unity for each site (the "stack," though they're separate files). That's what I've done, though want to make it read properly from the Google drive plus a couple more changes.
2. Produce derived rasters such as NDVI in the stack folders. (optional)  
3. Upsample selected rasters into the stack folders. (optional)
4. Sample rasters for transects at a site, producing an R data frame (this is the first time we have anything big in memory, and it's not that big). This data frame does NOT contain the entirety of the rasters, just the values at the sample points. Save as an RDS (binary R format that's fast to read).
5. Stitch sample data frames for multiple sites and save as an RDS. If this gets too big, we'll have to subsample. Only for building models across multiple sites. (optional)
6. Fit model. Read sample data for site(s). Optionally reclass dependent variable (e.g., to ICS_V4). Fit random forest or AdaBoost model(s), potentially evaluate fit automatically and refit, write fit statistics and model for human evaluation and future prediction.
7. Predict model. For the few models we think have potential, read the model and go back to the "stack" and create a geoTIFF of predicted classes.  

Step 1 is only repeated when you have fresh raster data, for instance as you finish canopy height models. It only needs to be run for the new/changed layers. It'll be relatively slow, much of that getting data off the Google Drive.  

Step 2 is only run when source data (or the metrics) change.

Step 3 is only run when 1 or 2 change.

Steps 4 and are only run when 1/2/3 change.

Step 6 will be run a lot of times, often in a loop. It'll only read the data file (the RDS) once per session. Nearly all of the time it takes will be in fitting the models.

Step 7 will take longer, as it has to go back to the raster data (but only for variables that end up in the model). I anticipate not running this nearly as many times as Step 6, as most models will obviously suck from the stats and we won't want to look at them.
# Code 
8. **gather_data**. Collect raster data from various source locations (orthophotos, DEMs, canopy height models) for each site. Clip to site boundary, resample and align to standard resolution.  
	*Arguments*:  
		**site** - one or more site names. Default = all sites  
		**pattern** -  regex filtering rasters. Default = '.\*' (match all)  
		**subdirs** - subdirectories to search. Default = c('RFM processing inputs/Orthomosaics/', 'Share/Photogrammetry DEMs/', 'Share/Canopy height models/')  
		**basedir** - full path to subdirs  
		**standard** - point to a raster that will be used as the standard for grain and alignment; all rasters will be resampled to match. Default: orthomosiacs/ Mica file with earliest date (regardless of whether it's in the rasters specification).   
		**replace** = FALSE. If true, deletes the existing stack and replaces it. Use with care!  
		**resultdir** - name of result subdirectory. Default = 'predictors/'  
	*Source*: geoTIFFs for each site  
	*Results*: geoTIFFs, clipped, resampled, and aligned  
- All source data are expected to be in EPSG:4326. Non-conforming rasters will be reprojected.
- Note that adding to an existing stack using a different standard will lead to sorrow. If a stack for the site already exists and replace = FALSE, one of the rasters in the stack will be compared with the standard for alignment, potentially producing an error. **Not currently implemented**; not sure if I'll bother.
- **May modify it to read from [Google drive](https://googledrive.tidyverse.org/)**, but not sure what the best approach to doing this on Unity is yet. It might make more sense to copy source files from the Google drive first. It'd be slicker but probably slower to read files from GD.
		
9. **upscale_predictors**. 
	Upscale predictor variables. Create predictors at coarser grains (e.g., mean, SD, IQR, maybe 10th and 90th percentile)  
	*Arguments*:  
		rasters - regex or vector of target geoTIFFs. Default: all files with "ortho" in the name  
		functions - list of functions. Default = c('mean', 'sd', 'iqr', 'p10', 'p90')  
		scales - number of cells for focal functions. Must be odd. Default = c(3, 5, 7, 9, 11)  
	*Source*: processed geoTIFFs (from layer_stack_kcf) in site-specific stack folders  
	*Results*: additional geoTIFFs in the same folder. Name will be \<source name>\_\<function>\_\<scale>.tif  
	Dunno what functions and scales will make sense (if any). Will play with it.
	
10. **derive_predictors**. Derive indices by combining two or more predictor variables. Start with NDVI and NDWI.   
	*Arguments*:  
		rasters - regex or vector of target geoTIFFs. Default: all files with "ortho" in the name.   
		functions - list of functions. Default = c('NDVI', 'NWVI')  
	*Source*: processed geoTIFFs (from layer_stack_kcf) in site-specific stack folders  
	*Results*: additional geoTIFFs in the same folder. Name will be \<source name>\_\<function>.tif  
	Need to do this only on files for sensors with near infrared (NDVI) or both near and short-wave infrared (NDWI). **WHICH SENSORS ARE THESE? Do we have sensors with 4 bands, or do we need to combine multiple sensors?** May need an argument to specify bands too.
	
11. **sample_predictors**. Read each raster, select all training points, collect in a data frame, and save as RDS (which takes seconds to read). Mild subsampling if necessary. Now we have all of the training data in something we can quickly read and select from.  
	Arguments:  
	Source: processed geoTIFFs from layer stack, transect polys  
	Result: site_name.RDS in dataframes/  
	To figure out: how to do a block sampling scheme to reduce spatial autocorrelation

12. **stitch_sites**. Stack data frames from individual sites for all sites or a selected subset.  
	Arguments: vector of site names, result name  
	Source: \*.RDS in dataframes/  
	Result: result.RDS in dataframes/  

13. **fit_model**. Read training data from RDS (if not already cached), select training points, pull out holdout set, run RF model, return CCR, confusion matrix, var importance, and save fit. This should be able to cycle quickly, allowing automated variable selection if we want. Option *reclass* to reclass dependent variable. 

14. **predict_fit**. For models we like, go back to raster stack, reading only variables used in model, predict, and write raster model prediction.