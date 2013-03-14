# User Module for Origami
# Author: Justin Eittreim (DivinityArcane)
# Contact: eittreim.justin@live.com
# Date: Tue November 13 2012, 14:19

package Users;

    use strict;
    use warnings;
    
    use feature "switch";
    
    
    my $bot;
    my %users = (
        Owner       => [],
        Admins      => [],
        Operators   => [],
        Members     => [],
        Banned      => [],
        real_names  => {});
    
    
    sub new {
        return bless {}, shift;
    }
    
    sub init {
        $bot = $_[1];
        push($users{Owner}, lc $bot->owner);
        $users{real_names}{lc $bot->owner} = $bot->owner;
        
        # Ensure the use db exists.
        unless (-f './Storage/Users.db') {
            OriDB->save('Users', %users);
        }
        
        %users = OriDB->load('Users');
        
        # Commands
        $bot->Events->add_command('user', 'Users->cmd_user', ('Users', 75, 'DivinityArcane', 
            'User management.', 'No help needed'));
    }
    
    sub proper_id {
        my ($self, $privs) = @_;
        # Check if we were given a numeric privclass order.
        if ($privs =~ /^[0-9]+$/) {
            $privs = $self->numeric_to_id($privs);
        } else {
            # Otherwise, ensure it's "Members" and not "members", "MEMBERS", etc.
            $privs = ucfirst lc $privs;
        }
        return $privs;
    }
    
    sub check_privs {
        my ($self, $who, $privs) = @_;
        $who = lc $who;
        
        $privs = $self->proper_id($privs);
        
        $privs = $self->id_to_numeric($privs);
        my $their_privs = $self->get_privs($who);
        if ($their_privs == 0) {
            $their_privs = 10;
        }
        
        if ($their_privs >= $privs) {
            return 'true';
        } else {
            return 'false';
        }
    }
    
    sub get_privs {
        my ($self, $user) = @_;
        my $who = lc $user;
        # Shit like in_array didn't exist back in my day...
        if (grep(/^$who$/, @{ $users{Owner} })) {
            return 100;
        } elsif (grep(/^$who$/, @{ $users{Admins} })) {
            return 75;
        } elsif (grep(/^$who$/, @{ $users{Operators} })) {
            return 50;
        } elsif (grep(/^$who$/, @{ $users{Members} })) {
            return 25;
        } elsif (grep(/^$who$/, @{ $users{Banned} })) {
            return -1;
        } else {
            # Guests.
            return 10;
        }
    }
    
    sub numeric_to_id {
        my ($self, $privs) = @_;
        given ($privs) {
            when(100) { return 'Owner';     }
            when(75)  { return 'Admins';    }
            when(50)  { return 'Operators'; }
            when(25)  { return 'Members';   }
            when(-1)  { return 'Banned';    }
            default   { return 'Guests';    }
        }
    }
    
    sub id_to_numeric {
        my ($self, $privs) = @_;
        given ($privs) {
            when('Owner')       { return 100;   }
            when('Admins')      { return 75;    }
            when('Operators')   { return 50;    }
            when('Members')     { return 25;    }
            when('Banned')      { return -1;    }
            default             { return 0;     }
        }
    }
    
    sub get_pc_users {
        my ($self, $pc) = @_;
        $pc = ucfirst lc $pc;
        given ($pc) {
            when('Owner')       {} # OK
            when('Admins')      {} # OK
            when('Operators')   {} # OK
            when('Members')     {} # OK
            when('Banned')      {} # OK
            default             { return 'None.'; } # Nope.
        }
        my @list = ();
        foreach my $key (@{$users{$pc}}) {
            push(@list, substr($users{real_names}{$key}, 0, 1) . '<i></i>' . substr($users{real_names}{$key}, 1));
        }
        if (exists($list[0])) {
            if (!exists($list[1])) {
                return $list[0];
            } else {
                return join ', ', sort @list;
            }
        } else {
            return 'None.';
        }
    }
    
    sub save {
        OriDB->save('Users', %users);
    }
    
    
    # Commands!
    
    sub cmd_user {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $trigger = $bot->trigger;
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'.
                $trigger.'user list<br/><b>&raquo; </b>'.
                $trigger.'user add <i>[username] [priv level]</i><br/><b>&raquo; </b>'.
                $trigger.'user del <i>[username]</i>'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $privs = $self->get_privs(lc $from);
        
        given ($args[1]) {
            
            when('list') {
                my $list = '<b>:bulletred: User list</b><br/><b>&raquo; Owner: </b>'.
                    $bot->owner .'<br/><b>&raquo; Admins: </b>'.
                    $self->get_pc_users('Admins').'<br/><b>&raquo; Operators: </b>'.
                    $self->get_pc_users('Operators').'<br/><b>&raquo; Members: </b>'.
                    $self->get_pc_users('Members').'<br/><b>&raquo; Banned: </b>'.
                    $self->get_pc_users('Banned').$highlight;
                $bot->say($ns, $list);
                return;
            }
            
            when('add') {
                if(scalar(@args) != 4) {
                    $bot->say($ns, $helpmsg);
                    return;
                }
                my ($user, $pc) = ($args[2], $args[3]);
                $pc = $self->proper_id($pc);
                if ($pc eq 'Owner') {
                    $bot->say($ns, '<b>No. </b>:stare:');
                    return;
                }
                if ($pc eq 'Guests') {
                    $bot->say($ns, $from.': Invalid priv level.');
                    return;
                }
                if ($self->get_privs($user) > 10 or $self->get_privs($user) == -1) {
                    $bot->say($ns, $from.': That user is already in the list.');
                    return;
                }
                push($users{$pc}, lc $user);
                $users{real_names}{lc $user} = $user;
                $self->save();
                $bot->say($ns, $from.': User has been added.');
            }
            
            when('del') {
                if(scalar(@args) != 3) {
                    $bot->say($ns, $helpmsg);
                    return;
                }
                my $user = lc $args[2];
                if ($user eq lc $bot->owner) {
                    $bot->say($ns, '<b>No. </b>:stare:');
                    return;
                }
                my $privs = $self->get_privs($user);
                if ($privs == 0) {
                    $bot->say($ns, $from.': That user doesn\'t exist.');
                    return;
                }
                my $pc = $self->numeric_to_id($privs);
                my $key = 0;
                $key++ until $users{$pc}[$key] eq $user;
                splice $users{$pc}, $key, 1;
                delete($users{real_names}{$user});
                $self->save();
                $bot->say($ns, $from.': User was successfully removed.');
            }
            
            default {
                $bot->say($ns, $helpmsg);
                return;
            }
        }
    }


1;
