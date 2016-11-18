package Local::TCP::Calc::Server;

use strict;
use Local::TCP::Calc;
use Local::TCP::Calc::Server::Queue;
use Local::TCP::Calc::Server::Worker;
use IO::Socket;
use Local::TCP::Calc::Server::WorkerManager;
use feature 'say';
use IO::Compress::Gzip;
use Local::TCP::Calc::Server::FileName;
use POSIX;
use DDP;

my $max_worker;
my $in_process = 0;

my $pids_master = {};
my $receiver_count = 0;
my $max_forks_per_task = 0;
my $max_queue_task = 0;
my $pid_worker;
my $q;

sub REAPER {

	while (my $pid = waitpid(-1, WNOHANG)) {

		last if $pid == -1;

		my $status = $?;
		if (exists($pids_master->{$pid})) {
			delete $pids_master->{$pid};

			$receiver_count--;
		}
	}
	$SIG{CHLD} = \&REAPER;
}


sub int_signal {
	kill('INT', $pid_worker);
	
	for (%$pids_master) {
		kill('TERM', $_);
	}
	$q->delete_all();
	exit(0);
};

sub take_message {
	my $client = shift;
	my $header;
	my $len = sysread $client, $header, 2;
	if ($len != 2) {say STDERR "Wrong size of header"; close($client); exit(1)}
	my $message;

	my $ref = Local::TCP::Calc->unpack_header($header);

	my $size = $ref->{size};
	my $type = $ref->{type};
	$len = sysread $client, $message, $size;
	if ($len != $size) {say STDERR "Wrong size of message"; close($client); exit(1)}
	my $res = Local::TCP::Calc->unpack_message($message);

	return {res_type => $type, result => [@$res]};
}

sub send_message_arr {

	my $client = shift;
	my $type = shift;
	my $message = shift;

	my $new_message = Local::TCP::Calc->pack_message([@$message]);
	my $new_header = Local::TCP::Calc->pack_header($type, length($new_message));

	my $len = syswrite $client, $new_header;
	if ($len != 2) {say STDERR "Wrong size of header"; close($client); exit(1)}
	$len = syswrite $client, $new_message;
	if ($len != length($new_message)) {say STDERR "Wrong size of message"; close($client); exit(1)}
}

sub send_message {
	my $client = shift;
	my $type = shift;
	my $message = shift;

	my $new_message = Local::TCP::Calc->pack_message([$message]);
	my $new_header = Local::TCP::Calc->pack_header($type, length($new_message));

	my $len = syswrite $client, $new_header;
	if ($len != 2) {say STDERR "Wrong size of header"; close($client); exit(1)}
	$len = syswrite $client, $new_message;
	if ($len != length($new_message)) {say STDERR "Wrong size of message"; close($client); exit(1)}
}

sub start_server {
	my ($pkg, $port, %opts) = @_;
	$max_worker         = $opts{max_worker} // die "max_worker required"; 
	$max_forks_per_task = $opts{max_forks_per_task} // die "max_forks_per_task required";
	$max_queue_task = $opts{max_queue_task} // die "max_queue_task required";
	my $max_receiver    = $opts{max_receiver} // die "max_receiver required"; 
	my $server = IO::Socket::INET->new(LocalPort => $port, Proto => 'tcp', Type => SOCK_STREAM, Listen => $max_receiver, Reuse => 1, LocalAddr => '127.0.0.1') or die "$!";
say "$port: $max_worker $max_forks_per_task $max_queue_task $max_receiver";
	$q = Local::TCP::Calc::Server::Queue->new(max_task => $max_queue_task, queue_filename => '/tmp/local_queue.'.$port.'.log');
	$q->init();
	my $qref = \$q;
  	$pid_worker = fork();
	$SIG{INT} = \&int_signal;
	if (!defined($pid_worker)) {die "Can't fork: $!"}
	if (!$pid_worker) {
		Local::TCP::Calc::Server::WorkerManager->check_queue_workers($qref, $max_worker, $max_forks_per_task);
	}
	

	while (1) {
		my $client = $server->accept();
		if (!defined($client)) {next}
		$client->autoflush(1);

		if ($client == 0) {
			next;
		}


		if ($receiver_count < $max_receiver) {
			my $child = fork();
			if ($child) {
				close($client);
				$receiver_count++;
				$pids_master->{$child} = $child;
				$SIG{CHLD} = \&REAPER;
				next;
			}
			if (defined $child) {
				send_message($client, Local::TCP::Calc::TYPE_CONN_OK(), '');

				my $ref = take_message($client);
				my $type = $ref->{res_type};
				my $taskref = $ref->{result};

				if ($type eq Local::TCP::Calc::TYPE_START_WORK()) {

					

					my $id = $q->add($taskref);
					if ($id) {
						kill('ALRM', $pid_worker);
						send_message($client, Local::TCP::Calc::TYPE_NEW_WORK_OK(), $id);
					}
					else {
						send_message($client, Local::TCP::Calc::TYPE_NEW_WORK_ERR(), '0');
					}
				}
				elsif ($type eq Local::TCP::Calc::TYPE_CHECK_WORK()) {

					my $id = $taskref->[0];


					my $status = $q->get_status($id);
					if ($status eq 'done') {
						open(my $fh, '<', Local::TCP::Calc::Server::FileName::res($id));
						my @ress = <$fh>;

						for (@ress) {chomp $_}

						send_message_arr($client, Local::TCP::Calc::STATUS_DONE(), \@ress);
						$q->delete($id, $status);
					}
					elsif ($status eq 'error') {
						open(my $fh, '<', Local::TCP::Calc::Server::FileName::res($id));
						my @ress = <$fh>;
						for (@ress) {chomp $_}
						send_message_arr($client, Local::TCP::Calc::STATUS_ERROR(), \@ress);
						$q->delete($id, $status);
					}
					elsif ($status eq 'new') {
						send_message($client, Local::TCP::Calc::STATUS_NEW(), '');
					}
					elsif ($status eq 'work') {
						send_message($client, Local::TCP::Calc::STATUS_WORK(), '');
					}
					else {
						send_message($client, Local::TCP::Calc::TYPE_CHECK_WORK_ERR_ID(), '');
					}
				}
				else {
					send_message($client, Local::TCP::Calc::TYPE_ASK_ERR(), '');
				}
				close $client;
				exit(0);
			}
			else {die "Can't fork: $!"}
		}
		else {
			my $child = fork();
			if ($child) {
				close($client);
				$receiver_count++;
				$pids_master->{$child} = $child;
				$SIG{CHLD} = \&REAPER;
				next;
			}
			if (defined $child) {
				send($client, Local::TCP::Calc->pack_header(Local::TCP::Calc::TYPE_CONN_ERR(), 0), 0);
				close($client);
				exit(0);
			}
			close($client);
		}
	}
	$server->close();
	say "exit";
	kill('INT', $pid_worker);
}

1;
