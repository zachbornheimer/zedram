#!/usr/local/bin/perl6
# The purpose of this module is to generate a parser for Zedram.
use v6;
use Zedram::Grammar;

class ZedramParser is ZedramGrammar is export {
    has $.grammarFile;

    method prep() {
        parse_grammar($.grammarFile);
        return 1;
    }

    method test() {
        dispParams();
        return 1;
    }


    sub parse_grammar($grammarFile) {
        my @GRAMMAR_FILE;
        @GRAMMAR_FILE = lines slurp $grammarFile;

        for @GRAMMAR_FILE {
            chomp($_);
            if zedram_grammar_grammar.parse($_, :rule<identify_grammar_delimiter>) {
                GrammarDelimiter(get_delimiter($_));
                last;
            }
        }

        # After we have the grammar_delimiter, we should parse the settings
        for @GRAMMAR_FILE {
            chomp($_);
            my $alpha = zedram_grammar_grammar.parse($_);
            if ($alpha<setting><sym>) { # if the setting is valid
                change_parser_using_token($alpha<setting><sym>, $alpha<value>); # override the default
            }
        }
    }

    sub dispParams() {
        my @grammarUnits = ('GrammarDelimiter', 'ParserDelimiter', 'LineEndingDelimiter', 'BlockDelimiter', 'Concatenate', 'VarPrefix', 'DefaultVariable');
        for @grammarUnits { 
            if defined ParserProperty($_) {
                say $_ ~ ParserProperty($_);
            }
        }
    }

    sub get_delimiter ($line) {
        $line ~~ rx/<zedram_grammar_grammar::setting:sym<grammar_delimiter>>(.*)/;
        return ~($0).substr(0, ~($0).chars / 2);
    }
    
    # This returns the variable name so it can be appended to an array and exported out of the module.
    sub change_parser_using_token ($token, $value) {
        my $t = ~($token);
        my $v = ~($value);
        $t = lc($t);
        $t ~~ s:g/^(.)/{ uc($0) }/;
        $t ~~ s:g/_(.)/{ uc($0) }/;
        $t ~~ s:g/_//;
        $v ~~ s:i/NONE$//;
        ParserProperty($t, $v);
    }
}