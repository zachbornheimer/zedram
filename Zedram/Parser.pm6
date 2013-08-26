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

        # Everything is explained here: http://zysys.org/wiki/index.php/Zedram:_Dynamic_Parse_Trees

        # Purpose is to expand the compressed Zedram file
        # Add curly braces where necessary
        # Add parentheses for methods if omitted
        # Replace mappings,
        # compress blocks
        #   compress blocks so that they can be passes in analyze()
        #   analyze parses the keyword then the statement or block
        # split lines into an array where blocks create a multidimensional array
        # apply the framework to the expansion.

        $!zedramFilename = $file;
        my $f = slurp $!zedramFilename;

        if ~ParserProperty('BlockDelimiter') ne 'WHITESPACE' {
            #$f ~~ s:g/<{~ParserProperty('LineEndingDelimiter')}>*(<{~escape(~ParserProperty('BlockDelimiter').substr(0, ~ParserProperty('BlockDelimiter').chars / 2 ))}>)<{~ParserProperty('LineEndingDelimiter')}>*/$0/;
            #$f ~~ s:g/<{~ParserProperty('LineEndingDelimiter')}>/;/; # use semicolons to allow for merging of lines in blocks;
            #while ( $f ~~ s:g/\s\s/ / ) { 1 }; # remove supurflous spaces

            my @tree = assemble_parse_tree($f);
            say @tree.perl;
            $f.say;
        }


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

    sub assemble_parse_tree($code) {
        # Space is the delimiter
        # if block, open an array
        # if close block, close array

        my @tree;
        my @blockReferences;

        # We are going move all blocks to @blockReferences and replace them with
        # literal substitutions of @blockReferences[i] where i is the index.
        # The purpose of this is to simplify parsing trees down to replacing blocks with static
        #   refs to those blocks to allow for top level parsing and then we can keep parsing each block
        #   reference until there are no blocks left to parse.

        my $codeToParse = $code;
        say $code.perl;
        my $codeToParseIndex = 0;
        my $blockReferencesIndex = 0;
        my @codeToParse;
        {
            my @chars = $codeToParse.split('');
            my $addToBlock = 0;
            for 0 .. @chars.elems - 1 {
                if @chars[0] eq ~ParserProperty('LineEndingDelimiter') {
                    if $addToBlock {
                        @blockReferences[$blockReferencesIndex] ~= @chars[0];
                    } else {
                        @codeToParse[$codeToParseIndex] ~= @chars[0];
                    }
                    $codeToParseIndex += 1;
                } elsif @chars[0] eq ~ParserProperty('BlockDelimiter').substr(0,~ParserProperty('BlockDelimiter').chars/2) {
                    $addToBlock = 1;
                    @codeToParse[$codeToParseIndex] ~= '@blockReferences['~$blockReferencesIndex~']';
                    @blockReferences[$blockReferencesIndex] ~= @chars[0];
                } elsif @chars[0] eq ~ParserProperty('BlockDelimiter').substr(~ParserProperty('BlockDelimiter').chars/2) {
                    $addToBlock = 0;
                    @blockReferences[$blockReferencesIndex] ~= @chars[0];
                    $blockReferencesIndex += 1;
                } else {
                    if $addToBlock {
                        @blockReferences[$blockReferencesIndex] ~= @chars[0];
                    } else {
                        @codeToParse[$codeToParseIndex] ~= @chars[0];
                    }
                }
                shift @chars;
            }
        }

        # INCOMPLETE!

        say @codeToParse.perl;
        say @blockReferences.perl;
        return @tree;
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
