#!/usr/local/bin/perl6

# For now, this shall test the Zedram Modules (until the parser is complete);

use Zedram::Parser;

my $grammarFile = "examples/grammar.zyg";
my $testFile = "examples/html_doc.zdrm";

my $zedramParser = ZedramParser.new(:grammarFile($grammarFile));
$zedramParser.prep();
$zedramParser.test();
