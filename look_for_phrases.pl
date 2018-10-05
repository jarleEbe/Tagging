#!/usr/bin/perl

use strict;
use utf8;

#E.g. prepdata/
my ($basePath) = @ARGV;

my $inputfile = "phrases3.txt";
open(INN, "$inputfile");
binmode INN, ":utf8";
my @tempcontent = <INN>;
close(INN);
my @phrases = ();
my $numphrases = 0;
foreach (@tempcontent)
{
	chomp;
	my @row = split/ /;
	if ($#row > 2) #2 = four items/words
	{
#		s/^X /\(.+\) /;
#		s/ X / \(.+\) /g;
#		print "$_\n";
		push(@phrases, $_);
		$numphrases++;
	}
}
print "Number of phrases: $numphrases\n";
#exit;
opendir(DS, $basePath) or die $!;
my $numFiles = 0;
my $numhits = 0;
my $outputfile = "all_hits_phrases.txt";
open(OUT, ">$outputfile");
binmode OUT, ":utf8";
while (my $txt = readdir(DS))
{
	if ($txt =~ /\.txt$/i)
	{
		$numFiles++;
		open(INN, "$basePath$txt");
		binmode INN, ":utf8";
		my @content = <INN>;
		close(INN);
		print "$txt\n";
		my $clause = ' ';
		$txt =~ s/_clean_cwb\.txt$//;
		$txt =~ s/_cwb\.txt$//;
		foreach my $line (@content)
		{
		    chomp($line);
			if ($line !~ /<\/s>/ && $line !~ /<s>/)
			{
				if ($line =~ /\t/)
				{
					my @rad = split/\t/, $line;
					my $item = $rad[2];
					$clause = $clause . $item . ' ';
				}
			}
			elsif ($line =~ /<s>/)
			{
				$clause = ' ';
			}
			elsif ($clause ne '' && $clause ne ' ')
			{
				if ($clause =~ / my / || $clause =~ / your / ||$clause =~ / their / ||$clause =~ / his / ||$clause =~ / her / ||$clause =~ / its / )
				{
					$clause =~ s/ my / one /g;
					$clause =~ s/ your / one /g;
					$clause =~ s/ their / one /g;
					$clause =~ s/ his / one /g;
					$clause =~ s/ her / one /g;
					$clause =~ s/ its / one /g;
				}
				foreach my $phrase (@phrases)
				{
#					my $pattern = "([^ ]+) ";
#					$phrase =~ s/^X /$pattern/;
#					$pattern = " ([^ ]+) ";
#					$phrase =~ s/ X /$pattern/;
					if ($clause =~ /$phrase/i)
					{
						print OUT "$phrase\t$clause\t$txt\n";
						$numhits++;
						last;
					}
				}
				$clause = ' ';
			}
		}
	}
}
close(OUT);
close(DS);
print "Number of files: $numFiles\n";
print "Number of hits: $numhits\n";
exit;
