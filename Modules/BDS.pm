# BDS Module for Origami
# Author: Justin Eittreim (DivinityArcane)
# Contact: eittreim.justin@live.com
# Date: Tue November 13 2012, 00:54

package BDS;
    
    use strict;
    use warnings;
    use Digest::MD5 qw(md5_hex);
    
    use feature "switch";
    
    my $bot;
    
    sub new {
        return bless {}, shift;
    }
    
    sub init {
        $bot = $_[1];
    }
    
    sub HandleMessage {
        my ($self, $from, $msg) = @_;
        if (index ($msg, ':') != -1) {
            my @bits = split /:/, lc $msg;
            my ($username, $owner, $version, $trigger, $policebot) = 
                ($bot->username, $bot->owner, $bot->version, $bot->trigger, $bot->policebot);
            
            if ($bits[0] eq 'bds') {
                given ($bits[1]) {
                    
                    when ("botcheck") {
                        if (scalar @bits < 3) { return; }
                        if (lc $from ne lc $policebot) { return; }
                        if ($bits[2] eq 'all') {
                            my $hash = lc md5_hex(lc $trigger . lc $from . lc $username);
                            $bot->npsay('chat:datashare', "BDS:BOTCHECK:RESPONSE:$from,$owner,Origami,$version/0.3,$hash,$trigger");
                        } elsif ($bits[2] eq 'direct' and lc $bits[3] eq lc $username) {
                            my $hash = lc md5_hex(lc $trigger . lc $from . lc $username);
                            $bot->npsay('chat:datashare', "BDS:BOTCHECK:RESPONSE:$from,$owner,Origami,$version/0.3,$hash,$trigger");
                        }
                    }
                    
                    when ("botdef") {
                        if (scalar @bits < 4) { return; }
                        if (lc $from ne lc $policebot) { return; }
                        if ($bits[2] eq 'request' and lc $bits[3] eq lc $username) {
                            my $hash = lc md5_hex(lc $from . 'origamidivinityarcane');
                            $bot->npsay('chat:datashare', "BDS:BOTDEF:RESPONSE:$from,Origami,Perl,DivinityArcane,http://www.botdom.com/wiki/Origami,$hash");
                        }
                    }
                    
                    default {
                        # Don't output this, because it'd be spammy.
                        # $bot->out('CORE', "Unhandled BDS category: $bits[1]");
                    }
                }
            }
        }
    }
    
    sub reply_ns_botcheck {
        my ($self, $ns, $from) = @_;
        my ($username, $owner, $version, $trigger, $policebot) = 
            ($bot->username, $bot->owner, $bot->version, $bot->trigger, $bot->policebot);
        if (lc $from ne lc $policebot) { return; }
        my $hash = lc md5_hex(lc $trigger . lc $from . lc $username);
        my $payload = lc "botresponse: $from $owner Origami $version/0.3 $hash $trigger";
        $bot->say($ns, "meow<abbr title=\"$payload\"></abbr>");
    }
    
1;
