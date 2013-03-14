#!/bin/sh
echo "Finding ActivePerl installation...\n"
appath=`ls /usr/local|grep ActivePerl`
if [ -z "$appath" ]
then
    echo "ActivePerl was not found.\n"
    exit
    read -p "Press any key to close the window."
else
    echo "Found ActivePerl in /usr/local/$appath\n"
    echo "Saving /usr/bin/perl as /usr/bin/perl.bak\n"
    sudo cp /usr/bin/perl /usr/bin/perl.bak
    echo "Copying /usr/local/$appath/bin/perl to /usr/bin/perl\n"
    sudo cp /usr/local/$appath/bin/perl /usr/bin/perl
    echo "Copying /usr/local/$appath/bin/ppm to /usr/bin/ppm\n"
    sudo cp /usr/local/$appath/bin/ppm /usr/bin/ppm
    echo "Done!\n"
    read -p "Press any key to close the window."
fi
