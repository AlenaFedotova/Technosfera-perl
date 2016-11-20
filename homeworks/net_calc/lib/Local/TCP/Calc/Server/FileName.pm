package Local::TCP::Calc::Server::FileName;

sub task {
	my $id = shift;
	return '/tmp/net_calc.'.$id.'.task';
}

sub res {
	my $id = shift;
	return '/tmp/net_calc.'.$id.'.res';
}

1;
