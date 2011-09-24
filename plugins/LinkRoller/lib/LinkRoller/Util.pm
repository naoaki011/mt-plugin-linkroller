package LinkRoller::Util;

use strict;
use base 'Exporter';
our @EXPORT_OK = qw( is_user_can );

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
