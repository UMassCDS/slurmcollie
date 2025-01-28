Hi Steve,

As far as I’m concerned, we can ignore the bare ground subclasses and stick with the class for now. We’ve tried to classify water feature subclasses (ditch, creek, pool, etc.) with poor results. For now, we can stick with the class level for water features. It is vegetation that I’m most interested in. We have already taken a shot at aggregating the vegetation subclasses into fewer categories in an effort to use an iterative RFM. The idea we were working on is the same as you suggested, Steve. Ryan can provide these aggregated subclasses.

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
Sent: Monday, January 27, 2025 7:55 PM
To: Bradley Compton <bcompton@eco.umass.edu>
Cc: Scott Jackson <sjackson@umext.umass.edu>; Ryan Wicks <rwicks@umass.edu>; Ethan Plunkett <plunkett@umass.edu>; Charles Schweik <cschweik@umass.edu>
Subject: Re: Current Random Forest project

 

One more question. If I am correct, you have 27 classes to sort through in the RF model. That seems like a lot. Do you need all 27, at least to start? Or can you boil it down to a much smaller set? This can easily be done programmatically by relabeling as a pre-processing step; no need to relabel the attribute table. For instance, I boil down 5 classes into 2: banks and everything else. I now have binary classification and this improved results whoppingly. I am then left to deal with the banks, but I can tailor a 2nd model just to those two classes (healthy and unhealthy).

 

Guess it depends on the goal of the RF classification, which I admit, I am a little hazy on.

 

S