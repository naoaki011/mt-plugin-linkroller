# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2008, Arvind Satyanarayan.

package LinkRoller::Template::ContextHandlers;

use strict;

sub _hdlr_core_tag {
	my $tag = shift;
	my $class = 'MT::Template::Context';
	eval "require $class;";
	if ($@) { die $@; $@ = undef; return 1; }
	my $method_ref = $class->can($tag);
	return $method_ref->(@_) if $method_ref;
	die MT->translate("Failed to find [_1]::[_2]", $class, $tag);	
}

sub _hdlr_links {
	my($ctx, $args, $cond) = @_;
	$args->{type} = 'link';
	require MT::Template::Context;
	return MT::Template::Context::_hdlr_assets($ctx, $args, $cond);
}

sub _hdlr_link_description {
	my $a = $_[0]->stash('asset')
		or return $_[0]->_no_asset_error('MTLinkDescription');
	$a->description;
}

sub _hdlr_link_property {
	my $property = shift;
	my ($ctx, $args) = @_;
	$args->{property} = $property;
	require MT::Template::Context;
	return MT::Template::Context::_hdlr_asset_property($ctx, $args);
}


sub _hdlr_if_tagged {
	_hdlr_core_tag('_hdlr_asset_if_tagged', @_);
}

sub _hdlr_tags {
	_hdlr_core_tag('_hdlr_asset_tags', @_);
}

sub _hdlr_is_first_in_row {
	_hdlr_core_tag('_hdlr_pass_tokens', @_);
}

sub _hdlr_is_last_in_row {
	_hdlr_core_tag('_hdlr_pass_tokens', @_);
}

sub _hdlr_header {
	_hdlr_core_tag('_hdlr_pass_tokens', @_);
}

sub _hdlr_footer {
	_hdlr_core_tag('_hdlr_pass_tokens', @_);
}


sub _hdlr_id {
	_hdlr_core_tag('_hdlr_asset_id', @_);
}

sub _hdlr_name {
	_hdlr_core_tag('_hdlr_asset_label', @_);
}

sub _hdlr_url {
	_hdlr_core_tag('_hdlr_asset_url', @_);
}

sub _hdlr_author {
	_hdlr_link_property('link_author', @_);
}

sub _hdlr_rel {
	_hdlr_link_property('rel', @_);
}

sub _hdlr_target {
	_hdlr_link_property('target', @_);
}

sub _hdlr_xfn {
	_hdlr_link_property('xfn', @_);
}

sub _hdlr_date_added {
	_hdlr_core_tag('_hdlr_asset_date_added', @_);
}

sub _hdlr_date_modified {
	_hdlr_core_tag('_hdlr_asset_date_added', @_);
}

sub _hdlr_added_by {
	_hdlr_core_tag('_hdlr_asset_added_by', @_);
}

1;