## SKYARC (C) 2004-2011 SKYARC System Co., Ltd., All Rights Reserved.
## $Id: Abs2RelTags.pl 1998 2011-09-08 09:34:59Z t-yagishita $

package MT::Plugin::Abs2RelTags;

use strict;
use warnings;

use MT;
use MT::Template::Handler;

use vars qw( $PLUGIN_NAME $VERSION $DEFAULT_TAGS );
$PLUGIN_NAME  = 'Abs2RelTags';
$VERSION      = '1.05';
$DEFAULT_TAGS = 'EntryBody,EntryMore,PageBody,PageMore';

use base qw( MT::Plugin );
my $plugin = MT::Plugin::Abs2RelTags->new(
    {   id      => $PLUGIN_NAME,
        key     => $PLUGIN_NAME,
        name    => $PLUGIN_NAME,
        version => $VERSION,
        description =>
            "<__trans phrase='Override tags handler and convert an absolute url in the blog domain to a relative url automatically.'>",
        author_name            => "<__trans phrase='SKYARC System Co.,Ltd.'>",
        author_link            => 'http://www.skyarc.co.jp/',
        doc_link               => 'http://www.mtcms.jp',
        l10n_class             => 'Abs2Rel::L10N',
        system_config_template => \&system_config_template,
        settings               => new MT::PluginSettings(
            [
                [ 'abs2rel_tags', { Scope => 'system', Default => $DEFAULT_TAGS }],
                [ 'abs2rel_secure', { Scope => 'system', Default => 0 } ],
            ]
        ),
        registry => {
            tags      => { modifier => { 'abs2rel' => \&abs2rel, }, },
            callbacks => {
                'build_file_filter' => \&on_build_file_filter,
                'build_page'        => \&on_build_file,
            },
        },
    }
);
MT->add_plugin($plugin);

sub instance { $plugin; }

sub get_config {
    my ( $plugin, $name, $blog_id ) = @_;

    my $config
        = $plugin->get_config_hash( $blog_id ? "blog:$blog_id" : undef )
        || {};
    $config->{$name};
}

#----- Config templates
sub system_config_template {
    my ( $self, $param, $scope ) = @_;

    # Config template.
    <<'EOT';
<mtapp:setting id="abs2rel_tags" label="<__trans phrase="Tags to override">:" hint="<__trans phrase="Enumrate template tags separated with comma(,).">" show_hint="1">
<input type="text" name="abs2rel_tags" id="abs2rel_tags" value="<mt:var name="abs2rel_tags" escape="html">" />
</mtapp:setting>

<mtapp:setting id="abs2rel_secure" label="<__trans phrase="Secure URL">:">
<ul>
<li><input type="radio" name="abs2rel_secure" id="abs2rel_secure_no" value="0" <mt:unless name="abs2rel_secure"> checked="checked"</mt:unless> /> <label for="abs2rel_secure_no"><__trans phrase="Not replace a url starts from https://."></label></li>
<li><input type="radio" name="abs2rel_secure" id="abs2rel_secure_yes" value="1" <mt:if name="abs2rel_secure"> checked="checked"</mt:if> /> <label for="abs2rel_secure_yes"><__trans phrase="Replace a url starts from https://."></label></li>
</ul>
</mtapp:setting>
EOT
}

#----- Global filter
sub abs2rel {
    my ( $text, $arg, $ctx, $tag ) = @_;

    # $tag が無い場合は、modifierとして呼ばれた場合。
    # この場合は置換処理を行う。
    if ( $tag ) {
        return $text unless $tag eq lc( $ctx->stash('tag') );
    }

    my $replace_secure = $plugin->get_config('abs2rel_secure') || 0;

    # Get the blog domain.
    my $blog = $ctx->stash('blog')
        or return $text;
    my $site_url = $blog->site_url;
    my ($domain) = $site_url =~ m!https?://([^/]+)!i
        or return $text;

    # Replace urls.
    my $schema = $replace_secure ? 'https?:' : 'http:';
    $text =~ s!href="$schema//$domain!href="!igs;
    $text;
}

#----- Hook
sub on_build_file_filter {
    my ( $cb, %args ) = @_;
    my $ctx = $args{Context};

    # Check if already override
    defined $ctx->{__handlers}{__abs2rel_original}
        and return 1;
    $ctx->{__handlers}{__abs2rel_original} = {};

    # Override tags.
    my $tags = $plugin->get_config('abs2rel_tags') || '';
    my @tags = map { my $tag = lc; $tag =~ s/^mt:?//; $tag; } split /\s*,\s*/,
        $tags;
    foreach my $tag (@tags) {

        # Avoid repetition.
        $ctx->{__handlers}{__abs2rel_original}->{$tag}
            and next;

        # Override the handler.
        my $original_handler = $ctx->{__handlers}{$tag}
            or next;
        if ( ref( $original_handler->[0] ) ne 'CODE' ) {

            # Resolve
            $original_handler->[0]
                = MT->handler_to_coderef( $original_handler->[0] );
        }
        $ctx->{__handlers}{__abs2rel_original}->{$tag} = $original_handler;
        $ctx->{__handlers}{$tag} = MT::Template::Handler->new(
            sub {
                my ($ctx) = @_;
                abs2rel( $original_handler->[0]->(@_), {}, $ctx, $tag );   # closure
            },
            $ctx->{__handlers}{$tag}[1],
            $ctx->{__handlers}{$tag}[2],
        );
    }
    1;                                                                     # success
}

sub on_build_file {
    my ( $cb, %args ) = @_;
    my $ctx = $args{Context};

    # Take tags back.
    defined $ctx->{__handlers}{__abs2rel_original}
        or return;
    foreach my $tag ( keys %{ $ctx->{__handlers}{__abs2rel_original} } ) {
        $ctx->{__handlers}{$tag}
            = $ctx->{__handlers}{__abs2rel_original}->{$tag};
    }

    # Clear flag and original handlers.
    delete $ctx->{__handlers}{__abs2rel_original};
}

1;
