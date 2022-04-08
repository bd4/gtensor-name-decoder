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

  <TOP=expr> | <TOP=assign> | <TOP=type> | <TOP=scalar>

  <rule: expr> <MATCH=gfunction> | <MATCH=span> | <MATCH=gview> | <MATCH=scalar>
  <token: space> gt::space:: <MATCH=(?:device|host|thrust|cuda|hip|sycl)>

  <token: dimnum> [1-6]
  <rule: dim> \(<.integer>\) <MATCH=dimnum>
            | <MATCH=dimnum> ul
            | <MATCH=dimnum>

  <rule: type> (?:const)? (?: <MATCH=complex> | <MATCH=fp> | <MATCH=integer> )
    <.constref>

  <rule: integer> (int | long | unsigned int | unsigned long)
    <MATCH=(?{ $int_map{$CAPTURE} })>
  <token: fp> (double | float)
    <MATCH=(?{ $fp_map{$CAPTURE}  })>
  <rule: complex> (?:gt|std|thrust)::complex\<
    (?: <stype=fp> | <stype=integer> ) \> <MATCH=(?{ "c$MATCH{stype}" })>

  <rule: constref> (?:const)? (?:\&)?

  <rule: span> gt::gtensor_span\< <type>, <dim>, <space> \> <.constref>
    <MATCH=(?{ "s$MATCH{dim}\[$MATCH{type}\]" })>

  <rule: gview> gt::gview \< <span>, <dim> \> <.constref>
    <MATCH=(?{ "v$MATCH{dim}$MATCH{span}" })>

  <token: op1> gt::ops::(multiply | divide)
    <MATCH=(?{ $op_map{$CAPTURE} })>
  <token: op2> gt::ops::(plus | minus)
    <MATCH=(?{ $op_map{$CAPTURE} })>

  <rule: gfunction> (?: <MATCH=gfunction1> | <MATCH=gfunction2> ) <.constref>
  <rule: gfunction1> gt::gfunction\< <op1>, <expr1=expr>, <expr2=expr> \>
    <MATCH=(?{ "($MATCH{expr1} $MATCH{op1} $MATCH{expr2})" })>
  <rule: gfunction2> gt::gfunction\< <op2>, <expr1=expr>, <expr2=expr> \>
    <MATCH=(?{ "$MATCH{expr1} $MATCH{op2} $MATCH{expr2}" })>

  <rule: assign> <MATCH=assign1> | <MATCH=assign2>

  <rule: assign1> gt::detail::kernel_assign_ <dimnum>
    \< <lhs=expr>, <rhs=expr> \> \( <.expr>, <.expr> \)
    <MATCH=(?{ "$MATCH{lhs} =$MATCH{dimnum} $MATCH{rhs}" })>

  <rule: assign2> Assign<dimnum> \< <lhs=expr>, <rhs=expr>, <.expr>, <.expr> \>
    <MATCH=(?{ "$MATCH{lhs} =$MATCH{dimnum} $MATCH{rhs}" })>

  <rule: scalar> gt::gscalar\< <type> \>
    <MATCH=(?{ "[$MATCH{type}]" })>
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
