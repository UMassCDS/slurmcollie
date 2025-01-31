Ryan Wicks  
Fri, Jan 24, 6:02 PM (5 days ago)  
to Stephen, Bradley, William, Eva

Hi Steve, Brad, Eva, and William,

   Here is a link to all of Python and R code that we've been using fore the EPA-funded salt Marsh project form the last 7 years:

https://drive.google.com/drive/folders/1EVkBsHHDC9Vynrbl3QRYBw_WFrrvXFjv?usp=sharing

The file path in the google drive share is: \7. SaltMUAS_share\Code

This includes the Random Forest Model (RFM) code that Kate wrote, and then Georgia edited last year to run more efficiently; the versions of that code are in the folder labeled "Random Forest Model". There are 4 very similar versions of the code with only slight changes between them. Perhaps the most pertinent versions are the ones with the "Ryan" and "Georgia" suffixes. The "Georgia" version is the version that Georgia handed off to us after her edits before I started using it. The "Ryan" version is probably almost identical except there were perhaps a few file pathing changes and is the most recent general version that I have run. The other two versions are specific versions that were for running the RFM with the 27 landcover subclasses aggregated into a few broader classes - I think all that I changed was just the file paths for inputs where the subclasses had been aggregated.

The "Stacking Raster Inputs Code" folder has code for building an arbitrary number of raster files into a single raster with an arbitrary number of bands that can be passed as an input into Kate and Georgia's RFM code.

"Hydrology R_scripts" is code that was written (and is still being worked on) by Eva Gerstle for doing statistical analysis of our hydrology data at each of our 9 sites.

"Ground Truth Vector File Construction" was supposed to contain code that was written by Brett Barnard that would take point data that was collected in accordance with our field data collection protocols outlined in QAPP Appendix C and QAPP Appendix E (see https://drive.google.com/open?id=1NxsSOBkB5gZwtqMTm21QDe383GieiZWP&usp=drive_fs), and then from those points construct the polygons that would define the regions of the ground surface that the field crew wanted to classify. This code, along with the documentation, and transects that Brett Barnard had constructed are all missing. I am not sure what happened to these files, but it is possible that the UMass system cued them for deletion after a set time after Brett left UMass. I am going to keep trying to track extra copies of them down, but if we don't find any we can discuss howe we want to recreate those polygon creation tools and the polygons themselves; those polygons are passed as inputs to the RFM model to define regions of pixels that constitute training and test/validation data.

@William Speiser and @Eva Gerstle, Brad, Steve and I are going to meet regularly on Mondays 1pm - 3pm specifically to have technical discussions for pushing the RFM work forward. The zoom meeting information is below. You are both welcome to join as you are interested and able, though I understand you both have commitments of higher priority. William, I am hopeful that if the classification modeling can be shown to be accurate, it could perhaps serve as decent time-series land-cover data for about 800 acres of space for the time period 2018-2023. Maybe... but I guess we have to see if we can actually get it working reliably. I am really glad that Brad is around to take the lead on that effort!

...

Cheers,
Ryan
