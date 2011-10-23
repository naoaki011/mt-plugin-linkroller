# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2008, Arvind Satyanarayan.

package MT::Asset::Link;

use strict;
use warnings;
use base qw(MT::Asset);
use MT::Util qw( encode_html );

__PACKAGE__->install_properties(
    {   class_type    => 'link',
        column_defs => {
            'link_target'   => 'string meta',
            'xfn_rel'       => 'string meta',
            'link_author'   => 'string meta',
            'primary_feed'  => 'string meta',
            'last_modified' => 'string meta',
            'hidden'        => 'string meta',
        },
    }
);

sub class_label {
    MT->translate('Link');
}

sub class_label_plural {
    MT->translate('Links');
}

sub has_thumbnail { 0; }

sub as_html {
    my $asset   = shift;
    my ($param) = @_;
    my $target = $asset->link_target || '';
    my $relation = $asset->xfn_rel || '';
    my $text = '<a href="' . encode_html( $asset->url ) . '"'
             . ' title="'. ( $asset->description || $asset->label ) . '"';
    $text .= ' target="' . $target . '"' if $target;
    $text .= ' rel="' . $relation . '"' if $relation;
    $text .= '>' . $asset->label . '</a>';
	return $asset->enclose($text);
}

sub link_target {
    my $asset = shift;
    my $link_target = $asset->meta( 'link_target', @_ );
    return $link_target if $link_target || @_;
}

sub xfn_rel {
    my $asset = shift;
    my $xfn_rel = $asset->meta( 'xfn_rel', @_ );
    return $xfn_rel if $xfn_rel || @_;
}

sub link_author {
    my $asset = shift;
    my $link_author = $asset->meta( 'link_author', @_ );
    return $link_author if $link_author || @_;
}

sub last_modified {
    my $asset = shift;
    my $last_modified = $asset->meta( 'last_modified', @_ );
    return $last_modified if $last_modified || @_;
}

sub primary_feed {
    my $asset = shift;
    my $primary_feed = $asset->meta( 'primary_feed', @_ );
    return $primary_feed if $primary_feed || @_;
}

sub hidden {
    my $asset = shift;
    my $hidden = $asset->meta( 'hidden', @_ );
    return $hidden if $hidden || @_;
}

1;