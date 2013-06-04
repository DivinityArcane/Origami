package Origami;
    
    use strict;
    use warnings;

    use POSIX qw(strftime);
    use Time::HiRes qw(time sleep);
    use Config;
    
    use feature "switch";
    
    require dAmnPacket;
    require EventSystem;
    require OriDB;
    
    my $self;
    my %MODREF = ();
    
    my $Events      = new EventSystem();
    my $dAmn        = undef;
    my $BDS         = undef;
    my $Users       = undef;
    
    my $version     = '0.4';
    my $useragent   = "Origami v$version";
    my $author      = 'DivinityArcane <eittreim.justin@live.com>';
    my $date        = 'Thu November 22 2012 20:31';
    my $cwd         = '.';
    my $logdir      = "$cwd/logs";
    my $at_file     = "$cwd/Storage/authtoken.db";
    my $server      = 'chat.deviantart.com';
    my $port        = 3900;
    my $socket      = undef;
    my $username    = undef;
    my $password    = undef;
    my $authtoken   = undef;
    my $owner       = undef;
    my $trigger     = '!';
    my $connected   = 'TRUE';
    my $policebot   = 'botdom';
    my $start_time  = time;
    my $ping_sent   = 0;
    my $disconnects = 0;
    my $bytesread   = 0;
    my $bytessent   = 0;
    my @channels    = (); 
        
        
    # OOP ftw!
    sub new {
        $self = $_[0];
        return bless {}, shift;
    }
    
    # Protected variables. We use subreutines for this.
    sub Events      { return $Events;       }
    sub dAmn        { return $dAmn;         }
    sub BDS         { return $BDS;          }
    sub Users       { return $Users;        }
    sub version     { return $version;      }
    sub useragent   { return $useragent;    }
    sub author      { return $author;       }
    sub date        { return $date;         }
    sub username    { return $username;     }
    sub authtoken   { return $authtoken;    }
    sub owner       { return $owner;        }
    sub trigger     { return $trigger;      }
    sub policebot   { return $policebot;    }
    sub start_time  { return $start_time;   }
    sub disconnects { return $disconnects;  }
    sub ping_sent   { return $ping_sent;    }
    sub bytesread   { return $bytesread;    }
    sub bytessent   { return $bytessent;    }
    sub channels    { return @channels;     }
    
    sub set_ping_ts { $ping_sent = $_[1];   }

    sub getAuthToken {
        # Define variables we'll be using
        my ($UA, $POST, $REQ, $RES, $TMP);
        
        # Include the needed modules
        use LWP::UserAgent;
        use HTTP::Cookies;
        
        # dA itself doesn't pass verification.
        $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "Net::SSL";
        $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

        # We need a cookie jar so our login is persistant.
        $UA = LWP::UserAgent->new;
        $UA->cookie_jar(HTTP::Cookies->new( { } ));
        
        # Form valid POST data from the username and password.
        $POST =
            'ref=https%3A%2F%2Fwww.deviantart.com%2Fusers%2Floggedin'.
            '&username='. $username .'&password='. $password .'&remember_me=1';
            
        # We need to make a POST request to the login page first.
        $REQ = HTTP::Request->new(POST => "https://www.deviantart.com/users/login");
        $REQ->content_type('application/x-www-form-urlencoded');
        $REQ->content($POST);

        # Now, post the login data.
        $RES = $UA->request($REQ);
        
        # If the username or password was wrong, return null
        if ($RES->as_string =~ m/wrong-password/) {
            return undef;
        }
        
        # Now that we're logged in, get the working token from the chat page.
        $REQ = HTTP::Request->new(GET => "http://chat.deviantart.com/chat/Botdom");
        $RES = $UA->request($REQ);
        
        # Grab the token from all the madness.
        ($authtoken = join "", split /\n/, $RES->as_string) =~ s/.*dAmn_Login\([^,]*, "([^"]*)" \).*/$1/g;
    }
    
    sub init_connect {
        use IO::Socket;    
        use IO::Select;
        
        # Let's get an authtoken
        
        if (-f $at_file) {
            $self->out('CORE', 'Checking stored authtoken...');
            open(my $ATF, '<', $at_file)
                or die("Failed to read authtoken from file: $!");
                
            $authtoken = <$ATF>;
            chomp $authtoken;
            close $ATF;
        } else {
            $self->out('CORE', 'No stored authtoken, getting one...');
            $self->getAuthToken($username, $password);
            
            if (defined $authtoken) {
                # Store it
                open(my $ATF, '>', $at_file)
                    or die("Failed to write authtoken from file: $!");
                    
                print $ATF $authtoken;
                close $ATF;
            }
        }
        
        if (not defined $authtoken) {
            $self->out('CORE', 'Failed to get an authtoken! Check your username/password.');
            exit;
        } else {
            $self->out('CORE', 'We got an authtoken!');
        }
        
        $self->out('CORE', 'Connecting to the server...');
        
        $socket = new IO::Socket::INET(
                    PeerAddr => "$server:$port",
                    Proto    => 'tcp',
                    Type     => SOCK_STREAM,
                    Timeout  => 100,
                    Blocking => 0) or die("Connect failed: $!\n");
        $connected = 'TRUE';
        
        # Connection monitor
        my $cr = new IO::Select($socket);
                
        $self->out('CORE', 'Connecting to dAmn at ' . $socket->peerhost() . ':' . $port);
        
        $self->sendPacket("dAmnClient 0.3\nagent=$useragent\nauthor=$author\nowner=$owner");
        
        my $packet = '';
        my $char = '';
        
        # Nix.
        local $SIG{ALRM} = sub { timed_out() };
        alarm(120);
        while ((my @can_be_read = $cr->can_read(120)) and $connected eq 'TRUE') {
            foreach my $sock (@can_be_read) {
                if ($sock == $socket) {
                    sysread($socket, $char, 1);
                    $bytesread++;
                    if ($char eq "\0") {
                        if (length($packet) < 1) { $connected = undef; }
                        $self->handle($packet);
                        $packet = '';
                        alarm(100);
                    } else {
                        $packet .= $char;
                    }
                } else {
                    $connected = undef;
                }
            }
        }
        
        $self->timed_out();
    }
    
    sub incdcc { $disconnects++; }
    
    sub timed_out {
        alarm 0;
        $disconnects++;
        $self->out('CORE', 'Caught timeout signal, reconnecting in 5 seconds...');
        close $socket;
        sleep(5);
        $self->init_connect();
    }
    
    sub handle {
        my ($self, %packet) = ($_[0], dAmnPacket::parse($_[1]));
        
        if (defined($packet{body})) {
            $packet{body} = $self->tablumps($packet{body});
        }
        
        if ($packet{command} eq 'recv' and length($packet{subCommand}) > 0) {
            $Events->fire_event('recv_'.$packet{subCommand}, %packet);
        } else {
            $Events->fire_event($packet{command}, %packet);
        }
    }
    
    sub format_bytes {
        my ($self, $bytes) = @_;
        # While we could add higher multiples, we will never encounter them.
        my ($kb, $mb, $gb) = (0, 0, 0);
        
        # Extract GB
        while ($bytes >= 1073741824) {
            $gb++;
            $bytes -= 1073741824;
        }
        
        # Extract MB
        while ($bytes >= 1048576) {
            $mb++;
            $bytes -= 1048576;
        }
        
        # Extract kB
        while ($bytes >= 1024) {
            $kb++;
            $bytes -= 1024;
        }
        
        # Now we create a human-readable string.
        my $fmt = '';
        
        if ($gb > 0) {
            $fmt .= $gb . ' GB, ';
        }
        
        if ($mb > 0) {
            $fmt .= $mb . ' MB, ';
        }
        
        if ($kb > 0) {
            $fmt .= $kb . ' kB, ';
        }
        
        if ($bytes > 0) {
            $fmt .= $bytes . ' bytes.  ';
        }
        
        return substr($fmt, 0, -2);
    }
    
    sub joinChannel {
        my ($self, $chan) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        $self->sendPacket("join $chan");
    }
    
    sub partChannel {
        my ($self, $chan) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        $self->sendPacket("part $chan");
    }
    
    sub say {
        my ($self, $chan, $msg) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        $self->sendPacket("send $chan\n\nmsg main\n\n$msg");
    }
    
    sub npsay {
        my ($self, $chan, $msg) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        $self->sendPacket("send $chan\n\nnpmsg main\n\n$msg");
    }
    
    sub act {
        my ($self, $chan, $msg) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        $self->sendPacket("send $chan\n\naction main\n\n$msg");
    }
    
    sub kick {
        my ($self, $chan, $who, $reason) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        $self->sendPacket("kick $chan\nu=$who\n\n$reason");
    }
        
    sub promote {
        my ($self, $chan, $who, $pc) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        my $pcc = "\n";
        $pcc = "\n\n$pc" if defined($pc) and length($pc) > 0;
        print "'$pcc'\n";
        $self->sendPacket("send $chan\n\npromote $who$pcc", 1);
    }
        
    sub demote {
        my ($self, $chan, $who, $pc) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        my $pcc = "\n";
        $pcc = "\n\n$pc" if defined($pc) and length($pc) > 0;
        $self->sendPacket("send $chan\n\ndemote $who$pcc", 1);
    }
        
    sub ban {
        my ($self, $chan, $who) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        $self->sendPacket("send $chan\n\nban $who");
    }
        
    sub unban {
        my ($self, $chan, $who) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        $self->sendPacket("send $chan\n\nunban $who");
    }
        
    sub whois {
        my ($self, $who) = @_;
        $self->sendPacket("get login:$who\np=info");
    }
        
    sub get {
        my ($self, $chan, $p) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        $self->sendPacket("get $chan\np=$p");
    }
        
    sub set {
        my ($self, $chan, $p, $value) = @_;
        if (substr ($chan, 0, 5) ne 'chat:') {
            $chan = $self->formatNS($chan);
        }
        $self->sendPacket("set $chan\np=$p\n\n$value");
    }
    
    sub quit {
        $self->sendPacket("disconnect");
    }
    
    sub sendPacket {
        my ($self, $payload, $nonl) = @_;
        my $nl = "\n";
        $nl = '' if defined($nonl);
        print $socket $payload.$nl.chr(0);
        $bytessent += length($payload.$nl) + 1;
    }
    
    sub formatNS {
        my ($self, $chan) = @_;
        if (substr ($chan, 0, 1) eq '#') {
            return 'chat:' . substr $chan, 1;
        } elsif (substr ($chan, 0, 5) eq 'chat:') {
            return '#' . substr $chan, 5;
        } elsif (substr ($chan, 0, 6) eq 'login:') {
            return '@' . substr $chan, 6;
        } else { return $chan; }
    }
    
    sub timestamp {
        return strftime "[%H:%M:%S]", localtime;
    }
    
    sub monthstamp {
        strftime "%b-%Y", localtime;
    }
    
    sub daystamp {
        strftime "%d", localtime;
    }
    
    sub uptime {
        my $self = $_[0];
        return $self->format_time(int(time - $start_time));
    }
    
    sub format_time {
        my $seconds = int($_[1]);
        my ($minutes, $hours) = (0, 0);
        my $uptime = '';
        
        while ($seconds >= 3600) {
            $hours++;
            $seconds -= 3600;
        }
        
        while ($seconds >= 60) {
            $minutes++;
            $seconds -= 60;
        }
        
        if ($hours > 0) {
            $uptime = "$hours hour" . ($hours == 1 ? ', ' : 's, ');
        }
        
        if ($minutes > 0) {
            $uptime .= "$minutes minute" . ($minutes == 1 ? ', ' : 's, ');
        }
        
        return $uptime . $seconds . ' seconds.';
    }
    
    sub tablumps {
        my ($self, $string) = @_;
        
        # Dev links
        $string =~ s/&dev\t([^\t])\t([^\t]+)\t/:dev$2:/g;
        
        # Icons
        $string =~ s/&avatar\t([^\t]+)\t([^\t]+)\t/:icon$1:/g;
        
        # Abbr/Acronym
        $string =~ s/&(abbr|acro)\t([^\t]+)\t/<$1 title="$2">/g;
        
        # Links
        $string =~ s/&a\t([^\t]+)\t([^\t]*)\t/<a href="$1">/g;
        $string =~ s/&link\t([^\t]+)\t([^\t]+)\t([^\t]+)\t/<a href="$1">$2<\/a>/g;
        $string =~ s/&link\t([^\t]+)\t([^\t]+)\t/$1/g;
        
        # Images and IFrames
        $string =~ s/&(img|iframe)\t([^\t]+)\t([^\t]*)\t([^\t]+)\t/<$1 src="$2" \/>/g;
        
        # Don't think any other simple ones are supported?
        $string =~ s/&(|\/)(a|b|i|u|s|sup|sub|code|bcode|abbr|acro)\t/<$1$2>/g;
        
        # Breaks!
        $string =~ s/&br\t/<br\/>/g;
        
        # Thumbs
        $string =~ s/&thumb\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t/:thumb$1:/g;
        
        # Emotes
        $string =~ s/&emote\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t/$1/g;
        
        # < and >
        $string =~ s/&gt;/>/g;
        $string =~ s/&lt;/</g;
        
        return $string;
    }
    
    sub out {
        my ($self, $ns, $msg) = @_;
        print timestamp(), " [$ns] $msg\n";
        
        # Logging. Only log channels or pchats.
        if ((substr $ns, 0, 1) eq '#' or (substr $ns, 0, 1) eq '@') {
            # File/folder prefixes.
            my $ms = monthstamp();
            my $ds = daystamp();
            # Make sure the log directory exists.
            unless (-d $logdir) {
                mkdir $logdir, 0777;
            }
            # Make sure we have a directory for the namespace.
            unless (-d "$logdir/$ns") {
                mkdir "$logdir/$ns", 0777;
            }
            # Make sure we have a directory for this month.
            unless (-d "$logdir/$ns/$ms") {
                mkdir "$logdir/$ns/$ms", 0777;
            }
            # Append [and create] the log file for today.
            open(my $fh, ">>", "$logdir/$ns/$ms/$ds-$ms.txt") 
                or die "Cannot open log file for writing: $!";
            print $fh timestamp(), " $msg\r\n";
            close $fh;
        }
    }

    sub init {
        ($self, $username, $password, $trigger, $owner, @channels) = @_;
        $self->out('CORE', "Origami $version by DivinityArcane <eittreim.justin\@live.com>");
        $self->out('CORE', "Built: $date");
       
        # Time to load the modules.
        # First off, $self will be overwritten. We need a second variable.
        my $Origami = $self;
        
        # Open the folder for reading
        opendir(MODULES, './Modules') or die $!;

        # Loop through each file
        while (my $module = readdir(MODULES)) {

            # Make sure it's in the modules directory and not a subdirectory.
            next unless (-f "./Modules/$module");

            # Make sure it's a valid Perl module.
            next unless ($module =~ m/\.pm$/);
            
            # Grab the class name, which has to be the same as the file name. (Case sensitive)
            my $class = $module;
            $class =~ s/\.pm$//;
            
            # Let them know what's loading. We need a static reference from here.
            $Origami->out('Modules', 'Importing module '.$class);
        
            # Load it up
            require './Modules/'.$module;
            
            # Store the classref
            $MODREF{$class} = new $class;
            
            # Initialize the module!
            $MODREF{$class}->init($Origami);
        }

        # We're done here.
        closedir(MODULES);
        
        # Reset the $self variable.
        $self = $Origami;
        
        # We need these
        $dAmn  = $MODREF{dAmn};
        $BDS   = $MODREF{BDS};
        $Users = $MODREF{Users};
       
        # Initialize the core mods.
        $Events->init($self);
        $self->init_connect();
    }

1;
