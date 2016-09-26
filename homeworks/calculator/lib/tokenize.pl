=head1 DESCRIPTION

Эта функция должна принять на вход арифметическое выражение,
а на выходе дать ссылку на массив, состоящий из отдельных токенов.
Токен - это отдельная логическая часть выражения: число, скобка или арифметическая операция
В случае ошибки в выражении функция должна вызывать die с сообщением об ошибке

Знаки '-' и '+' в первой позиции, или после другой арифметической операции стоит воспринимать
как унарные и можно записывать как "U-" и "U+"

Стоит заметить, что после унарного оператора нельзя использовать бинарные операторы
Например последовательность 1 + - / 2 невалидна. Бинарный оператор / идёт после использования унарного "-"

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

sub tokenize {
	chomp(my $expr = shift);
	my @res;

	my @tmp;
	my $k=0;
	my $m=0;
	my $i;
	my @dig = ('0','1','2','3','4','5','6','7','8','9','.');
	@tmp = split //, $expr;
	for ($i=0;$i<@tmp;$i++) {
		given ($tmp[$i]) {
			when (' ') {}
			when ([@dig]) {
				my @num;
				my $x;
				push (@num, $tmp[$i]);
				for ($i++; $tmp[$i] ~~ @dig;$i++)
					{push (@num, $tmp[$i])}
				$i--;
				$x = join('',@num);
				if (index($x, '.') && index($x, '.') != rindex($x, '.')) {die "Too many points"}
				push @res, $x;
			}
			when ('e') {
				if ($i < @tmp-1 && ($tmp[$i+1]eq'+' || $tmp[$i+1]eq'-')) {push(@res, join('','e',$tmp[$i+1]));$i++}
				else {push(@res, 'e+')}
			}
			default {push @res, $tmp[$i]}
		}
	}


	@tmp = @res;
	$#res = -1;
	for ($i=0;$i<@tmp;$i++) {
		if ($tmp[$i] =~ /[0-9\.]/ && $i < @tmp-1 && ($tmp[$i+1] eq 'e+' || $tmp[$i+1] eq 'e-')) {
			if ($i < @tmp-2 && $tmp[$i+2] =~ /[0-9]/) {
				push (@res, 0+join('',$tmp[$i],$tmp[$i+1],$tmp[$i+2]));
				$i+=2;
			}
			else {die "Bad exp"}
		}
		elsif ($tmp[$i] =~ /[0-9\.]/) {push (@res, 0+$tmp[$i])}
		else {push (@res, $tmp[$i])}
	}

	@tmp = @res;
	$#res = -1;
	for ($i=0;$i<@tmp;$i++) {
		if ($tmp[$i] eq '+' || $tmp[$i] eq '-') {
			if ($i==@tmp-1) {die "Bad signs"}
			elsif ($i==0) {push (@res, join('','U',$tmp[$i]))}
			elsif (!($tmp[$i-1] =~ /[0-9]/ || $tmp[$i-1] eq ')')) {push (@res, join('','U',$tmp[$i]))}
			else {push (@res, $tmp[$i])}
		}
		else {push (@res, $tmp[$i])}
	}

	for ($i=0;$i<@res;$i++) {
		given ($res[$i]) {
			when (['+','-','*','/','^','U+','U-','(',')']) {}
			when (/\d/) {}
			default {die "Bad smth"}		
		}
	}
	for ($i=0;$i<@res;$i++) {
		given ($res[$i]) {
			when (['+','-','*','/','^','U+','U-']) 
			{
				if($i==@res-1 ||  ($res[$i+1]eq'+' || $res[$i+1]eq'-' || $res[$i+1]eq'*' || $res[$i+1]eq'/' || $res[$i+1]eq'^'|| $res[$i+1]eq')')) {die "Bad signs"}
			}		
		}
	}
	for ($i=0;$i<@res;$i++) {
		given ($res[$i]) {
			when (['+','-','*','/','^']) 
			{
				if($i==0 ||  ($res[$i-1]eq'+' || $res[$i-1]eq'-' || $res[$i-1]eq'*' || $res[$i-1]eq'/' || $res[$i-1]eq'^'|| $res[$i-1]eq'(')) {die "Bad signs"}
			}		
		}
	}
	for ($i=0;$i<@res;$i++) {
		given ($res[$i]) {
			when (['(']) 
			{
				if($i==@res-1) {die "Bad brackets"}
			}
			when ([')']) 
			{
				if($i==0) {die "Bad brackets"}
			}		
		}
	}
	for ($i=0;$i<@res;$i++) {
		given ($res[$i]) {
			when (['(']) 
			{
				if($i!=0 && !($res[$i-1]eq'+' || $res[$i-1]eq'-' || $res[$i-1]eq'*' || $res[$i-1]eq'/' || $res[$i-1]eq'^'|| $res[$i-1]eq'(' || $res[$i-1]eq'U+' || $res[$i-1]eq'U-')) {die "Bad brackets and signs"}
			}
			when ([')']) 
			{
				if($i!=@res-1 && !($res[$i+1]eq'+' || $res[$i+1]eq'-' || $res[$i+1]eq'*' || $res[$i+1]eq'/' || $res[$i+1]eq'^'|| $res[$i+1]eq')')) {die "Bad brackets and signs"}
			}		
		}
	}

	for (@res) {
		if ($_ eq'(') {$k++}
		if ($_ eq')') {$m++}
	}
	if ($k != $m) {die "Bad brackets"}

	return \@res;
}

1;
