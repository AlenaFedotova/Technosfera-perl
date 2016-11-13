package Local::Habr::Base;

use strict;
use warnings;
use Mouse;
use DBI;
use Local::Schema;
use List::MoreUtils;
use feature 'say';
use open ":utf8",":std";
use DDP;

=encoding utf8

=head1 NAME

Local::Habr - habrahabr.ru crawler

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

has database => (is => 'ro', isa => 'Str', default => 'habr');
has name     => (is => 'ro', isa => 'Str', required => 1);
has password => (is => 'ro', isa => 'Str', required => 1);
has schema   => (is => 'rw', isa => 'Local::Schema');

sub init {
	my $self = shift;

	$self->{schema} = Local::Schema->connect("DBI:mysql:database=".$self->{database}, $self->{name}, $self->{password});
}

sub _user_information {
	my $self = shift;
	my $user = shift;
	return {username => $user->username, karma => $user->karma, rating => $user->rating}
}

sub _post_information {
	my $self = shift;
	my $post = shift;
	return {id => $post->id, author => $post->author->username, topic => $post->topic, rating => $post->rating, views => $post->views, stars => $post->stars}
}

sub take_user {
	my $self = shift;
	my $name = shift;
	my $res;

	my $tmp = $self->{schema}->resultset('User')->find($name);
	if (!defined($tmp)) {return undef}
	$res = $self->_user_information($tmp);

	return $res;
}

sub take_post {
	my $self = shift;
	my $post = shift;
	my $res;
	my $author;
	my @commentors;

	my $tmp = $self->{schema}->resultset('Post')->find($post);
	
	if (!defined($tmp)) {return undef}

	my @tmp = $tmp->comments;
	$res = $self->_post_information($tmp);

	$author = $self->_user_information($tmp->author);

	for (@tmp) {
		push(@commentors, $self->_user_information($_->commentor))
	}

	return ($res, $author, \@commentors);
}

sub self_commentors {
	my $self = shift;
	my @self_com;

	my @tmp;
	my $comments = $self->{schema}->resultset('Comment');
	while (my $com = $comments->next) {
		if ($com->post->author->username eq $com->commentor->username && !List::MoreUtils::any {$_->{username} eq $com->commentor->username} @self_com) {
			push(@self_com, $self->_user_information($com->commentor))
		}
	}
	
	return @self_com;
}

sub desert_posts {
	my $self = shift;
	my $n = shift;
	my @des_posts;

	my @commentors;
	my $posts = $self->{schema}->resultset('Post');
	while (my $post = $posts->next) {
		my @coms = $post->comments;

		if ($#coms < $n) {
			my $tmp = $self->_post_information($post);
			push(@des_posts, $self->_post_information($post));
		}
	}
	
	return @des_posts;
}

sub add_user {
	my $self = shift;
	my $user = shift;

	$self->{schema}->resultset('User')->update_or_create({username => $user->{username}, karma => $user->{karma}, rating => $user->{rating}})
}

sub add_post {
	my $self = shift;
	my $post = shift;
	my $author = shift;
	my $commentors = shift;

	my $tmp = $self->{schema}->resultset('Post')->find($post->{id});

	if (defined $tmp) {
		my @coms = $tmp->comments;
		for (@coms) {$_->delete()}

		$tmp->delete();
	}
	$self->add_user($author);
	my $a = $self->{schema}->resultset('User')->find($author->{username});
	my $p = $self->{schema}->resultset('Post')->create({id => $post->{id}, author => $post->{author}, topic => $post->{topic}, rating => $post->{rating}, views => $post->{views}, stars => $post->{stars}});

	for (@$commentors) {

		$self->add_user($_);

		$self->{schema}->resultset('Comment')->create({post_id => $post->{id}, commentor => $_->{username}});
	}
}

1;
