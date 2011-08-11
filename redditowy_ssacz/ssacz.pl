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
use Digest::MD5 qw(md5_hex);
use Data::Dumper; # for debug only

#subs
sub separate
{
	my($input) = @_ or die('expected one string parameter');
	my $ret = {};	
	$input =~ m/(.*)\.(.*)/;
	$ret->{'name'} = $1 or $ret->{'name'} = $input;
	$ret->{'ext'} = $2 or $ret->{'ext'} = '';
	return $ret;
}

sub download_img
{
	my ($save_dir, $img_url, $filename, $hash_filename, $selfpost) = @_;
	my $s = '';
	$s = '(from selfpost)' if($selfpost);
	
	if($hash_filename)
	{
		my $f = separate($filename);
		$filename = md5_hex($f->{'name'}).'.'.$f->{'ext'};
	}
	
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

sub main
{
	# config
	my $cfg = Config::Tiny->new();
	$cfg = $cfg->read('./ssacz.ini');
				
	for my $subreddit (keys %$cfg)
	{
		say "------ Downloading using configuration \"$subreddit\" -----";
	
		my ($save_dir, $input_url, $num_pages, $filter, $hash_filename) =
			@{$cfg->{$subreddit}}{ qw( save_dir input_url num_pages filter hash_filename) };
		
		# variables
		my $url = $input_url;
		my $after; # download next page AFTER this submission id		
		my $content;
		my $parsed;	
		
		# get one subreddit at the time
		for my $page (1..$num_pages)	
		{
			$content = get($url);
			unless (defined $content) {
			    say "Error getting URL $url, skipping.";
			    next;
			}	
			$parsed = from_json($content);
			say "Downloading page $page of $num_pages ($url)";
			
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
							download_img($save_dir, $img_url, $filename, $hash_filename, 1);				
						}		   	
		
				   }
				   else
				   {
				   	   if ($i->{'url'} =~ m^http://(?:i\.)?(imgur\.com/([a-zA-Z0-9]*\.(?:jpg|png|gif|jpeg)))^i )
					   {
						say "-- Got single image post";				   	
					   		my $img_url = "http://i.$1";
					   		my $filename = $2;
							download_img($save_dir, $img_url, $filename, $hash_filename, 0);
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
}

main(); # execute main sub
