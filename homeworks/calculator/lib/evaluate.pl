=head1 DESCRIPTION

Эта функция должна принять на вход ссылку на массив, который представляет из себя обратную польскую нотацию,
а на выходе вернуть вычисленное выражение

=cut

use 5.010;
use strict;
use warnings;
use diagnostics;
BEGIN{
	if ($] < 5.018) {
		package experimental;
		use warnings::register;
	}
}
no warnings 'experimental';

sub evaluate {
	my $rpn = shift;

	my @num;

	for (@$rpn) {
		given ($_) {
			when (/\d/) {push @num,$_}
			when ('U+') {}
			when ('U-') {$num[@num-1]=-$num[@num-1]}
			when ('+') {$num[@num-2]=$num[@num-2]+$num[@num-1];pop(@num)}
			when ('-') {$num[@num-2]=$num[@num-2]-$num[@num-1];pop(@num)}
			when ('*') {$num[@num-2]=$num[@num-2]*$num[@num-1];pop(@num)}
			when ('/') {$num[@num-2]=$num[@num-2]/$num[@num-1];pop(@num)}
			when ('^') {$num[@num-2]=$num[@num-2]**$num[@num-1];pop(@num)}
		}
	}

	return $num[0];
}

1;
