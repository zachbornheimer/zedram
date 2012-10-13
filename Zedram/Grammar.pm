#!/usr/local/bin/perl6
# The purpose of this module is to define the grammar for Zedram.
use v6;
module Zedram::Grammar;

class ZedramGrammar is export {
    our %ParserProperties is export;

# Default variable assignments
# These are overidden by options parsed in the supplied grammar (unless it isn't supplied) 
    GrammarDelimiter('->');
    ParserProperty('ParserDelimiter', ':');
    ParserProperty('LineEndingDelimiter', '');
    ParserProperty('BlockDelimiter', '{}');
    ParserProperty('ConcatenationSymbol', '.');
    ParserProperty('VarPrefix', '$');
    ParserProperty('DefaultVariable', '_');
    ParserProperty('WhitespaceDelimiter', '    ');

    sub ParserProperty($property, $value?) is export {
        %ParserProperties{$property} = $value if $value;
        return %ParserProperties{$property}; 
    }

    sub GrammarDelimiter($value?) is export {
        ParserProperty('GrammarDelimiter', $value) if $value;
        return ParserProperty('GrammarDelimiter');
    }

    grammar zedram_grammar_grammar is export {
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
        token grammarDelimiter { {ParserProperty('GrammarDelimiter')} }
    }
}
