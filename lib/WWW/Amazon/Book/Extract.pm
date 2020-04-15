package WWW::Amazon::Book::Extract;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

#use HTML::Entities qw(decode_entities);

our %SPEC;

sub _strip_summary {
    my $html = shift;
    $html =~ s!<a[^>]+>.+?</a>!!sg;
    #$html = replace($html, {
    #    '&nbsp;' => ' ',
    #    '&raquo;' => '"',
    #    '&quot;' => '"',
    #});
    decode_entities($html);
    $html =~ s/\n+/ /g;
    $html =~ s/\s{2,}/ /g;
    $html;
}

$SPEC{parse_amazon_book_page} = {
    v => 1.1,
    summary => 'Extract information from an Amazon book page',
    args => {
        page_content => {
            schema => 'str*',
            req => 1,
            cmdline_src => 'stdin_or_file',
        },
    },
};
sub parse_amazon_book_page {
    my %args = @_;

    my $ct = $args{page_content} or return [400, "Please supply page_content"];

    my $res = {};
    my $resmeta = {};
    my $ld;

    # isbn
    if ($ct =~ m!<li><b>ISBN-10:</b> ([0-9Xx]+)</li>!) {
        $res->{isbn10} = $1;
    }
    if ($ct =~ m!<li><b>ISBN-13:</b> ([0-9Xx-]+)</li>!) {
        $res->{isbn13} = $1;
    }

    # title
    if ($ct =~ m!<span id="productTitle" class="a-size-large">(.+?)</span>!) {
        $res->{title} = $1;
    }

    # edition & pages
    if ($ct =~ m!<li><b>(Hardcover|Paperback):</b> ([0-9,]+) pages</li>!) {
        my ($edition, $num_pages) = ($1, $2);
        $num_pages =~ s/\D+//g;
        $res->{edition} = $edition;
        $res->{num_pages} = $num_pages;
    }

    # publisher & date
    if ($ct =~ m!<li><b>Publisher:</b> (.+?) \(([^)]+)\)</li>!) {
        my ($publisher, $pubdate) = ($1, $2);
        require DateTime::Format::Natural;
        my $dt = DateTime::Format::Natural->new->parse_datetime($pubdate);
        $res->{publisher} = $publisher;
        $res->{pub_date} = $dt->ymd if $dt;
    }

    [200, "OK", $res, $resmeta];
}

1;
# ABSTRACT:

=head1 SEE ALSO

The Amazon drivers for L<WWW::Scraper::ISBN>.
