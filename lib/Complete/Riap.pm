package Complete::Riap;

our $DATE = '2014-12-02'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(complete_riap_url);

$SPEC{complete_riap_url} = {
    v => 1.1,
    summary => 'Complete Riap URL',
    description => <<'_',

Currently only support local Perl schemes (e.g. `/Pkg/Subpkg/function` or
`pl:/Pkg/Subpkg/`).

_
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        type => {
            schema => ['str*', in=>['function','package']], # XXX other types?
            summary => 'Filter by entity type',
        },
    },
    result_naked => 1,
};
sub complete_riap_url {
    my %args = @_;

    my $word = $args{word} // ''; $word = '/' if !length($word);
    my $type = $args{type} // '';

    my $scheme;
    if ($word =~ m!\A/!) {
        $scheme = '';
    } elsif ($word =~ s!\Apl:/!/!) {
        $scheme = 'pl';
    } else {
        return [];
    }

    my ($pkg, $leaf) = $word =~ m!(.*/)(.*)!;
    state $pa = do {
        require Perinci::Access;
        Perinci::Access->new;
    };

    my $riap_res = $pa->request(list => $pkg, {detail=>1});
    return [] unless $riap_res->[0] == 200;

    my @res;
    for my $ent (@{ $riap_res->[2] }) {
        next unless $ent->{type} eq 'package' ||
            (!$type || $type eq $ent->{type});
        next unless index($ent->{uri}, $leaf) == 0;
        push @res, "$pkg$ent->{uri}";
    }

    # put scheme back on
    if ($scheme) {
        for (@res) { $_ = "$scheme:$_" }
    }

    {words=>\@res, path_sep=>'/'};
}

1;
#ABSTRACT: Riap-related completion routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Riap - Riap-related completion routines

=head1 VERSION

This document describes version 0.01 of Complete::Riap (from Perl distribution Complete-Riap), released on 2014-12-02.

=head1 SYNOPSIS

 use Complete::Riap qw(complete_riap_url);
 my $res = complete_riap_url(word => '/Te', type=>'package');
 # -> {word=>['/Template/', '/Test/', '/Text/'], path_sep=>'/'}

=head1 FUNCTIONS


=head2 complete_riap_url(%args) -> any

Complete Riap URL.

Currently only support local Perl schemes (e.g. C</Pkg/Subpkg/function> or
C<pl:/Pkg/Subpkg/>).

Arguments ('*' denotes required arguments):

=over 4

=item * B<type> => I<str>

Filter by entity type.

=item * B<word>* => I<str>

=back

Return value:

 (any)

=head1 TODO

'ci' option (this should perhaps be implemented in
L<Perinci::Access::Schemeless>?).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Riap>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Riap>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Riap>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
