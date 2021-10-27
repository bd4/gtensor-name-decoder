#!/usr/bin/env raku

grammar N {
    token TOP {
        | <assign>
        | <launch>
        | <expr>
    }
    token expr {
        | <gfunction>
        | <span>
        | <gview>
    }
    token assign {
        'gt::detail::kernel_assign_' <dimnum>
        '<' <lhs=.expr> <.sep> <rhs=.expr> <.ws> '>'
        '(' <alhs=.expr> <.sep> <arhs=.expr> ')'
    }
    token dimnum {
        <[1..6]>
    }
    token launch {
        'gt::kernel_launch<' <lambda_wrapper> '>('
           <shape> <.sep> <lambda_wrapper> ')'
    }
    token shape {
        'gt::sarray<int' <.sep> <dim> <.ws> '>'
    }
    token lambda_wrapper {
        'contract_wrapper::{lambda(int)$1}'
    }
    token gfunction {
        'gt::gfunction<' <op> <.sep> <expr1=.expr> <.sep> <expr2=.expr> <.ws> '>'
    }
    token span {
        'gt::gtensor_span<' <type> <.sep> <dim> <.sep> <space> <.ws> '>'
    }
    token dim {
        <dimnum> ['u' | 'ul']?
    }
    token space {
        'gt::space::' (['thrust' | 'host'])
    }
    token type {
        | <fp>
        | <integer>
        | <complex>
    }
    token fp {
        | 'float'
        | 'double'
    }
    rule complex {
        [ 'thrust::complex' | 'gt::complex' ] '<' <fp> '>'
    }
    token integer {
        | 'int'
        | 'unsigned int'
        | 'long'
        | 'unsigned long'
    }
    token op {
        'gt::ops::' <opname>
    }
    token opname {
        | 'multiply'
        | 'plus'
        | 'minus'
        | 'divide'
    }
    token gview {
        'gt::gview<' <span> <.sep> <dim> <.ws> '>'
    }
    rule sep { ',' }
}

class ShortenAction {
    method end($/) {}
    method fp($/) { make $/.Str eq 'double' ?? 'f64' !! 'f32' }
    method integer($/) {
        given $/.Str {
            when 'int'           { make 'i32' }
            when 'unsigned int'  { make 'u32' }
            when 'long'          { make 'i64' }
            when 'unsigned long' { make 'u64' }
        }
    }
    method complex($/) {
       given $<fp>.made {
           when 'f32' { make 'c32' }
           when 'f64' { make 'c64' }
       }
    }
    method type($/) {
        with $<fp> || $<integer> || $<complex> { make .made }
    }
    method dimnum($/) { make $/.Str }
    method dim($/) { make $<dimnum>.made }
    method opname($/) {
        given $/.Str {
            when 'plus'     { make '+' }
            when 'minus'    { make '-' }
            when 'multiply' { make '*' }
            when 'divide'   { make '/' }
        }
    }
    method op($/) { make $<opname>.made }
    method space($/) { make $/[0].Str }
    method gfunction($/) {
        given $<op>.made {
            when '*' {
                make "($<expr1>.made() $<op>.made() $<expr2>.made())"
            }
            default {
                make "$<expr1>.made() $<op>.made() $<expr2>.made()"
            }
        }
    }
    method span($/) { make "s$<dim>.made()D[$<type>.made()]" }
    method gview($/) { make "v$<dim>.made()$<span>.made()" }
    method assign($/) { make "$<lhs>.made() = $<rhs>.made()" }
    method expr($/) {
        with $/.hash.first { make .value.made }
    }
    method TOP($/) {
        with $/.hash.first { make .value.made }
    }
}

my $assign6d = 'gt::detail::kernel_assign_6<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > > >(gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::plus, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >, gt::gfunction<gt::ops::multiply, gt::gview<gt::gtensor_span<double, 6ul, gt::space::thrust>, 6ul>, gt::gview<gt::gtensor_span<thrust::complex<double>, 6ul, gt::space::thrust>, 6ul> > >)';

my @tests = [
  'gt::complex<float>',
  'gt::gtensor_span<thrust::complex<double>, 4ul, gt::space::thrust>',
  'gt::gview<gt::gtensor_span<thrust::complex<double>, 4ul, gt::space::thrust>, 4ul>',
  'gt::detail::kernel_assign_1<gt::gtensor_span<double, 1ul, gt::space::thrust>, gt::gtensor_span<double, 1ul, gt::space::thrust>>(gt::gtensor_span<double, 1ul, gt::space::thrust>, gt::gtensor_span<double, 1ul, gt::space::thrust>)',
  $assign6d,
];

for @tests -> $n {
    my $match = N.parse($n, :rule<TOP>, :actions(ShortenAction));
    #my $match = N.parse($n);
    if $match {
        say "=== '$n' ===";
        say $match.made;
        say "=================\n";
    } else {
        say "NOT OK $n";
    }
}
