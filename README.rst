Mass Upload to Cloud Files 
==========================

This is a Linux/Unix shell script that uses a 'loop' to upload all files from a directory that you specify to a container that you specified.

Requirements : 
  Python 2.6 + 
  Python Module "simplejson"
  Curl 
  bash 3.0 + 


Download the script, run it on your system.

--------

Note :
  I found this to be effective in uploading a lot of files fairly quickly. However it is single threaded.  This script will preserve the directory structure of objects as they are found on the file system and can handle spaces in the file name though it will NOT handle special characters.  
