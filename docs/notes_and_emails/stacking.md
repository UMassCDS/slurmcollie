Stephen Fickas
	
Jan 27, 2025, 12:19 PM (2 days ago)
	
to me, Scott, Ryan, Ethan, Charles

Ryan, we probably should be capturing all this design discussion somewhere. I agree with Brad that using GitHub would probably be a good idea to start documenting and maintaining the project. Also, need some way to record results from different alternatives, given this is an exploration process. I am currently using a separate notebook for this, but there are libraries that support it more automatically.

Brad: I did not mention, but for my project (detecting unhealthy creek banks), I am using a tiling (upscaling) approach. The difference is that you are suggesting pooling each tile using statistical methods to a single value. I am using straight-up image analysis tools, treating each tile as a separate image. What would be interesting is to combine both these approaches at some point. So run each model separately to get class probabilities, then combine them (e.g., through stacking as an ensemble) as a final stage. I like this because it really keeps them independent and if stacking does not provide better results, just omit it. Still have original models.

I also note that I am working with roughly 10 different sites, each with labeled data. I am getting very good results from a two-stage model built for each site. However, so far using a version of the CV approach you suggest to combine k sites in a model and then predict on hold out has not worked well. I was a little surprised at this. It would seem that combining sites would lead to a more robust model. But not so far. What I plan to do next is try the stacking approach. So keep each model separate and combine results at end (as opposed to create one model to rule them all). This is really the next phase on my project: explore how to combine models with an overall goal of doing well on new sites with no labeled data.

S
