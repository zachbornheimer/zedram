#!/usr/local/bin/perl6
# The purpose of this module is to generate a parser for Zedram.
use v6;
use Zedram::Grammar;

class ZedramParser is ZedramGrammar is export {
    has $.grammarFile;
    has $!zedramFilename;

    method prep() {
        parse_grammar($!grammarFile);
        return 1;
    }

    method test() {
        dispParams();
        return 1;
    }

    method read($file) {
        $!zedramFilename = $file;
        my @contents = lines slurp $!zedramFilename;
        my %constants;
        my %map;
        # store:
        # determine constants.zyc
        for @contents {
            my $parsed = zedram_grammar_core.parse($_);
            if $parsed<statement><keyword> && $parsed<statement><keyword> eq 'constants' {
                my $constString = $parsed<statement><keyword>.orig;
                my @files = $constString.split(ParserProperty('ListDelimiter'));
                @files[0] ~~ s/^.*?\://;
                for @files {
                    parseIntoHash(%constants.item, $_);
                }
            }
        }
        # get framework declaration
        #   get includes
        #   get methods
        #   build includes hash
        #   build methods replacement regex

    }

    sub parseIntoHash($hash, $filename) {
        my $file = slurp $filename if $filename.IO ~~ :e;
        if $file {
            my @lines = $file.split(ParserProperty('LineEndingDelimiter'));
            for @lines {
                $hash{$_.split(ParserProperty('ParserDelimiter'))[0]} = $_.split(ParserProperty('ParserDelimiter'))[1];
            }
        }
    }

    method compileTo($lang) {
        # XML and HTML so far
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
                say $alpha<value>;
                change_parser_using_token($alpha<setting><sym>, $alpha<value>); # override the default
            }
        }
    }

    sub dispParams() {
        my @grammarUnits = ('GrammarDelimiter', 'ParserDelimiter', 'LineEndingDelimiter', 'BlockDelimiter', 'Concatenate', 'VarPrefix', 'DefaultVariable', 'ListDelimiter');
        for @grammarUnits { 
            if defined ParserProperty($_) {
                say $_ ~ GrammarDelimiter() ~ ParserProperty($_);
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
        $_ = GrammarDelimiter();
        ParserProperty($t, $v.substr(($_.chars/2)+1));
    }
}
