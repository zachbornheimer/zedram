#!/usr/local/bin/perl6
# Written by Z. Bornheimer (Zysys)
# The purpose of this module is to generate a parser for Zedram.
use v6;
use Zedram::Grammar;
use Zedram::Semantics;

sub escape($string) is export {
    my @metachars = '{}\\\/\'\"\?'.split('').uniq;
    my @str = $string.split('');
    for @str -> $_ is rw {
        for @metachars -> $meta {
            if ($meta eq $_) {
                $_ = ~('\\'  ~ $_);
                $_ ~~ s:g/\\\\/\\/;
            }
        }
    }
    return @str.join('');
}

class ZedramParser is ZedramGrammar is ZedramSemantics is export {
    has $.grammarFile;
    has $!zedramFilename;

    submethod BUILD(:$!grammarFile) {
        parse_grammar($!grammarFile) if $!grammarFile;
    }

    method test() {
        dispParams();
        return 1;
    }

    method expand($file) {

        # Purpose is to expand the compressed Zedram file
        # Add curly braces where necessary
        # Replace mappings,
        # compress blocks
        #   compress blocks so that they can be passes in analyze()
        #   analyze parses the keyword then the statement or block
        # split lines into an array where blocks create a multidimensional array
        # apply the framework to the expansion.

        $!zedramFilename = $file;
        my $f = slurp $!zedramFilename;

        $f ~~ s:g/<{~ParserProperty('LineEndingDelimiter')}>*(<{~escape(~ParserProperty('BlockDelimiter').substr(0, ~ParserProperty('BlockDelimiter').chars / 2 ))}>)<{~ParserProperty('LineEndingDelimiter')}>*/$0/;
        #$f ~~ s:g/<{~ParserProperty('LineEndingDelimiter')}>*(<{~escape(~ParserProperty('BlockDelimiter').substr(ParserProperty('BlockDelimiter').chars / 2 ))}>)<{~ParserProperty('LineEndingDelimiter')}>*/$0/;
        $f.say;

        # Add Semicolons at the end of blocks if they do not exist

        # Procedure for splitting:
        # Go through each character and look for the first half of the block delimiter
        # Store all characters up to the line delimiter.  Increment Array Index for each Line Delimiter.
        # If begin block, do not increment the index until close block.
        
        # Analyze blocks to determine if they are implementation of methods
        # Expand all non-blocks re: mappings
        # Expand all block internals re: mappings
        # Expand all non-blocks and blocks re methods
        # Expand loop blocks
        
        # Compile to Expanded Zedram

        
        my %constants;
        my %map;
        # store:
        # determine constants.zyc
        #for @contents {
            my $parsed = zedram_grammar_core.parse($f);
            # All methods for keywords presented will be executed
            #analyze($parsed, %map);
            #}
                say $parsed.perl;
        # get framework declaration
        #   get includes
        #   get methods
        #   build includes hash
        #   build methods replacement regex

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
