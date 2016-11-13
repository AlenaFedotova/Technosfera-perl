#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use DDP;
use Local::Habr;
use JSON::XS;
require 'habr.conf';

Local::Habr->init(conf());

my $type = shift;
my %opt;
$opt{refresh} = 0;

Getopt::Long::GetOptions (\%opt, "format:s", "refresh", "name:s", "post:s", "id:s", "n:i");
#p %opt;

if ($type eq "user" && (!(defined($opt{name}) ^ defined($opt{post})) || defined($opt{id}) || defined($opt{n}))) {die "Bad options"}
if ($type eq "post" && (!(defined($opt{id})) || defined($opt{name}) || defined($opt{n}) || defined($opt{post}))) {die "Bad options"}
if ($type eq "commenters" && (!(defined($opt{post})) || defined($opt{name}) || defined($opt{n}) || defined($opt{id}))) {die "Bad options"}
if ($type eq "self_commentors" && (defined($opt{id}) || defined($opt{name}) || defined($opt{n}) || defined($opt{post}))) {die "Bad options"}
if ($type eq "desert_posts" && (!(defined($opt{n})) || defined($opt{name}) || defined($opt{id}) || defined($opt{post}))) {die "Bad options"}

my @res;

if ($type eq 'user' && defined($opt{name})) {@res = Local::Habr->ask_user_by_name($opt{name}, $opt{refresh})}
if ($type eq 'user' && defined($opt{post})) {@res = Local::Habr->ask_user_by_post($opt{post}, $opt{refresh})}
if ($type eq 'post' && defined($opt{id})) {@res = Local::Habr->ask_post($opt{id}, $opt{refresh})}
if ($type eq 'commenters' && defined($opt{post})) {@res = Local::Habr->ask_commenters($opt{post}, $opt{refresh})}
if ($type eq 'self_commentors') {@res = Local::Habr->ask_self_commenters()}
if ($type eq 'desert_posts' && defined($opt{n})) {@res = Local::Habr->ask_desert_posts($opt{n})}

if (defined $opt{format} && $opt{format} eq 'ddp') {
	for (@res) {p $_}
}
elsif (defined $opt{format} && $opt{format} eq 'json') {
	for (@res) {print JSON::XS->new->utf8->encode($_)."\n"}
}
else {
	print Dumper(@res)
}
