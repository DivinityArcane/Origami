# dAmn Module for Origami
# Author: Justin Eittreim (DivinityArcane)
# Contact: eittreim.justin@live.com
# Date: Tue November 13 2012, 00:22

package dAmn;
    
    use strict;
    use warnings;
    use POSIX qw(strftime);
    use Time::HiRes qw(time sleep);
    
    use feature "switch";

    my $bot;
    
    # Whois channels
    my %WCHANS = ();
    
    # Channel info
    my %CHANDATA = ();
    
    sub CHANDATA { return %CHANDATA; }

    sub new {
        return bless {}, shift;
    }
    
    sub init {
        $bot = $_[1];
        $bot->Events->add_event('dAmnServer',   'dAmn->on_connect');
        $bot->Events->add_event('login',        'dAmn->on_login');
        $bot->Events->add_event('ping',         'dAmn->on_ping');
        $bot->Events->add_event('join',         'dAmn->on_join');
        $bot->Events->add_event('part',         'dAmn->on_part');
        $bot->Events->add_event('property',     'dAmn->on_property');
        $bot->Events->add_event('kicked',       'dAmn->on_kicked');
        $bot->Events->add_event('recv_msg',     'dAmn->on_recv_msg');
        $bot->Events->add_event('recv_action',  'dAmn->on_recv_action');
        $bot->Events->add_event('recv_join',    'dAmn->on_recv_join');
        $bot->Events->add_event('recv_part',    'dAmn->on_recv_part');
        $bot->Events->add_event('recv_privchg', 'dAmn->on_recv_privchg');
        $bot->Events->add_event('recv_kicked',  'dAmn->on_recv_kicked');
        $bot->Events->add_event('recv_admin',   'dAmn->on_recv_admin');
        $bot->Events->add_event('send',         'dAmn->on_senderror');
        $bot->Events->add_event('kick',         'dAmn->on_kickerror');
        $bot->Events->add_event('get',          'dAmn->on_geterror');
        $bot->Events->add_event('set',          'dAmn->on_seterror');
        $bot->Events->add_event('kill',         'dAmn->on_killerror');
        $bot->Events->add_event('disconnect',   'dAmn->on_disconnect');
        $bot->Events->add_event('whois',        'dAmn->on_whois');
        
        # Commands
        $bot->Events->add_command('about', 'dAmn->cmd_about', ('dAmn', 10, 'DivinityArcane', 
            'Shows information about the bot.', 'No help needed'));
            
        $bot->Events->add_command('ping', 'dAmn->cmd_ping', ('dAmn', 10, 'DivinityArcane', 
            'Tests latency between the bot and dAmn.', 'No help needed'));
            
        $bot->Events->add_command('help', 'dAmn->cmd_help', ('dAmn', 10, 'DivinityArcane', 
            'Shows information on a command.', $bot->trigger.'help <i>[command]</i>'));
            
        $bot->Events->add_command('commands', 'dAmn->cmd_commands', ('dAmn', 10, 'DivinityArcane', 
            'Displays available commands.', 'No help needed'));
            
        $bot->Events->add_command('say', 'dAmn->cmd_say', ('dAmn', 75, 'DivinityArcane', 
            'Makes the bot say something.', $bot->trigger.'say <i>[#channel]</i> message'));
            
        $bot->Events->add_command('npsay', 'dAmn->cmd_npsay', ('dAmn', 75, 'DivinityArcane', 
            'Makes the bot say something (non-parsed).', $bot->trigger.'npsay <i>[#channel]</i> message'));
            
        $bot->Events->add_command('me', 'dAmn->cmd_me', ('dAmn', 75, 'DivinityArcane', 
            'Makes the bot say something in /me format.', $bot->trigger.'me <i>[#channel]</i> message'));
            
        $bot->Events->add_command('join', 'dAmn->cmd_join', ('dAmn', 75, 'DivinityArcane', 
            'Makes the bot join a channel.', $bot->trigger.'join <i>[#channel]</i>'));
            
        $bot->Events->add_command('part', 'dAmn->cmd_part', ('dAmn', 75, 'DivinityArcane', 
            'Makes the bot leave a channel.', $bot->trigger.'part <i>[#channel]</i>'));
            
        $bot->Events->add_command('kick', 'dAmn->cmd_kick', ('dAmn', 75, 'DivinityArcane', 
            'Kicks the specified user from the given channel, with an optional reason.', $bot->trigger.'kick #channel username <i>reason</i>'));
            
        $bot->Events->add_command('su', 'dAmn->cmd_su', ('dAmn', 100, 'DivinityArcane', 
            'Performs the command as the specified user.', $bot->trigger.'su username command'));
            
        $bot->Events->add_command('promote', 'dAmn->cmd_promote', ('dAmn', 75, 'DivinityArcane', 
            'Promotes the user in the specified channel, optionally to the specified privclass.', $bot->trigger.'promote #channel username <i>privclass</i>'));
            
        $bot->Events->add_command('demote', 'dAmn->cmd_demote', ('dAmn', 75, 'DivinityArcane', 
            'Demotes the user in the specified channel, optionally to the specified privclass.', $bot->trigger.'demote #channel username <i>privclass</i>'));
            
        $bot->Events->add_command('ban', 'dAmn->cmd_ban', ('dAmn', 75, 'DivinityArcane', 
            'Bans the user in the specified channel.', $bot->trigger.'ban #channel username'));
            
        $bot->Events->add_command('unban', 'dAmn->cmd_unban', ('dAmn', 75, 'DivinityArcane', 
            'Unbans the user in the specified channel.', $bot->trigger.'unban #channel username'));
            
        $bot->Events->add_command('topic', 'dAmn->cmd_topic', ('dAmn', 75, 'DivinityArcane', 
            'Changes the topic in the specified channel.', $bot->trigger.'topic #channel content'));
            
        $bot->Events->add_command('title', 'dAmn->cmd_title', ('dAmn', 75, 'DivinityArcane', 
            'Changes the title in the specified channel.', $bot->trigger.'title #channel content'));
            
        $bot->Events->add_command('whois', 'dAmn->cmd_whois', ('dAmn', 25, 'DivinityArcane', 
            'Does a /whois on the specified user.', $bot->trigger.'whois user'));
    }
    
    sub on_connect {
        my ($self, %packet) = @_;
        $bot->out('dAmn', 'Connected to dAmnServer '.$packet{parameter});
        $bot->sendPacket('login '.$bot->username.chr(10).'pk='.$bot->authtoken);
    }
    
    sub on_login {
        my ($self, %packet) = @_;
        if ($packet{arguments}{e} eq 'ok') {
            $bot->out('dAmn', 'Logged in as '.$bot->username);
            # Time to autojoin :p
            $bot->joinChannel('chat:datashare');
            foreach ($bot->channels) {
                $bot->joinChannel($bot->formatNS($_));
            }
        } else {
            $bot->out('dAmn', "Failed to login: $packet{arguments}{e}");
            $bot->out('dAmn', 'Authtoken expired or password is wrong.');
            unlink "./authtoken.db";
            $bot->init_connect();
        }
    }
    
    sub on_ping {
        $bot->sendPacket('pong');
    }
    
    sub on_join {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        if ($packet{arguments}{e} eq 'ok') {
            $bot->out($ns, "** Joined $ns [$packet{arguments}{e}]");
            
            $CHANDATA{lc substr($ns, 1)} = ();
            
        } else {
            $bot->out('dAmn', "** Failed to join $ns [$packet{arguments}{e}]");
        }
    }
    
    sub on_part {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        if ($packet{arguments}{e} eq 'ok') {
            my $reason = '';
            if (defined $packet{arguments}{r}) {
                $reason = ': '.$packet{arguments}{r};
            }
            $bot->out($ns, "** Parted $ns [$packet{arguments}{e}]".$reason);
            if (length($reason) > 2 and $reason ne ': quit') {
                $bot->timed_out();
            }
        } else {
            $bot->out('dAmn', "** Failed to part $ns [$packet{arguments}{e}]");
        }
    }
    
    sub on_property {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        my $pos = index($packet{raw}, "\n\n");
        my $body = $bot->tablumps(substr($packet{raw}, $pos + 2));
        
        given ($packet{arguments}{p}) {
            when ('topic') {
                $CHANDATA{lc substr($ns, 1)}{topic} = {
                    'content' => $body,
                    'by' => $packet{arguments}{by},
                    'ts' => $packet{arguments}{ts}
                };
            }
            
            when ('title') {
                $CHANDATA{lc substr($ns, 1)}{title} = {
                    'content' => $body,
                    'by' => $packet{arguments}{by},
                    'ts' => $packet{arguments}{ts}
                };
            }
            
            when ('privclasses') {
                $CHANDATA{lc substr($ns, 1)}{privclasses} = ();
                my @lines = split "\n", $body;
                foreach my $line (@lines) {
                    if (length($line) >= 3 and index($line, ':') != -1) {
                        my ($order, $privclass) = split ':', $line;
                        $CHANDATA{lc substr($ns, 1)}{privclasses}{lc $privclass} = {
                            'order' => $order,
                            'name' => $privclass
                        };
                    }
                }
            }
            
            when ('members') {
                $CHANDATA{lc substr($ns, 1)}{members} = ();
                my @chunks = split "\n\n", $body;
                foreach my $chunk (@chunks) {
                    if (length($chunk) >= 3 and index($chunk, 'member ') != -1) {
                        my @lines = split "\n", $chunk;
                        next unless(scalar(@lines) >= 7 and length($lines[0]) >= 8);
                        $CHANDATA{lc substr($ns, 1)}{members}{lc substr($lines[0], 7)} = {
                            'name'     => substr($lines[0], 7),
                            'pc'       => substr($lines[1], 3),
                            'usericon' => substr($lines[2], 9),
                            'symbol'   => substr($lines[3], 7),
                            'realname' => substr($lines[4], 9),
                            'typename' => substr($lines[5], 9),
                            'gpc'      => substr($lines[6], 4),
                        }
                    }
                }
            }
        
            default {
                $bot->out('Error', 'Unknown channel property: ' . $packet{arguments}{p});
            }
        }
        
        if (substr($ns, 0, 1) eq '@') {
            $bot->Events->fire_event('whois', %packet);
        } else {
            $bot->out($ns, "*** Got $packet{arguments}{p} for $ns");
        }
    }
    
    sub on_whois {
        my ($self, %packet) = @_;
        my $ns = $bot->formatNS($packet{parameter});
        my $who = substr($ns, 1);
        if (defined($WCHANS{lc $who})) {
            my $conn_start = index($packet{raw}, 'conn');
            if ($conn_start != -1) {
                my @connections = split 'conn\n', substr($packet{raw}, $conn_start);
                my $msg = '<b>'.$packet{arguments}{symbol}.'<a href="http://'.$who.'.deviantart.com/">'.$who.'</a></b> :icon'.$who.':<br/><br/>'.
                    '<b>&raquo; '.$packet{arguments}{realname}.'</b>';
                my $conn_count = 1;
                foreach my $connection (@connections) {
                    next unless (length($connection) > 15);
                    my @lines = split "\n", $connection;
                    $msg .= '<br/><br/><b>Connection '.$conn_count.'</b><br/>'.
                        '<b>&raquo; Online:</b> '.$bot->format_time(substr($lines[0], 7)).'<br/>'.
                        '<b>&raquo; Idle:</b> '.$bot->format_time(substr($lines[1], 5));
                    my @chans = ();
                    foreach (2 ... scalar(@lines) - 1) {
                        if (length($lines[$_]) > 3) {
                            my $chan = substr $lines[$_], 8;
                            if (lc $chan ne 'datashare' and lc $chan ne 'dshost') {
                                push(@chans, $chan);
                            }
                        }
                    }
                    if (scalar(@chans) > 0) {
                        $msg .= '<br/><b>&raquo; Channels:</b> [#'.join('], [#', sort @chans).']';
                    }
                    $conn_count++;
                }
                $bot->say($WCHANS{lc $who}, $msg);
            }
            delete($WCHANS{lc $who});
        }
    }
    
    sub on_kicked {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        my $reason = '';
        if (defined($packet{body}) and length $packet{body} > 0) {
            $reason = "($packet{body})";
        }
        $bot->out($ns, "** Kicked from $ns by $packet{arguments}{by} $reason");
        # Rejoin.
        $bot->joinChannel($ns);
        
    }
    
    sub on_recv_msg {
        my ($self, %packet) = @_;
        my $ns = $bot->formatNS($packet{parameter});
        my $from = $packet{arguments}{from};
        my $msg = $packet{body};
        if (lc $ns eq '#datashare') {
            $bot->BDS->HandleMessage($from, $msg);
            return;
        } else {
            my ($username, $trigger ,$policebot) = ($bot->username, $bot->trigger, $bot->policebot);
            
            $bot->out($ns, "<$from> $msg");
            
            if (substr(lc $msg, 0, length($username) + 2) eq lc $username.': ') {
                given (substr(lc $msg, length($username) + 2)) {
                    when ('trigcheck') {
                        $bot->say($ns, $from.': My trigger is <code>'.$trigger.'</code>');
                        return;
                    }
                    
                    when ('botcheck') {
                        if (lc $from ne lc $policebot) { return; }
                        $bot->BDS->reply_ns_botcheck($ns, $from);
                        return;
                    }
                    
                    default {
                        # Maybe add AI here? :P
                    }
                }
                # I usually ignore this, but maybe someone wants the bot name as the trigger.
                #return;
            }
            
            if (index(lc $msg, lc "<abbr title=\"$username: botcheck\"></abbr>") != -1) {
                if (lc $from ne lc $policebot) { return; }
                $bot->BDS->reply_ns_botcheck($ns, $from);
                return;
            }
            
            if ($msg eq 'Ping...' and lc $from eq lc $username) {
                my $elapsed = sprintf '%.3f', time - $bot->ping_sent;
                $bot->set_ping_ts(0);
                $bot->say($ns, 'Pong! Took '.$elapsed.' seconds!');
                return;
            }
            
            if (substr($msg, 0, length($trigger)) eq $trigger and lc $from ne lc $username) {
                # Commands!
                my @args = split ' ', substr($msg, length($trigger));
                my $command = lc $args[0];
                $bot->Events->fire_command($command, $ns, $from, @args);
            }
        }
    }
    
    sub on_recv_action {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        my $from = $packet{arguments}{from};
        my $msg = $packet{body};
        $bot->out($ns, "* $from $msg");
    }
    
    sub on_recv_join {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        my $who = $packet{subParameter};
        $bot->out($ns, "** $who joined.");
    }
    
    sub on_recv_part {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        my $who = $packet{subParameter};
        my $reason = '';
        if (defined($packet{arguments}{r})) {
            $reason = "($packet{arguments}{r})";
        }
        $bot->out($ns, "** $who left. $reason");
    }
    
    sub on_recv_privchg {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        my $who = $packet{subParameter};
        my $by = $packet{arguments}{by};
        my $pc = $packet{arguments}{pc};
        $bot->out($ns, "** $who was made a member of $pc by $by.");
    }
    
    sub on_recv_kicked {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        my $who = $packet{subParameter};
        my $by = $packet{arguments}{by};
        my $reason = '';
        if (defined($packet{body}) and length $packet{body} > 0) {
            $reason = "($packet{body})";
        }
        $bot->out($ns, "*** $who was kicked by $by $reason");
    }
    
    sub on_recv_admin {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        my $what = $packet{subParameter};
        given ($what) {
            
            when ('create') {
                $bot->out($ns, "** $packet{arguments}{by} created privclass $packet{arguments}{name} with privs: $packet{arguments}{privs}");
            }
            
            when ('update') {
                $bot->out($ns, "** $packet{arguments}{by} updated privclass $packet{arguments}{name} with privs: $packet{arguments}{privs}");
            }
            
            when ('rename') {
                $bot->out($ns, "** $packet{arguments}{by} renamed privclass $packet{arguments}{prev} to $packet{arguments}{name}");
            }
            
            when ('move') {
                $bot->out($ns, "** $packet{arguments}{by} moved all members of privclass $packet{arguments}{prev} to $packet{arguments}{name}. $packet{arguments}{n} user(s) were affected.");
            }
            
            when ('remove') {
                $bot->out($ns, "** $packet{arguments}{by} removed privclass $packet{arguments}{name}. $packet{arguments}{n} user(s) were affected.");
            }
            
            # No reason to parse SHOW and its subcommands for now.
        }
    }
    
    sub on_senderror {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        $bot->out('dAmn', "*** Failed to send to $ns: $packet{arguments}{e}");
    }
    
    sub on_kickerror {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        my $who = 'user';
        if (defined($packet{arguments}{u})) {
            $who = $packet{arguments}{u};
        }
        $bot->out('dAmn', "*** Failed to kick $who in $ns: $packet{arguments}{e}");
    }
    
    sub on_geterror {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        $bot->out('dAmn', "*** Failed to get $packet{arguments}{p} in $ns: $packet{arguments}{e}");
    }
    
    sub on_seterror {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        $bot->out('dAmn', "*** Failed to set $packet{arguments}{p} in $ns: $packet{arguments}{e}");
    }
    
    sub on_killerror {
        my ($self, %packet) = @_;
        if (lc $packet{parameter} eq 'chat:datashare') { return; }
        my $ns = $bot->formatNS($packet{parameter});
        my $u = substr $packet{parameter}, 6;
        $bot->out('dAmn', "*** Failed to kill $u: $packet{arguments}{e}");
    }
    
    sub on_disconnect {
        my ($self, %packet) = @_;
        
        $bot->out('dAmn', "Disconnected: $packet{arguments}{e}");
                
        if ($packet{arguments}{e} eq 'ok') {
            exit;
        } else {
            $bot->incdcc();
            $bot->out('dAmn', 'Attempting to reconnect in 5 seconds...');
            sleep(5);
            $bot->init_connect();
        }
    }
    
    
    # Commands!
    
    sub cmd_about {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my ($version, $owner, $uptime, $disconnects) = 
            ($bot->version, $bot->owner, $bot->uptime, $bot->disconnects);
        $bot->say($ns, "<b>:bulletred: <a href=\"http://www.botdom.com/wiki/Origami\">Origami</a> <i>v$version</i></b> by <b>:devDivinityArcane:</b><br/><b>&raquo; Owned and operated by:</b> :dev$owner:<br/><b>&raquo; Bot uptime:</b> $uptime<br/><b>&raquo; Disconnects:</b> $disconnects $highlight<br/><b>&raquo; System:</b> Running on $^O with Perl $^V");
    }
    
    sub cmd_ping {
        my ($self, $bot, $ns, $from, @args) = @_;
        $bot->set_ping_ts(time);
        $bot->say($ns, 'Ping...');
    }
    
    sub cmd_help {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        if (scalar(@args) < 2) {
            $bot->say($ns, '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.$bot->trigger.'help <i>[command name]</i>'.$highlight);
            return;
        }
        my %cmd_info = $bot->Events->cmd_info($args[1]);
        if (defined $cmd_info{author}) {
            $bot->say($ns, "<b>:bulletred: Information on the command <i>$args[1]</i>:</b><br/>".
                "<b>&raquo; Author:</b> $cmd_info{author}<br/>".
                "<b>&raquo; Module:</b> $cmd_info{mod_name}<br/>".
                "<b>&raquo; Minimum Privs:</b> $cmd_info{privlvl}<br/>".
                "<b>&raquo; Description:</b> $cmd_info{description}<br/>".
                "<b>&raquo; Help:</b> $cmd_info{help} $highlight");
        } else {
            $bot->say($ns, "$from: Sorry, I don't know that command.");
        }
    }
    
    sub cmd_commands {
        my ($self, $bot, $ns, $from, @args) = @_;
        my @cmds = $bot->Events->cmd_list_by_privs($bot->Users->get_privs($from));
        if (scalar(@cmds) < 1) {
            $bot->say($ns, '<b>:bulletred: There are no commands available for :dev'.$from.':</b>');
            return;
        }
        my $msg = '<b>:bulletred: Commands available for :dev'.$from.':</b><br/>'.
            ':bulletblue: [<i>'. join('</i>], [<i>', @cmds) .'</i>]';
        $bot->say($ns, $msg);
    }
    
    sub cmd_say {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'say <i>[#channel]</i> message'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $msg;
        if (substr($args[1], 0, 1) eq '#') {
            $ns = $args[1];
            $msg = substr(join(' ', @args), 3 + length($ns) + length($bot->trigger));
        } else {
            $msg = substr(join(' ', @args), 3 + length($bot->trigger));
        }
        $bot->say($ns, $msg);
    }
    
    sub cmd_npsay {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'npsay <i>[#channel]</i> message'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $msg;
        if (substr($args[1], 0, 1) eq '#') {
            $ns = $args[1];
            $msg = substr(join(' ', @args), 5 + length($ns) + length($bot->trigger));
        } else {
            $msg = substr(join(' ', @args), 5 + length($bot->trigger));
        }
        $bot->npsay($ns, $msg);
    }
    
    sub cmd_me {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'me <i>[#channel]</i> message'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $msg;
        if (substr($args[1], 0, 1) eq '#') {
            $ns = $args[1];
            $msg = substr(join(' ', @args), 2 + length($ns) + length($bot->trigger));
        } else {
            $msg = substr(join(' ', @args), 2 + length($bot->trigger));
        }
        $bot->act($ns, $msg);
    }
    
    sub cmd_join {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'join <i>[#channel]</i>'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        $bot->joinChannel($args[1]);
    }
    
    sub cmd_part {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'part <i>[#channel]</i>'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        if (index(lc $args[1], 'datashare') != -1) { return; }
        $bot->partChannel($args[1]);
    }
    
    sub cmd_kick {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'kick #channel username <i>[reason]</i>'.$highlight;
        if (scalar(@args) < 3) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $reason = '';
        if (scalar(@args) >= 4) {
            $reason = join(' ', splice(@args, 3));
        }
        $bot->kick($args[1], $args[2], $reason);
    }
    
    sub cmd_su {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'su username command'.$highlight;
        if (scalar(@args) < 3) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $who = $args[1];
        my @n_args = splice(@args, 2);
        $bot->Events->fire_command($n_args[0], $ns, $who, @n_args);
    }
    
    sub cmd_promote {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'promote #channel username <i>[privclass]</i>'.$highlight;
        if (scalar(@args) < 3) {
            $bot->say($ns, $helpmsg);
            return;
        }
        if (defined($args[3])) {
            $bot->demote($args[1], $args[2], $args[3]);
        } else {
            $bot->demote($args[1], $args[2]);
        }
    }
    
    sub cmd_demote {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'demote #channel username <i>[privclass]</i>'.$highlight;
        if (scalar(@args) < 3) {
            $bot->say($ns, $helpmsg);
            return;
        }
        if (defined($args[3]) and length($args[3]) > 0) {
            $bot->demote($args[1], $args[2], $args[3]);
        } else {
            $bot->demote($args[1], $args[2]);
        }
    }
    
    sub cmd_ban {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'ban #channel username'.$highlight;
        if (scalar(@args) < 3) {
            $bot->say($ns, $helpmsg);
            return;
        }
        $bot->ban($args[1], $args[2]);
    }
    
    sub cmd_unban {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'unban #channel username'.$highlight;
        if (scalar(@args) < 3) {
            $bot->say($ns, $helpmsg);
            return;
        }
        $bot->unban($args[1], $args[2]);
    }
    
    sub cmd_topic {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'topic #channel content'.$highlight;
        if (scalar(@args) < 3) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $channel = $args[1];
        my $content = join ' ', splice(@args, 2);
        $bot->set($channel, 'topic', $content);
    }
    
    sub cmd_title {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'title #channel content'.$highlight;
        if (scalar(@args) < 3) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $channel = $args[1];
        my $content = join ' ', splice(@args, 2);
        $bot->set($channel, 'title', $content);
    }

    sub cmd_whois {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $bot->trigger.'whois user'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        $WCHANS{lc $args[1]} = $ns;
        $bot->whois($args[1]);
    }
    
1;
