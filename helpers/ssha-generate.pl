#! /usr/bin/perl
# This script is partly from the openldap faq-omatic pages with a few changes for password/salt

#The following deb packages are required 
#libstring-random-perl libdigest-sha1-perl

use Digest::SHA1;
use MIME::Base64;
use String::Random "random_string";

chomp($password = <STDIN>);
$salt =  random_string("."x"10");

$ctx = Digest::SHA1->new;
$ctx->add($password);
$ctx->add($salt);
$hashedPasswd = '{SSHA}' . encode_base64($ctx->digest . $salt ,'');
print $hashedPasswd;
