#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Term::ReadLine;
use IO::Select;
use Local::Chat::ServerConnection;
use Data::Dumper;
use Term::ReadKey;
use LWP::UserAgent;
use open ":utf8",":std";

$|=1;

my @strings_to_show = ();

local $SIG{TERM} = $SIG{INT} = \&stop;

my ( $term_width, $term_height ) = GetTerminalSize();

my $term = Term::ReadLine->new('Simple perl chat');
$term->MinLine();

my $login_prompt = "Enter your nick ";
my $prompt = "Enter your message> ";

local $SIG{WINCH} = sub {
	( $term_width, $term_height ) = GetTerminalSize();
};

sub stop {
    print "\e[".(2 + @strings_to_show).";1H\e[J\n";
    exit;
}

sub init {
    print "\e[1;1H\e[J";
    print $prompt;
}

sub redraw {
	print "\e7";
    print "\e[2;1H\e[J";
	print join "\n", @strings_to_show;
    print "\e8";
}

sub add_message {
	my $string = shift;
	unshift @strings_to_show, split /\n/, $string;
	splice @strings_to_show, ( $term_height - 1 ) if @strings_to_show > $term_height - 1;
	redraw;
}

my $nick = 'pozdravok';

$term->MinLine(1);

init();

my $server = Local::Chat::ServerConnection->new(nick => $nick, host => $ARGV[0] || 'localhost', 
	on_fd => sub {
		my ($srv, $fd) = @_;
		if ($fd == $term->IN) {
			my $msg = $term->readline('');
			print "\e[1;1H\e[2K";
            print $prompt;
                        stop() unless defined $msg;
			chomp($msg);
                        return unless length $msg;
			if ($msg =~ m{^/(\w+)(?:\s+(\S+))*$}) {
				if ($1 eq 'nick') {
					$srv->nick($2);
					return;
				}
				elsif ($1 eq 'names') {
					$srv->names();
				}
				elsif ($1 eq 'kill') {
					$srv->kill($2);
				}
				else {
					add_message( "\e[31mUnknown command '$1'\e[0m\n" );
				}
				return;
			}
			
			$srv->message({ text => $msg });
		}
	},
	on_message => sub {
		my ($srv, $message) = @_;
		add_message( $message->{from} . ": ". $message->{text} );
		if ($message->{text} eq 'pozdravok' && $message->{from} ne 'pozdravok') {
			my $gr = LWP::UserAgent->new;

			$gr->timeout (10);
			$gr->env_proxy;
			my $greating = $gr->get('http://pozdravok.ru/pozdravleniya/a/');
			if($greating->is_success) {
				my $n = 10;
				my $r = int(rand($n));
				
				my $str = $greating->decoded_content;
		
				my $tmp;
				for my $i (0..$r) {
					$str =~ s/\<p id=\"p\d{6}_\d\"\>(.*?)(\<p id=\"p\d{6}_\d\"\>)/$2/s;
					$tmp = $1;
				}
		
				$str = $tmp;
				$str =~ s/\<br \/\>/\n/g;
				$str =~ s/\<.*/\n/g;
				$srv->message( $message->{from}.",\n". $str );
	}
	else {
		$srv->message( 'Err' );
	}
		}
		if ($message->{text} =~ m/^\s*!who\s?/) {
			$srv->message( 'i am ' . $nick );
		}
		
		
	},
	on_rename => sub {
		my ($srv, $message) = @_;
		add_message( "\e[31m" . "Пользователь" . $message->{prev} . " изменил имя на " . $message->{nick} . "\e[0m" );
	},
	on_join => sub {
		my ($srv, $message) = @_;
		add_message("\e[34m" . ">> Пользователь " . $message->{nick} . " присоеденился" . "\e[0m");
	},
	on_part => sub {
		my ($srv, $message) = @_;
		add_message("\e[34m" . "<< Пользователь " . $message->{nick} . " покинул чат" . "\e[0m");
	},
	on_names => sub {
		my ($srv, $message) = @_;
		add_message( $message->{room} . ": " . join ', ', @{$message->{names}} );
	},
	on_disconect => sub {
		my ($srv) = @_;
		add_message("Сервер оборвал соединение");
	},
	on_error => sub {
		my ($srv, $message) = @_;
		add_message( "\e[31;1m"."Error"."\e[0m".": $message->{text}\n" );
	}
);

$server->sel->add($term->IN);
my $last_error = time();
while () {
	eval {
		$server->connect;
	};
	if ($@) {
		if (time() - $last_error > 60) {
			add_message("Ожидание сервера");
			$last_error = time();
		}
		sleep(1);
	}
	else {
		$server->poll();
	}

}

stop();
