#!/usr/local/bin/perl6
# Written by Z. Bornheimer (Zysys)
# The purpose of this module is to describe the semantics of Zedram
use v6;
use Zedram::Grammar;

module Zedram::Semantics;

# Keyword? Call appropriate function
# Block? Compress and Process

# How to implement?  Class or Methods?

class ZedramSemantics is export {

    sub analyze($parsed, $map is rw) is export {
        my $hash = analyze-helper($parsed, %$map.item).item;
        $map = $hash.item if $hash;
    }

    sub analyze-helper($parsed is rw, $map is rw) {
        my $cmd = ~$parsed<statement><keyword>.orig if $parsed<statement><keyword>;
        if $cmd {
            $cmd ~~ s/^\s*//;
            my $commandString = $cmd.substr(1+($parsed<statement><keyword><sym>).chars);
            my $func = '&' ~ $parsed<statement><keyword><sym> ~ "('" ~ $commandString ~ "', " ~ $map.perl ~ ")"if $parsed<statement><keyword> && $parsed<statement><keyword>;
            my %alpha; # the new map
            try {
                    %alpha = $func.eval;
            }

            CATCH {
                # Function Most Likely Not Declared
                if $parsed<statement><keyword> ne Any {
                    say "No function declared for the keyword: " ~ ~$parsed<statement><keyword>;
                }
                CATCH { }
            }
            return %alpha;
        }
    }

    sub constants($command, $map) {
        my @constantFiles = getList($command);
        parseIntoHash($map.hash, $_) for @constantFiles;
        return $map;
    }

    sub getList($string) {
        return $string.split(ParserProperty('ListDelimiter'));
    }

    sub parseIntoHash(%hash is rw, $filename) {
        my %mapHash;
        my $file = slurp $filename if $filename.IO.e;
        if $file {
            my @lines = (~$file).split("\n");
            for @lines {
                if $_ {
                    my @linesplit = $_.split(ParserProperty('ParserDelimiter'));
                    my $key = @linesplit.shift;
                    my $value = ~(@linesplit.join(ParserProperty('ParserDelimiter')));
                    %hash{$key} = $value if $key && $value; 
                }
            }
        }
    }
}
