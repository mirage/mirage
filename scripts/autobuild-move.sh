#!/bin/bash 
# 
# Build script for CI server
# Part 2
# 

#
# Move relevant files to www
#

#rm -r /var/www/mir-inst  # don't need this line as 'cp' overwrites
cp -pr ~/mir-inst/ /var/www/
cp -p ~/jobs/$JOB_NAME/builds/$BUILD_NUMBER/log /var/www/buildlogs/$JOB_NAME-log-$BUILD_ID.txt
cd /var/www/
ln -nsf buildlogs/$JOB_NAME-log-$BUILD_ID.txt mirlog
