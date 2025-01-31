Ryan Wicks
	
Thu, Jan 23, 1:59 PM (6 days ago)
	
to Bradley  
Hi Brad,

   I found my notes on the details for the recommended settings for our Unity working directory and sessions:  

#############################################  
access unity: https://ood.unity.rc.umass.edu/  
unity documentation: https://docs.unity.rc.umass.edu/software/conda.html#conda-environments-and-jupyter  

01:14:42    Georgia Stuart:   os.environ['GDAL_NUM_THREADS'] = '60'  


unity working directory:  

directories:  
usable (faster) storage (1 TB)  
/work/pi_cschweik_umass_edu/Ryan  
/work/pi_cschweik_umass_edu/kate  


long-term (slower) storage (5GB)  
/project/pi_cschweik_umass_edu/  


partition: cpu,cpu-preempt  
Maximum job duration: 2:00:00  
CPU core count: 64 (no less than 4)  
Memory (in GB): 128 (no less than 8)  
Extra arguments for Slurm: --qos=short  

for running code, use a enrionment parameters like:  
os.environ['PROJ_LIB'] = "/work/pi_cschweik_umass_edu/kate/conda/share/proj"  

###################################################  

Certainly the code was uploaded there to run for the RFM work that I did, so I can try an pull it from there.  

-Ryan
