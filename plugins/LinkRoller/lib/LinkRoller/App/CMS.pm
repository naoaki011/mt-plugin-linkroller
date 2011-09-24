# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2008, Arvind Satyanarayan.

package LinkRoller::App::CMS;

use strict;
use MT 5;
use MT::Asset;
use MT::Util qw( format_ts );
use LinkRoller::Util qw( is_user_can );

sub quickadd_link {
    my $app = shift;
    my $blog = $app->blog;
    if (! $blog ) {
        return MT->translate( 'Invalid request.' );
    }
    my $user = $app->user;
    if (! is_user_can( $blog, $user, 'manage_links' ) ) {
        return MT->translate( 'Permission denied.' );
    }
    my $plugin = MT->component("LinkRoller");
    return $app->build_page($plugin->load_tmpl('quickadd.tmpl'));
}

sub save_link {
    my $app = shift;
    my $blog = $app->blog;
    if (! $blog ) {
        return MT->translate( 'Invalid request.' );
    }
    $app->validate_magic()
      or return MT->translate( 'Permission denied.' );
    my $user = $app->user;
    if (! is_user_can( $blog, $user, 'manage_links' ) ) {
        return MT->translate( 'Permission denied.' );
    }

    my $q = $app->param;
    my $blog_id = $blog->id;
    my $id = $q->param('id');
    my $class = $app->model('asset.link');

    my $link = $id ? $class->load($id) : $class->new;

    if($q->param('quickadd')){
        my $ua = MT->new_ua;
        my $req = HTTP::Request->new('GET', $q->param('url'));
        my $result = $ua->request( $req );
        my $label = $result->title;
        my $content = $result->content;

        if ( MT->version_number ge '5.0' ) {
            $label = MT::I18N::encode_text( $label, '', 'utf-8' );
            $content = MT::I18N::encode_text( $content, '', 'utf-8' );
        }

        $q->param('label', $label);
        $content =~ m!<\s*?meta\s*?name="description"\s*?content="(.*?)"\s*?/?\s*?>!i; 
        $q->param('description', $1);
        $content =~ m!<\s*?meta\s*?name="(author|dc\.creator|dc\.publisher)"\s*?content="(.*?)"\s*?/?\s*?>!i;
        $q->param('link_author', $2);
    }

    my $names  = $link->column_names;
    my %values = map { $_ => ( scalar $q->param($_) ) } @$names;
    my $meta_columns = $class->properties->{meta_columns} || {};

    foreach my $col (keys %$meta_columns) {
        $values{$col} = $q->param($col);
    }

    foreach my $col (keys %values) {
        $link->$col($values{$col});
    }

    my $tags = $q->param('tags');
    if(defined $tags) {
        require MT::Tag;
        my $tag_delim = chr($app->user->entry_prefs->{tag_delim});
        my @tags = MT::Tag->split($tag_delim, $tags);
        $link->set_tags(@tags);    
    }
    $link->class('link');
    $link->save or die $link->errstr;

    $app->add_return_arg( id => $link->id )
        if !$id;
    $app->call_return( saved => 1 );
}

sub edit_asset_param {
    my ($cb, $app, $param, $tmpl) = @_;
    
    return 1 unless $param->{class} eq 'link';
    
    my $class = $app->model('asset.link');
    my $id = $app->param('id');
    my $perms  = $app->permissions;
    
    if($id) {
        my $link = $class->load($id);
        my $meta_columns = $class->properties->{meta_columns} || {};
        foreach my $col (keys %$meta_columns) {
            $param->{$col} =
              defined $app->param($col) ? $app->param($col) : $link->$col();
        }
    }

    ## Now load user's preferences and customization for new/edit
    ## entry page.
    #if ($perms) {
    #    my $link_prefs = $perms->link_prefs || 'hidden,name,url,description,tags|Bottom';
    #    my $pref_param = $app->load_entry_prefs( $link_prefs );
    #    %$param = ( %$param, %$pref_param );
    #}

    push @{$param->{targets}}, { target_name => $_ }
        foreach qw( _self _blank _parent _top );

    #push @{$param->{positions}}, { position_i => $_ }
    #    foreach (1..100);
}

sub edit_asset_src {
	my ($cb, $app, $tmpl) = @_;
	
    my $plugin = MT->component("LinkRoller");
	my $edit_link_tmpl = File::Spec->catdir($plugin->path,'tmpl','edit_link.tmpl');
	$$tmpl = '<mt:if name="class" eq="link"><mt:include name="'.$edit_link_tmpl.'"><mt:else>'.$$tmpl.'</mt:if>';
}

sub asset_table_src {
	my ($cb, $app, $tmpl) = @_;
	my ($old, $new);
	
	# First switch to using asset-thumbnail class
	$old = q{asset-no-thumbnail};
	$old = quotemeta($old);
	$new = q{<mt:if name="class" eq="link">asset-thumbnail<mt:else>asset-no-thumbnail</mt:if>};
	$$tmpl =~ s/$old/$new/;
	
	# Then add a div with the thumbnail within
	$old = q{<span><__trans phrase="No thumbnail image"></span>};
	$old = quotemeta($old);
	$new = <<HTML;
<mt:if name="class" eq="link">
	<div style="width: 75px; height: 75px; overflow: hidden; margin-left: 2px;">
		<img title="Powered by Snap Shots (tm)" src="http://shots.snap.com/preview/?url=<mt:var name="url">" />
	</div>
<mt:else>
	<span><__trans phrase="No thumbnail image"></span>
</mt:if>
HTML
	$$tmpl =~ s/$old/$new/;
}

sub doLog {
    my ($msg) = @_; 
    return unless defined($msg);
    require MT::Log;
    my $log = MT::Log->new;
    $log->message($msg) ;
    $log->save or die $log->errstr;
}

1;