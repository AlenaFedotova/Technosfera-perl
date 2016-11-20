package Local::TCP::Calc::Server::WorkerManager;

use strict;
use Local::TCP::Calc;
use Local::TCP::Calc::Server::Queue;
use Local::TCP::Calc::Server;
use Local::TCP::Calc::Server::Worker;
use IO::Socket::INET;
use feature 'say';
use Math::Expression::Evaluator;
use Math::Expression;
use POSIX;


my $in_process = 0;
my $pids_master = {};


sub REAPER {
	while (my $pid = waitpid(-1, WNOHANG)) {
		last if $pid == -1;

		my $status = $?;
		if (exists($pids_master->{$pid})) {
			delete $pids_master->{$pid};
			$in_process--;
		}
	}
	$SIG{CHLD} = \&REAPER;
}


sub int_signal {
	for (%$pids_master) {
		kill('INT', $_);
	}
	exit(0);
};

my $check_queue_workers_active = 0;
$SIG{ALRM} = \&alrm;
sub alrm {
	$check_queue_workers_active++;
	$SIG{ALRM} = \&alrm;
};

sub check_queue_workers {
	my $pkg = shift;
	my $qref = shift;
	my $q = $$qref;
	$SIG{INT} = \&int_signal;
	my $max_worker = shift;
	my $max_forks_per_task = shift;
	
	while (1) {
		if ($check_queue_workers_active && $in_process < $max_worker) {
			my $child = fork();
			if ($child) {
				$in_process++;
				$check_queue_workers_active--;
				$pids_master->{$child} = $child;
				$SIG{CHLD} = \&REAPER;
				next;
			}

			if(!defined($child)) {die "Can't fork: $!"}

			my $id = $q->get();

			my $worker = Local::TCP::Calc::Server::Worker->new(cur_task_id => $id, calc_ref => \&func, max_forks => $max_forks_per_task);
			my $err = $worker->start();
			if ($err) {
				$q->to_done($id, 'error');
			}
			else {
				$q->to_done($id, 'done');
			}
			exit(0);
		}
		sleep 0.1;
	}
}

sub func {
	open STDERR, ">/dev/null";
	my $str = shift;
	my $m = Math::Expression::Evaluator->new;
	my $p = Math::Expression->new;
	if ($p->ParseString($str)) {
		return $m->parse($str)->val();
	}
	else {return 'NaN'}
	
}

1;
