package Local::TCP::Calc::Server::Queue;

use strict;
use warnings;
use Fcntl qw(:flock);

use Mouse;
use Local::TCP::Calc;
use Local::TCP::Calc::Server::FileName;
use feature 'say';
use DDP;

has f_handle       => (is => 'rw', isa => 'FileHandle');
has queue_filename => (is => 'ro', isa => 'Str', default => '/tmp/local_queue.log');
has max_task       => (is => 'rw', isa => 'Int', default => 0);
has last_added_id  => (is => 'rw', isa => 'Int', default => 0);
has last_given_id  => (is => 'rw', isa => 'Int', default => 0);
has num_finish_id  => (is => 'rw', isa => 'Int', default => 0);

sub init {
	my $self = shift;
	open($self->{f_handle}, '>', $self->{queue_filename})
		or die "Can't open ".$self->{queue_filename}."\n";
	$self->{f_handle}->print ($self->{last_added_id}.' '.$self->{last_given_id}.' '.$self->{num_finish_id}."\n");
	close($self->{f_handle});
}

sub open {
	my $self = shift;
	my $open_type = shift;

	open($self->{f_handle}, $open_type, $self->{queue_filename})
		or die "Can't open ".$self->{queue_filename}."\n";
	until (flock($self->{f_handle}, LOCK_EX)) {sleep 0.01}
	my $fh = $self->{f_handle};
	my $first_line = <$fh>;
	chomp $first_line;
	($self->{last_added_id}, $self->{last_given_id}, $self->{num_finish_id}) = split / /, $first_line;

	my @lines = <$fh>;
	my %hash;

	for (@lines) {
		chomp $_;
		my @tmp = split /:/, $_;
		$hash{$tmp[0]} = $tmp[1];
	}

	return \%hash;
}

sub close {
	my $self = shift;
	my $struct = shift;
	my $open_type = shift;

	if ($open_type ne '<') {
		truncate($self->{f_handle}, 0);
		seek($self->{f_handle}, 0, 0);

		$self->{f_handle}->print ($self->{last_added_id}.' '.$self->{last_given_id}.' '.$self->{num_finish_id}."\n");
		for my $id (1..$self->{last_added_id}) {	
			$self->{f_handle}->print ($id.":".$struct->{$id}."\n");
		}
	}
	flock($self->{f_handle}, LOCK_UN)
		or die "Can't unlock ".$self->{queue_filename}."\n"; 

	close($self->{f_handle});
}

sub to_done {
	my $self = shift;
	my $task_id = shift;
	my $status = shift;
	
	my $struct = $self->open('+<');
	$struct->{$task_id} = $status;
	$self->{num_finish_id}++;

	$self->close($struct, '+<');
}

sub get_status {
	my $self = shift;
	my $id = shift;
	my $struct = $self->open('<');
	my $status = 'not found';
	if (defined($struct->{$id})) {
		$status = $struct->{$id};
	}
	$self->close($struct, '<');

	return $status
}

sub delete {
	my $self = shift;
	my $id = shift;
	my $status = shift;
	my $struct = $self->open('+<');
	my $real_status = $struct->{$id};
	if ($status eq $real_status) {
		$struct->{$id} = 'deleted';
		unlink(Local::TCP::Calc::Server::FileName::task($id));
		unlink(Local::TCP::Calc::Server::FileName::res($id));
	}
	$self->close($struct, '+<');
}

sub get {
	my $self = shift;

	my $struct = $self->open('+<');
	my $tmp = 0;
	my $id;


	if ($self->{last_added_id} > $self->{last_given_id}) {
		$self->{last_given_id}++;

		$id = $self->{last_given_id};
		$struct->{$id} = 'work';
	}

	$self->close($struct, '+<');

	if (defined($id)) {return $id}
}

sub add {
	my $self = shift;
	my $new_work = shift;

	my $struct = $self->open('+<');
	my $new_id;

	if ($self->{last_added_id} - $self->{num_finish_id} < $self->{max_task}) {
		$self->{last_added_id}++;

		$new_id = $self->{last_added_id};
		$struct->{$new_id} = 'new';
		my $filename = Local::TCP::Calc::Server::FileName::task($new_id);
		CORE::open(my $fh, '>', $filename)
			or die "Can't open ".$filename."\n";
		print $fh join("\n", @$new_work)."\n";
		CORE::close($fh)
			or die "Can't close ".$filename."\n";
	}
	else {$new_id = 0}

	$self->close($struct, '+<');
	return $new_id;
}

sub delete_all {
	my $self = shift;

	my $struct = $self->open('<');

	for my $id (1..$self->{last_added_id}) {
		unlink(Local::TCP::Calc::Server::FileName::task($_));
		unlink(Local::TCP::Calc::Server::FileName::res($_));
	}
	$self->close({}, '<');
	unlink($self->{queue_filename});
}

no Mouse;
__PACKAGE__->meta->make_immutable();

1;
