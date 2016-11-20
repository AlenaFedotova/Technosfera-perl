package Local::Object;

use strict;
use warnings;

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

sub new {
	my ($class, %params) = @_;
	
	my $obj = bless \%params, $class;
	$obj->init();

	return $obj;
}

sub init {
	my ($self) = @_;

	return;
}

1;
