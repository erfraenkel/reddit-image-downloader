#!/usr/bin/env perl

# simple reddit image downloader
#
# MIT licensed (https://secure.wikimedia.org/wikipedia/en/wiki/MIT_license)
# (c) by pecet
# pecet.jogger.pl
# 

use feature 'say';
use strict;
use warnings;
use JSON;
use LWP::Simple;
use Config::Tiny;
use Data::Dumper; # for debug only

#subs
sub download_img
{
	my ($save_dir, $img_url, $filename, $selfpost) = @_;
	my $s = '';
	$s = '(from selfpost)' if($selfpost);
	
	if (-e $save_dir.$filename)
	{
		say "Already got image $s $img_url";
	}
	else
	{
		say "Downloading image $s from $img_url";
		mirror($img_url, $save_dir.$filename);
	}	
}

#config
my $cfg = Config::Tiny->new();
$cfg = $cfg->read('./ssacz.ini');	

#main
for my $subreddit (keys %$cfg)
{
	say "------ Downloading using configuration \"$subreddit\" -----";

	my ($save_dir, $input_url, $numpages, $filter) =
		@{$cfg->{$subreddit}}{ qw( save_dir input_url numpages filter ) };
	
	#the rest variables
	my $url = $input_url;
	my $after;
	
	my $content;
	my $parsed;	
	
	# get one subreddit at the time
	for my $page (1..$numpages)	
	{
		$content = get($url);
		unless (defined $content) {
		    say "Error getting URL $url, skipping.";
		    next;
		}	
		$parsed = from_json($content);
		say "Downloading page $page of $numpages ($url)";
		
		$parsed = $parsed->{'data'}->{'children'}; 
		
		for my $i (@$parsed)
		{
		   $i = $i->{'data'};
	
		   if(!$filter or $i->{'title'} =~ m/$filter/i) 
		   {
			   if($i->{'selftext'})		   
			   {	   	
			   		say "-- Got selftext post";
			   		my @img_urls = $i->{'selftext'} =~ m^http://(?:i\.)?(?:imgur\.com/([a-zA-Z0-9]*\.(?:jpg|png|gif|jpeg)))^gi ;
					for my $filename (@img_urls)
					{
						my $img_url = "http://i.imgur.com/$filename";
						download_img($save_dir, $img_url, $filename, 1);				
					}		   	
	
			   }
			   else
			   {
			   	   if ($i->{'url'} =~ m^http://(?:i\.)?(imgur\.com/([a-zA-Z0-9]*\.(?:jpg|png|gif|jpeg)))^i )
				   {
					say "-- Got single image post";				   	
				   		my $img_url = "http://i.$1";
				   		my $filename = $2;
						download_img($save_dir, $img_url, $filename, 0);
				   }
			   }
			}
			$after = $i->{'id'};	   
		}
		
		$url = "$input_url&after=t3_$after";
	}
	say "Done with $subreddit!";
}
say 'All done!';