## SKYARC (C) 2004-2011 SKYARC System Co., Ltd., All Rights Reserved.
## $Id: ja.pm 1998 2011-09-08 09:34:59Z t-yagishita $

package Abs2Rel::L10N::ja;

use strict;
use warnings;

use base 'Abs2Rel::L10N';
use vars qw( %Lexicon );

our %Lexicon = (

## common
    'SKYARC System Co.,Ltd.' => '株式会社 スカイアークシステム',

## Abs2Rel
    'Omit the domain name and base path from its URL, and make it only relative path.'
        => 'ブログ記事・ウェブページを出力する際にstyleやaタグを相対パスに変換して出力します。',
    'Ignore Extensions'  => 'パス変換を行わない拡張子',
    'Ignore Directories' => 'パス変換を行わないディレクトリ',

## Abs2RelTags
    'Override tags handler and convert an absolute url in the blog domain to a relative url automatically.'
        => 'タグの動作を上書きし、ブログURLと同じドメインの絶対URLを相対URLに自動的に変換します。',
    'Tags to override' => '上書きするタグ',
    'Enumrate template tags separated with comma(,).' =>
        'カンマ(,)区切りでテンプレートタグ名を指定してください。',
    'Secure URL' => 'セキュアURL',
    'Replace a url starts from https://.' =>
        'https://から始まるURLも置換する',
    'Not replace a url starts from https://.' =>
        'https://から始まるURLは置換しない',

);

1;