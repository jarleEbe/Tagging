#!/usr/bin/perl

use strict;
use utf8;

#E.g. cwbdata/
my ($basePath) = @ARGV;

#<text id="WilGol1" gender="male" decade="1950">
#<s>
#one	MC1	one
#THE	AT	the
#See https://perlmaven.com/multi-dimensional-hashes
open(COUNTS, "/var/www/cgi-bin/cbf/cbfdecades.csv");
my @totwords = <COUNTS>;
close(COUNTS);
my $P1 = 0;
my $P2 = 0;
my $P3 = 0;
my $PALL = 0;
foreach my $dec (@totwords)
{
	my ($tiaar, $antord) = split/,/, $dec;
	if (int($tiaar) >= 1900 && int($tiaar < 1940))
	{
		$P1 = $P1 + $antord;
	}
	elsif (int($tiaar) >= 1940 && int($tiaar < 1980))
	{
		$P2 = $P2 + $antord;
	}
	elsif (int($tiaar) >= 1980 && int($tiaar < 2020))
	{
		$P3 = $P3 + $antord;
	}
	$PALL = $PALL + $antord;
}
print "Totalt antall ord: $PALL\n";

opendir(DS, $basePath) or die $!;
my $numFiles = 0;
my %verbhasj = ();
my $verbsfile = "all_cbf-verbs.txt";
open(VERBS, ">verbcounts/$verbsfile");
binmode VERBS, ":utf8";
my $periodsfile = "period_all_cbf-verbs.txt";
open(PERIOD, ">verbcounts/$periodsfile");
binmode PERIOD, ":utf8";
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
		my $gender = '';
		my $decade = '';
		my $period = '';
		foreach my $line (@content)
		{
		    chomp($line);
			if ($line =~ /<text id/)
			{
				my @temptable = split/ /, $line;
				$gender = $temptable[2];
				$gender =~ s/gender="//;
				$gender =~ s/"//;
				$decade = $temptable[3];
				$decade =~ s/decade="//;
				$decade =~ s/">//;
				if (int($decade) >= 1900 && int($decade < 1940))
				{
					$period = "1900-1939"
				}
				elsif (int($decade) >= 1940 && int($decade < 1980))
				{
					$period = "1940-1979"
				}
				elsif (int($decade) >= 1980 && int($decade < 2020))
				{
					$period = "1980-2019"
				}
				print "$gender, $decade, $period\n";
			}
			if ($line =~ /\t/)
			{
				my ($word, $pos, $lemma) = split/\t/, $line;
				if ($pos =~ /^V/)
				{
					if ($lemma =~ /'/ || $lemma =~ /\//)
					{
					}
					else
					{
						my $genderverb = $gender;
						my $decadeverb = $decade;
						my $periodverb = $period;
						if (exists($verbhasj{$lemma}))
						{
							if (exists($verbhasj{$lemma}{$genderverb} ))
							{
								my $temp = $verbhasj{$lemma}{$genderverb};
								$temp++;
								$verbhasj{$lemma}{$genderverb} = $temp;
							}
							else
							{
								$verbhasj{$lemma}{$genderverb} = 1;
							}

							if (exists($verbhasj{$lemma}{$decadeverb} ))
							{
								my $temp = $verbhasj{$lemma}{$decadeverb};
								$temp++;
								$verbhasj{$lemma}{$decadeverb} = $temp;
							}
							else
							{
								$verbhasj{$lemma}{$decadeverb} = 1;
							}

							if (exists($verbhasj{$lemma}{$periodverb} ))
							{
								my $temp = $verbhasj{$lemma}{$periodverb};
								$temp++;
								$verbhasj{$lemma}{$periodverb} = $temp;
							}
							else
							{
								$verbhasj{$lemma}{$periodverb} = 1;
							}
							my $temp = $verbhasj{$lemma}{'total'};
							$temp++;
							$verbhasj{$lemma}{'total'} = $temp;
						}
						else
						{
							$verbhasj{$lemma}{$genderverb} = 1;
							$verbhasj{$lemma}{$decadeverb} = 1;
							$verbhasj{$lemma}{$periodverb} = 1;
							$verbhasj{$lemma}{'total'} = 1;
						}
					}
				}
			}
		}
	}
}
close(DS);
print "No. files processed: $numFiles\n";

foreach my $outerkey (sort(keys(%verbhasj)))
{
	foreach my $innerkey (keys %{$verbhasj{$outerkey}})
	{
		print VERBS "$outerkey\t$innerkey\t$verbhasj{$outerkey}{$innerkey}\n";
		if ($innerkey eq 'total')
		{
			my $temp = $verbhasj{$outerkey}{$innerkey};
			my $permill = ($temp / $PALL) * 1000000;
			my $rounded = sprintf("%.0f", $permill);
			print VERBS "$outerkey\tpmw\t$rounded\n";
		}
		if ($innerkey =~ /-/)
		{
			my $permill = 0;
			if ($innerkey eq '1900-1939')
			{
				my $temp = $verbhasj{$outerkey}{$innerkey};
				$permill = ($temp / $P1) * 1000000;				
			}
			if ($innerkey eq '1940-1979')
			{
				my $temp = $verbhasj{$outerkey}{$innerkey};
				$permill = ($temp / $P2) * 1000000;				
			}
			if ($innerkey eq '1980-2019')
			{
				my $temp = $verbhasj{$outerkey}{$innerkey};
				$permill = ($temp / $P3) * 1000000;				
			}
			if ($permill >= 5)
			{
				my $rounded = sprintf("%.0f", $permill);
				print PERIOD "$outerkey\t$innerkey\tpmw\t$rounded\n";
			}
		}
	}
}
close(VERBS);
close(PERIOD);
exit;
