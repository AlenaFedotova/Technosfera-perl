package Local::TCP::Calc::Client;

use strict;
use IO::Socket::INET;
use Local::TCP::Calc;
use feature 'say';
use DDP;

sub set_connect {
	my $pkg = shift;
	my $ip = shift;
	my $port = shift;

	my $sock = IO::Socket::INET->new(PeerPort => $port, Proto => 'tcp', Type => SOCK_STREAM, PeerAddr => $ip) or die "$!";;

	my $res = take_message($sock);

	my $type = $res->{res_type};
	p $res;
	if ($type eq Local::TCP::Calc::TYPE_CONN_ERR()) {return 0}
	return $sock;
}

sub send_message {
	my $server = shift;
	my $type = shift;
	my $message = shift;

	my $new_message = Local::TCP::Calc->pack_message($message);
	my $new_header = Local::TCP::Calc->pack_header($type, length($new_message));

	syswrite $server, $new_header;
	my @arr = split //, $new_message;

	syswrite $server, $new_message;
}

sub take_message {
	my $server = shift;
	my $header;

	sysread $server, $header, 8;

	my $message;

	my $ref = Local::TCP::Calc->unpack_header($header);
	my $size = $ref->{size};
	my $type = $ref->{type};
	sysread $server, $message, $size;

	my $res = Local::TCP::Calc->unpack_message($message);
	return {res_type => $type, result => [@$res]};
}

sub do_request {
	my $pkg = shift;
	my $server = shift;
	my $type = shift;
	my $message = shift;
	my $struct;

	send_message($server, $type, $message);
	$struct = take_message($server);
	if ($struct->{res_type} eq Local::TCP::Calc::TYPE_NEW_WORK_OK()) {return $struct->{result}->[0]}
	if ($struct->{res_type} eq Local::TCP::Calc::TYPE_NEW_WORK_ERR()) {return 0}

	return ($struct->{res_type}, @{$struct->{result}});
}

sub break_connect {
	my $pkg = shift;
	my $sock = shift;

	close($sock);
}

1;
