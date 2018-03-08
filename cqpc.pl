#!/usr/bin/perl
$|++;

use strict;
use utf8;
use IPC::Open2;

my $pid = open2 my $out, my $in, "cqp -c -D CBF" or die "Could not open cqp";

my $search = 'brutal';
my $opened = <$out>;
#print "$opened";
#print $in "set AutoShow on;\n";
print $in "set Context 30;\n";
print $in "set PrintStructures 'text_id, text_gender, text_decade';\n";
print $in "sok = [word='$search' %c];\n";
print $in "size sok;\n";
my $numbhits = <$out>;
#print "$numbhits";
print $in "cat sok;\n";

my $result;
while (! ($result = <$out>))
{
}
print $result;
my @content = ();
push(@content, $result);
my $index = 0;
my $flag = 1;
for (my $ind = 1; $ind++; $ind <= $numbhits)
{
    chomp($result = <$out>);
    print "$result\n";
    push(@content, $result);
    $result = '';
    if ($ind >= $numbhits)
    {
#        print "$ind\n";
        last;
    }
}

print $in "exit;\n";
close($in);
close($out);

waitpid($pid, 0);
