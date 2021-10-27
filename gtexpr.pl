#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
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

  <TOP=expr> | <TOP=assign> | <TOP=type>

  <rule: expr> <MATCH=gfunction> | <MATCH=span> | <MATCH=gview>
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

  <token: op1> gt::ops::(multiply | divide)
    <MATCH=(?{ $op_map{$CAPTURE} })>
  <token: op2> gt::ops::(plus | minus)
    <MATCH=(?{ $op_map{$CAPTURE} })>

  <rule: gfunction> <MATCH=gfunction1> | <MATCH=gfunction2>
  <rule: gfunction1> gt::gfunction\< <op1>, <expr1=expr>, <expr2=expr> \>
    <MATCH=(?{ "($MATCH{expr1} $MATCH{op1} $MATCH{expr2})" })>
  <rule: gfunction2> gt::gfunction\< <op2>, <expr1=expr>, <expr2=expr> \>
    <MATCH=(?{ "$MATCH{expr1} $MATCH{op2} $MATCH{expr2}" })>

  <rule: assign> gt::detail::kernel_assign_ <dimnum>
    \< <lhs=expr>, <rhs=expr> \> \( <alhs=expr>, <arhs=expr> \)
    <MATCH=(?{ "$MATCH{lhs} =$MATCH{dimnum} $MATCH{rhs}" })>
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
  'gt::detail::kernel_assign_4<gt::gtensor_span<thrust::complex<double>, 4ul, gt::space::thrust>, gt::gtensor_span<thrust::complex<double>, 4ul, gt::space::thrust>>(gt::gtensor_span<thrust::complex<double>, 4ul, gt::space::thrust>, gt::gtensor_span<thrust::complex<double>, 4ul, gt::space::thrust>)',
);

my $test = '';
GetOptions(
  'test' => \$test,
) or die("Error in command line arguments\n");

if ($test) {
  foreach ( @test_types, @test_exprs ) {
    if (/$parser/) {
      print "MATCH $_\n  => $/{TOP}\n";
      #print Dumper(%/), "\n";
    } else {
      print "NO MATCH $_\n";
    }
  }
} else {
  while (<>) {
    chomp;
    if (/$parser/) {
      print "MATCH $_\n  => $/{TOP}\n";
      #print Dumper(%/), "\n";
    } else {
      print "NO MATCH $_\n";
    }
  }
}
