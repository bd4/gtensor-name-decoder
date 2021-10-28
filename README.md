# gtensor-name-decoder
Scripts to convert gtensor kernel names from profiler/debuggers to easier to read strings

## Requirements

For the Raku version, you will need a recent Raku implementation like
[Rakudo](https://rakudo.org/downloads). Tested with Rakudo 2021.9, may work
with older versions (but the version in Ubuntu LTS is likely too old).

For the Perl version, you will need Perl 5.10 or later and Regexp::Grammar
module. On ubuntu or debian:

```
$ sudo apt install libregexp-grammars-perl
```

## Usage

Both will take gtensor expressions as input in stdin or from files
specified on the command line. For example:

```
$ ./gtexpr.pl 
gt::gview<gt::gtensor_span<thrust::complex<double>, 4ul, gt::space::thrust>, 3ul>
MATCH gt::gview<gt::gtensor_span<thrust::complex<double>, 4ul, gt::space::thrust>, 3ul>
  => v3s4[cF64]
Ctrl+d
```

See [examples.txt](examples.txt) and [intel-advisor.txt](intel-advisor.txt).
The latter is for the SYCL backend collected with Intel Advisor (it has
slightly different templates and syntax).

gfunctions are replaced by inline binary ops, e.g. a gfunction for
`gt::ops::plus` will become `expr1 + expr2`. Expressions can only show the type
- the `gview` example above, `[cF64]` indicates complex double (64 bit floating
point), `s4[cF64]` indicates a 4D `gtensor_span` over complex double, and
`v3s4[cF64]` indicates a 3D view over that span. This should help track down
which expression in the source code maps to the region from the profiler,
absent more context from something like NVTX.

## Contributing

Other language versions welcome. A Python version in particular, ideally using
a pure Python module not a C extension module, would be helpful. Also turning
the example txt's into real tests would be useful.
