#!/usr/bin/perl

use strict;
use utf8;

my ($basePath, $resultPath) = @ARGV;
#my $resultPath = $basePath;
#$resultPath =~ s/test/result/;

opendir(DS, $basePath) or die $!;
my $numFiles = 0;
while (my $txt = readdir(DS))
{
	if ($txt =~ /\.txt$/i)
	{
		$numFiles++;
		open(INN, "$basePath$txt");
		binmode INN, ":utf8";
		my @content = <INN>;
		close(INN);
		my $outputfile = $txt;
		$outputfile =~ s/\.txt/_tokenized\.txt/;
		open(OUT, ">$resultPath$outputfile");
		binmode OUT, ":utf8";
		print "Tokenizing $txt\n";
		my $lineindex = 0;
        my $thewholetext = '';
		my $flag = 0;
		my $ind = -1;
		foreach my $line (@content)
		{
		    chomp($line);
			$line =~ s/^\x{FEFF}//;
			$line =~ s/\x{000B}//g;

			$line =~ s/<([^>]+?)>//g;
			$line =~ s/^\s+//;
			$line =~ s/\s+$//;
			if ($line ne '')
			{
				$ind++;
			}

			if ( ($line =~ /^(Prologue|PROLOGUE)$/ || $line =~ /^(Book|BOOK) / || $line =~ /^(Chapter|CHAPTER) / || $line =~ /^(Part|PART) / || $line =~ /^([I]+)$/ || $line =~ /^([XIV])$/ || $line =~ /^\d+$/) && ($line =~ /(\p{isAlnum})$/) )
			{
				$line = ' <s> ' . $line . ' </s> ';
#				print "1: $line\n";
				$flag = 1;
			}
			elsif ($line eq lc('the end'))
			{
				$line = ' <s> ' . $line . ' </s> ';
			}
#			elsif ( ($ind == 1 || $flag == 1) && $line =~ /[^.!?,;<>":]/)
#			{
#				$line = ' <s> ' . $line . ' </s> ';	
#				print "2: $line\n";
			else
			{
				$flag = 0;
			}
			$line =~ s/(\p{isAlnum})_(\p{isAlnum})/$1$2/g;
			$line =~ s/_/ /g;
			$line =~ s/\*//g;
			$line =~ s/\|//g;

			$line =~ s/--/–/g;
			$line =~ s/−/–/g;
			$line =~ s/–/–/g;
			$line =~ s/&mdash;/–/g;
			$line =~ s/&dash;/–/g;
			$line =~ s/—/–/g;
			$line =~ s/–/ – /g;

			$line =~ s/“/"/g;
			$line =~ s/”/"/g;

			$line =~ s/‘/'/g;
			$line =~ s/’/'/g;
			$line =~ s/´/'/g;
			$line =~ s/`/'/g;
			$line =~ s/ʻ/'/g;
			$line =~ s/ʼ/'/g;

			$line =~ s/…/\.\.\./g;
			$line =~ s/�/ /g;

			$line =~ s/ \s+/ /g;

			$lineindex++;
			my $alphanum = '';
			my @tokenArr = ();
			my $char = '';
			my $preceding = '';
			my $following = '';
			my $follow2 = '';
			my $follow3 = '';
			my $follow4 = '';
			my @unit = split//, $line;
			for (my $ind = 0; $ind <= $#unit; $ind++)
			{
				$char = $unit[$ind];
				if ($ind <= $#unit)
				{
					$following = $unit[$ind + 1];
				}
				else
				{
					$following = '';
				}
				if (($ind + 1) <= $#unit) #Contracted 's, 'd, 'm
				{
					$follow2 = $unit[$ind + 2];
				}
				else
				{
					$follow2 = '';
				}
				if (($ind + 2) <= $#unit) #Contracted 'll, 're, 've
				{
					$follow3 = $unit[$ind + 3];
				}
				else
				{
					$follow3 = '';
				}
				if (($ind + 4) <= $#unit) #Contracted 'tis
				{
					$follow4 = $unit[$ind + 4];
				}
				else
				{
					$follow4 = '';
				}
				if ($char =~ /[\t\n\f\r\p{IsZ}]/) #White space
				{
					if ($alphanum ne '')
					{
						push(@tokenArr, $alphanum);
						$alphanum = '';
					}
#					push(@tokenArr, ' ');
				}
				elsif ($char =~ /\p{isAlnum}/ || ($char eq '-' && $preceding =~ /\p{isAlnum}/) ) #Hyphenated words
				{
#					print "$alphanum : $char\n";
					$alphanum = $alphanum . $char;
				}
				elsif ($char eq "'") #Genitive and contracted forms
				{
#					print "$char : $following : $follow2 : $ind : $#unit\n";
					if ( ($following =~ /[dms]/i) && ( ($follow2 eq ' ') || (($ind + 1) == $#unit) )) #'d, 'm, 's
					{
							$alphanum = $alphanum . $char;	
					}
					elsif ( ( ($following =~ /[l]/i) && ($follow2 =~ /[l]/i) ) || ( ($following =~ /[r]/i) && ($follow2 =~ /[e]/i) ) || ( ($following =~ /[v]/i) && ($follow2 =~ /[e]/i) ) && ( ($follow3 eq ' ') || (($ind + 2) == $#unit) )) #'ll, 're, 've
					{
							$alphanum = $alphanum . $char;
					}
					elsif ( ($following =~ /[t]/i) && ($follow2 =~ /[i]/i) && ($follow3 =~ /[s]/i) && ( ($follow4 eq ' ') || (($ind + 3) == $#unit) )) #'tis
					{
							$alphanum = $alphanum . $char;
					}
					elsif ($ind >= 0 && $preceding =~ /\p{isAlnum}/ && $following =~ /\p{isAlnum}/)
					{
						$alphanum = $alphanum . $char;
					}
					else
					{
						if ($alphanum ne '')
						{
							push(@tokenArr, $alphanum);
							$alphanum = '';
						}
#						push(@tokenArr, $char);
						push(@tokenArr, '"'); #DETTA BLIR FEIL VED f.eks. evenin'
					}
				}
				else
				{
#					print "$alphanum : $char\n";
					if ($alphanum ne '')
					{
						push(@tokenArr, $alphanum);
						$alphanum = '';
					}
					push(@tokenArr, $char);
				}
				$preceding = $char;
			}
			if ($alphanum ne '')
			{
				push(@tokenArr, $alphanum);
			}
			foreach my $token (@tokenArr)
			{
                $thewholetext = $thewholetext . "$token ";
#				print OUT "$token ";
			}
		}
        $thewholetext =~ s/ '([A-Za-z]{1,4}) /'$1 /g; #For the benefit of the tagger
        $thewholetext =~ s/ 'd 've /'d've /g; #For the benefit of the tagger
        $thewholetext =~ s/ (CA|ca|Ca) n't / $1n't /g; #For the benefit of the tagger
        $thewholetext =~ s/ (SHA|sha|Sha) n't / $1n't /g; #For the benefit of the tagger
        $thewholetext =~ s/ (MUS|mus|Mus) n't / $1n't /g; #For the benefit of the tagger
        $thewholetext =~ s/,'tis/, 'tis/g; #For the benefit of the tagger
        $thewholetext =~ s/([a-z]{1,1})'tis/$1 'tis/g; #For the benefit of the tagger
        $thewholetext = &sInsert($thewholetext);
        print OUT $thewholetext;
        close(OUT);
	}
}
close(DS);
print "No. files processed: $numFiles\n";
exit;

sub sInsert
{
    my $thetext = shift(@_);

	$thetext =~ s/ \s+/ /g;

	$thetext =~ s/(\.|\?|\!) ([[:upper:]]{1})/$1 <\/s> <s> $2/g;
	$thetext =~ s/ § (\p{Alnum})/ <\/s> <s> § $1/g;

	$thetext =~ s/(\.|\?|\!\–) " ([[:upper:]]{1})/$1 " <\/s> <s> $2/g;
	$thetext =~ s/(\.) \] ([[:upper:]]{1})/$1 \] <\/s> <s> $2/g;
	$thetext =~ s/ : ([[:upper:]]{1})/ : <\/s> <s> $1/g;
	$thetext =~ s/ : " ([[:upper:]]{1})/ : <\/s> <s> " $1/g;

	$thetext =~ s/(\.|\?|\!) \) ([[:upper:]]{1})/$1 \) <\/s> <s> $2/g;
	$thetext =~ s/(\.|\?|\!) \( ([[:upper:]]{1})/$1 <\/s> <s> \( $2/g;

	$thetext =~ s/(\.|\?|\!) " \( " ([[:upper:]]{1})/$1 " <\/s> <s> \( " $2/g;
	$thetext =~ s/(\.|\?|\!) " \( ([[:upper:]]{1})/$1 " <\/s> <s> \( $2/g;
	$thetext =~ s/(\.|\?|\!) " \) ([[:upper:]]{1})/$1 " \) <\/s> <s> $2/g;
	$thetext =~ s/(\.|\?|\!) \) " ([[:upper:]]{1})/$1 \) <\/s> <s> " $2/g;

	$thetext =~ s/(\.|\?|\!|\–) " " " ([[:upper:]]{1})/$1 " " <\/s> <s> " $2/g;
	$thetext =~ s/(\.|\?|\!|\–) " " ([[:upper:]]{1})/$1 " <\/s> <s> " $2/g;

	$thetext =~ s/(\.|\?|\!) " " '([T]{1})/$1 " <\/s> <s> " '$2/g;
	$thetext =~ s/(\.|\?|\!) " '([T]{1})/$1 " <\/s> <s> '$2/g;

	$thetext =~ s/(\.|\?|\!) " "'(Tis)/$1 " <\/s> <s> " '$2/g;
	$thetext =~ s/(\.|\?|\!) "'(Tis) /$1 " <\/s> <s> '$2 /g;
	$thetext =~ s/(\.|\?|\!)'(Tis) /$1 <\/s> <s> '$2 /g;
	
	$thetext =~ s/(\.|\?|\!)'(Read) /$1 <\/s> <s> " $2 /g;

	$thetext =~ s/(\.|\?|\!) " " ([0-9]{1})/$1 " <\/s> <s> " $2/g;

#	$thetext =~ s/([0-9]{1}) \. \. \. ([[:lower:]]{1})/$1 <\/s> <s> \. \. \. $2/g;
	$thetext =~ s/([0-9]{1}) \. ([[:upper:]]{1})/$1 \. <\/s> <s> $2/g;
	$thetext =~ s/([0-9]{1}) \. " ([[:upper:]]{1})/$1 \. <\/s> <s> " $2/g;

#Abbreviations - remove <s> </s>
   $thetext =~ s/Mr \. <\/s> <s>/Mr\. /g; 
   $thetext =~ s/Mrs \. <\/s> <s>/Mrs\. /g;
   $thetext =~ s/Ms \. <\/s> <s>/Ms\. /g;
   $thetext =~ s/MR \. <\/s> <s>/Mr\. /g; 
   $thetext =~ s/MRS \. <\/s> <s>/Mrs \. /g;
   $thetext =~ s/MS \. <\/s> <s>/Ms\. /g;
   $thetext =~ s/St \. <\/s> <s>/St\. /g;
   $thetext =~ s/Hon \. <\/s> <s>/Hon\. /g;
   $thetext =~ s/Dr \. <\/s> <s>/Dr\. /g;
   $thetext =~ s/dr \. <\/s> <s>/dr\. /g;
   $thetext =~ s/Prof \. <\/s> <s>/Prof\. /g;
   $thetext =~ s/prof \. <\/s> <s>/prof\. /g;
   $thetext =~ s/W \. C \. <\/s> <s>/W\.C\. /g;
   $thetext =~ s/cf \. <\/s> <s>/cf\. /g;

   $thetext =~ s/P \. <\/s> <s> M \. /P\.M\. /g;
   $thetext =~ s/P \. M \. <\/s> <s>/P\.M\. /g;
   $thetext =~ s/p \. m \. <\/s> <s>/p\.m\. /g;
   $thetext =~ s/A \. <\/s> <s> M \. /A\.M\. /g;   
   $thetext =~ s/A \. M \. <\/s> <s>/A\.M\. /g;
   $thetext =~ s/a \. m \. <\/s> <s>/a\.m\. /g;

   $thetext =~ s/P \. <\/s> <s> T \. <\/s> <s>/P\.T\. /g;
   $thetext =~ s/P \. <\/s> <s> S \. <\/s> <s>/P\.S\. /g;
   $thetext =~ s/U \. <\/s> <s> S \. <\/s> <s>/U\.S\. /g;

   $thetext =~ s/P \. T \. <\/s> <s>/P\.T\. /g;
   $thetext =~ s/P \. S \. <\/s> <s>/P\.S\. /g;
   $thetext =~ s/U \. S \. <\/s> <s>/U\.S\. /g;

   $thetext =~ s/B \. <\/s> <s> B \. <\/s> <s> C \. /B\.B\.C\. /g;
   $thetext =~ s/B \. B \. C \. <\/s> <s>/B\.B\.C\. /g;

   $thetext =~ s/Mr \. /Mr\. /g; 
   $thetext =~ s/Mrs \. /Mrs\. /g;
   $thetext =~ s/Ms \. /Ms\. /g;
   $thetext =~ s/MR \. /Mr\. /g; 
   $thetext =~ s/MRS \. /Mrs\. /g;
   $thetext =~ s/MS \. /Ms\. /g;
   $thetext =~ s/St \. /St\. /g;
   $thetext =~ s/Hon \. /Hon\. /g;
   $thetext =~ s/Dr \. /Dr\. /g;
   $thetext =~ s/dr \. /dr\. /g;
   $thetext =~ s/Prof \. /Prof\. /g;
   $thetext =~ s/prof \. /prof\. /g;
   $thetext =~ s/W \. C \. /W\.C\. /g;
   $thetext =~ s/cf \. /cf\. /g;
   $thetext =~ s/P \. M \. /P\.M\. /g;
   $thetext =~ s/p \. m \. /p\.m\. /g;
   $thetext =~ s/A \. M \. /A\.M\. /g;
   $thetext =~ s/a \. m \. /a\.m\. /g; 
   $thetext =~ s/P \. T \. /P\.T\. /g;
   $thetext =~ s/P \. S \. /P\.S\. /g;
   $thetext =~ s/U \. S \. /U\.S\. /g;
   $thetext =~ s/B \. B \. C \. /B\.B\.C\. /g;

#E.g. P . </s> <s> K . </s> <s> Jones
   $thetext =~ s/ ([[:upper:]]{1}) \. <\/s> <s> ([[:upper:]]{1}) \. <\/s> <s> ([[:upper:]]{1})/ $1\. $2\. $3/g;
#E.g. Paul K . </s> <s> Jones
   $thetext =~ s/ ([[:upper:]]{1})([[:lower:]]+) ([[:upper:]]{1}) \. <\/s> <s> ([[:upper:]]{1})/ $1$2 $3\. $4/g;
#E.g. M. </s> <s> Winterbottom 
   $thetext =~ s/ ([[:upper:]]{1,1}) \. <\/s> <s> ([[:upper:]]{1}) / $1\. $2 /g;

#Remove likely errors, e.g. Stupid ! " I said .
#   local_text = regex.sub(r'\?"</s> <s>I ([[:lower:]])', r'?" I \1', local_text)
#   local_text = regex.sub(r'\!"</s> <s>I ([[:lower:]])', r'!" I \1', local_text)
#   local_text = regex.sub(r'\.\.\."</s> <s>I ([[:lower:]])', r'..." I \1', local_text)

# ? " </s> <s> Elaine said . </s>

#questions  ? " </s> <s> Lucy asked 
   $thetext =~ s/\? " <\/s> <s> ([[:upper:]]{1})([[:lower:]]+) (said|ask.*|enquire.*|inquire.*|plead.*|queri.*|question.*|murmur.*|amend.*|whisper.*|repli.*)/\? " $1$2 $3 /g;
   $thetext =~ s/\? " <\/s> <s> (Mr\.|Mrs\.|Ms\.|Dr\.|dr\.) ([[:upper:]]{1})([[:lower:]]+) (said|ask.*|enquire.*|inquire.*|plead.*|queri.*|question.*|murmur.*|amend.*|whisper.*|repli.*)/\? " $1 $2$3 $4 /g;

#commands/statments
   $thetext =~ s/\! " <\/s> <s> ([[:upper:]]{1})([[:lower:]]+) (said|add.*|allge.*|amend.*|announce.*|answer.*|cri.*|exclaim.*|profess.*|protest.*|repli.*|sniff.*)/\! " $1$2 $3 /g;
   $thetext =~ s/\! " <\/s> <s> (Mr\.|Mrs\.|Ms\.|Dr\.|dr\.) ([[:upper:]]{1})([[:lower:]]+) (said|add.*|allge.*|amend.*|announce.*|answer.*|cri.*|exclaim.*|profess.*|protest.*|repli.*|sniff.*)/\! " $1 $2$3 $4 /g;

	if ($thetext =~ /< \/ s > (\p{Alnum}|"|')/)
	{
		$thetext =~ s/< \/ s > (\p{Alnum}|"|')/< \/ s > <s> $1/g;
	}

	$thetext =~ s/< s >/<s>/g;
	$thetext =~ s/< \/ s >/<\/s>/g;
	$thetext =~ s/<s> <\/s>//g;

	$thetext =~ s/&/&amp;/g;

	if ($thetext !~ /^<s>/)
	{
		$thetext = '<s> ' . $thetext;
	}

    if ($thetext !~ /<\/s>$/)
    {
        $thetext = $thetext . ' </s>';
    }

	$thetext =~ s/ \s+/ /g;

	if ($thetext =~ /(\.|\?|\!|\p{Alnum}|") <s>/)
	{
		$thetext =~ s/(\.|\?|\!|\p{Alnum}|") <s>/$1 <\/s> <s> /g;
	}

	$thetext =~ s/ <\/s> <\/s> / <\/s> /g;
	$thetext =~ s/<\/s><\/s>$/<\/s>/;
	$thetext =~ s/<\/s> <\/s>$/<\/s>/;

	if ($thetext =~ /(\.|\?|\!|\p{Alnum}|"|') <s>/)
	{
		print "Found missing </s>.\n"
	}

#	if ($thetext =~ /(\p{Alnum}| )<\/s> <s> (\p{Alnum}|"})/)
#	{
#		print "Possible wrongly inserted </s> <s>.\n"
#	}

	if ($thetext =~ /<s>  \d+ <\/s> \. \. \. /)
	{
		print "Possible wrongly inserted <s> NUMB </s> . . .\n";
		$thetext =~ s/<s>  (\d+) <\/s> \. \. \. /<s> $1 <\/s> <s> \. \. \. /g;
	}

	if ($thetext =~ /, <s> \d+ <\/s> <s>/)
	{
		print "Possible wrongly inserted , <s> NUMB </s> . Deleting extra <s>.\n";
		$thetext =~ s/, <s> (\d+) <\/s> <s>/, $1 <\/s> <s>/g;
	}

#Some oddities
	$thetext =~ s/dinin " - room/dinin'-room/g;
	$thetext =~ s/drawin " - room/drawin'-room/g;
	$thetext =~ s/livin " - room/livin'-room/g;

 	my $matchingSs = &check_matching_s($thetext);

	if ($matchingSs == 1)
	{
		print "Entering including/excluding </s>.\n";
		if ($thetext =~ / <s> ([^\/]+) (\"|\)|\–|\]|:) <s> /)
		{
			print "Inserting </s>.\n";
			$thetext =~ s/ <s> ([^\/]+) ([\:\"\)\]\–]{1,1}) <s> / <s> $1 $2 <\/s> <s> /g;
			$thetext =~ s/ <\/s> (\W+) <\/s> <s> / <\/s> $1 <s> /g;
			#Single text problems
			$thetext =~ s/ <\/s> \[ SCENE : <\/s> <s> / <\/s> <s> \[ SCENE : /;
			#G1A
			$thetext =~ s/ <\/s> \( ([^\)]+)\) " / <\/s> <s> \( $1\) <\/s> <s> " /g;
		}
		#pg49331
		$thetext =~ s/ II <\/s> \. \. \. so / II <\/s> <s> \. \. \. so /;
		#GraGre3
		$thetext =~ s/ BOOK THREE <\/s> <s> I <\/s> \. \. \. / BOOK THREE <\/s> <s> I \. \. \. /;
		#pg2688
		$thetext =~ s/ CHAPTER ([IVX]+?) <\/s>T\. X \./ CHAPTER $1 <\/s> <s> T\. X\./g;
		#pg49331
		$thetext =~ s/ <s>  ([IVX]+?) <\/s>W\. G \./ <s> $1 <\/s> <s> W\. G\./g;
		#fp20110701
		$thetext =~ s/<\/s> \( 1 \) / <\/s> <s> \( 1 \)/g;
		#pg56447
		$thetext =~ s/<s> 1 <\/s> . . . " <\/s> <s> And /<s> 1 <\/s> <s> . . . " And /;
	}

	$thetext =~ s/ \s+/ /g;

    return $thetext;
}

sub check_matching_s
{
	my ($document) = @_;

	my @splitdocument = split/ /, $document;

	my $startS = 0;
	my $endS = 0;
	my $linenr = -1;
	my $flag = 0;
	foreach (@splitdocument)
	{
		$linenr++;
		if (/<s>/)
		{
			$startS++;
			$endS = 0;
		}

		if (/<\/s>/)
		{
			$endS++;
			$startS = 0;
		}

		if ($startS > 1 || $endS > 1)
		{
			print "Non-matching Ss: $linenr\n";
			$flag = 1;
		}
	}
	if ($startS > 1 || $endS > 1)
	{
		print "Non-matching Ss: $linenr : $splitdocument[$linenr]\n";
		$flag = 1;
	}

	return $flag;
}
