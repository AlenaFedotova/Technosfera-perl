package Local::TCP::Calc;

use strict;
use feature 'say';
use DDP;

sub TYPE_START_WORK {1}
sub TYPE_CHECK_WORK {2}
sub TYPE_CONN_ERR   {3}
sub TYPE_CONN_OK    {4}
sub TYPE_NEW_WORK_OK {5}
sub TYPE_NEW_WORK_ERR {6}
sub TYPE_CHECK_WORK_ERR {7}
sub TYPE_ASK_ERR {8}
sub TYPE_CHECK_WORK_ERR_ID {9}

sub STATUS_NEW   {1}
sub STATUS_WORK  {2}
sub STATUS_DONE  {3}
sub STATUS_ERROR {4}

sub pack_header {
	my $pkg = shift;
	my $type = shift;
	my $size = shift;
	return pack "ii", $type, $size;
}

sub unpack_header {
	my $pkg = shift;
	my $header = shift;
	my ($type, $size) = unpack "ii", $header;
	return {type => $type, size => $size};
}

sub pack_message {
	my $pkg = shift;
	my $messages = shift;

	return pack "(C/a*)*", @$messages;

}

sub unpack_message {
	my $pkg = shift;
	my $message = shift;
	my @messages = unpack "(C/a*)*", $message;
	return [@messages];
}

1;
