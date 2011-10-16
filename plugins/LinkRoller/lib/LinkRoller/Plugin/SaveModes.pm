package LinkRoller::Plugin::SaveModes;

use strict;
use LinkRoller::Util qw( _internal_save );

sub quickadd_link {
	my $app = shift;
	my $plugin = MT->component('LinkRoller');
	return $app->build_page($plugin->load_tmpl('quickadd.tmpl'));
}

sub save_link {
	my $app = shift;
	my $link;
	($app, $link) = _internal_save($app);
	$app->call_return( saved => 1 );
}

1;
