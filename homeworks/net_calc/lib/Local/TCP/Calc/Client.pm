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

	my $sock = IO::Socket::INET->new(PeerPort => $port, Proto => 'tcp', Type => SOCK_STREAM, PeerAddr => $ip) or die "$!";

	my $res = take_message($sock);
	if ($res eq "err") {return}

	my $type = $res->{res_type};
	if ($type ne Local::TCP::Calc::TYPE_CONN_ERR()) {return $sock}
}

sub send_message {
	my $server = shift;
	my $type = shift;
	my $message = shift;

	my $new_message = Local::TCP::Calc->pack_message($message);
	my $new_header = Local::TCP::Calc->pack_header($type, length($new_message));

	my $len = syswrite $server, $new_header;
	if ($len != 2) {
		__PACKAGE__->break_connect($server); 
		say STDERR "Wrong size of header"; 
		return "err"
	}

	$len = syswrite $server, $new_message;
	if ($len != length($new_message)) {
		__PACKAGE__->break_connect($server); 
		say STDERR "Wrong size of message"; 
		return "err"
	}
}

sub take_message {
	my $server = shift;
	say $server;
	my $header;
	
	my $len = sysread $server, $header, 2;
	if ($len != 2) {
		__PACKAGE__->break_connect($server); 
		say STDERR "Wrong size of header"; 
		return "err"
	}

	my $message;
	my $ref = Local::TCP::Calc->unpack_header($header);

	my $size = $ref->{size};
	my $type = $ref->{type};
	$len = sysread $server, $message, $size;
	if ($len != $size) {
		__PACKAGE__->break_connect($server); 
		say STDERR "Wrong size of message"; 
		return "err"
	}
	my $res = Local::TCP::Calc->unpack_message($message);

	return {res_type => $type, result => [@$res]};
}

sub do_request {
	my $pkg = shift;
	my $server = shift;
	my $type = shift;
	my $message = shift;
	my $struct;

	$struct = send_message($server, $type, $message);
	if ($struct eq "err") {return}
	$struct = take_message($server);
	if ($struct eq "err") {return}

	return ($struct->{res_type}, @{$struct->{result}});
}

sub break_connect {
	my $pkg = shift;
	my $sock = shift;

	close($sock);
}

1;
