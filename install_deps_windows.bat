@ECHO off
CLS
ECHO Installing deps...

CALL perl -MCPAN -e "install Crypt::SSLeay"
CALL perl -MCPAN -e "install JSON::XS"
CALL perl -MCPAN -e "install File::Slurp"
ECHO Done!
PAUSE