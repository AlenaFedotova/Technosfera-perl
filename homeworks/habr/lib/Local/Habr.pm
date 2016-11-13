package Local::Habr;

use strict;
use warnings;
use Local::Habr::Base;
use Local::Habr::Cache;
use Local::Habr::Site;
use feature 'say';

=encoding utf8

=head1 NAME

Local::Habr - habrahabr.ru crawler

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

my $base;
my $cache;
my $site;

sub init {
	my $pkg = shift;
	my $conf = shift;

	$base = Local::Habr::Base->new(database => $conf->{database}->{database_name}, name => $conf->{database}->{username}, password => $conf->{database}->{password});
	$cache = Local::Habr::Cache->new(server => $conf->{memcached}->{host}.':'.$conf->{memcached}->{port});
	$site = Local::Habr::Site->new();
	$base->init();
	$cache->init();
	$site->init();
}

sub ask_user_by_name {
	my $pkg = shift;
	my $name = shift;
	my $refresh = shift;
	my $res;

	if (!$refresh) {
		$res = $cache->take_user($name);
		if (defined($res)) {
			return $res
		}
		$res = $base->take_user($name);
		if (defined($res)) {
			$cache->add_user($res);
			return $res
		}
	}
	$res = $site->take_user($name);
	if (!defined($res)) {
		return undef;
	}
	$base->add_user($res);
	$cache->add_user($res);

	return $res;
}

sub ask_by_post {
	my $pkg = shift;
	my $post = shift;
	my $refresh = shift;

	my $res;
	my $author;
	my $commenters;
	if (!$refresh) {
		($res, $author, $commenters) = $base->take_post($post);
		if (defined($res)) {
			return ($res, $author, $commenters);
		}
	}
	($res, $author, $commenters) = $site->take_post($post);
	if (!defined($res)) {
		return undef;
	}
	$base->add_post($res, $author, $commenters);

	return ($res, $author, $commenters);
}

sub ask_user_by_post {
	my $pkg = shift;
	my $post = shift;
	my $refresh = shift;

	my $res;
	my $author;
	my $commenters;
	($res, $author, $commenters) = __PACKAGE__->ask_by_post($post, $refresh);
	$cache->add_user($author);
	return $author;
}

sub ask_post {
	my $pkg = shift;
	my $post = shift;
	my $refresh = shift;
	
	my $res;
	my $author;
	my $commenters;
	($res, $author, $commenters) = __PACKAGE__->ask_by_post($post, $refresh);
	return $res;
}

sub ask_commenters {
	my $pkg = shift;
	my $post = shift;
	my $refresh = shift;

	my $res;
	my $author;
	my $commenters;
	($res, $author, $commenters) = __PACKAGE__->ask_by_post($post, $refresh);

	return @$commenters;
}

sub ask_self_commenters {
	my $pkg = shift;
	return $base->self_commentors();
}

sub ask_desert_posts {
	my $pkg = shift;
	my $n = shift;
	return $base->desert_posts($n);
}

1;
