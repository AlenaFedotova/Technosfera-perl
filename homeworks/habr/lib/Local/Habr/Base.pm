package Local::Habr::Base;

use strict;
use warnings;
use Moose;
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
has schema   => (is => 'rw', isa => 'Local::Schema', builder => '_build_schema', lazy => 1);

sub _build_schema {
	my ($self) = @_;
	return Local::Schema->connect("DBI:mysql:database=".$self->database, $self->name, $self->password, {mysql_enable_utf8 => 1, mysql_init_command => 'SET NAMES utf8'});
}

sub _user_information {
	my ($self, $user) = @_;
	return {username => $user->username, karma => $user->karma, rating => $user->rating}
}

sub _post_information {
	my ($self, $post) = @_;
	return {id => $post->id, author => $post->author->username, topic => $post->topic, rating => $post->rating, views => $post->views, stars => $post->stars}
}

sub take_user {
	my ($self, $name) = @_;
	my $res;

	my $tmp = $self->schema->resultset('User')->find($name);
	if (!defined($tmp)) {return}
	$res = $self->_user_information($tmp);

	return $res;
}

sub take_post {
	my ($self, $post) = @_;
	my $res;
	my $author;
	my @commentors;

	my $tmp = $self->schema->resultset('Post')->find($post);
	
	if (!defined($tmp)) {return}

	my @tmp = $tmp->comments;
	$res = $self->_post_information($tmp);

	$author = $self->_user_information($tmp->author);

	for (@tmp) {
		push(@commentors, $self->_user_information($_->commentor))
	}

	return ($res, $author, \@commentors);
}

sub self_commentors {
	my ($self) = @_;
	my @self_com;

	my $comments = $self->schema->resultset('Comment');
	while (my $com = $comments->next) {
		if ($com->post->author->username eq $com->commentor->username && !List::MoreUtils::any {$_->{username} eq $com->commentor->username} @self_com) {
			push(@self_com, $self->_user_information($com->commentor))
		}
	}
#select distinct username, karma, user.rating from user join post on post.author = user.username join comment on comment.post_id = post.id where post.author = comment.commentor
	return @self_com;
}

sub desert_posts {
	my ($self, $n) = @_;
	my @des_posts;

	my @commentors;
	my $posts = $self->schema->resultset('Post');
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
	my ($self, $user) = @_;

	$self->schema->resultset('User')->update_or_create({username => $user->{username}, karma => $user->{karma}, rating => $user->{rating}})
}

sub add_post {
	my ($self, $post, $author, $commentors) = @_;

	my $tmp = $self->schema->resultset('Post')->find($post->{id});

	if (defined $tmp) {
		my @coms = $tmp->comments;
		for (@coms) {$_->delete()}

		$tmp->delete();
	}
	$self->add_user($author);
	my $a = $self->schema->resultset('User')->find($author->{username});
	my $p = $self->schema->resultset('Post')->create({id => $post->{id}, author => $post->{author}, topic => $post->{topic}, rating => $post->{rating}, views => $post->{views}, stars => $post->{stars}});

	for (@$commentors) {

		$self->add_user($_);

		$self->schema->resultset('Comment')->create({post_id => $post->{id}, commentor => $_->{username}});
	}
}

1;
