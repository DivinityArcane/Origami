#!/usr/bin/perl
use strict;
use warnings;
use File::Slurp qw(read_file write_file);

# Because I'm lazy as shit.
sub trim { my $str = $_[0]; $str =~ s/^\s+|\s+$//g; return $str; }

# Check for the config file
if (-f './config.txt') {
    my ($username, $password, $trigger, $owner, $chanlist, @channels);
    
    use feature 'switch';
    
    my $buffer = read_file('./config.txt', { binmode => ':raw' });
    
    my @lines = split /\r\n/, $buffer;
    my $line_number = 0;
    
    foreach my $line (@lines) {
        if (length $line > 0 and (my $pos = index($line, '=')) != -1) {
            my $key = trim(substr $line, 0, $pos);
            
            given ($key) {
                
                when ('username') { $username = trim(substr $line, ++$pos); }
                when ('password') { $password = trim(substr $line, ++$pos); }
                when ('trigger')  { $trigger  = trim(substr $line, ++$pos); }
                when ('owner')    { $owner    = trim(substr $line, ++$pos); }
                when ('channels') { $chanlist = trim(substr $line, ++$pos); }
                
                default { }
            }
        } else {
            die "Line $line_number of config.txt is invalid.\n";
        }
        $line_number++;
    }
    
    foreach my $chan (split / /, $chanlist) {
        push(@channels, $chan);
    }

    # Push the Core directory to the Perl path
    push(@INC, './Core');
    
    # Import the bot class.
    require Origami;
    
    # Fire up the core.
    my $bot = new Origami();
    $bot->init($username, $password, $trigger, $owner, @channels);
} else {
    print "No config file was found. Creating a default config...\n";
   write_file('./config.txt', { binmode => ':raw' }, 
                "username = Origami\r\n".
                "password = SuperSecretPassword\r\n".
                "owner    = fella\r\n".
                "trigger  = !\r\n".
                "channels = #Botdom #SomeWhereElse\r\n");
    print "Done! Please modify the config.txt file with your bots' details.\n";
    exit;
}
