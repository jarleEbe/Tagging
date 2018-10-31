#!/usr/bin/perl

use strict;
use utf8;
use JSON;

my ($infile, $outfile) = @ARGV;

open(CBF, "/var/www/cgi-bin/cbf/cbf.json");
my @content = <CBF>;
close(CBF);
my $cbf = '';
foreach (@content)
{
	chomp;
	$cbf = $cbf . $_;
}
my $jsonperl = decode_json($cbf);
#print $jsonperl->{'Texts'}->{'pg46693'}->{'Gender'};
#print "\n";
#foreach my $dec (@totwords)
#{
#}

open(INN, "$infile");
binmode INN, ":utf8";
my @content = <INN>;
close(INN);

open(OUT, ">$outfile");
binmode OUT, ":utf8";

my %collapsedPhrases = ();
foreach my $line (@content)
{
    chomp($line);
	my ($phrase, $context, $textcode, $author, $title, $YofB, $gender, $YofP, $decade) = split/\t/, $line;
	my $period = '';

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

	if (exists($collapsedPhrases{$textcode}))
	{
		if (exists($collapsedPhrases{$textcode}{$phrase}))
		{
			my $temp = $collapsedPhrases{$textcode}{$phrase};
			$temp++;
			$collapsedPhrases{$textcode}{$phrase} = $temp;
		}
		else
		{
			$collapsedPhrases{$textcode}{$phrase} = 1;
		}
		my $temp = $collapsedPhrases{$textcode}{'total'};
		$temp++;
		$collapsedPhrases{$textcode}{'total'} = $temp;
	}
	else
	{
		$collapsedPhrases{$textcode}{$phrase} = 1;
		$collapsedPhrases{$textcode}{'total'} = 1;
	}
}

foreach my $outerkey (sort(keys(%collapsedPhrases)))
{
	foreach my $innerkey (keys %{$collapsedPhrases{$outerkey}})
	{
#		print OUT "$outerkey\t$innerkey\t$collapsedPhrases{$outerkey}{$innerkey}\n";
		if ($innerkey eq 'total')
		{
			my $period = '';
			my $decade = $jsonperl->{'Texts'}->{$outerkey}->{'Decade'};
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
			print OUT "$outerkey\t$collapsedPhrases{$outerkey}{$innerkey}\t";
			print OUT "$jsonperl->{'Texts'}->{$outerkey}->{'Gender'}\t";
			print OUT "$jsonperl->{'Texts'}->{$outerkey}->{'Decade'}\t";
			print OUT "$period\t";
			print OUT "$jsonperl->{'Texts'}->{$outerkey}->{'noWords'}\t";

			my $nowords = $jsonperl->{'Texts'}->{$outerkey}->{'noWords'};
			my $totphrases = $collapsedPhrases{$outerkey}{$innerkey};
			my $permill = ($totphrases / $nowords) * 100000;
			my $rounded = sprintf("%.0f", $permill);
			print OUT "$rounded\n";
			#print OUT "$totphrases\n";
		}
#		if ($innerkey =~ /-/)
#		{
#			my $permill = 0;
#			if ($innerkey eq '1900-1939')
#			{
#				my $temp = $collapsedPhrases{$outerkey}{$innerkey};
#				$permill = ($temp / $P1) * 1000000;				
#			}
#			if ($innerkey eq '1940-1979')
#			{
#				my $temp = $collapsedPhrases{$outerkey}{$innerkey};
#				$permill = ($temp / $P2) * 1000000;				
#			}
#			if ($innerkey eq '1980-2019')
#			{
#				my $temp = $collapsedPhrases{$outerkey}{$innerkey};
#				$permill = ($temp / $P3) * 1000000;				
#			}
#			if ($permill >= 5)
#			{
#				my $rounded = sprintf("%.0f", $permill);
#				print PERIOD "$outerkey\t$innerkey\tpmw\t$rounded\n";
#			}
#		}
	}
}
close(OUT);
exit;
