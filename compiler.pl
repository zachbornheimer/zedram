#!/usr/local/bin/perl6

# Default variable assignments
# These are overidden by options parsed in the supplied grammar (unless it isn't supplied) 
my Str $GRAMMARDELIMITER = '->';
my Str $PARSERDELIMITER = ':';
my Str $LINEENDINGDELIMITER = '';
my Str $BLOCKDELIMITER = '{}';
my Str $CONCATENATIONSYMBOL = '.';
my Str $VARPREFIX = '$';
my Str $DEFAULTVARIABLE = '_';
my Str $WHITESPACEDELIMITER = '    ';

grammar zedram_grammar {
    rule TOP {
        <option>
            || <setting><grammarDelimiter><value>
    }
    rule identify_grammar_delimiter {
        'grammar_delimiter'
    }
    token option { <action>\s*<modification> }
    proto token action {*}
    token action:sym<use> { <sym> }
    proto token modification {*}
    token modification:sym<english_syntax> { english\s*syntax }
    proto token setting {*}
    token setting:sym<grammar_delimiter> { <sym>|<identify_grammar_delimiter> }
    token setting:sym<parser_delimiter> { <sym> }
    token setting:sym<line_ending_delimiter> { <sym> }
    token setting:sym<block_delimiter> { <sym> }
    token setting:sym<whitespace_delimiter> { <sym> }
    token setting:sym<concatenation_symbol> { <sym> }
    token setting:sym<var_prefix> { <sym> }
    token setting:sym<default_variable> { <sym> }
    token value {.*}
    token grammarDelimiter { $GRAMMARDELIMITER }
}

sub MAIN(:$grammarFile = 'grammar.zyg') {
    my @GRAMMAR_FILE;
    my $GRAMMAR_FILE = open $grammarFile, :r;
    for $GRAMMAR_FILE.lines -> $_ {
        push @GRAMMAR_FILE, $_;
    }
    $GRAMMAR_FILE.close;
    for @GRAMMAR_FILE -> $_ {
        chomp($_);
        if zedram_grammar.parse($_, :rule<identify_grammar_delimiter>) {
            $GRAMMARDELIMITER = get_delimiter($_);
            last;
        }
    }

    # After we have the grammar_delimiter, we should parse the settings
    for @GRAMMAR_FILE -> $_ {
        chomp($_);
        my $alpha = zedram_grammar.parse($_);
            if ($alpha<setting><sym>) { # if the setting is valid
                set_variable_using_token($alpha<setting><sym>, $alpha<value>); # override the default
            }
    }

}

sub get_delimiter ($line) {
    $line ~~ rx/<zedram_grammar::setting:sym<grammar_delimiter>>(.*)/;
    return ~($0).substr(0, ~($0).chars / 2);
}

sub set_variable_using_token ($token, $value) {
    my $t = ~($token);
    my $v = ~($value);
    $t = uc($t);
    $t ~~ s:g/_//;
    $v ~~ s:i/^NONE$//;
    $$t = $v; # Interpret the variable name as a variable and not a string.
}
