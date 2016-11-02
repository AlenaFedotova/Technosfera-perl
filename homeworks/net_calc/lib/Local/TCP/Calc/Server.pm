package Local::TCP::Calc::Server;

use strict;
use Local::TCP::Calc;
use Local::TCP::Calc::Server::Queue;
use Local::TCP::Calc::Server::Worker;
use IO::Socket::INET;
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


$SIG{INT} = sub {
	kill('INT', $pid_worker);
	
	for (%$pids_master) {
		kill('TERM', $_);
	}
	$q->delete_all();
	exit(0);
};

sub send_message_arr {
	my $client = shift;
	my $type = shift;
	my $message = shift;
p $message;
	my $new_message = Local::TCP::Calc->pack_message([@$message]);
	my $new_header = Local::TCP::Calc->pack_header($type, length($new_message));
	print $client $new_header."\n";
	print $client $new_message."\n";
}

sub send_message {
	my $client = shift;
	my $type = shift;
	my $message = shift;
	
	my $new_message = Local::TCP::Calc->pack_message([$message]);
	my $new_header = Local::TCP::Calc->pack_header($type, length($new_message));
	print $client $new_header."\n";
	print $client $new_message."\n";
}

sub start_server {
	my ($pkg, $port, %opts) = @_;
	$max_worker         = $opts{max_worker} // die "max_worker required"; 
	$max_forks_per_task = $opts{max_forks_per_task} // die "max_forks_per_task required";
	$max_queue_task = $opts{max_queue_task} // die "max_queue_task required";
	my $max_receiver    = $opts{max_receiver} // die "max_receiver required"; 
	my $server = IO::Socket::INET->new(LocalPort => $port, Proto => 'tcp', Type => SOCK_STREAM, Listen => $max_receiver) or die "$!";

	$q = Local::TCP::Calc::Server::Queue->new(max_task => $max_queue_task);

  	$pid_worker = fork();
	if ($pid_worker == 0) {
		Local::TCP::Calc::Server::WorkerManager->check_queue_workers($q, $max_worker, $max_forks_per_task);
	}
	if (!defined($pid_worker)) {die "Can't fork: $!"}
	$q->init();

	while (1) {
		my $client = $server->accept();
		if ($client == 0) {
			next;
		}
		if ($receiver_count < $max_receiver) {
			send_message($client, Local::TCP::Calc::TYPE_CONN_OK(), '');

			my $child = fork();
			if ($child) {
				close($client);

				$receiver_count++;
				$pids_master->{$child} = $child;
				$SIG{CHLD} = \&REAPER;
				next;
			}
			if (defined $child) {
				my $header = <$client>; 
				chomp $header;

				$header = Local::TCP::Calc->unpack_header($header);
				my $size = $header->{size};
				my $type = $header->{type};

				if ($type eq Local::TCP::Calc::TYPE_START_WORK()) {
					my $message = <$client>;
					chomp $message;

					if (length($message) != $size) {
						send_message($client, Local::TCP::Calc::TYPE_NEW_WORK_ERR(), '');
						close($client);
						exit(0);
					}
					my $taskref = Local::TCP::Calc->unpack_message($message);

					my $id = $q->add($taskref);
						
					if ($id) {
						kill('ALRM', $pid_worker);
						send_message($client, Local::TCP::Calc::TYPE_NEW_WORK_OK(), $id);
					}
					else {
						send_message($client, Local::TCP::Calc::TYPE_NEW_WORK_ERR(), '');
					}
				}
				elsif ($type eq Local::TCP::Calc::TYPE_CHECK_WORK()) {
					my $message = <$client>;
					chomp $message;
					if (length($message) != $size) {
						send_message($client, Local::TCP::Calc::TYPE_CHECK_WORK_ERR(), '');
						close($client);
						exit(0);
					}
					my $ref = Local::TCP::Calc->unpack_message($message);
					my $id = $ref->[0];

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
			send($client, Local::TCP::Calc->pack_header(Local::TCP::Calc::TYPE_CONN_ERR(), 0), 0);
			close($client);
		}
	}
	$server->close();
	kill('TERM', $pid_worker);
	# Начинаем accept-тить подключения
	# Проверяем, что количество принимающих форков не вышло за пределы допустимого ($max_receiver)
	# Если все нормально отвечаем клиенту TYPE_CONN_OK() в противном случае TYPE_CONN_ERR()
	# В каждом форке читаем сообщение от клиента, анализируем его тип (TYPE_START_WORK(), TYPE_CHECK_WORK()) 
	# Не забываем проверять количество прочитанных/записанных байт из/в сеть
	# Если необходимо добавляем задание в очередь (проверяем получилось или нет) 
	# Если пришли с проверкой статуса, получаем статус из очереди и отдаём клиенту
	# В случае если статус DONE или ERROR возвращаем на клиент содержимое файла с результатом выполнения
	# После того, как результат передан на клиент зачищаем файл с результатом
}

1;
