package LinkRoller::Util;
use strict;
use base 'Exporter';

our @EXPORT_OK = qw( _internal_save plugin is_user_can );

sub plugin { MT::Plugin::LinkRoller->instance; }

sub _internal_save {
    my $app = shift;
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
    my $plugin = MT->component( 'LinkRoller' );

    my $link_url = $q->param('url')
      or return;
    my $id = $q->param('id');
    my $class = $app->model('asset.link');
    my $link = $id
             ? $class->load($id)
             : $class->load({
                   'url' => $link_url,
                   'blog_id' => $blog->id,
               }) || $class->new;
    if ($q->param('quickadd')) {
        my $ua = MT->new_ua;
        my $req = HTTP::Request->new('GET', $link_url);
        my $result = $ua->request( $req );
        my $link_label = $result->title;
        $link_label = MT::I18N::encode_text($link_label, undef);
        $q->param('label', $link_label);
        my $dat = $result->content;
        $dat = MT::I18N::encode_text($dat, undef);
        $dat =~ m!<\s*?meta\s*?name="description"\s*?content="(.*?)"\s*?/?\s*?>!i and $q->param('description', $1);
        $dat =~ m!<\s*?meta\s*?name="(author|dc\.creator|dc\.publisher)"\s*?content="(.*?)"\s*?/?\s*?>!i and $q->param('link_author', $2);
        $dat =~ m!<\s*?link\s*?rel="alternate"\s[^>]*?href="([^">]*?\.rss|[^">]*?\.rdf|[^">]*?\.atom|[^">]*?\.xml|http://feeds.feedburner[^">]+)"\s*?/?\s*?>!i and my $feed = $1;
        (my $host = $link_url) =~ s!(https?://[^/]+/).*?!$1!i;
        $feed = $host . $1 if ($feed =~ m!^/(.*)$!i);
        $feed = $host . $1 if ($feed =~ m!^([^/]+)$!i);
        $q->param('primary_feed', $feed);
        $q->param('last_modified', $result->header('last_modified'));
        $q->param('hidden', 0);
    }
    $link->blog_id($blog->id);
    $link->class('link');
    $link_url = $link->url if (! $link_url);
    $link->url($link_url);
    $link->label($q->param('label') || 'NoLabel');
    $link->description($q->param('description') || '');
    $link->link_target($q->param('link_target') || '');
    $link->xfn_rel($q->param('xfn_rel') || '');
    $link->link_author($q->param('link_author') || '');
    $link->last_modified($q->param('last_modified') || '');
    $link->primary_feed($q->param('primary_feed') || '');
    $link->hidden($q->param('hidden') || 0);
    $link->save
      or return $link->errstr;
    $app->add_return_arg( id => $link->id )
      if !$id;
    return ($app, $link);
}

sub is_user_can {
    my ( $blog, $user, $permission ) = @_;
    $permission = 'can_' . $permission;
    my $perm = $user->is_superuser;
    unless ( $perm ) {
        if ( $blog ) {
            my $admin = 'can_administer_blog';
            $perm = $user->permissions( $blog->id )->$admin;
            $perm = $user->permissions( $blog->id )->$permission unless $perm;
        } else {
            $perm = $user->permissions()->$permission;
        }
    }
    return $perm;
}

sub is_mt5 {
    my $version = MT->version_id;
    if (($version < 5.1)&&($version >= 5)) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_illiad {
    my $version = MT->version_id;
    if ($version >= 5.1) {
        return 1;
    }
    else {
        return 0;
    }
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
