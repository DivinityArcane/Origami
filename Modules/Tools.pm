# Tools Module for Origami
# Author: Justin Eittreim (DivinityArcane)
# Contact: eittreim.justin@live.com
# Date: Tue November 20 2012, 23:11

package Tools;

    use strict;
    use warnings;
    use POSIX qw(strftime);
    
    use feature 'switch';
	
    my $bot;
    my %store = ();
    
    sub new {
        return bless {}, shift;
    }
    
    sub init {
        $bot = $_[1];
        
        # Ensure the use db exists.
        unless (-f './Storage/StickyNotes.db') {
            OriDB->save('StickyNotes', %store);
        }
        
        %store = OriDB->load('StickyNotes');
        
        # Commands
        $bot->Events->add_command('sticky', 'Tools->cmd_sticky', ('Tools', 25, 'DivinityArcane', 
            'Sticky note functionality.', $bot->trigger.'sticky <b>[add/del/read/list]</b>'));
    }
    
    sub save {
        OriDB->save('StickyNotes', %store);
    }
    
    # Commands!
    
    sub cmd_sticky {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'. $bot->trigger .'sticky <b>[add/del/read/list]</b>'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        
        my $who = lc $from;
        
        given ($args[1]) {
            when ('add') {
                if (scalar(@args) < 3) {
                    $bot->say($ns, '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'. $bot->trigger .'sticky add <b>some message</b>'.$highlight);
                    return;
                }
                unless (defined($store{$who})) {
                    $store{$who} = [];
                }
                my $timestamp = strftime "%b %d %Y - %H:%M:%S", localtime;
                my $msg = join ' ', splice(@args, 2);
                push(@{ $store{$who} }, '<b>&raquo; Date:</b> '.$timestamp.'<br/><b>&raquo; Content:</b><br/><br/>'.$msg);
                $self->save();
                $bot->say($ns, '<b>:bulletblue: Note saved!</b>'.$highlight);
            }
            
            when ('del') {
                if (scalar(@args) < 3) {
                    $bot->say($ns, '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'. $bot->trigger .'sticky del <b>note ID</b>'.$highlight);
                    return;
                }
                unless (defined($store{$who})) {
                    $store{$who} = [];
                }
                if (defined($store{$who}[$args[2]])) {
                    splice $store{$who}, $args[2], 1;
                    $self->save();
                    $bot->say($ns, '<b>:bulletblue: Note deleted!</b>'.$highlight);
                } else {
                    $bot->say($ns, '<b>:bulletred: No such note!</b>'.$highlight);
                }
            }
            
            when ('read') {
                if (scalar(@args) < 3) {
                    $bot->say($ns, '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'. $bot->trigger .'sticky del <b>note ID</b>'.$highlight);
                    return;
                }
                unless (defined($store{$who})) {
                    $store{$who} = [];
                }
                if (defined($store{$who}[$args[2]])) {
                    my $content = $store{$who}[$args[2]];
                    $bot->say($ns, $content.$highlight);
                } else {
                    $bot->say($ns, '<b>:bulletred: No such note!</b>'.$highlight);
                }
            }
            
            when ('list') {
                if (defined($store{$who})) {
                    if (scalar(@{ $store{$who} }) > 0) {
                        my $msg = '<b>:bulletgreen: You have '.scalar(@{ $store{$who} }).' notes saved.</b><br/><b>&raquo; Note IDs:</b> '.join(', ', keys @{ $store{$who} }).$highlight;
                        $bot->say($ns, $msg);
                    } else {
                        $bot->say($ns, '<b>:bulletred: You have no notes saved!</b>'.$highlight);
                    }
                } else {
                    $bot->say($ns, '<b>:bulletred: You have no notes saved!</b>'.$highlight);
                }
            }
        
            default {
                $bot->say($ns, $helpmsg);
            }
        }
    }
    
1;