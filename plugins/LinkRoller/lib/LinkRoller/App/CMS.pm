# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2007, Arvind Satyanarayan.

package LinkRoller::App::CMS;

use strict;

use MT::Util qw( format_ts );

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
    if ($perms) {
		my $link_prefs = $perms->link_prefs || 'hidden,name,url,description,tags|Bottom';
        my $pref_param = $app->load_entry_prefs( $link_prefs );
        %$param = ( %$param, %$pref_param );
	}
	
	push @{$param->{targets}}, { target_name => $_ }
		foreach qw( _self _blank _parent _top );
		
	push @{$param->{positions}}, { position_i => $_ }
		foreach (1..100);
}

sub edit_asset_src {
	my ($cb, $app, $tmpl) = @_;
	
	my $plugin = plugin();	
	my $edit_link_tmpl = File::Spec->catdir($plugin->path,'tmpl','edit_link.tmpl');
	
	$$tmpl = '<mt:if name="class" eq="link"><mt:include name="'.$edit_link_tmpl.'"><mt:else>'.$$tmpl.'</mt:if>';
}

sub save_link {
	my $app = shift;
	my $q = $app->param;
	
	my $blog_id = $q->param('blog_id');
	my $id = $q->param('id');
	my $class = $app->model('asset.link');
	
	my ($link);
	

	if($id) {
		$link = $class->load($id);
	} else {
		$link = $class->new;
	}
	
	if($q->param('quickadd')){
	    my $ua = MT->new_ua;
	    my $req = HTTP::Request->new('GET', $q->param('url'));
	    my $result = $ua->request( $req );
	    $q->param('label', $result->title);
	    my $dat = $result->content;
			$dat =~ m!<\s*?meta\s*?name="description"\s*?content="(.*?)"\s*?/?\s*?>!i; 
		$q->param('description', $1);
		$dat =~ m!<\s*?meta\s*?name="(author|dc\.creator|dc\.publisher)"\s*?content="(.*?)"\s*?/?\s*?>!i;
		$q->param('blog_author', $2);
   	}
		
	my $names  = $link->column_names;
    my %values = map { $_ => ( scalar $q->param($_) ) } @$names;
	my $meta_columns = $class->properties->{meta_columns} || {};

	foreach my $col (keys %$meta_columns) {
		$values{$col} = $q->param($col);
	}
	
	$values{hidden} = 0
      if !defined( $values{hidden} )
      || $app->param('hidden') eq '';

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

sub save_link_prefs {
    my $app   = shift;
    my $perms = $app->permissions
      or return $app->error( $app->translate("No permissions") );
    $app->validate_magic() or return;
    my $q     = $app->param;
    my $prefs = $app->_entry_prefs_from_params;
    $perms->link_prefs($prefs);
    $perms->save
      or return $app->error(
        $app->translate( "Saving permissions failed: [_1]", $perms->errstr ) );
    $app->send_http_header("text/json");
    return "true";
}

sub list_asset_src {
	my ($cb, $app, $tmpl) = @_;
	
	my $old = q{<$mt:var name="label" escape="html"$>};
	$old = quotemeta($old);
	my $new = q{<mt:if name="class" eq="link"><a href="<mt:var name="script_url">?__mode=view_link&amp;id=<mt:var name="id">&amp;blog_id=<mt:var name="blog_id">"><mt:var name="label" escape="html"></a><mt:else><$mt:var name="label" escape="html"$></mt:if>};
	
	$$tmpl =~ s/$old/$new/g;
}

sub plugin { MT::Plugin::LinkRoller->instance; }

1;