Draft salt marsh vegetation modeling approach.
# Source data
## Predictors
All in UAS data collection/***site***/
- Orthomosaics: RFM processing inputs/Orthomosaics/
- Canopy height model:  ***site***/Share/Canopy height models/
  (Old Town Hill only so far)
- Ortho-based DEMs: ***site***/Share/Photogrammetry DEMs/
- LiDAR-based DTMs: (not available yet)
## Field data
All in UAS data collection/***site***/
- **Transects**: RFM processing inputs/Ground Truth Data/ (need to be recreated for all sites but Old Town Hill)
## Footprints
- RFM processing inputs/footprint/\*.shp or site footprint/\*.shp (paths inconsistent)
## Text parameter files
- pars/**sites.txt** - contains site, site_name, footprint, and standard for each site. 
	- site - 3 letter code
	- site_name - name used in directory paths on Google Drive
	- footprint - path to footprint shapefile, including subdir
	- standard - name of geoTIFF to treat as the standard for grain and alignment. These should be fine-grained (8 cm) rasters, such as Mica files. *Do not change these without recreating stack with gather.data.R!*
- pars/**classes.txt** - maps raster values to various classification schemes. This is where reclassification for lumping and multi-stage models are stored. Each classification consists of 2 columns:
	- \<class> - numeric class value. These should be nested or unique across classifications, so we can use the same legend for all vegetation rasters.
	- \<class>_name - name of the class
- pars\/*derive.txt* - lists source and result files for derived metrics (NDVI, NDWI). Exact details not pinned down yet. See **derive_data** for details.
## Reading source data
Data are currently up on a Google Drive. It's not working well, and IT's suggestion is to get a NAS (Synology 8 bay, 3 20 TB drives = 40 TB RAID 5 for $3687.56; natively supports SFTP without connection to a server!) and set it up in the LSL. gather_data can read from local drive, Google Drive, or SFTP, so we'll be ready for switchover from Google Drive to a NAS.
## Relevant docs
- [Flight log](https://docs.google.com/spreadsheets/d/1y-2HHg88itLQekMAlTrHAq7HzCulU56lfH7j_USbK5Y/edit?gid=0#gid=0)
- [R caret library](https://topepo.github.io/caret/index.html)
- [Python scikit-learn library](https://scikit-learn.org/stable/index.html)
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
- We want to try multi-stage classification, e.g., veg/water/bare ground on 1st pass, then finer veg types on second pass. 
- pars\/classes.txt defines various classification schemes. We'll reclassify on the fly on fit_model and predict_fit.
## Renaming predictors
In order to combine across sites, we'll need to treat comparable predictors together, e.g., rename  02Aug19_OTH_Low_Mica_Ortho and 26Jul19_WES_Low_Mica_Ortho to midsummer_Low_Mica_Ortho. Rather than rename geoTIFFs, I'm inclined to come up with a mapping file to index these on the fly. Ryan has a good sense of how to lump these. I need to come up with a scheme. We'll have a parameter file, lump_fields.txt or something that defines these, and a function that can be called by fit_model and predict_fit.
## Sampling strategy
- Transect polys are 2 m wide, varying lengths
- Previous runs used all 8 cm pixels within polys (transects are 25 pixels wide). We believe the resulting spatial autocorrelation contaminated the OOB estimates, and expect it would also contaminate true holdouts if they were simply randomly-selected points.
- One approach is to subsample these points to make them far more sparse. 
- Another approach is to cut them into blocks (2x2 m, perhaps), retaining all points but using blocks as the units for OOB and holdout data. We won't have enough blocks to treat each block as a sample point. 
- Another consideration is we want to try upscaling input data to reduce spatial heterogeneity. This would result in fewer (perhaps far fewer) points in each block.
## Tracking model runs
- We'll want an approach to track modeling runs. I don't have details worked out, but I'm thinking there will be a master model file (tab-delimited text) with a row for each model that includes the following:
	- model id
	- date it was run
	- site(s)
	- modeling approach used (random forest, AdaBoost)
	- x variables included, or maybe link to parameters file
	- hyperparameters (or link to file)
	- model fit summary: CCR, kappa, F1, etc.
	- link to model fit: confusion matrix, variable importance
	- link to model in RDS file
	- link to predicted geoTIFF
	- subjective scoring field - 1 to 5 stars or something
	- comment field
- When a model is launched, a row will be created for it
- When a predicted grid is created, a link to it will be added
- a function to delete (or maybe archive) rows that deletes/archives linked data files too
- May want a split mechanism to launch models vs. actually run them
# Data prep and modeling overview
1. Copy geoTIFFs from the Google Drive (or NAS via SFTP) for each site, resample and align, clip, and put separate geoTIFFs in a single folder on Unity for each site (the "stack," though they're separate files).
2. Produce derived rasters such as NDVI in the stack folders. (optional)  
3. Upsample selected rasters into the stack folders. (optional)
4. Sample rasters for transects at a site, producing an R data frame (this is the first time we have anything big in memory, and it's not that big). This data frame does NOT contain the entirety of the rasters, just the values at the sample points. Save as an RDS (binary R format that's fast to read).
5. Stitch sample data frames for multiple sites and save as an RDS. If this gets too big, we'll have to subsample (it probably won't). Only for building models across multiple sites. (optional)
6. Fit model. Read sample data for site(s). Optionally reclass dependent variable (e.g., to ICS_V4). Splits data into train/test/validation samples (random forest does one split internally with OOB). Fit random forest or AdaBoost model(s), potentially evaluate fit automatically and refit, write fit statistics and model for human evaluation and future prediction. This will be set up to support multi-stage modeling. 
7. Predict model. For the few models we think have potential, read the model and go back to the "stack" and create a geoTIFF of predicted classes.  

Step 1 is only repeated when you have fresh raster data, for instance as you finish canopy height models. It only needs to be run for the new/changed layers. It'll be relatively slow, much of that getting data off the Google Drive.  

Step 2 is only run when source data (or the metrics) change.

Step 3 is only run when 1 or 2 change.

Steps 4 and 5 are only run when 1/2/3 change.

Step 6 will be run a lot of times, often in a loop. It'll only read the data file (the RDS) once per session. Nearly all of the time it takes will be in fitting the models.

Step 7 will take longer, as it has to go back to the raster data (but only for variables that end up in the model). I anticipate not running this nearly as many times as Step 6, as most models will obviously suck from the stats and we won't want to look at them.
# Code 
## find_standards
Pick raster standards (grain and alignment) for gather_data. Creates a new sites.txt. May make more sense to just do this by hand for only 10 files. They shouldn't change over time.
	*Status*: done, but need to work with Google Drive and SFTP. Might drop this.
## gather_data
Collect raster data from various source locations (orthophotos, DEMs, canopy height models) for each site. Clip to site boundary, resample and align to standard resolution.  
### Arguments
**site** - one or more site names. Default = all sites  
**pattern** -  regex filtering rasters. Default = '.\*' (match all)  
**subdirs** - subdirectories to search. Default = c('RFM processing inputs/Orthomosaics/', 'Share/Photogrammetry DEMs/', 'Share/Canopy height models/')  
**basedir** - full path to subdirs  
**resultbase** - base name of result directory
**resultdir** - subdir for results. Default is 'stacked/'. The site name will be appended to this.
**replace** = FALSE. If true, deletes the existing stack and replaces it. Use with care!  
**update** -  if TRUE, only process new files, assuming existing files are good. Default = TRUE.  
**sourcedrive** - one of 'local', 'google', 'sftp'
	- 'local' - read source from local drive  
	- 'google' - get source data from currently connected Google Drive (login via browser on first connection) and cache it locally. Must set cachedir option.  
	- 'sftp' - get source data from sftp site. Must set sftp option  and cachedir option.  
**cachedir** -  path to local cache directory; required when sourcedrive = 'google' or 'sftp'. The cache directory should be larger than the total amount of data processed--this code isn't doing any quota management. This is not an issue when using a scratch drive on Unity, as the limit is 50 TB. There's no great need to carry over cached data over long periods, as downloading from Google to Unity is very fast. To set up a scratch drive on Unity, see https://docs.unity.rc.umass.edu/documentation/managing-files/hpc-workspace/. Be polite and release the scratch workspace when you're done. See comments in get_file.R for more notes on caching.  
**sftp** - SFTP credentials, either 'username:password' or '\*filename' with username:password. Make sure to include credential files in .gitignore and .Rbuildignore so it doesn't end up out in the world!  
### Source
geoTIFFs for each site  
### Results
geoTIFFs, clipped, resampled, and aligned  
### Status
**need to implement sftp**
### Notes
- All source data are expected to be in EPSG:4326. Non-conforming rasters will be reprojected with a warning. Alignment for reprojected files should be checked, as I've found one that was misaligned.
- Note that adding to an existing stack using a different standard will lead to sorrow. If you change a site's raster standard, **delete the stack** or use **replace = TRUE** on a run for all files at the site.
## upscale_data 
Upscale predictor variables. Create predictors at coarser grains (e.g., mean, SD, IQR, maybe 10th and 90th percentile)  
### Arguments
**site** - one or more sites, or NULL for all
**pattern** - regex matching source files. Default: all files with "ortho" in the name  
**functions** - list of functions. Default = c('mean', 'sd', 'iqr', 'p10', 'p90')  
**scales** - number of cells for focal functions. Must be odd. Default = c(3, 5, 7, 9, 11)  
### Source
Processed geoTIFFs in site-specific stack folders  
### Results
additional geoTIFFs in the same folder. Name will be \<source name>\_\<function>\_\<scale>.tif   
## derive_data
Derive indices by combining two or more predictor variables. Start with NDVI and NDWI.   
### Arguments
**site** - one or more sites, or NULL for all
**pattern** - regex matching result names
**metrics** - list of functions. Default = c('NDVI', 'NWVI')  
**source** - path to parameters file, default = 'pars\/derive.txt' File has columns:
- site
- source1 - 1st source file
- source2 - 2nd source file
- result - base name of result file (ndvi or ndwi appended)
- bands? Here if these are consistent; otherwise in function
### Source
processed geoTIFFs (from layer_stack_kcf) in site-specific stack folders  
### Results
additional geoTIFFs in the same folder. Name will be \<source name>\_\<function>.tif 
### Notes
- Need to do this only on files for sensors with near infrared (NDVI) or both near and short-wave infrared (NDWI). **WHICH SENSORS ARE THESE? Do we have sensors with 4 bands, or do we need to combine multiple sensors?** May need an argument to specify bands too. See - [Flight log](https://docs.google.com/spreadsheets/d/1y-2HHg88itLQekMAlTrHAq7HzCulU56lfH7j_USbK5Y/edit?gid=0#gid=0).
## sample_data
Read each raster, select all training points, collect in a data frame, and save as RDS (which takes seconds to read). Mild subsampling if necessary. Now we have all of the training data in something we can quickly read and select from.  
### Arguments
### Source
processed geoTIFFs from layer stack, transect polys  
### Results
site_name.RDS in dataframes/  
### Notes
- To figure out: how to do a block sampling scheme to reduce spatial autocorrelation
## stitch_sites
Stack data frames from individual sites for all sites or a selected subset.  
### Arguments
vector of site names, result name  
### Source
\*.RDS in dataframes/  
### Results
result.RDS in dataframes/  
## fit_model
Read training data from RDS (if not already cached), select training points, pull out holdout sets (validation for RF, test/validation for boosting), run RF model, return CCR, confusion matrix, var importance, and save fit. This should be able to cycle quickly, allowing automated variable selection if we want. Option *reclass* to reclass dependent variable. This will be set up to easily support multi-stage modeling.
## predict_fit
For models we like, go back to raster stack, reading only variables used in model, predict, and write raster model prediction.