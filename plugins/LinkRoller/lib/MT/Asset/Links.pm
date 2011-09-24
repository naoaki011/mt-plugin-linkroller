package MT::Asset::Links;

use MT::Util qw( encode_html );
use strict;
use base qw(MT::Asset);

__PACKAGE__->install_properties( { class_type => 'link', } );
__PACKAGE__->install_meta( { columns => [ 
                                 'target',
                                 'rel',
                                 'link_autjor',
                                 'updated',
                                 'xfn',
                                 ] 
                           } );

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

    my $text = sprintf(
        '<a href="%s" title="%s" target="%s" rel="%s">%s</a>',
        encode_html( $asset->url ),
        encode_html( $asset->description ),
        encode_html( $asset->target ),
        encode_html( $asset->rel ),
        encode_html( $asset->label )
    );

	return $asset->enclose($text);
}

sub metadata {
    my $obj  = shift;
    my $meta = $obj->SUPER::metadata(@_);

    my $tracking = $obj->tracking;

    $meta;
}

sub tracking {
    my $asset = shift;
    my $tracking = $asset->meta('tracking', @_);
    return $tracking;
}


1;