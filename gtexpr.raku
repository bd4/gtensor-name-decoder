#!/usr/bin/env raku

grammar N {
    token TOP {
        | <assign>
        | <launch>
        | <expr>
        | <type>
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
    token complex {
        [ 'thrust' | 'gt' | 'std' ] '::complex<' [ <fp> | <integer> ] '>'
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
    method fp($/) { make $/.Str eq 'double' ?? 'F64' !! 'F32' }
    method integer($/) {
        given $/.Str {
            when 'int'           { make 'I32' }
            when 'unsigned int'  { make 'U32' }
            when 'long'          { make 'I64' }
            when 'unsigned long' { make 'U64' }
        }
    }
    method complex($/) {
        with $<fp> || $<integer> { make 'c' ~ .made }
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
            when '*' | '/' {
                make "($<expr1>.made() $<op>.made() $<expr2>.made())"
            }
            default {
                make "$<expr1>.made() $<op>.made() $<expr2>.made()"
            }
        }
    }
    method span($/) { make "s{$<dim>.made()}[$<type>.made()]" }
    method gview($/) { make "v{$<dim>.made()}{$<span>.made()}" }
    method assign($/) { make "$<lhs>.made() = $<rhs>.made()" }
    method expr($/) {
        with $/.hash.first { make .value.made }
    }
    method TOP($/) {
        with $/.hash.first { make .value.made }
    }
}

for $*ARGFILES.lines -> $n {
  my $match = N.parse($n, :rule<TOP>, :actions(ShortenAction));
  if $match {
      say "MATCH $n";
      say "  => ", $match.made;
  } else {
      say "NO MATCH $n";
  }
}
