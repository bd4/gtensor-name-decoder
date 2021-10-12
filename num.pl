#!/usr/bin/raku

grammar N {
    token TOP {
        <sign>?
        [
            | <value> <exp> <sign>? <digits>
            | <value>
        ]
    }
    token sign {
        '+' | '-'
    }
    token exp {
        'e' | 'E'
    }
    token digits {
        <digit>+ ['_' <digits>]?
    }
    token value {
        | <digits> '.' <digits>
        | '.' <digits>
        | <digits> '.'
        | <digits>
    }
}

for <1 42 123 1000 -3 +17 3.1415926535 .1 1. -.14 10E2 -1.2e3> -> $n {
    say N.parse($n) ?? "OK $n" !! "NOT OK $n";
}
