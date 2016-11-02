package Local::TCP::Calc::Server::Worker;

use strict;
use warnings;
use Mouse;
use feature 'say';
use Local::TCP::Calc::Server::FileName;
use Fcntl qw(:flock);
use POSIX;

has cur_task_id => (is => 'ro', isa => 'Int', required => 1);
has forks       => (is => 'rw', isa => 'HashRef', default => sub {return {}});
has calc_ref    => (is => 'ro', isa => 'CodeRef', required => 1);
has max_forks   => (is => 'ro', isa => 'Int', required => 1);

my $err = 0;
my $num_forks = 0;

sub write_err {
	my $self = shift;
	my $error = shift;

	my $fh;
	open($fh, '>', Local::TCP::Calc::Server::FileName::res($self->{cur_task_id}))
		or die "Can't open ".Local::TCP::Calc::Server::FileName::res($self->{cur_task_id})."\n";
	until (flock($fh, 2)) {sleep 0.01}

	say $fh $error;
	flock($fh, 8)
		or die "Can't unlock ".Local::TCP::Calc::Server::FileName::res($self->{cur_task_id})."\n";
	close($fh);
}

sub write_res {
	my $self = shift;
	my $task = shift;
	my $res = shift;
	my $fh;

	open($fh, '>>', Local::TCP::Calc::Server::FileName::res($self->{cur_task_id}))
		or die "Can't open ".Local::TCP::Calc::Server::FileName::res($self->{cur_task_id})."\n";
	until (flock($fh, 2)) {sleep 0.01}

	say $fh $task.' == '.$res;
	flock($fh, 8)
		or die "Can't unlock ".Local::TCP::Calc::Server::FileName::res($self->{cur_task_id})."\n";
	close($fh);
}

sub start {
	my $self = shift;



	sub REAPER {
		while (my $pid = waitpid(-1, WNOHANG)) {

			last if $pid == -1;

			my $status = $?;
			if ($status != 0) {
				$err++;
			}

			delete $self->forks->{$pid};
			$num_forks--;

		}
		$SIG{CHLD} = \&REAPER;
	}
	

	$SIG{INT} = sub {
		for (%{$self->forks}) {
			kill('TERM', $_);
		}
		exit(0);
	};

	my $fhtask;
	open($fhtask, '<', Local::TCP::Calc::Server::FileName::task($self->{cur_task_id}))
		or die "Can't open ".Local::TCP::Calc::Server::FileName::task($self->{cur_task_id})."\n";
	
	while (<$fhtask>) {
		chomp $_;
		if ($err) {
			for (%{$self->forks}) {
				kill('TERM', $_);
			}
			last
		}

		while ($num_forks >= $self->{max_forks}) {
			sleep 0.1;
		}
		my $child = fork();
		if ($child) {
			$num_forks++;
			$self->forks->{$child} = $child;
			$SIG{CHLD} = \&REAPER;
			next;
		}
		if (defined $child) {
			my $res = $self->calc_ref->($_);

			$self->write_res($_, $res);
			exit(0);
		}
		else {die "Can't fork: $!"}
	}
	while ($num_forks) {sleep 0.1}

	close $fhtask;
	return $err;
}

no Mouse;
__PACKAGE__->meta->make_immutable();

1;
