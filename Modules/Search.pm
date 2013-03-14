# Search Module for Origami
# Author: Justin Eittreim (DivinityArcane)
# Contact: eittreim.justin@live.com
# Date: Tue November 20 2012, 20:30

package Search;

    use strict;
    use warnings;
    
    use feature 'switch';
	
    my $bot;
    
    sub new {
        return bless {}, shift;
    }
    
    sub init {
        $bot = $_[1];
        
        # Commands
        $bot->Events->add_command('google', 'Search->cmd_google', ('Search', 25, 'DivinityArcane', 
            'Searches Google for the specified query.', $bot->trigger.'google <b>something</b>'));
            
        $bot->Events->add_command('botdom', 'Search->cmd_botdom', ('Search', 25, 'DivinityArcane', 
            'Searches the Botdom wiki for pages containing the specified query.', $bot->trigger.'botdom <b>something</b>'));
            
        $bot->Events->add_command('docs', 'Search->cmd_docs', ('Search', 25, 'DivinityArcane', 
            'Searches the Botdom docs for pages containing the specified query.', $bot->trigger.'docs <b>something</b>'));
            
        $bot->Events->add_command('thumbinfo', 'Search->cmd_thumbinfo', ('Search', 10, 'DivinityArcane', 
            'Gets information on the specified thumb.', $bot->trigger.'thumbinfo <b>:thu<i></i>mb68344829:</b>'));
            
        $bot->Events->add_command('weather', 'Search->cmd_weather', ('Search', 10, 'DivinityArcane', 
            'Gets the current weather for the specified area.', $bot->trigger.'weather <b>[zip code/city]</b>'));
    }
    
    sub json_page {
        my ($self, $base, $query) = @_;
        
        # Include the needed modules
        use LWP::UserAgent;
        use URI::Escape;
        use JSON::XS qw(decode_json);

        my $url = $base.uri_escape($query);
        
        my $UA = LWP::UserAgent->new;
        my $RQ = HTTP::Request->new(GET => $url);
        my $RS = $UA->request($RQ);
        
        return ('status'=>'failed') unless ($RS->is_success);
        
        if (index($RS->content, '404 Not Found') != -1) {
            return ('status'=>'failed');
        }
        
        return %{ decode_json $RS->content };
    }
    
    sub search {
        my ($self, $type, $query) = @_;
        
        given ($type) {
            when ('google') {
                return $self->json_page('http://ajax.googleapis.com/ajax/services/search/web?v=2.0&q=', $query);
            }
            
            when ('botdom') {
                return $self->json_page('http://botdom.com/w/api.php?action=query&list=search&format=json&srwhat=text&srsearch=', $query);
            }
            
            when ('docs') {
                return $self->json_page('http://botdom.com/d/api.php?action=query&list=search&format=json&srwhat=text&srsearch=', $query);
            }
            
            when ('thumbinfo') {
                return $self->json_page('http://backend.deviantart.com/oembed?url=', $query);
            }
            
            when ('weather') {
                return $self->json_page('http://free.worldweatheronline.com/feed/weather.ashx?format=json&num_of_days=1&key=5ea0d0bf10080502122111&q=', $query);
            }
            
            default { ('status'=>'failed'); }
        }
    }
    
    # Commands!
    
    sub cmd_google {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'. $bot->trigger .'google <b>something</b>'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $query = join ' ', splice(@args, 1);
        my %response = $self->search('google', $query);
        my @results = @{ $response{responseData}{results} };
        if (scalar(@results) <= 0) {
            $bot->say($ns, '<b>:bulletred: No results!</b>'.$highlight);
            return;
        }
        my ($res_count, $res_url, $time) =
            ($response{responseData}{cursor}{resultCount}, $response{responseData}{cursor}{moreResultsUrl}, $response{responseData}{cursor}{searchResultTime});
        my $msg = '<b>:bulletgreen: Google</b> - '.$res_count.' results.<br/><br/>';
        foreach my $key (keys @results) {
            my %res = %{ $results[$key] };
            my ($title, $url, $desc, $cached) = ($res{title}, $res{url}, $res{content}, $res{cacheUrl});
            my $cachelink = '';
            if (length($cached) >= 10) {
				$cachelink = ' <sup><a href="'.$cached.'">Cached page</a></sup>';
			}
            $msg .= '<b>&raquo;</b> <a href="'.$url.'">'.$title.'</a>'.$cachelink.'<br/>'.$desc.'<br/><br/>';
        }
        $msg .= '<br /><b>&raquo; The search took '.$time.' seconds. <a href="'.$res_url.'">View more results.</a>'.$highlight;
        $bot->say($ns, $msg);
    }
    
    
    sub cmd_botdom {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'. $bot->trigger .'botdom <b>something</b>'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $query = join ' ', splice(@args, 1);
        my %response = $self->search('botdom', $query);
        my @results = @{ $response{query}{search} };
        if (scalar(@results) <= 0) {
            $bot->say($ns, '<b>:bulletred: No results!</b>'.$highlight);
            return;
        }
        my ($res_count, $res_url) =
            (scalar(@results), 'http://botdom.com/w/index.php?title=Special:Search&search='.$query.'&fulltext=Search&profile=advanced&redirs=0');
        my $msg = '<b>:bulletgreen: Botdom Wiki</b> - '.$res_count.' results.<br/><br/>';
        my $count = 0;
        foreach my $key (keys @results) {
            last unless ($count < 10);
            $count++;
            my %res = %{ $results[$key] };
            my ($title, $url) = ($res{title}, 'http://www.botdom.com/wiki/'.$res{title});
            $msg .= '<b>&raquo;</b> <a href="'.$url.'">'.$title.'</a><br/>';
        }
        $msg .= '<br /><b>&raquo; <a href="'.$res_url.'">View more results.</a>'.$highlight;
        $bot->say($ns, $msg);
    }
    
    
    sub cmd_docs {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'. $bot->trigger .'docs <b>something</b>'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $query = join ' ', splice(@args, 1);
        my %response = $self->search('docs', $query);
        my @results = @{ $response{query}{search} };
        if (scalar(@results) <= 0) {
            $bot->say($ns, '<b>:bulletred: No results!</b>'.$highlight);
            return;
        }
        my ($res_count, $res_url) =
            (scalar(@results), 'http://botdom.com/d/index.php?title=Special:Search&search='.$query.'&fulltext=Search&profile=advanced&redirs=0');
        my $msg = '<b>:bulletgreen: Botdom Docs</b> - '.$res_count.' results.<br/><br/>';
        my $count = 0;
        foreach my $key (keys @results) {
            last unless ($count < 10);
            $count++;
            my %res = %{ $results[$key] };
            my ($title, $url) = ($res{title}, 'http://www.botdom.com/documentation/'.$res{title});
            $msg .= '<b>&raquo;</b> <a href="'.$url.'">'.$title.'</a><br/>';
        }
        $msg .= '<br /><b>&raquo; <a href="'.$res_url.'">View more results.</a>'.$highlight;
        $bot->say($ns, $msg);
    }
    
    
    sub cmd_thumbinfo {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'. $bot->trigger .'thumbinfo <b>:thu<i></i>mb68344829:</b>'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $thumb = $args[1];
        chomp $thumb;
        if ($thumb !~ m/^:thumb[0-9]+:$/) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my %response = $self->search('thumbinfo', $thumb);
        if (not defined($response{title})) {
            $bot->say($ns, '<b>:bulletred: Invalid thumb.</b>'.$highlight);
            return;
        }
        my ($title, $category, $author) =
            ($response{title}, $response{category}, $response{author_name});
        my $msg = '<b>:bulletgreen: deviantART Thumb information</b><br/><br/>'.
            '<b>&raquo; Deviation:</b> <a href="http://www.deviantart.com/deviation/'.substr($thumb, 6, -1).'"><code>'.$title.'</code></a><br/>'.
            '<b>&raquo; Category:</b> '.$category.'<br/>'.
            '<b>&raquo; Author:</b> :dev'.$author.':<br/>'.$highlight;
        $bot->say($ns, $msg);
    }
    
    
    sub cmd_weather {
        my ($self, $bot, $ns, $from, @args) = @_;
        my $highlight = "<abbr title=\"$from\"></abbr>";
        my $helpmsg = '<b>:bulletred: Usage:</b><br/><b>&raquo; </b>'. $bot->trigger .'weather <b>[zip code/city]</b>'.$highlight;
        if (scalar(@args) < 2) {
            $bot->say($ns, $helpmsg);
            return;
        }
        my $query = join ' ', splice(@args, 1);
        my %response = $self->search('weather', $query);
        if (not defined($response{data}{current_condition})) {
            $bot->say($ns, '<b>:bulletred: Invalid zip code or city name.</b>'.$highlight);
            return;
        }
        my ($cloudcover, $humidity, $tempc, $tempf, $visibility, $desc) = (
            $response{data}{current_condition}[0]{cloudcover},
            $response{data}{current_condition}[0]{humidity},
            $response{data}{current_condition}[0]{temp_C},
            $response{data}{current_condition}[0]{temp_F},
            $response{data}{current_condition}[0]{visibility},
            $response{data}{current_condition}[0]{weatherDesc}[0]{value});
        my ($city_name, $city_type) = (
			$response{data}{request}[0]{query},
			$response{data}{request}[0]{type});
        my $msg = '<b>:bulletgreen: Weather information</b><br/><br/>'.
            '<b>&raquo; '.$city_type.':</b> '. $city_name .'<br/>'.
            '<b>&raquo; Description:</b> '. $desc .'<br/>'.
            '<b>&raquo; Cloud cover:</b> '. $cloudcover .'<br/>'.
            '<b>&raquo; Humidity:</b> '. $humidity .'%<br/>'.
            '<b>&raquo; Temperature:</b> '. $tempf .'&deg;<br/>'.
            '<b>&raquo; Visibility:</b> '. $visibility .' miles<br/>'.$highlight;
        $bot->say($ns, $msg);
    }
    
1;
