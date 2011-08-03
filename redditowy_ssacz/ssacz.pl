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
use Config::Simple;
use Data::Dumper; # for debug only

#config
my $cfg = new Config::Simple('./ssacz.ini');

my $save_dir = $cfg->get_block('gonewild')->{'save_dir'};
my $input_url = $cfg->get_block('gonewild')->{'input_url'};
my $numpages = $cfg->get_block('gonewild')->{'numpages'};
my $filter = $cfg->get_block('gonewild')->{'filter'};

#the rest variables
my $url = $input_url;
my $after;

my $content;
my $parsed;


#subs
sub download_img
{
	my ($img_url, $filename, $selfpost) = @_;
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


#main
for my $page (1..$numpages)	
{
	$content = get($url);
	unless (defined $content) {
	    say "Error getting URL $url";
	    next;
	}	
	$parsed = from_json($content);
	say "Downloading page $page of $numpages ($url)";
	
	$parsed = $parsed->{'data'}->{'children'}; 
	
	for my $i (@$parsed)
	{
	   $i = $i->{'data'};

	   if($i->{'title'} =~ m/$filter/i) 
	   {
		   unless($i->{'selftext'})
		   {	   	
			   if ($i->{'url'} =~ m|http://(?:i\.)?(imgur\.com/([a-zA-Z0-9]*\.jpg))|)
			   {
				say "-- Got single image post";				   	
			   		my $img_url = "http://i.$1";
			   		my $filename = $2;
					download_img($img_url, $filename, 0);
			   }
		   }
		   else
		   {
		   		say "-- Got selftext post";
		   		my @img_urls = $i->{'selftext'} =~ m|http://(?:i\.)?(?:imgur\.com/([a-zA-Z0-9]*\.jpg))|g;
		   		#say Dumper(\@img_urls);
				for my $filename (@img_urls)
				{
					my $img_url = "http://i.imgur.com/$filename";
					download_img($img_url, $filename, 1);				
				}		   		
		   }
		}
		$after = $i->{'id'};	   
	}
	
	$url = "$input_url&after=t3_$after";
}
say 'Done!';