# Core Module for Origami
# Author: Justin Eittreim (DivinityArcane)
# Contact: eittreim.justin@live.com
# Date: Thu November 15 2012, 14:19

package Core;

    use strict;
    use warnings;
	
    my $bot;
    
    sub new {
        return bless {}, shift;
    }
    
    sub init {
        $bot = $_[1];
        
        # Commands
        $bot->Events->add_command('eval', 'Core->cmd_eval', ('Core', 100, 'DivinityArcane', 
            'Evaluates Perl code.', $bot->trigger.'eval <b>Perl code</b>'));
            
        $bot->Events->add_command('uptime', 'Core->cmd_uptime', ('Core', 10, 'DivinityArcane', 
            'Shows the bot uptime.', 'No help needed.'));
            
        $bot->Events->add_command('disconnects', 'Core->cmd_disconnects', ('Core', 10, 'DivinityArcane', 
            'Shows how many times the bot has disconnected.', 'No help needed.'));
            
        $bot->Events->add_command('quit', 'Core->cmd_quit', ('Core', 100, 'DivinityArcane', 
            'Shuts the bot down.', 'No help needed.'));
            
        $bot->Events->add_command('restart', 'Core->cmd_restart', ('Core', 100, 'DivinityArcane', 
            'Rerstarts the bot.', 'No help needed.'));
            
        $bot->Events->add_command('netinfo', 'Core->cmd_netinfo', ('Core', 10, 'DivinityArcane', 
            'Shows information on network data usage.', 'No help needed.'));
    }
    
    
    # Commands!
    
    sub cmd_eval {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'. $bot->trigger .'eval <b>Perl code</b>'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $code = join ' ', splice(@args, 1);
        eval $code;
        my $error = '';
        $error = " Output: <bcode>$@</bcode>" if defined $@ and length($@) > 2;
        $bot->say($ns, 'Evaluated.' . $error);
    }
    
    sub cmd_uptime {
        my ($self, $bot, $ns, $from, @args) = @_;
        $bot->say($ns, '<b>:bulletred: Bot uptime:</b> ' . $bot->uptime);
    }
    
    sub cmd_disconnects {
        my ($self, $bot, $ns, $from, @args) = @_;
        $bot->say($ns, '<b>:bulletred:</b> The bot has disconnected <b>' . $bot->disconnects . '</b> times.');
    }
    
    sub cmd_quit {
        my ($self, $bot, $ns, $from, @args) = @_;
        $bot->say($ns, '<b>:bulletpurple: Shutting down!</b> <i>[Uptime: ' . $bot->uptime . ']</i>');
        $bot->quit();
    }
    
    sub cmd_restart {
        my ($self, $bot, $ns, $from, @args) = @_;
        $bot->say($ns, '<b>:bulletblue: Restarting!</b> <i>[Uptime: ' . $bot->uptime . ']</i>');
        open(FH, '>restart');
        print FH 'Don\'t touch me!';
        close(FH);
        $bot->quit();
    }
    
    sub cmd_netinfo {
        my ($self, $bot, $ns, $from, @args) = @_;
        my ($bytes_sent, $bytes_received) = ($bot->bytessent, $bot->bytesread);
        my $sent = $bot->format_bytes($bytes_sent);
        my $read = $bot->format_bytes($bytes_received);
        $bot->say($ns, '<b>:bulletblue: Network usage:</b><br/><b>&raquo; Sent:</b> '.$sent.'<br/><b>&raquo; Received:</b> '.$read);
    }
    
1;