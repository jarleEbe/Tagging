#!/usr/bin/perl

use strict;
use utf8;

my ($basePath) = @ARGV;

open(LEMMAS, ">treetagger-lemmas.txt");
binmode LEMMAS, ":utf8";

opendir(DS, $basePath) or die $!;
my %lemmas = ();
my $numFiles = 0;
while (my $txt = readdir(DS))
{
	if ($txt =~ /_tagged\.txt$/i)
	{
		$numFiles++;
		open(INN, "$basePath$txt");
		binmode INN, ":utf8";
		my @content = <INN>;
		close(INN);
		foreach my $line (@content)
		{
		    chomp($line);
            if ($line =~ /\t/)
            {
                my ($word, $pos, $lemma) = split/\t/, $line;
                $word = lc($word);
                $lemma = lc($lemma);
                if (($pos eq 'NNS' || $pos eq 'JJR' || $pos eq 'JJS' || $pos eq 'RBR' || $pos eq 'RBS' || $pos eq 'VBN' || $pos eq 'VBG' || $pos eq 'VBD' || $pos eq 'VBP' || $pos eq 'VBZ') && $lemma ne '<unknown>')
                {
                    my $initialPOS = substr($pos, 0, 1);
                    my $key = $word . "\t" . $initialPOS;
                    if (exists($lemmas{$key}))
                    {

                    }
                    else
                    {
                        $lemmas{$key} = "$word\t$pos\t$lemma";
                    }
                }
            }
        }
	}
}
close(DS);
my $lcount = 0;
foreach my $key (keys(%lemmas))
{
    print LEMMAS "$key\t$lemmas{$key}\n";
    $lcount++;
}
close(LEMMAS);
print "No. files processed: $numFiles\n";
print "No. of lemmas: $lcount\n";
exit;
