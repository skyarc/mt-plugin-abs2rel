## SKYARC (C) 2004-2011 SKYARC System Co., Ltd., All Rights Reserved.
## $Id: Abs2Rel.pl 1998 2011-09-08 09:34:59Z t-yagishita $

package MT::Plugin::Abs2Rel;

use strict;
use warnings;

use MT 3;
use MT::Blog;
use Data::Dumper;

use vars qw( $MYNAME $VERSION );
$MYNAME  = 'Abs2Rel';
$VERSION = '1.31';

### Sub-Class
use base qw( MT::Plugin );
my $plugin = __PACKAGE__->new(
    {   name    => $MYNAME,
        version => $VERSION,
        id      => lc $MYNAME,
        key     => lc $MYNAME,
        description =>
            "<__trans phrase='Omit the domain name and base path from its URL, and make it only relative path.'>",
        author_name          => "<__trans phrase='SKYARC System Co.,Ltd.'>",
        author_link          => 'http://www.skyarc.co.jp/',
        doc_link             => 'http://www.mtcms.jp',
        l10n_class           => 'Abs2Rel::L10N',
        blog_config_template => \&_tmpl_config_template,
        settings             => new MT::PluginSettings(
            [   [ 'enable_func', { Default => 0, Scope => 'blog' } ],
                [ 'ignore_file', { Default => "xml,rdf,php,cgi,js,css,rb,pl", Scope   => 'blog' } ],
                [ 'ignore_dirs', { Default => undef, Scope => 'blog' } ],
            ]
        ),
    }
);
MT->add_plugin($plugin);

sub instance { $plugin; }

### Configuration screen
sub _tmpl_config_template {
    <<HTMLHEREDOC;
<mtapp:setting id="enable_func" label="<__trans phrase='Enable'>">
<input type="checkbox" name="enable_func" value="1"<TMPL_IF NAME=ENABLE_FUNC> checked="checked"</TMPL_IF> />
</mtapp:setting>

<mtapp:setting id="ignore_file" label="<__trans phrase='Ignore Extensions'>">
<input type="text" name="ignore_file" size="20" value="<TMPL_VAR NAME=IGNORE_FILE ESCAPE=HTML>" />
</mtapp:setting>

<mtapp:setting id="ignore_dirs" label="<__trans phrase='Ignore Directories'>">
<input type="text" name="ignore_dirs" size="20" value="<TMPL_VAR NAME=IGNORE_DIRS ESCAPE=HTML>" />
</mtapp:setting>
HTMLHEREDOC
}

### Add callback handler for building pages
MT->add_callback( 'BuildPage', 9, $plugin, \&_hdlr_build_page );

sub _hdlr_build_page {
    my ( $cb, %opt ) = @_;
    my $blog = $opt{Blog}
        or return 1;

    ### Skip when disabled
    my $scope = 'blog:' . $blog->id;
    &instance->get_config_value( 'enable_func', $scope )
        or return 1;

    ### Skip the file by its file extensions
    my $base_path = $opt{File}
        or return 1;
    my ($file_ext) = $base_path =~ m!\.(\w+?)$!;
    my $ignore_file = &instance->get_config_value( 'ignore_file', $scope )
        || '';
    foreach ( split /[\s,]/, $ignore_file ) {
        return 1 if lc $_ eq lc $file_ext;    # skip in this file type
    }

    ### Base pathname and filename
    my $site_path = $blog->{column_values}->{archive_path} || $blog->site_path
        or return 1;
    $base_path =~ s!^\Q$site_path\E!!;
    $base_path =~ s!\\!/!g;                   # for Windows

    ### Ignore directories
    my $ignore_dirs = &instance->get_config_value( 'ignore_dirs', $scope )
        || '';
    foreach ( split /[\s,]/, $ignore_dirs ) {
        return 1 if $base_path =~ m!^/$_/!;    # skip in this directory
    }

    ### Blog domain name and base path
    my $site_url = $blog->{column_values}->{archive_url} || $blog->site_url
        or return 1;
    my ( $url_domain, $url_path )
        = $site_url =~ m!^(https?://[^/]+)(/[^#\?]*)?!;

    $base_path = $url_path . $base_path;
    $base_path =~ s!//*!/!g;                   # omit doubled slashes
    my ( $base_pathname, $base_filename ) = $base_path =~ m!(.+/)(.*)!;

    ### Replace domain name + absolute path description to relative one.
    my $content = $opt{Content};
    $$content
        =~ s!(<[^>]+(?:href|src|action)\s*=\s*(["']))([^'"]+)\2!$1.abs2rel($3, $url_domain, $base_pathname).$2!segi;

    ### PageBute Support
    my $ctx = $opt{Context};
    my $pb = $ctx->stash('PageBute') or return 1;
    $pb->{abs2rel} = 1;
    $pb->{contents}
        =~ s!(<[^>]+(?:href|src|action)\s*=\s*(["']))([^'"]+)\2!$1.abs2rel($3, $url_domain, $base_pathname).$2!segi;

    return 1;
}

### Absolute path to relative one with $url_domain and $base_pathname
sub abs2rel {
    my ( $path, $url_domain, $base_pathname ) = @_;

    return $path if $path =~ m!^#!;               # anchor link
    return $path if $path =~ m!^javascript:!i;    # JavaScript
    return $path if $path =~ m!^\.+/!;            # already relative path
    return $path if $path =~ m!^/!;               # already absolute path
    return $path    # return $path when external link
        if $path !~ m!^\Q$url_domain\E/!;

    $path =~ s!^\Q$url_domain\E!!;
    $path;
}

1;