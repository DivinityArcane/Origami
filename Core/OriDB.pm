# "Database" Module for Origami
# Author: Justin Eittreim (DivinityArcane)
# Contact: eittreim.justin@live.com
# Date: Tue November 13 2012, 13:17

package OriDB;
    
    use strict;
    use warnings;
    use JSON::XS qw(encode_json decode_json);
    use File::Slurp qw(read_file write_file);
	
    my $bot;
    
    sub new {
        return bless {}, shift;
    }
    
    sub init {
        $bot = $_[1];
    }
    
    sub save {
        my ($self, $filename, %data) = @_;
        $filename = './Storage/'.$filename.'.db';
        # Make sure the storage directory exists.
        unless (-d './Storage') {
            mkdir './Storage', 0777;
        }
        write_file($filename, { binmode => ':raw' }, JSON::XS->new->pretty(1)->encode(\%data));
    }
    
    sub load {
        my ($self, $filename) = @_;
        $filename = './Storage/'.$filename.'.db';
        my %data = %{ decode_json read_file($filename, { binmode => ':raw' }) };
        return %data;
    }
        
1;
