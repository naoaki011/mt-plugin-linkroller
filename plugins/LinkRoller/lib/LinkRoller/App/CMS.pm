# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2008, Arvind Satyanarayan.

package LinkRoller::App::CMS;

use strict;
use MT;
use MT::Asset;
use LinkRoller::Util qw( is_user_can  _internal_save );

sub edit_asset_param {
    my ($cb, $app, $param, $tmpl) = @_;
    return 1 unless $param->{class} eq 'link';
    my $class = $app->model('asset.link');
    my $id = $app->param('id')
      or return;
    my $link = $class->load($id)
      or return;
    $param->{link_author} = ($link->link_author || '');
    $param->{link_target}        = ($link->link_target || '');
    $param->{xfn_rel}            = ($link->xfn_rel || '');
    $param->{last_modified}      = ($link->last_modified || '');
    $param->{primary_feed}       = ($link->primary_feed || '');
    $param->{hidden}             = ($link->hidden || 0);
    push @{$param->{targets}}, { target_name => $_ }
        foreach qw( _self _blank _parent _top );
    my $plugin = MT->component('LinkRoller');
    my $scope = 'blog_id:' . $param->{blog_id};
    $param->{show_xfn}           = $plugin->get_config_value('show_xfn', $scope);
}

sub edit_asset_src {
	my ($cb, $app, $tmpl) = @_;
    my $plugin = MT->component("LinkRoller");
	my $edit_link_tmpl = File::Spec->catdir($plugin->path,'tmpl','edit_link.tmpl');
	$$tmpl = '<mt:if name="class" eq="link"><mt:include name="'.$edit_link_tmpl.'"><mt:else>'.$$tmpl.'</mt:if>';
}

sub post_save_asset {
    my ($cb, $app, $obj, $original) = @_;
    return 1
      unless (($obj->column_values->{class} || '') eq 'link');
    my $q = $app->param;
    my $blog = $app->blog
      or return;
    if (! $blog ) {
        return MT->translate( 'Invalid request.' );
    }
    $app->validate_magic()
      or return MT->translate( 'Permission denied.' );
    my $user = $app->user
      or return;
    if (! is_user_can( $blog, $user, 'upload' ) ) {
        return MT->translate( 'Permission denied.' );
    }
    my $link = $obj;
    ($app, $link) = _internal_save($app);
}

1;