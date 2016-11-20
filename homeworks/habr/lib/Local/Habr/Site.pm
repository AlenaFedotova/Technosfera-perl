package Local::Habr::Site;

use strict;
use warnings;
use LWP::UserAgent;
use Moose;
use open ":utf8",":std";
use Mojo::DOM;
use feature 'say';
use DDP;
use Lingua::Translit;
use List::MoreUtils;

=encoding utf8

=head1 NAME

Local::Habr - habrahabr.ru crawler

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

has address => (is => 'ro', isa => 'Str', default => 'https://habrahabr.ru/');
has ua => (is => 'rw', isa => 'LWP::UserAgent', builder => '_build_ua', lazy => 1);

sub _build_ua {
	my ($self) = @_;

	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->env_proxy;
	return $ua;
}

sub take_user {
	my ($self, $name) = @_;

	my $response = $self->ua->get($self->{address}.'users/'.$name.'/');
	if (!$response->is_success) {return}
	my $str = $response->decoded_content;

	my $dom = Mojo::DOM->new($str);
	my $username = $dom->at('a[class="author-info__nickname"]')->text;
	$username = substr($username, 1);
	my $rating = $dom->at('div[class="statistic__value statistic__value_magenta"]')->text;
	my $karma = $dom->at('div[class="voting-wjt__counter-score js-karma_num"]')->text;

	$karma =~ s/\,/\./;
	$rating =~ s/\,/\./;

	if (!($karma =~ /^[\d\.\-]*$/)) {
		$karma =~ s/^.//;
		$karma =~ s/^/-/;
	}
	if (!($rating =~ /^[\d\.\-]*$/)) {
		$rating =~ s/^.//;
		$rating =~ s/^/-/;
	}
	
	return {username => $username, karma => $karma, rating => $rating}
}

sub take_company {
	my ($self, $name) = @_;

	return {username => $name};
}

sub take_post {
	my ($self, $id) = @_;

	my $response = $self->ua->get($self->{address}.'post/'.$id.'/');
	if (!$response->is_success) {return}
	my $str = $response->decoded_content;

	my $dom = Mojo::DOM->new($str);
	my $post_id = $dom->at('input[name="moderation"]')->{value};
	my $author = $dom->at('a[class="author-info__nickname"]');
	if (!defined($author)) {
		$author = $dom->at('a[class="author-info__name"]')->text;
		$author = $self->take_company($author);
	}
	else {
		$author = $author->text;
		$author = substr($author, 1);
		$author = $self->take_user($author)
	}
	
	my $views = $dom->at('div[class="views-count_post"]')->text;
	my $stars = $dom->at('span[class="favorite-wjt__counter js-favs_count"]')->text;
	my $topic = $dom->at('meta[property="og:title"]')->{content};
	my $tmp = $dom->at('span[class="voting-wjt__counter-score js-score"]');
	my $rating;
	if (defined($tmp)) {$rating = $tmp->text}

	my @commenters;
	for my $e ($dom->find('span[class="comment-item__user-info"]')->each) {
		my $name = $e->{'data-user-login'};
		if (!List::MoreUtils::any {$_->{username} eq $name} @commenters) {
			push(@commenters, $self->take_user($name))
		}
	}
	if (defined $rating) {
		$rating =~ s/\,/\./;
		$rating =~ s/^\+//;
		if (!($rating =~ /^[\d\.\-]*$/)) {
			$rating =~ s/^.//;
			$rating =~ s/^/-/;
		}
	}
	else {$rating = 0}

	return ({id => $post_id, author => $author->{username}, topic => $topic, rating => $rating+0, views => $views, stars => $stars}, $author, \@commenters)
}

1;
