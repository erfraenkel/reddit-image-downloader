#!/usr/bin/env perl

# simple reddit image downloader
# companion script -- change name of files, to hash of filename
#
# if you want to use hash of filename instead of file name itself 
# (hash_filename = 1 in ssacz.ini config file)
# this is usefull for case unsensitive file systems (like NTFS)
# since imgur urls are case sensitive, and we could skip some files to download
# because of this little quirk
#
# this allows to convert previously downloaded file names to new-hash format
# please note this is only ONE WAY OPERATION, 
# please DON'T RUN THIS SCRIPT more than once on one directory
# invocation: changenametohash.pl C:\path\to\dir OR /path/to/dir
#
# MIT licensed (https://secure.wikimedia.org/wikipedia/en/wiki/MIT_license)
# (c) by pecet
# pecet.jogger.pl
# 

use feature 'say';
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Data::Dumper; # debug only

sub separate
{
	my($input) = @_ or die('expected one string parameter');
	my $ret = {};	
	$input =~ m/(.*)\.(.*)/;
	$ret->{'name'} = $1 or $ret->{'name'} = $input;
	$ret->{'ext'} = $2 or $ret->{'ext'} = '';
	return $ret;
}

sub main
{
	my $dirpath = join(' ', @_);
	say('You must specify input dir, please include trailing / or \\.') and exit() until $dirpath;
	
	opendir(my $dir, $dirpath);
	my @files = readdir($dir);
	for my $file (@files)
	{
		my $f = separate($file);
		my $newfile = md5_hex($f->{'name'}).'.'.$f->{'ext'};
		say "$file -> $newfile";
		rename($dirpath.$file, $dirpath.$newfile)
	}
		say '' and say 'Done! Please DON\'T RUN IT AGAIN!';
}

main(@ARGV);
