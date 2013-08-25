#!/usr/local/bin/perl6

# For now, this shall test the Zedram Modules (until the parser is complete);

use Zedram::Parser;

#my $grammarFile = "examples/grammar.zyg";
my $testFile = "examples/html_doc.zdrm";

#my $zedramParser = ZedramParser.new(:grammarFile($grammarFile));
my $zedramParser = ZedramParser.new();
escape('test');
$zedramParser.test();

# Eventually:
$zedramParser.expand($testFile);
# # Compiler!
# $zedramParser.compileTo("html"); # or $zedramParser.compileTo("xml");
