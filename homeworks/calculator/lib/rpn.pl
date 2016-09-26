=head1 DESCRIPTION

Эта функция должна принять на вход арифметическое выражение,
а на выходе дать ссылку на массив, содержащий обратную польскую нотацию
Один элемент массива - это число или арифметическая операция
В случае ошибки функция должна вызывать die с сообщением об ошибке

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
use FindBin;
require "$FindBin::Bin/../lib/tokenize.pl";

sub rpn {
	my $expr = shift;
	my $source = tokenize($expr);

	return rpn_($source);
}

sub rpn_ {
	my @rpn;
	$#rpn = -1;

	my $x = $_[0];
	
	my $i;
	my $p;
	if($#$x==0) {return $x}
	if ($x->[0] eq '(') {
		for ($p=1, $i=1;$i<$#$x+1 && $p != 0;$i++) {
			if ($x->[$i] eq '(') {$p++}
			if ($x->[$i] eq ')') {$p--}
		}
		if ($p==0 && $i == $#$x+1) {
			pop(@$x);
			shift(@$x);
		}
	}
	my $done=0;
	if ($done==0) {
		for($i=$#$x,$p=0; $i!=0 && !($p==0 && ($x->[$i] eq '+' || $x->[$i] eq '-'));$i--) {
			if ($x->[$i] eq '(') {$p++}
			if ($x->[$i] eq ')') {$p--}
		}
		if ($i!=0) {
			$done++;
			my @arr1=@{$x}[0..$i-1];
			my @arr2=@{$x}[$i+1..$#$x];
			@rpn = (@{rpn_(\@arr1)},@{rpn_(\@arr2)},$x->[$i]);
		}
	}
	if ($done==0) {
		for($i=$#$x,$p=0; $i!=0 && !($p==0 && ($x->[$i] eq '*' || $x->[$i] eq '/'));$i--) {
			if ($x->[$i] eq '(') {$p++}
			if ($x->[$i] eq ')') {$p--}
		}
		if ($i!=0) {
			$done++;
			my @arr1=@{$x}[0..$i-1];
			my @arr2=@{$x}[$i+1..$#$x];
			@rpn = (@{rpn_(\@arr1)},@{rpn_(\@arr2)},$x->[$i]);
		}
	}
	if ($done==0) {
		for($i=0,$p=0; $i!=$#$x && !($p==0 && ($x->[$i] eq '^'));$i++) {
			if ($x->[$i] eq '(') {$p++}
			if ($x->[$i] eq ')') {$p--}
		}
		if ($i!=$#$x) {
			$done++;
			my @arr1=@{$x}[0..$i-1];
			my @arr2=@{$x}[$i+1..$#$x];
			if ($arr1[0] eq 'U+' || $arr1[0] eq 'U-') {
				my $y = $arr1[0];
				shift (@arr1);
				@rpn = (@{rpn_(\@arr1)},@{rpn_(\@arr2)},$x->[$i],$y);
			}
			else {
				@rpn = (@{rpn_(\@arr1)},@{rpn_(\@arr2)},$x->[$i]);
			}
		}
	}
	if ($done==0) {
		$done++;
		my @arr1=@{$x}[1..$#$x];
		@rpn = (@{rpn_(\@arr1)},$x->[0]);
	}
	return \@rpn;
}

1;
