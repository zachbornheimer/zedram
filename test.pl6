my $f = 'constants constants.zyc,externconst.zyc\nframework html_doc \{\n    include javascript javascript.js\n  ';

$f ~~ s/(<{ParserProperty('alsdfkj')}>)\\n*/$0/;
$f.say;

sub ParserProperty($s) {
return '\{|\}';
}
