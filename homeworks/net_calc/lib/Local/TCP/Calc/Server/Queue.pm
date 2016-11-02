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

sub init {
	my $self = shift;
	open($self->{f_handle}, '>', $self->{queue_filename})
		or die "Can't open ".$self->{queue_filename}."\n";
	close($self->{f_handle});
}

sub open {
	my $self = shift;
	my $open_type = shift;

	open($self->{f_handle}, $open_type, $self->{queue_filename})
		or die "Can't open ".$self->{queue_filename}."\n";
	until (flock($self->{f_handle}, 2)) {sleep 0.01}

	my $fh = $self->{f_handle};
	my @lines = <$fh>;
	my %hash;
	my @id;

	for (@lines) {
		chomp $_;
		my @tmp = split /:/, $_;
		$hash{$tmp[0]} = $tmp[1];
		push(@id, $tmp[0]);
	}
	return [\%hash, \@id];
}

sub close {
	my $self = shift;
	my $struct = shift;
	my $open_type = shift;
	if ($open_type ne '<') {
		truncate($self->{f_handle}, 0);
		seek($self->{f_handle}, 0, 0);
		
		my %hash = %{$struct->[0]};
		my @id = @{$struct->[1]};

		for (@id) {
		say $_;	
			$self->{f_handle}->print ($_.":".$hash{$_}."\n");
		}
	}
	flock($self->{f_handle}, 8)
		or die "Can't unlock ".$self->{queue_filename}."\n"; 

	close($self->{f_handle});
}

sub to_done {
	my $self = shift;
	my $task_id = shift;
	my $status = shift;
	
	my $struct = $self->open('+<');
	my %hash = %{$struct->[0]};
	$hash{$task_id} = $status;

	$self->close([\%hash, $struct->[1]], '+<');
}

sub get_status {
	my $self = shift;
	my $id = shift;
	my $struct = $self->open('<');
	my %hash = %{$struct->[0]};
	my $status = 'not found';
	if (defined($hash{$id})) {
		$status = $hash{$id};
	}
	$self->close($struct, '<');

	return $status
}

sub delete {
	my $self = shift;
	my $id = shift;
	my $status = shift;
	my $struct = $self->open('+<');
	my %hash = %{$struct->[0]};
	my @id = @{$struct->[1]};
	my $real_status = $hash{$id};
	if ($status eq $real_status) {
		delete $hash{$id};
		my $i;
		for ($i = 0; $id[$i] ne $id; $i++) {}
		splice(@id, $i, 1);
		unlink(Local::TCP::Calc::Server::FileName::task($id));
		unlink(Local::TCP::Calc::Server::FileName::res($id));
	}
	$self->close([\%hash, \@id], '+<');
}

sub get {
	my $self = shift;

	my $struct = $self->open('+<');

	my %hash = %{$struct->[0]};
	my @id = @{$struct->[1]};

	my $tmp = 0;
	my $id;
	for (my $i = 0; $i <= $#id && !$tmp; $i++) {
		if ($hash{$id[$i]} eq 'new') {
			$hash{$id[$i]} = 'work';
			$tmp++;
			$id = $id[$i];
		}
	}

	$self->close([\%hash, \@id], '+<');

	if (defined($id)) {return $id}
}

sub add {
	my $self = shift;
	my $new_work = shift;

	my $struct = $self->open('+<');
	my %hash = %{$struct->[0]};
	my @id = @{$struct->[1]};
	my $new_id;
	if ($#id+1 < $self->{max_task}) {
		if ($#id == -1) {$new_id = 1}
		else {$new_id = $id[$#id]+1}
		push(@id, $new_id);
		$hash{$new_id} = 'new';
		my $filename = Local::TCP::Calc::Server::FileName::task($new_id);
		open(my $fh, '>', $filename)
			or die "Can't open ".$filename."\n";
		print $fh join("\n", @$new_work)."\n";
		close($fh)
			or die "Can't close ".$filename."\n";
	}
	else {$new_id = 0}

	$self->close([\%hash, \@id], '+<');
	return $new_id;
}

sub delete_all {
	my $self = shift;

	my $struct = $self->open('+<');
	my @id = @{$struct->[1]};
	for (@id) {
		unlink(Local::TCP::Calc::Server::FileName::task($_));
		unlink(Local::TCP::Calc::Server::FileName::res($_));
	}
	$self->close($struct, '+<');
	unlink($self->{queue_filename});
}

no Mouse;
__PACKAGE__->meta->make_immutable();

1;
