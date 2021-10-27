#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use Regexp::Grammars;

my %fp_map = (
    double => 'F64',
    float  => 'F32',
);

my %int_map = (
    int             => 'I32',
    long            => 'I64',
    'unsigned int'  => 'U32',
    'unsigned long' => 'U64',
);

my %op_map = (
    multiply => '*',
    divide   => '/',
    plus     => '+',
    minus    => '-',
);

my $parser = qr{
  <nocontext:>

  <expr>

  <rule: expr> (?: <MATCH=gfunction> | <MATCH=span> | <MATCH=gview> )

  <token: space> gt::space:: <MATCH=(?:device|host|thrust|cuda|hip)>

  <token: dimnum> [1-6]
  <rule: dim> <MATCH=dimnum> ul|u

  <rule: type> (?: <MATCH=complex> | <MATCH=fp> | <MATCH=integer> )

  <token: integer> (int | long | unsigned int | unsigned long)
    <MATCH=(?{ $int_map{$CAPTURE} })>
  <token: fp> (double | float)
    <MATCH=(?{ $fp_map{$CAPTURE}  })>
  <rule: complex> (?:gt|std|thrust)::complex\<
    (?: <stype=fp> | <stype=integer> ) \> <MATCH=(?{ "c$MATCH{stype}" })>

  <rule: span> gt::gtensor_span\< <type>, <dim>, <space> \> 
    <MATCH=(?{ "s$MATCH{dim}\[$MATCH{type}\]" })>

  <rule: gview> gt::gview \< <span>, <dim> \>
    <MATCH=(?{ "v$MATCH{dim}$MATCH{span}" })>

  <token: op> gt::ops::<MATCH=opname>
  <token: opname> (multiply | plus | minus | divide)
    <MATCH=(?{ $op_map{$CAPTURE} })>

  <rule: gfunction> gt::gfunction\< <op>, <expr1=expr>, <expr2=expr> \>
    <MATCH=(?{ "$MATCH{expr1} $MATCH{op} $MATCH{expr2}" })>
}x;

my @test_types = qw/
  double float int long
  std::complex<double> gt::complex<float>
  thrust::complex<int>
/;

my @test_exprs = (
  'gt::gtensor_span<thrust::complex<double>, 4ul, gt::space::thrust>',
  'gt::gview<gt::gtensor_span<thrust::complex<double>, 4ul, gt::space::thrust>, 3ul>',
  'gt::gfunction<gt::ops::plus, gt::gview<gt::gtensor_span<thrust::complex<double>, 4ul, gt::space::thrust>, 3ul>, gt::gtensor_span<thrust::complex<double>, 3ul, gt::space::thrust>>',
);

foreach ( @test_exprs ) {
    if (/$parser/) {
        print "MATCH $_ => $/{expr}\n";
    } else {
        print "NO MATCH $_\n";
    }
}
