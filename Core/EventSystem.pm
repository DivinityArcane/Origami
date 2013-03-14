# Event System for Origami
# Author: Justin Eittreim (DivinityArcane)
# Contact: eittreim.justin@live.com
# Date: Mon November 12 2012, 23:44

package EventSystem;
    
    use strict;
    use warnings;

    use POSIX qw(strftime);

    my %events = (
        # Bot
        'whois',        [],
        
        # dAmn
        'dAmnServer',   [],
        'disconnect',   [],
        'get',          [],
        'join',         [], 
        'kick',         [],
        'kicked',       [],
        'kill',         [],
        'login',        [],
        'part',         [],
        'ping',         [],
        'property',     [],
        'recv_msg',     [],
        'recv_action',  [],
        'recv_join',    [],
        'recv_part',    [],
        'recv_kicked',  [],
        'recv_privchg', [],
        'recv_admin',   [],
        'send',         [],
        'set',          []);
        
    my %event_hits = ();
        
    my %commands = ();
    my %cmd_info = ('null','null');
        
    my $bot;
        
        
    sub new {
        return bless {}, shift;
    }
    
    sub init {
        $bot = $_[1];
        
        # Commands
        $bot->Events->add_command('evc', 'EventSystem->cmd_evc', ('EventSystem', 50, 'DivinityArcane', 
            'Event hit counts.', 'No help needed'));
            
        $bot->Events->add_command('evi', 'EventSystem->cmd_evi', ('EventSystem', 50, 'DivinityArcane', 
            'Event bind information.', $bot->trigger.'evi <i>some_event_name</i>'));
    }
    
    sub add_event {
        my ($self, $event, $callback) = @_;
        if (defined $events{$event}) {
            push($events{$event}, $callback);
        } else {
            out("Unknown event: $event");
        }
    }
    
    sub remove_event {
        my ($self, $event, $callback) = @_;
        if (defined $events{$event}{$callback}) {
            delete($events{$event}{$callback});
        } else {
            out("Unknown event: $event");
        }
    }
    
    sub add_command {
        my ($self, $cmd, $callback, @info) = @_;
        my ($mod, $privlvl, $author, $desc, $help) = @info;
        $commands{$cmd} = $callback;
        $cmd_info{$cmd} = {'mod_name'=>$mod,'author'=>$author,'privlvl'=>$privlvl,'description'=>$desc,'help'=>$help};
    }
    
    sub remove_command {
        my ($self, $cmd) = @_;
        if (defined $commands{$cmd}) {
            delete($commands{$cmd});
            delete($cmd_info{$cmd});
        } else {
            out("Unknown command: $cmd");
        }
    }
    
    sub cmd_info {
        my ($self, $cmd) = @_;
        if (defined $cmd_info{$cmd}) {
            return %{$cmd_info{$cmd}};
        } else {
            return ();
        }
    }
    
    sub cmd_list {
        my @list = ();
        foreach (keys %commands) { push @list, $_; }
        return sort @list;
    }
    
    sub cmd_list_by_privs {
        my ($self, $privlvl) = @_;
        my @list = ();
        foreach (keys %commands) { 
            if (defined $cmd_info{$_}) {
                if ($cmd_info{$_}{privlvl} <= $privlvl) {
                    push @list, $_;
                }
            }
        }
        return sort @list;
    }
    
    sub fire_event {
        my ($self, $event, %packet) = @_;
        if (defined $events{$event}) {
            unless (defined($event_hits{$event})) {
                $event_hits{$event} = 0;
            }
            $event_hits{$event}++;
            if (scalar(@{$events{$event}}) < 1) {
                out('Firing event with no callbacks: '.$event);
            }
            {   # We need to use a loose reference.
                no strict "refs";
                while (my ($key, $value) = each($events{$event})) {
                    my ($class, $callback) = split '->', $value;
                    $class->$callback(%packet);
                }
            }
        } else {
            out("Unknown event: $event");
        }
    }
    
    sub fire_command {
        my ($self, $cmd, $ns, $from, @args) = @_;
        if (defined $commands{$cmd}) {
            my %cmd_info = $self->cmd_info($cmd);
            if ('true' eq $bot->Users->check_privs($from, $cmd_info{privlvl})) {
                no strict "refs";
                my ($class, $callback) = split '->', $commands{$cmd};
                $class->$callback($bot, $ns, $from, @args);
            } else {
                $bot->say($ns, $from.': <b><i><code>Access denied.</code></i></b>');
            }
        } else {
            out("Unknown command: $cmd");
        }
    }
    
    sub out {
        my $msg = $_[0];
        my $timestamp = strftime "[%H:%M:%S]", localtime;
        print "$timestamp [Events] $msg\n";
    }
    
    
    # Commands!
    
    sub cmd_evc {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $total_fires = 0;
        my $msg = '<b>:bulletred: Fires per event</b>';
        foreach my $key (sort keys %event_hits) {
            $msg .= '<br/><b>&raquo; '.$key.': </b> '.$event_hits{$key}.' hits.';
            $total_fires += $event_hits{$key};
        }
        $msg .= '<br/><br/><b>&raquo; Total fires:</b> '.$total_fires;
        $bot->say($ns, $msg);
    }
    
    sub cmd_evi {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = '<abbr title="'.$from.'"></abbr>';
        if (scalar(@args) < 2) {
            $bot->say($ns, '<b>:bulletgreen: Usage:</b><br/>&raquo; '.$bot->trigger.'evi <i>some_event_name</i>'.$highlight);
            return;
        }
        if (defined($events{$args[1]})) {
            my $msg = '<b>:bulletblue: Event <i>'.$args[1].'</i> has '.scalar(@{$events{$args[1]}}).' handlers bound to it.</b>';
            foreach my $value (@{$events{$args[1]}}) {
                my ($class, $callback) = split '->', $value;
                $msg .= '<br/><b>&raquo; Module:</b> '.$class.' <b>&raquo; Method:</b> '.$callback;
            }
            $bot->say($ns, $msg);
        } else {
            if ($args[1] eq '-list') {
                my $msg = '<b>:bulletblue: '.scalar(keys %events).' events.</b><bcode>';
                foreach my $key (sort keys %events) {
                    my $pad = ' ' x (20 - length($key));
                    $msg .= chr(10).'&raquo; Event: '.$key.$pad.' &raquo; Handlers bound: '.scalar(@{$events{$key}});
                }
                $bot->say($ns, $msg.'</bcode>');
            } else {
                $bot->say($ns, '<b>:bulletred: Unknown event:</b> '.$args[1].$highlight);
            }
        }
    }

1;
