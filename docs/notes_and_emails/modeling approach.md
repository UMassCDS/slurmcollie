Bradley Compton <bcompton@umass.edu>
	
Mon, Jan 27, 9:56?AM (1 day ago)
	
to Stephen, Scott, Ryan, Ethan, Charles
Hi all,

I'm looking forward to discussing the modeling approach this afternoon. I've invited my colleague Ethan Plunkett, who has a good head for modeling. He can join us for the first 45 minutes.

This is my 4th day on the salt marsh project, and I'm still getting my head around it. I'm still in the transition from overwhelmed to rolling up my sleeves, but I've got some initial thoughts about the approach, hopefully on the mark. I was glad to see Steve's comments concurred on several of the main points.

    I think we'll want to use fewer predictor variables--130 (presumably highly-correlated) predictors seems like massive overkill. It's great to have such a rich library to choose from. Steve's point about transferability is well-taken--to the extent we can get good results from one or two flights, the more useful results will be when applying elsewhere.
    Here's where I contradict (1) and suggest adding lots of predictor variables! I want to try upscaling, as I suspect fine-grained heterogeneity is adding a lot of noise. I'd like to try focal means (and probably SD, IQR, maybe 10th and 90th percentile) at several scales. With 8 cm pixels in 2 m transects, we have a fair bit of room to scale up. Also, it's probably worth trying derived metrics like NDVI and NDWI.
    The random forest model I've been able to look at seems severely overfit. Looking at the model results on the map, the transects jump out to the eye, as it's predicting them perfectly. And the confusion matrices I saw were all zeros on the off-diagonals. Ethan and I talked about this Friday and we think what's happening is that massive spatial autocorrelation is blowing out the out of bag (OOB) estimates. Each cell in a random holdout set will have several cells used to train the model within a few cm, so there's really no distinction between the OOB and the training set. I totally agree with Steve about keeping a true holdout for testing, but I think if we keep all of the cells, we'll run into the same problem there. We can talk about strategies to at least mitigate this, but probably we'll want to take a much smaller sample of the transects for training. Otherwise we're flying blind, without a good measure of model fit.
    I'd like to try pooling sites and building a generalized model for MA salt marshes, as this would be far more useful--doing field transects for each marsh is awfully expensive. Doubtless a pooled model will have worse fit; the question is how good it is. Probably best done as a cross-validation: e.g., fit to 6 sites, test on 3. We might also pool by region, e.g., a model for salt marshes on the Cape, one on the North Shore, etc. Stuff to try after we (hopefully) get decent fits to individual sites.
    To do all of the above, the code needs refactoring. All of the mucking around with GIS data needs to be pulled out of the modeling cycle so we can do many model runs quickly. I think Steve's comments hit on all of the changes I'd make, as did Ethan's thoughts when we talked Friday. I'm thinking of 4 separate main functions that can be called independently:
        Make derived training data: transform/upscale geoTIFFs and write to stack
        Collect data: read each raster, select all training points, collect in a data frame, and save as RDS (which takes seconds to read). Mild subsampling if necessary. Now we have all of the training data in something we can quickly read and select from.
        Fit model: Read training data from RDS (if not already cached), select training points, pull out holdout set, run RF model, return CCR, confusion matrix, var importance, and save fit. This should be able to cycle quickly, allowing automated variable selection if we want.
        Produce prediction geoTIFF: For models we like, go back to raster stack, reading only variables used in model, predict, and write raster model prediction.

I'm a pretty good R programmer, and I don't know Python, so I think I'll rewrite this in R. Part of me thinks this would be a good opportunity to learn Python, but that feels like a luxury given the short timeframe.

Thanks, Steve, for your suggestion about boosting. I'd like to try it. It'll presumably be easy to drop into the model fitting module, and we can do some RF vs. boosting head-to-head battles.

See you all this afternoon.

Brad


On Sat, Jan 25, 2025 at 1:34?PM Stephen Fickas <stephenfickas@gmail.com> wrote:

    I might consider the opposite approach :)

    Start with one flight then appears to be most promising and build up more flights if needed. Growing complexity as needed instead of shrinking complexity if possible.

    S

    On Sat, Jan 25, 2025 at 10:13?AM Scott Jackson <sjackson@umext.umass.edu> wrote:

        Hi Steve, (adding Brad to the conversation)

        Good thoughts. Our original approach, per Kate, was to use all layers at first, assuming this would produce the best results, then reduce the number of layers until we find the best balance between effort and results. Now, we are having doubts about whether using all layers will provide the best result. We’ve begun thinking about going to layers from a single year to see what kind of results we get. If we get good results, we could reduce the number of layers from that year and see how much we can simplify the data needs and still get good results. If the results are not so good, we then have to decide whether to add layers or use fewer layers as the next step in the process.

        Scott

        ____________________________________________________________________________________

        Scott Jackson, Extension Professor
        Department of Environmental Conservation
        Holdsworth Hall
        University of Massachusetts
        Amherst, MA 01003
        (413) 545-4743
        sjackson@umass.edu

         

        From: Stephen Fickas <stephenfickas@gmail.com>
        Sent: Saturday, January 25, 2025 1:00 PM
        To: Ryan Wicks <rwicks@umass.edu>
        Cc: Scott Jackson <sjackson@umext.umass.edu>; Charles Schweik <cschweik@umass.edu>
        Subject: Current Random Forest project

         

        I left a number of comments in Ryan's notebook that we can discuss Monday in the sub-group.

         

        But I have a broader question about the approach of stacking 140 bands across multiple years, seasons and tides. Let's say we get good results. As an outside reader, I might say good for you but so what? Who has 140 bands of data that matches? How does this generalize?

         

        In contrast, with the EPA bank project, I have honed down to early season, low-tide DEM. I then colorize to get 3 bands. So if someone outside can get a single drone flight in with these constraints, they are cooking.

         

        I think it might be worth honing in the same way with Ryan's project. Try with just one flight at what appears to be best season and tide level. See how we do with that. If miserable, then back to adding more bands. But check most generalizable first.

         

        Or not. Just brainstorming.

         

        S

	
