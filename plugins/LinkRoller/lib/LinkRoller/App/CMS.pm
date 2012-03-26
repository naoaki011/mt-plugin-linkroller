# Link Roller - A plugin for Movable Type.
# Copyright (c) 2005-2008, Arvind Satyanarayan.

package LinkRoller::App::CMS;

use strict;
use MT;
use MT::Asset;
use LinkRoller::Util qw( is_user_can  _internal_save );

sub plugin { MT::Plugin::LinkRoller->instance; }

sub edit_asset_param {
    my ($cb, $app, $param, $tmpl) = @_;
    return unless $param->{class} eq 'link';
    my $class = $app->model('asset.link');
    my $id = $app->param('id')
      or return;
    my $link = $class->load($id)
      or return;
    return if ($link->class ne 'link');
    $param->{link_author}        = ($link->link_author || '');
    $param->{link_target}        = ($link->link_target || '');
    $param->{xfn_rel}            = ($link->xfn_rel || '');
    $param->{last_modified}      = ($link->last_modified || '');
    $param->{primary_feed}       = ($link->primary_feed || '');
    $param->{hidden}             = ($link->hidden || 0);
    push @{$param->{targets}}, { target_name => $_ }
        foreach qw( _self _blank _parent _top );
    #my $plugin = MT->component('LinkRoller');
    #my $scope = 'blog_id:' . $param->{blog_id};
    #$param->{show_xfn}           = $plugin->get_config_value('show_xfn', $scope);
    $param->{has_thumbnail}        = 1;
}

sub edit_asset_src {
    my ($cb, $app, $tmpl) = @_;
    my $id = $app->param('id')
      or return;
    my $link = $app->model('asset.link')->load($id)
      or return;
    return if ($link->class ne 'link');

    my $old = <<'HTML';
<mt:setvar name="page_title" value="<__trans phrase="Edit Asset">">
HTML
    $old = quotemeta($old);
    my $new = <<"HTML";
<mt:setvar name="page_title" value="<__trans_section component="LinkRoller"><__trans phrase="Edit Link"></__trans_section>">
HTML
    $$tmpl =~ s!$old!$new!;

    $old = <<'HTML';
<script type="text/javascript" src="<mt:var name="static_uri">js/tc/client.js"></script>
<script type="text/javascript">
/* <![CDATA[ */
HTML
    $old = quotemeta($old);
    $new = <<"HTML";
<script type="text/javascript" src="<mt:var name="static_uri">js/tc/client.js"></script>
<script type="text/javascript">
/* <![CDATA[ */
function changeTarget(s) {
    if (s.options[s.selectedIndex].value == 'other') {
        getByID('other_target_input').style.display = 'block'; 
        getByID('other_target_input').focus(); 
        s.style.display='none'; 
        s.disabled = true;
    }
}
HTML
    $$tmpl =~ s!$old!$new!;

    my $old = <<'HTML';
<img src="<mt:var name="thumbnail_url" escape="html">" width="<mt:var name="thumbnail_width" escape="html">" height="<mt:var name="thumbnail_height" escape="html">" />
        </div>
HTML
    $old = quotemeta($old);
    $new = <<"HTML";
<img src="http://capture.heartrails.com/300x400/shorten?<mt:var name="url">" alt="Powered by HeartRails Capture" title="Powered by HeartRails Capture" />
</div>
<div class="hint">Powered by <a href="http://capture.heartrails.com/">HeartRails Capture</a></div>
HTML
    $$tmpl =~ s!$old!$new!;

    $old = <<'HTML';
    <div class="asset-metadata">
      <ul class="metadata">
        <li class="metadata-item asset-name"><strong><__trans phrase="File Name">:</strong><mt:var name="file_name" escape="html"></li>
        <li class="metadata-item asset-type"><strong><__trans phrase="Type">:</strong><mt:var name="asset_class_label" escape="html"></li>
        <li class="metadata-item asset-size">
          <strong><__trans phrase="Dimensions">:</strong>
        <mt:if name="class" eq="image">
          <mt:var name="image_width" escape="html"> &times; <mt:var name="image_height" escape="html"><mt:if name="file_size_formatted"> - </mt:if>
        </mt:if>
          <mt:var name="file_size_formatted" escape="html">
        </li>
      </ul>
    </div>
HTML
    $old = quotemeta($old);
    my $link_target = $link->link_target;
    $new = <<"HTML";
<div class="asset-metadata">
  <ul class="metadata">
    <li class="metadata-item asset-type"><strong><__trans phrase="Type">:</strong><mt:var name="asset_class_label" escape="html"></li>
    <li class="metadata-item asset-name"><strong><__trans_section component="LinkRoller"><__trans phrase="Site Name"></__trans_section>:</strong><input type="text" name="label" id="label" class="text full" value="<mt:var name="label" escape="html">" style="width:75%;" /></li>
    <li class="metadata-item asset-update"><strong><__trans phrase="LastUpdate">:</strong><input type="text" name="last_modified" value="<mt:var name="last_modified">" readonly="readonly" style="background-color:#eee;width:20em;" /></li>
  </ul>
  <mtapp:setting
     id="url"
     label_class="top-label"
     label="<__trans phrase="URL">">
    <a href="<mt:var name="url" escape="html">"><__trans_section component="LinkRoller"><__trans phrase="View Link"></__trans_section></a>
    <input type="text" name="url" id="url" class="mt-edit-field text" style="width:80%;" value="<mt:var name="url" escape="html">" />
  </mtapp:setting>
  <mtapp:setting
     id="link_target"
     label="<__trans_section component="LinkRoller"><__trans phrase="Link Target"></__trans_section>"
     label_class="top-label"
     hint="<__trans_section component="LinkRoller"><__trans phrase="The name of a frame where this link should open"></__trans_section>"
     show_hint="1">
      <select name="link_target" id="link_target" class="quarter-width" onchange="changeTarget(this);">
        <option value=""><__trans phrase="Select"></option>
        <mt:loop name="targets">
        <option<mt:if name="target_name" eq="$link_target"> selected="selected"</mt:if> value="<mt:var name="target_name">"><mt:var name="target_name"></option>
        </mt:loop>
        <option value="other"><__trans phrase="Custom"></option>
      </select>
      <input type="text" name="link_target" value="<mt:var name="link_target" escape="html">" id="other_target_input" class="quarter-width" style="display: none;" />
  </mtapp:setting>
  <mtapp:setting
     id="link_author"
     label="<__trans_section component="LinkRoller"><__trans phrase="Author(s)"></__trans_section>"
     label_class="top-label"
     hint="<__trans_section component="LinkRoller"><__trans phrase="Who created the content being linked here?"></__trans_section>"
     show_hint="1">
    <div class="textarea-wrapper">
      <input type="text" name="link_author" value="<mt:var name="link_author" escape="html">" id="link_author" class="full-width" />
    </div>
  </mtapp:setting>
  <mtapp:setting
     id="primary_feed"
     label_class="top-label"
     label="<__trans phrase="Feed">">
    <a href="" class="icon-feed icon-left ">Open</a>
    <input type="text" name="primary_feed" id="primary_feed" readonly="readonly" class="text" style="width:80%;background-color:#eee;" value="<mt:var name="primary_feed" escape="html">" />
  </mtapp:setting>
</div>
HTML
    $$tmpl =~ s!$old!$new!;

    $old = <<'HTML';
      <mtapp:setting
         id="label"
         label="<__trans phrase="Label">"
         label_class="top-label"
         help_page="assets"
         help_section="asset_label">
        <input type="text" name="label" id="label" class="text full" value="<mt:var name="label" escape="html">" />
      </mtapp:setting>
HTML
    $old = quotemeta($old);
    $$tmpl =~ s!$old!!;

    my $old = <<'HTML';
      <mt:unless name="file_is_missing">
        <mtapp:setting
           id="asset-url"
           label_class="top-label"
           label="<__trans phrase="Embed Asset">">
          <input type="text" readonly="readonly" name="asset-url" id="asset-url" class="text full" value="<mt:var name="url" escape="html">" />
        </mtapp:setting>
      </mt:unless>
HTML
    $old = quotemeta($old);
    my $new = <<"HTML";
HTML
    $$tmpl =~ s!$old!$new!;
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
        <img title="Powered by Simple API" src="http://img.simpleapi.net/small/<mt:var name="url">" width="75" height="75" />
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