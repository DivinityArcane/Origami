#!/bin/sh
echo "Installing deps...\n"
# We don't always have ppm on Linux
# ppm install Crypt::SSLeay JSON::XS File::Slurp
# Let's just hijack the CPAN module.
perl -MCPAN -e 'my @mods = qw(Crypt::SSLeay LWP::UserAgent JSON::XS File::Slurp); foreach my $mod (@mods) { print "Trying to 
install $mod...\n"; CPAN::install($mod); }'
read -p "Done! Hit enter/return to close this window";
