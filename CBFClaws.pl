#!/usr/bin/perl

use strict;
use utf8;

my ($basePath, $resultPath) = @ARGV;

open(ERROR, ">>error-claws.txt");

print "Reading list of irregular verbs from file.\n";
open(VERBS, "verbs-irregular.txt");
my @irr_verbs = <VERBS>;
close(VERBS);

print "Reading list of irregular nouns from file.\n";
open(NOUNS, "nouns-irregular.txt");
my @irr_nouns = <NOUNS>;
close(NOUNS);

print "Reading lemma list based on TreeTagger from file.\n";
open(TREETAGGER, "treetagger-lemmas.txt");
my @ttlemmas = <TREETAGGER>;
close(TREETAGGER);

my %verbs = ();
foreach (@irr_verbs)
{
	chomp;
	my ($baseform, $past, $perfect) = split/\t/;
	$verbs{$past} = $_;
	if ($past ne $perfect)
	{
		$verbs{$perfect} = $_;
	}
}

my %nouns = ();
foreach (@irr_nouns)
{
	chomp;
	my ($singular, $plural) = split/\t/;
	$nouns{$plural} = $singular;
}

my %treetagger_lemmas = ();
foreach (@ttlemmas)
{
	chomp;
	my ($citation, $posOL, $word, $pos, $lemma) = split/\t/;
	my $key = $citation . "\t" . $posOL;
	$treetagger_lemmas{$key} = "$word\t$pos\t$lemma";
}

print "Populating lists of non-conformant (contracted) forms, e.g. evenin' / everythin' / seekin'.\n";
my %RESTing = ();
&fill_RESTing();
my %Jing = ();
&fillJing();

print "Populating a list of lemmas where ' (apostrophy) should be converted to \" quotation mark and put on a separat line. Will also insert new/different POS.\n";
my %APOSlist = ();
&fillAPOSlist();

print "Populating a list of lemmas where ' (apostrophy) should be converted to \" quotation mark and put on a separat line. Will *not* change POS.\n";
my %secondAPOSlist = ();
&fillsecondAPOSlist();

opendir(DS, $basePath) or die $!;
my $numFiles = 0;
my $nooflongwords = 0;
my $antAPOS = 0;
while (my $txt = readdir(DS))
{
	if ($txt =~ /\.txt\.c7$/i)
	{
		$numFiles++;
		open(INN, "$basePath$txt");
		binmode INN, ":utf8";
		my @content = <INN>;
		close(INN);
		my @longwordlist = &get_long_words($basePath, $txt);
		$nooflongwords = $#longwordlist + 1;
		my $indexoflongwords = -1;
		my @processedcontent = ();
		my $outputfile = $txt;
		$outputfile =~ s/_prepped\.txt\.c7/_cwb\.txt/;
		open(OUT, ">$resultPath$outputfile");
		binmode OUT, ":utf8";
		print "\nFrom CLAWS to CWB $txt\n";
		my $firstline = 0;
		my $index = -1;
		foreach my $line (@content)
		{
		    chomp($line);
			$index++;
            if ($line =~ /------------------------/)
            {
                $firstline++;
                if ($firstline == 1)
                {
#                    print OUT "<s>\n";
					push(@processedcontent, "<s>");
                }
                else
                {
#                    print OUT "</s>\n<s>\n";
					push(@processedcontent, "</s>\n<s>");
                }
            }
            elsif ($line =~ /;START   / || $line =~ /;text     /)
            {

            }
            else
            {
                #NB! Error + < > stuff
				if ($line =~ /   ERROR\?    /)
				{
					print ERROR "$line\n";
				}
				if ($line =~ /ERROR\?/ && $line =~ /TOOLONG/)
				{
					#Do something
					$nooflongwords--;
					$indexoflongwords++;
					my $lword = $longwordlist[$indexoflongwords];
					$lword = &convert_to_utf8($lword);
					my $llemma = lc($lword);
					my $FUpos = 'FU';
#	        	    print OUT "$lword\t$FUpos\t$llemma\n";
					push(@processedcontent, "$lword\t$FUpos\t$llemma");
	        	    print "Inserting: $lword\t$FUpos\t$llemma\n";
				}
				else
				{
                	$line =~ s/   ERROR\?    / /;
					$line =~ s/ > ERROR\?   / /;
                	$line =~ s/   <   / /;
                	$line =~ s/   >   / /;
                	$line =~ s/   =   / /;
                	$line =~ s/\s+/ /g;
			    	$line =~ s/&dollar;/\$/g;
			    	$line =~ s/&pound;/\£/g;
			    	$line =~ s/&mdash;/–/g;
					$line =~ s/&lsqb;/\[/g;
					$line =~ s/&rsqb;/\]/g;

			    	$line = &convert_to_utf8($line);
                	my @row = split/ /, $line;
                	my $word = $row[2];
                	my $pos = $row[4];
                	if ($pos =~ /\[/)
                	{
                    	$pos =~ s/^\[//;
                    	$pos =~ s/\]$//;
                    	$pos =~ s/\/([0-9]+)$//;
                    	$pos =~ s/\%//g;
                    	$pos =~ s/\@//g;
                	}
                	my $lemma = 'dummy';
					my $problematic = 0;
					if ($word =~ "'")
					{
						($lemma, $pos, $problematic) = &fixproblematic($word, $pos, $lemma);
					}

					if ($problematic == 0)
					{
						$lemma = &lemmatize($word, $pos);
					}

			    	$line =~ s/\s+/ /g;
#	        	    print OUT "$word\t$pos\t$lemma\n";
					push(@processedcontent, "$word\t$pos\t$lemma");
				}
            }
		}
#		print OUT "</s>\n";
		push(@processedcontent, "</s>");
		if ($nooflongwords != 0)
		{
			print "Something wrong with number of long words\n";
		}
		foreach my $c (@processedcontent)
		{
			if ($c =~ /\t/)
			{
				my ($wf, $wc, $lf) = split/\t/, $c;
				if (exists($APOSlist{$lf}))
				{
					$antAPOS++;
					my $twc = $APOSlist{$lf};

					my $tlf = $lf;
					$tlf =~ s/^'//;

					$wf =~ s/^'//;

					my $newline = '"' . "\t" . '"' . "\t" . '"';
					print OUT "$newline\n";
					my $fixedline = $wf . "\t" . $twc . "\t" . $tlf;
					print OUT "$fixedline\n";

#					print "$c\n";
#					print "$newline\n";	
#					print "$fixedline\n";
				}
				elsif ($wf =~ /^'/ && $lf !~ /^'/ && (exists($secondAPOSlist{$lf})))
				{
					my $newline = '"' . "\t" . '"' . "\t" . '"';
					print OUT "$newline\n";
					$wf =~ s/^'//;
					my $fixedline = $wf . "\t" . $wc . "\t" . $lf;
					print OUT "$fixedline\n";
				}
				else
				{
					print OUT "$c\n";	
				}
			}
			else
			{
				print OUT "$c\n";
			}
		}
		close(OUT);
	}
}
close(DS);
close(ERROR);
print "No. files processed: $numFiles\n";
print "No. of apostrophies changed: $antAPOS\n";
if ($nooflongwords != 0)
{
	print "Something wrong with number long words\n";
}
print "Consult error-claws.txt\n";
exit;

sub convert_to_utf8
{
	my $string = shift(@_);

    my %hasj = (
		'&Scaron;' => 'Š',
		'&OElig;' => 'Œ',
		'&Zcaron;' => 'Ž',
		'&scaron;' => 'š',
		'&oelig;' => 'œ',
		'&zcaron;' => 'ž',
		'&Yuml;' => 'Ÿ',
		'&iexcl;' => '¡',
		'&cent;' => '¢',
		'&pound;' => '£',
		'&yen;' => 	'¥',
		'&sect;' => '§',
		'&iquest;' => '¿',
		'&Agrave;' => 'À',
		'&Aacute;' => 'Á',
		'&Acirc;' => 'Â',
		'&Atilde;' => 'Ã',
		'&Auml;' => 'Ä',
		'&Aring;' => 'Å',
		'&AElig;' => 'Æ',
		'&Ccedil;' => 'Ç',
		'&Egrave;' => 'È',
		'&Eacute;' => 'É',
		'&Ecirc;' => 'Ê',
		'&Euml;' => 'Ë',
		'&Igrave;' => 'Ì',
		'&Iacute;' => 'Í',
		'&Icirc;' => 'Î',
		'&Iuml;' => 'Ï',
		'&ETH;' => 	'Ð',
		'&Ntilde;' => 'Ñ',
		'&Ograve;' => 'Ò',
		'&Oacute;' => 'Ó',
		'&Ocirc;' => 'Ô',
		'&Otilde;' => 'Õ',
		'&Ouml;' => 'Ö',
		'&times;' => '×',
		'&Oslash;' => 'Ø',
		'&Ugrave;' => 'Ù',
		'&Uacute;' => 'Ú',
		'&Ucirc;' => 'Û',
		'&Uuml;' => 'Ü',
		'&Yacute;' => 'Ý',
		'&THORN;' => 'Þ',
		'&szlig;' => 'ß',
		'&agrave;' => 'à',
		'&aacute;' => 'á',
		'&acirc;' => 'â',
		'&atilde;' => 'ã',
		'&auml;' => 'ä',
		'&aring;' => 'å',
		'&aelig;' => 'æ',
		'&ccedil;' => 'ç',
		'&egrave;' => 'è',
		'&eacute;' => 'é',
		'&ecirc;' => 'ê',
		'&euml;' => 'ë',
		'&igrave;' => 'ì',
		'&iacute;' => 'í',
		'&icirc;' => 'î',
		'&iuml;' => 'ï',
		'&eth;' => 	'ð',
		'&ntilde;' => 'ñ',
		'&ograve;' => 'ò',
		'&oacute;' => 'ó',
		'&ocirc;' => 'ô',
		'&otilde;' => 'õ',
		'&ouml;' => 'ö',
		'&divide;' => '÷',
		'&oslash;' => 'ø',
		'&ugrave;' => 'ù',
		'&uacute;' => 'ú',
		'&ucirc;' => 'û',
		'&uuml;' => 'ü',
		'&yacute;' => 'ý',
		'&thorn;' => 'þ',
		'&yuml;' => 'ÿ');

    foreach my $key (keys(%hasj))
    {
		my $entity = $key;
		my $char = $hasj{$key};
        $string =~ s/$entity/$char/g;
    }

    return $string;

}

sub fixproblematic
{
	my ($w, $p, $lemma) = @_;

	my $problem_fixed = 0;
	my $llemma = '';

	if (($w eq "O'" || $w eq "o'") && ($p eq "IO" || $p eq "RR21") )
	{
		$llemma = "of";
		$problem_fixed = 1;
	}
	elsif (($w eq "D'" || $w eq "d'") && ($p =~ /^VD/) )
	{
		$llemma = "do";
		$problem_fixed = 1;
	}
	elsif (($w eq "'E" || $w eq "'e") && ($p eq "PPHS1") )
	{
		$llemma = "he";
		$problem_fixed = 1;
	}
	elsif (($w eq "'IM" || $w eq "'im" || $w eq "'Im") && ($p eq "PPHO1") )
	{
		$llemma = "him";
		$problem_fixed = 1;
	}
	elsif (($w eq "'ER" || $w eq "'Er" || $w eq "'er") && ($p eq "PPHO1" || $p eq "APPGE") )
	{
		$llemma = "her";
		$problem_fixed = 1;
	}
	elsif (($w eq "'T" || $w eq "'t") && ($p eq "PPH1") )
	{
		$llemma = "it";
		$problem_fixed = 1;
	}

	if (($w eq "WI'" || $w eq "wi'" || $w eq "Wi'") && ($p eq "IW") )
	{
		$llemma = "with";
		$problem_fixed = 1;
	}
	elsif (($w eq "'AVE" || $w eq "'Ave" || $w eq "'ave") && ($p eq "VH0" || $p eq "VHI" ) )
	{
		$llemma = "have";
		$problem_fixed = 1;
	}
	elsif (($w eq "No'" || $w eq "no'") && ($p eq "JJ" || $p eq "VVI" || $p eq "NN1") )
	{
		$llemma = "not";
		$p = "XX";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Ere" || $w eq "'ERE" || $w eq "'ere") && ($p eq "RL") )
	{
		$llemma = "here";
		$problem_fixed = 1;
	}
	elsif (($w eq "'IS" || $w eq "'Is" || $w eq "'is") && ($p eq "APPGE") )
	{
		$llemma = "his";
		$problem_fixed = 1;
	}
	elsif (($w eq "A'") && ($p eq "VV0"|| $p eq "JJ"|| $p eq "NN1" ) )
	{
		$llemma = "all";
		$p = "DB";
		$problem_fixed = 1;
	}
	elsif (($w eq "a'") && ($p eq "JJ" || $p eq "NN1" ) )
	{
		$llemma = "all";
		$problem_fixed = 1;
	}
	elsif (($w eq "a'") && ($p eq "VV0" || $p eq "VVI" ) )
	{
		$llemma = "have";
		$problem_fixed = 1;
	}
	elsif (($w eq "ha'" || $w eq "Ha'" || $w eq "'av") && ($p eq "VV0" || $p eq "VVI" ) )
	{
		$llemma = "have";
		$problem_fixed = 1;
	}
	elsif (($w eq "ha'"|| $w eq "Ha'") && ($p eq "NN1" || $p eq "NP1") )
	{
		$llemma = "have";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "Th'" || $w eq "th'" || $w eq "t'" || $w eq "T'") && ($p eq "AT" ) )
	{
		$llemma = "the";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Ee" || $w eq "'ee" || $w eq "y'"  || $w eq "Y'") && ($p eq "PPY" ) )
	{
		$llemma = "you";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Ow" || $w eq "'ow") && ($p eq "RRQ" || $p eq "RGQ" ) )
	{
		$llemma = "how";
		$problem_fixed = 1;
	}
	elsif (($w eq "Sha'" || $w eq "sha'") && ($p eq "VV0" || $p eq "VM" ) )
	{
		$llemma = "shall";
		$p = "VM";
		$problem_fixed = 1;
	}
	elsif (($w eq "'UN" || $w eq "'Un" || $w eq "'un") && ($p eq "PN1" ) )
	{
		$llemma = "one";
		$problem_fixed = 1;
	}
	elsif (($w eq "'bus") && ($p eq "NN1" ) )
	{
		$llemma = "bus";
		$problem_fixed = 1;
	}
	elsif (($w eq "I'" || $w eq "i'") && ($p eq "VV0" || $p eq "JJ" || $p eq "NN1" ) )
	{
		$llemma = "in";
		$p = "II";
		$problem_fixed = 1;
	}
	elsif (($w eq "Don'" || $w eq "don'") && ($p eq "VV0" || $p eq "JJ" || $p eq "NN1" ) )
	{
		$llemma = "do";
		$p = "VD0";
		$problem_fixed = 1;
	}
	elsif (($w eq "Tak'" || $w eq "tak'") && ($p eq "VVI" || $p eq "VV0" || $p eq "JJ" || $p eq "NN1" ) )
	{
		$llemma = "take";
		$p = "VVI";
		$problem_fixed = 1;
	}
	elsif (($w eq "'phone") && ($p eq "NN1" ) )
	{
		$llemma = "phone";
		$problem_fixed = 1;
	}
	elsif (($w eq "'phoned") && ($p eq "VVD" || $p eq "VVN") )
	{
		$llemma = "phone";
		$problem_fixed = 1;
	}
	elsif (($w eq "'bus-conductor") && ($p eq "NN1" ) )
	{
		$llemma = "bus-conductor";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Pon" || $w eq "'pon") && ($p eq "NN1") )
	{
		$llemma = "upon";
		$p = "II";
		$problem_fixed = 1;
	}
	elsif (($w eq "No'" || $w eq "no'") && ($p eq "VVI" || $p eq "VV0" || $p eq "JJ") )
	{
		$llemma = "not";
		$p = "XX";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Bout" || $w eq "'bout") && ($p eq "II" || $p eq "RG") )
	{
		$llemma = "about";
		$problem_fixed = 1;
	}
	elsif (($w eq "Awa'" || $w eq "awa'") && ($p eq "RP") )
	{
		$llemma = "away";
		$problem_fixed = 1;
	}
	elsif (($w eq "mak'") && ($p eq "VV0" || $p eq "VVI") )
	{
		$llemma = "make";
		$problem_fixed = 1;
	}
	elsif (($w eq "mak'") && ($p eq "NN1") )
	{
		$llemma = "make";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Arf" || $w eq "'arf") && ($p eq "NN1" || $p eq "VV0") )
	{
		$llemma = "half";
		$p = "NN1";
		$problem_fixed = 1;
	}
	elsif (($w eq "fra'") && ($p eq "NN1" || $p eq "VV0" || $p eq "JJ") )
	{
		$llemma = "from";
		$p = "II";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Tis" || $w eq "'tis"|| $w eq "'Tes" || $w eq "'tes") && ($p eq "NN1" || $ p eq "NN2") )
	{
		$llemma = "'tis";
		$p = "FU";
		$problem_fixed = 1;
	}
	elsif (($w eq "Ver'" || $w eq "ver'") && ($p eq "NN1" || $p eq "VV0" || $p eq "JJ") )
	{
		$llemma = "very";
		$p = "RG";
		$problem_fixed = 1;
	}
	elsif (($w eq "Cam'" || $w eq "cam'") && ($p eq "NN1" || $p eq "VV0" || $p eq "JJ") )
	{
		$llemma = "come";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "kep'" || $w eq "Kep'") && ($p eq "NN1" || $p eq "VV0" || $p eq "JJ") )
	{
		$llemma = "keep";
		$problem_fixed = 1;
	}
	elsif (($w eq "Wiv'" || $w eq "wiv'") && ($p eq "NN1" || $p eq "VV0" || $p eq "JJ") )
	{
		$llemma = "with";
		$p = "IW";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Fraid" || $w eq "'fraid") && ($p eq "VVD" || $p eq "VVN") )
	{
		$llemma = "afraid";
		$p = "JJ";
		$problem_fixed = 1;
	}
	elsif (($w eq "'orspital") && ($p eq "JJ") )
	{
		$llemma = "hospital";
		$p = "NN1";
		$problem_fixed = 1;
	}
	elsif (($w eq "Yo'" || $w eq "yo'") && ($p eq "NNU" || $p eq "NP1") )
	{
		$llemma = "you";
		$p = "PPY";
		$problem_fixed = 1;
	}
	elsif (($w eq "Ca'" || $w eq "ca'") && ($p eq "VVI" || $p eq "VV0") )
	{
		$llemma = "call";
		$problem_fixed = 1;
	}
	elsif (($w eq "'N" || $w eq "'n") && ($p eq "CC") )
	{
		$llemma = "and";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Old" || $w eq "'old") && ($p eq "VVI" || $p eq "VV0" || $p eq "NN1") )
	{
		$llemma = "hold";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "'M" || $w eq "'m") && ($p eq "APPGE" || $p eq "JJ" || $p eq "VV0" ||  $p eq "NP1") )
	{
		$llemma = "my";
		$p = "APPGE";
		$problem_fixed = 1;
	}
	elsif (($w eq "'One" || $w eq "'one") && ($p eq "NN1" || $p eq "VV0" ) )
	{
		$llemma = "one";
		$p = "MC1";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Come" || $w eq "'come") && ($p eq "NN1") )
	{
		$llemma = "come";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "'SIR" || $w eq "'Sir" || $w eq "'sir") && ($p eq "NN1") )
	{
		$llemma = "sir";
		$p = "NNB";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Thank" || $w eq "'thank") && ($p eq "NN1" || $p eq "VV0" ) )
	{
		$llemma = "thank";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "'DEAR" || $w eq "'Dear" || $w eq "'dear") && ($p eq "NN1" || $p eq "VV0" || $p eq "NP1") )
	{
		$llemma = "dear";
		$p = "NN1";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Go" || $w eq "'go") && ($p eq "NN1") )
	{
		$llemma = "go";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Now" || $w eq "'now") && ($p eq "NN1" || $p eq "VV0" ) )
	{
		$llemma = "now";
		$p = "RT";
		$problem_fixed = 1;
	}
	elsif (($w eq "'So" || $w eq "'so") && ($p eq "NN1" ) )
	{
		$llemma = "so";
		$p = "RG";
		$problem_fixed = 1;
	}
	elsif (($w eq "'WHO" || $w eq "'Who" || $w eq "'who") && ($p eq "NN1") )
	{
		$llemma = "who";
		$p = "PNQS";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Here" || $w eq "'here") && ($p eq "NN1" || $p eq "JJ" ) )
	{
		$llemma = "here";
		$p = "RL";
		$problem_fixed = 1;
	}
	elsif (($w eq "IT'" || $w eq "It'" || $w eq "it'") && ($p eq "NN1" || $p eq "NP1" || $p eq "JJ" || $p eq "VV0" ) )
	{
		$llemma = "it";
		$p = "PPH1";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Just" || $w eq "'just") && ($p eq "RR") )
	{
		$llemma = "just";
		$p = "RR";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Let" || $w eq "'let") && ($p eq "NN1") )
	{
		$llemma = "let";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Little" || $w eq "'little") && ($p eq "NN1") )
	{
		$llemma = "little";
		$p = "DA1";
		$problem_fixed = 1;
	}
	elsif (($w eq "'On" || $w eq "'on") && ($p eq "JJ") )
	{
		$llemma = "on";
		$p = "II";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Where" || $w eq "'where") && ($p eq "RR") )
	{
		$llemma = "where";
		$p = "RRQ";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Very" || $w eq "'very") && ($p eq "JJ") )
	{
		$llemma = "where";
		$p = "RG";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Poor" || $w eq "'poor") && ($p eq "NN1") )
	{
		$llemma = "poor";
		$p = "JJ";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Ah") && ($p eq "UH") )
	{
		$llemma = "ah";
		$problem_fixed = 1;
	}
	elsif (($w eq "'God") && ($p eq "NN1") )
	{
		$llemma = "god";
		$p = 'NP1';
		$problem_fixed = 1;
	}
	elsif (($w eq "'When" || $w eq "'when") && ($p eq "NN1" || $p eq "JJ" ) )
	{
		$llemma = "when";
		$p = "RRQ";
		$problem_fixed = 1;
	}
	elsif (($w eq "'With" || $w eq "'with") && ($p eq "NN1") )
	{
		$llemma = "with";
		$p = "IW";
		$problem_fixed = 1;
	}
	elsif (($w eq "'tween") && ($p eq "NN1" || $p eq "JJ" ) )
	{
		$llemma = "between";
		$p = "II";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Are" || $w eq "'are") && ($p eq "NN1" || $p eq "VV0" ) )
	{
		$llemma = "be";
		$p = "VBR";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Get" || $w eq "'get") && ($p eq "NN1" || $p eq "VVI"|| $p eq "VV0" ) )
	{
		$llemma = "get";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Please" || $w eq "'please") && ($p eq "NN1" || $p eq "VV0" ) )
	{
		$llemma = "please";
		$p = "RR";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Then" || $w eq "'then") && ($p eq "NN1" ) )
	{
		$llemma = "then";
		$p = "RT";
		$problem_fixed = 1;
	}
	elsif (($w eq "wa'") && ($p eq "NN1" || $p eq "VV0" || $p eq "JJ") )
	{
		$llemma = "be";
		$p = "VBDZ";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Keep" || $w eq "'keep") && ($p eq "NN1" || $p eq "VVI"|| $p eq "VV0" ) )
	{
		$llemma = "keep";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "'By" || $w eq "'by") && ($p eq "NN1" ) )
	{
		$llemma = "by";
		$p = "II";
		$problem_fixed = 1;
	}
	elsif (($w eq "'eem") && ($p eq "NN1" ) )
	{
		$llemma = "him";
		$p = "PPH01";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Ed" || $w eq "'ed") && ($p eq "NN1" || $p eq "VVD"|| $p eq "JJ" ) )
	{
		$llemma = "head";
		$p = "NN1";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Am") && ($p eq "NN1" ) )
	{
		$llemma = "be";
		$p = "VBM";
		$problem_fixed = 1;
	}
	elsif (($w eq "'am") && ($p eq "NN1" ) )
	{
		$llemma = "ham";
		$p = "NN1";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Ha" || $w eq "'ha") && ($p eq "NN1" ) )
	{
		$llemma = "ha";
		$p = "UH";
		$problem_fixed = 1;
	}
	elsif (($w eq "ol'") && ($p eq "NN1" || $p eq "VV0") )
	{
		$llemma = "old";
		$p = "JJ";
		$problem_fixed = 1;
	}
	elsif (($w eq "gon'") && ($p eq "NN1" || $p eq "VV0") )
	{
		$llemma = "go";
		$p = "VVN";
		$problem_fixed = 1;
	}
	elsif (($w eq "roun'") && ($p eq "NN1" || $p eq "VV0" || $p eq "JJ") )
	{
		$llemma = "around";
		$p = "RR";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Mermaid") && ($p eq "NN1" ) )
	{
		$llemma = "mermaid";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Her" || $w eq "'her") && ($p eq "NN1" || $p eq "JJR" || $p eq "VV0" ) )
	{
		$llemma = "her";
		$p = "PPHO1";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Nothing" || $w eq "'nothing") && ($p eq "NN1" || $p eq "VVG") )
	{
		$llemma = "nothing";
		$p = "PN1";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Too" || $w eq "'too") && ($p eq "NN1") )
	{
		$llemma = "too";
		$p = "RG";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Home" || $w eq "'home") && ($p eq "NN1") )
	{
		$llemma = "home";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Love" || $w eq "'love") && ($p eq "NN1" || $p eq "VV0" ) )
	{
		$llemma = "love";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Man" || $w eq "'man") && ($p eq "NN1") )
	{
		$llemma = "man";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Morning" || $w eq "'morning") && ($p eq "NN1" || $p eq "VVG" || $p eq "JJ" ) )
	{
		$llemma = "morning";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Bye" || $w eq "'bye") && ($p eq "NN1" || $p eq "VV0") )
	{
		$llemma = "bye";
		$p = "UH";
		$problem_fixed = 1;
	}
	elsif (($w eq "'From" || $w eq "'from") && ($p eq "NN1" || $p eq "VV0" || $p eq "VVI") )
	{
		$llemma = "from";
		$p = "II";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Give" || $w eq "'give") && ($p eq "NN1" || $p eq "VV0" || $p eq "VVI") )
	{
		$llemma = "give";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Tell" || $w eq "'tell") && ($p eq "NN1" || $p eq "VV0" || $p eq "VVI") )
	{
		$llemma = "tell";
		$p = "VV0";
		$problem_fixed = 1;
	}
	elsif (($w eq "'His" || $w eq "'his") && ($p eq "NN1") )
	{
		$llemma = "his";
		$p = "APPGE";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Take" || $w eq "'take") && ($p eq "VV0" || $p eq "VVI") )
	{
		$llemma = "take";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Three" || $w eq "'three") && ($p eq "NN1") )
	{
		$llemma = "three";
		$p = "MC";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Young" || $w eq "'young") && ($p eq "VVN" || $p eq "VVD" || $p eq "JJ") )
	{
		$llemma = "young";
		$p = "JJ";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Did" || $w eq "'did") && ($p eq "NN1" || $p eq "JJ") )
	{
		$llemma = "do";
		$p = "VDD";
		$problem_fixed = 1;
	}
	elsif (($w eq "'Going" || $w eq "'going") && ($p eq "VVG" || $p eq "NN1" || $p eq "JJ") )
	{
		$llemma = "go";
		$p = "VVG";
		$problem_fixed = 1;
	}

	return $llemma, $p, $problem_fixed;
}
# http://ucrel.lancs.ac.uk/claws7tags.html / http://www.scientificpsychic.com/grammar/regular.html

sub lemmatize
{
    my ($w, $p) = @_;

	$w = lc($w);
    my $lemma = $w;
	my $origlemma = $lemma;
    
    my %lhash = (
        'VBDR' => 'be',
        'VBDZ' => 'be',
        'VBG' => 'be',
        'VBM' => 'be',
        'VBN' => 'be',
        'VBR' => 'be',
        'VBZ' => 'be',
        'VDD' => 'do',
        'VDG' => 'do',
        'VDN' => 'do',
        'VDZ' => 'do',
        'VHD' => 'have',
        'VHG' => 'have',
        'VHN' => 'have',
        'VHZ' => 'have');

	my $stillnotfound = 0;

	if ($w eq "ai" && $p eq "FU")
	{
		$stillnotfound++;
		$lemma = 'be';
	}

	if ($w eq "ca" && $p eq "VM")
	{
		$stillnotfound++;
		$lemma = 'can';
	}
	elsif ($w eq "wo" && $p eq "VM")
	{
		$stillnotfound++;
		$lemma = 'will';
	}
	elsif ($w eq "'ll" && $p eq "VM")
	{
		$stillnotfound++;
		$lemma = 'will';
	}
	elsif (($w eq "'d" || $w eq "'ud") && $p eq "VM")
	{
		$stillnotfound++;
		$lemma = 'would';
	}
    elsif ($p =~ /^V/)
    {
		my $key = $w . "\t" . 'V';

        if (exists($lhash{$p}))
        {
            $lemma = $lhash{$p};
			$stillnotfound++;
        }
		elsif ($p eq 'VVD' || $p eq 'VVN')
		{
			if (exists($verbs{$w}))
			{
				my $temp = $verbs{$w};
				my ($base, $past, $perfect) = split/\t/, $temp;
				$lemma = $base;
				$stillnotfound++;
			}
		}

		if ($stillnotfound == 0)
		{
			if (exists($treetagger_lemmas{$key}))
			{
				my ($baseform, $pos, $tlemma) = split/\t/, $treetagger_lemmas{$key};
				$lemma = $tlemma;
			}
			elsif ($w =~ /-/)
			{
				my @singlewords = split/-/, $w;
				my $lastword = $singlewords[$#singlewords];
				$lastword = $lastword . "\t" . "V";
				if (exists($treetagger_lemmas{$lastword}))
				{
					my ($baseform, $pos, $tlemma) = split/\t/, $treetagger_lemmas{$lastword};
					$lemma = $w;
					$lastword =~ s/\tV//;
					$lemma =~ s/$lastword$/$tlemma/;
				}
			}
		}
    }

    if ($p =~ /^N/ && $p !~ /^NP/)
    {
		my $key = $w . "\t" . 'N';

		if (exists($nouns{$w}))
		{
			my $temp = $nouns{$w};
			my ($singular, $plural) = split/\t/, $temp;
			$lemma = $singular;
		}
		elsif (exists($treetagger_lemmas{$key}))
		{
			my ($baseform, $pos, $tlemma) = split/\t/, $treetagger_lemmas{$key};
			$lemma = $tlemma;
		}
		elsif ($w =~ /-/)
		{
			my @singlewords = split/-/, $w;
			my $lastword = $singlewords[$#singlewords];
			$lastword = $lastword . "\t" . "N";
			if (exists($treetagger_lemmas{$lastword}))
			{
				my ($baseform, $pos, $tlemma) = split/\t/, $treetagger_lemmas{$lastword};
				$lemma = $w;
				$lastword =~ s/\tN//;
				$lemma =~ s/$lastword$/$tlemma/;
			}
		}
    }
    
	if ($p eq 'JJR' || $p eq 'JJT' || $p eq 'RRR' || $p eq 'RRT')
	{
		my $keyJ = $w . "\t" . 'J';
		my $keyR = $w . "\t" . 'R';

		if (exists($treetagger_lemmas{$keyJ}))
		{
			my ($baseform, $comparative, $superlative) = split/\t/, $treetagger_lemmas{$keyJ};
			$lemma = $baseform;
		}
		elsif (exists($treetagger_lemmas{$keyR}))
		{
			my ($baseform, $comparative, $superlative) = split/\t/, $treetagger_lemmas{$keyR};
			$lemma = $baseform;
		}
		elsif ($w =~ /-/)
		{
			my @singlewords = split/-/, $w;
			my $lastword = $singlewords[$#singlewords];
			$lastword = $lastword . "\t" . "J";
			if (exists($treetagger_lemmas{$lastword}))
			{
				my ($baseform, $comparative, $superlative) = split/\t/, $treetagger_lemmas{$lastword};
				$lemma = $baseform;
				$lastword =~ s/\tJ//;
				$lemma =~ s/$lastword$/$baseform/;
			}
			else
			{
				$lastword = $lastword . "\t" . "R";
				if (exists($treetagger_lemmas{$lastword}))
				{
					my ($baseform, $comparative, $superlative) = split/\t/, $treetagger_lemmas{$lastword};
					$lemma = $baseform;
					$lastword =~ s/\tR//;
					$lemma =~ s/$lastword$/$baseform/;
				}
			}
		}
	}

#   $lemma = lc($lemma);
#	$lemma = &double_check($lemma);
	if ($lemma =~ /'/ && $lemma ne "'s" && $lemma ne "'ll" && $lemma ne "'d" && $lemma ne "'ve" && $lemma ne "'m" && $lemma ne "'re" && $lemma ne "n't" && $lemma ne "o'clock" && $lemma ne "'")
	{
		if ($p =~ /^JJ/)
		{
			if (exists($Jing{$lemma}))
			{
				$lemma = $Jing{$lemma};
			}
		}
		elsif (exists($RESTing{$lemma}))
		{
			$lemma = $RESTing{$lemma};
		}
	}

	if ($origlemma ne $lemma)
	{
#		print ERROR "Lemma change: $origlemma <> $lemma\n";
	}

    return $lemma;
}


sub fill_RESTing()
{
	%RESTing = (
		"'aving" => "have",
		"n't" => "not",
		"n'" => "and",
		"damn'" => "damn",
		"dam'" => "damn",
		"fa'" => "fall",
		"giv'" => "give",
		"'em" => "them",
		"'flu" => "flu",
		"worl'" => "world",
		"tho'" => "though",
		"'usband" => "husband",
		"'abits" => "habit",
		"'abit" => "habit",
		"'ooman" => "woman",
		"ceilin'" => "ceiling",
		"'andle" => "handle",
		"'most" => "almost",
		"'ome" => "home",
		"'ouse" => "house",
		"'ead" => "head",
		"'ear" => "hear",
		"'elp" => "help",
		"'eard" => "hear",
		"'appened" => "happen",
		"'fore" => "before",
		"'alf" => "half",
		"'ands" => "hand",
		"'oo" => "who",
		"'imself" => "himself",
		"'isself" => "himself",
		"mysel'" => "myself",
		"yoursel'" => "yourself",
		"'undred" => "hundred",
		"poun'" => "pound",
		"'orse" => "horse",
		"'uns" => "ones",
		"'cause" => "because",
		"'eart" => "heart",
		"'ardly" => "hardly",
		"'appen" => "happen",
		"'ell" => "hell",
		"'orses" => "horse",
		"'arm" => "harm",
		"'ole" => "hole",
		"'urry" => "hurry",
		"'art" => "heart",
		"'ullo" => "hullo",
		"'air" => "hair",
		"'ed" => "head",
		"'erself" => "herself",
		"'osses" => "horse",
		"'ealth" => "health",
		"himsel'" => "himself",
		"'appens" => "happen",
		"'cept" => "except",
		"'elped" => "help",
		"'ouses" => "house",
		"'ospital" => "hospital",
		"'scuse" => "excuse",
		"'ang" => "hand",
		"'eads" => "head",
		"'ats" => "hat",
		"'ard" => "hard",
		"owin'" => "owe",
		"'oman" => "woman",
		"'opes" => "hope",
		"'ope" => "hope",
		"'oss" => "horse",
		"'spect" => "expect",
		"'emselves" => "themselves",
		"hersel'" => "herself",
		"'ung" => "hang",
		"'appiness" => "happiness",
		"'azel" => "hazel",
		"'eaven" => "heaven",
		"'ello" => "hello",
		"'ighly" => "highly",
		"'spose" => "suppose",
		"'uman" => "human",
		"'eavens" => "heaven",
		"'iding" => "hide",
		"'oliday" => "holiday",
		"actin'" => "act",
		"'ammer" => "hammer",
		"'appening" => "happen",
		"durin'" => "during",
		"'ook" => "hook",
		"'opped" => "hop",
		"'usbands" => "husband",
		"yersel'" => "yourself",
		"'ates" => "hate",
		"'ate" => "hate",
		"com'" => "come",
		"'ank" => "hank",
		"'ears" => "hear",
		"'urt" => "hurt",
		"'urts" => "hurt",
		"considerin'" => "consider",
		"'earty" => "hearty",
		"'enderson" => "henderson",
		"frien'" => "friend",
		"hav'" => "have",
		"'ired" => "hire",
		"'oles" => "hole",
		"'orspital" => "hospital",
		"'tice" => "entice",
		"'wot" => "what",
		"accordin'" => "accord",
		"amazin'" => "amaze",
		"an'" => "and",
		"anythin'" => "anything",
		"arguin'" => "argue",
		"askin'" => "ask",
		"axin'" => "ask",
		"avin'" => "have",
		"beggin'" => "beg",
		"beginnin'" => "begin",
		"bein'" => "be",
		"bleedin'" => "bleed",
		"blinkin'" => "blink",
		"bloomin'" => "bloom",
		"blowin'" => "blow",
		"boilin'" => "boil",
		"breathin'" => "breathe",
		"bringin'" => "bring",
		"buildin'" => "build",
		"burnin'" => "burn",
		"bustin'" => "bust",
		"callin'" => "call",
		"carryin'" => "carry",
		"comin'" => "come",
		"cookin'" => "cook",
		"couldna" => "could",
		"crawlin'" => "crawl",
		"cryin'" => "cry",
		"cuttin'" => "cut",
		"dancin'" => "dance",
		"darlin'" => "darling",
		"denyin'" => "deny",
		"diggin'" => "dig",
		"dinin'" => "dine",
		"doin'" => "do",
		"dreamin'" => "dream",
		"dressin'" => "dress",
		"drinkin'" => "drink",
		"drivin'" => "drive",
		"dyin'" => "die",
		"eatin'" => "eat",
		"evenin'" => "evening",
		"everythin'" => "everything",
		"expectin'" => "expect",
		"fallin'" => "fall",
		"feelin'" => "feel",
		"fightin'" => "fight",
		"findin'" => "find",
		"fishin'" => "fish",
		"fixin'" => "fix",
		"flyin'" => "fly",
		"fuckin'" => "fuck",
		"gettin'" => "get",
		"givin'" => "give",
		"goin'" => "go",
		"grinnin'" => "grin",
		"growin'" => "grow",
		"hangin'" => "hang",
		"havin'" => "have",
		"hearin'" => "hear",
		"hein" => "they",
		"helpin'" => "help",
		"hidin'" => "hide",
		"hittin'" => "hit",
		"holdin'" => "hold",
		"hopin'" => "hope",
		"huntin'" => "hunt",
		"interferin'" => "interfer",
		"keepin'" => "keep",
		"kickin'" => "kick",
		"killin'" => "kill",
		"kissin'" => "kiss",
		"knockin'" => "knock",
		"knowin'" => "know",
		"laughin'" => "laugh",
		"layin'" => "lay",
		"leavin'" => "leave",
		"lettin'" => "let",
		"listenin'" => "listen",
		"livin'" => "live",
		"lollin'" => "loll",
		"losin'" => "lose",
		"lyin'" => "lie",
		"makin'" => "make",
		"marryin'" => "marry",
		"meanin'" => "mean",
		"meetin'" => "meet",
		"missin'" => "miss",
		"mornin'" => "morning",
		"marnin'" => "morning",
		"movin'" => "move",
		"muckin'" => "muck",
		"nothin'" => "nothing",
		"nuthin'" => "nothing",
		"nuffin'" => "nothing",
		"nuttin'" => "nothing",
		"openin'" => "open",
		"packin'" => "pack",
		"passin'" => "pass",
		"payin'" => "pay",
		"plantin'" => "plant",
		"playin'" => "play",
		"pokin'" => "poke",
		"pretendin'" => "pretend",
		"prayin'" => "pray",
		"pinchin'" => "pinch",
		"'opping" => "hop",
		"ironin'" => "iron",
		"pullin'" => "pull",
		"puttin'" => "put",
		"readin'" => "read",
		"ridin'" => "ride",
		"ringin'" => "ring",
		"runnin'" => "run",
		"rusticatin'" => "rusticate",
		"sayin'" => "say",
		"seein'" => "see",
		"sellin'" => "sell",
		"sendin'" => "send",
		"settin'" => "set",
		"shillin'" => "shilling",
		"shootin'" => "shoot",
		"showin'" => "show",
		"singin'" => "sing",
		"sittin'" => "sit",
		"sleepin'" => "sleep",
		"smilin'" => "smile",
		"smokin'" => "smoke",
		"somethin'" => "something",
		"speakin'" => "speak",
		"spendin'" => "spend",
		"spoilin'" => "spoil",
		"scrappin'" => "scrap",
		"starin'" => "stare",
		"startin'" => "start",
		"starvin'" => "starve",
		"stayin'" => "stay",
		"stickin'" => "stick",
		"stoppin'" => "stop",
		"sufferin'" => "suffer",
		"supposin'" => "suppose",
		"surprisin'" => "surprise",
		"swearin'" => "swear",
		"talkin'" => "talk",
		"tearin'" => "tear",
		"tellin'" => "tell",
		"thinkin'" => "think",
		"travellin'" => "travel",
		"tryin'" => "try",
		"turnin'" => "turn",
		"usin'" => "use",
		"visitin'" => "visit",
		"waitin'" => "wait",
		"wanderin'" => "wander",
		"wantin'" => "want",
		"warnin'" => "warn",
		"wastin'" => "waste",
		"watchin'" => "watch",
		"wearin'" => "wear",
		"weddin'" => "wed",
		"willin'" => "willing",
		"windin'" => "wind",
		"wishin'" => "wish",
		"wonderin'" => "wonder",
		"worryin'" => "worry",
		"wouldna" => "would",
		"lookin'" => "look",
		"takin'" => "take",
		"workin'" => "work",
		"standin'" => "stand",
		"walkin'" => "walk",
		"leadin'" => "lead",
		"breakin'" => "break",
		"charmin'" => "charm",
		"guessin'" => "guess",
		"perishin'" => "perish",
		"sailin'" => "sail",
		"savin'" => "save",
		"boxin'" => "box",
		"exceptin'" => "except",
		"buyin'" => "buy",
		"courtin'" => "court",
		"gamblin'" => "gamble",
		"pickin'" => "pick",
		"plannin'" => "plan",
		"countin'" => "count",
		"drawin'" => "draw",
		"happenin'" => "happen",
		"learnin'" => "learn",
		"likin'" => "like",
		"rippin'" => "rip",
		"throwin'" => "throw",
		"washin'" => "wash",
		"complainin'" => "complain",
		"greetin'" => "greet",
		"gumshoein'" => "gumshoe",
		"jumpin'" => "jump",
		"messin'" => "mess",
		"rushin'" => "rush",
		"speirin'" => "speir",
		"touchin'" => "touch",
		"bangin'" => "bang",
		"bumpin'" => "bump",
		"buryin'" => "bury",
		"chasin'" => "chase",
		"crackin'" => "crack",
		"cussin'" => "cuss",
		"disgustin'" => "disgust",
		"distressin'" => "distress",
		"fechtin'" => "fetch",
		"followin'" => "follow",
		"handin'" => "hand",
		"hollerin'" => "holler",
		"janglin'" => "jangle",
		"kiddin'" => "kid",
		"kidnappin'" => "kidnap",
		"landin'" => "land",
		"leanin'" => "lean",
		"rememberin'" => "remember",
		"servin'" => "serve",
		"settlin'" => "settle",
		"shakin'" => "shake",
		"snorin'" => "snore",
		"spyin'" => "spy",
		"squealin'" => "squeal",
		"stealin'" => "steal",
		"allowin'" => "allow",
		"bashin'" => "bash",
		"beatin'" => "beat",
		"chuckin'" => "chuck",
		"cleanin'" => "clean",
		"clearin'" => "clear",
		"comfortin'" => "comfort",
		"considerin'" => "consider",
		"drippin'" => "drip",
		"droppin'" => "drop",
		"enjoyin'" => "enjoy",
		"figurin'" => "figure",
		"freezin'" => "freeze",
		"frontin'" => "front",
		"improvin'" => "improve",
		"investigatin'" => "investigate",
		"lightin'" => "light",
		"lovin'" => "love",
		"murderin'" => "murder",
		"needin'" => "need",
		"operatin'" => "operate",
		"preachin'" => "preach",
		"providin'" => "provide",
		"pushin'" => "push",
		"raisin'" => "raise",
		"reportin'" => "report",
		"risin'" => "rise",
		"rovin'" => "rove",
		"shavin'" => "shave",
		"shoppin'" => "shop",
		"sinkin'" => "sink",
		"stinkin'" => "stink",
		"studyin'" => "study",
		"swimmin'" => "swim",
		"rovin'" => "rove",
		"poppin'" => "pop",
		"wan'" => "want",
		"a-goin'" => "go",
		"agoin'" => "go",
		"collectin'" => "collect",
		"frettin'" => "fret",
		"writin'" => "write");

}

sub fillJing()
{

    %Jing = (
		"amazin'" => "amazing",
		"comfortin'" => "comforting",
		"'uman" => "human",
		"goo'" => "good",
		"sma'" => "small",
		"darlin'" => "darling",
		"damn'" => "damned",
		"dam'" => "damned",
		"awfu'" => "awful",
		"fu'" => "full",
		"'ot" => "hot",
		"li'l'" => "little",
		"'appy" => "happy",
		"'earty" => "hearty",
		"'oly" => "holy",
		"'ealthy" => "healthy",
		"'eavy" => "heavy",
		"'andy" => "handy",
		"'ard" => "hard",
		"'urt" => "hurt",
		"'igh" => "high",
		"ol'" => "old",
		"'fraid" => "afraid",
		"awfu'" => "awful",
		"'normous" => "enormous",
		"awfull'" => "awful",
		"'orrible" => "horrible",
		"nex'" => "next",		
		"charmin'" => "charming",
		"arguin'" => "arguing",
		"askin'" => "asking",
		"beggin'" => "begging",
		"beginnin'" => "beginning",
		"bleedin'" => "bleeding",
		"blinkin'" => "blinking",
		"bloomin'" => "blooming",
		"blowin'" => "blowing",
		"boilin'" => "boiling",
		"breathin'" => "breathing",
		"bringin'" => "bringing",
		"buildin'" => "building",
		"burnin'" => "burning",
		"bustin'" => "busting",
		"callin'" => "calling",
		"carryin'" => "carrying",
		"comin'" => "coming",
		"cookin'" => "cooking",
		"crawlin'" => "crawling",
		"cryin'" => "crying",
		"cuttin'" => "cutting",
		"dancin'" => "dancing",
		"denyin'" => "denying",
		"diggin'" => "digging",
		"dinin'" => "dining",
		"dreamin'" => "dreaming",
		"dressin'" => "dressing",
		"drinkin'" => "drinking",
		"drivin'" => "driving",
		"dyin'" => "dying",
		"eatin'" => "eating",
		"expectin'" => "expecting",
		"fallin'" => "falling",
		"fightin'" => "fighting",
		"fishin'" => "fishing",
		"fixin'" => "fixing",
		"flyin'" => "flying",
		"fuckin'" => "fuck",
		"grinnin'" => "grining",
		"growin'" => "growing",
		"hangin'" => "hanging",
		"hearin'" => "hearing",
		"helpin'" => "helping",
		"hidin'" => "hiding",
		"hittin'" => "hitting",
		"holdin'" => "holding",
		"hopin'" => "hoping",
		"huntin'" => "hunting",
		"interferin'" => "interfering",
		"kickin'" => "kicking",
		"killin'" => "killing",
		"kissin'" => "kissing",
		"knockin'" => "knocingk",
		"knowin'" => "knowing",
		"laughin'" => "laughing",
		"leavin'" => "leaving",
		"lettin'" => "letting",
		"listenin'" => "listening",
		"livin'" => "living",
		"lollin'" => "lolling",
		"losin'" => "losing",
		"lyin'" => "lying",
		"marryin'" => "marrying",
		"missin'" => "missing",
		"movin'" => "moving",
		"packin'" => "packing",
		"passin'" => "passing",
		"payin'" => "paying",
		"playin'" => "playing",
		"pokin'" => "poking",
		"pretendin'" => "pretending",
		"pullin'" => "pulling",
		"readin'" => "reading",
		"ridin'" => "riding",
		"ringin'" => "ringing",
		"runnin'" => "runing",
		"seein'" => "seeing",
		"sellin'" => "selling",
		"sendin'" => "sending",
		"settin'" => "setting",
		"shootin'" => "shooting",
		"singin'" => "singing",
		"sittin'" => "sitting",
		"sleepin'" => "sleeping",
		"smilin'" => "smiling",
		"smokin'" => "smoking",
		"speakin'" => "speaking",
		"spendin'" => "spending",
		"starin'" => "stareing",
		"startin'" => "starting",
		"starvin'" => "starving",
		"stayin'" => "staying",
		"stickin'" => "sticking",
		"stoppin'" => "stopping",
		"sufferin'" => "suffering",
		"surprisin'" => "surprising",
		"swearin'" => "swearing",
		"talkin'" => "talking",
		"tearin'" => "tearing",
		"tellin'" => "telling",
		"thinkin'" => "thinking",
		"travellin'" => "travelling",
		"tryin'" => "trying",
		"turnin'" => "turning",
		"visitin'" => "visiting",
		"waitin'" => "waiting",
		"wanderin'" => "wandering",
		"warnin'" => "warning",
		"wastin'" => "wasting",
		"watchin'" => "watching",
		"wearin'" => "wearing",
		"weddin'" => "wedding",
		"willin'" => "willing",
		"windin'" => "winding",
		"wishin'" => "wishing",
		"wonderin'" => "wondering",
		"worryin'" => "worrying",
		"workin'" => "working",
		"interestin'" => "interesting",
		"leadin'" => "leading",
		"good-lookin'" => "good-looking",
		"gamblin'" => "gamling",
		"disgustin'" => "disgusting",
		"distressin'" => "distressing",
		"lovin'" => "loving",
		"murderin'" => "murdering",
		"sinkin'" => "sinking",
		"stinkin'" => "stinking",
		"lightin'" => "lighting",
		"lookin'" => "looking",
		"shavin'" => "shaving",
		"shoppin'" => "shopping",
		"perishin'" => "perishing",
		"risin'" => "rising",
		"amusin'" => "amusing",
		"'andsome" => "handsome",
		"'appier" => "happy",
		"'ungry" => "hungry",
		"writin'" => "writing");
}

sub fillAPOSlist()
{

    %APOSlist = (
		"'the" => "AT",
		"'a" => "AT1",
		"'and" => "CC",
		"'but" => "CCB",
		"'it" => "PPH1",
		"'you" => "PPY",
		"'i" => "PPIS1",
		"'yes" => "UH",
		"'oh" => "UH",
		"'this" => "DD1",
		"'what" => "DDQ",
		"'my" => "APPGE",
		"'your" => "APPGE",
		"'do" => "VD0",
		"'that" => "DD1",
		"'at" => "II",
		"'in" => "II",
		"'for" => "CS",
		"'he" => "PPHS1",
		"'she" => "PPHS1",
		"'we" => "PPHS2",
		"'they" => "PPHS2",
		"'if" => "CS",
		"'all" => "DB",
		"'good" => "JJ",
		"'well" => "UH",
		"'to" => "TO",
		"'not" => "XX",
		"'there" => "EX",
		"'why" => "RRQ",
		"'how" => "RRQ",
		"'look" => "VV0",
		"'mr" => "NNB",
		"'mrs" => "NNB",
		"'miss" => "NNB",
		"'of" => "RR21",
		"'an" => "AT1",
		"'have" => "VH0",
		"'because" => "CS",
		"'dirty" => "JJ",
		"'nice" => "JJ",
		"'never" => "RR",
		"'out" => "RP",
		"'something" => "PN1",
		"'those" => "DD2",
		"'great" => "JJ",
		"'green" => "JJ",
		"'hello" => "UH",
		"'jane" => "NP1",
		"'la" => "FU",
		"'no" => "AT");
}


sub fillsecondAPOSlist()
{

    %secondAPOSlist = (
		"for" => "unknown",
		"one" => "unknown",
		"sir" => "unknown",
		"thank" => "unknown",
		"dear" => "unknown",
		"go" => "unknown",
		"now" => "unknown",
		"so" => "unknown",
		"who" => "unknown",
		"here" => "unknown",
		"just" => "unknown",
		"let" => "unknown",
		"little" => "unknown",
		"on" => "unknown",
		"where" => "unknown",
		"very" => "unknown",
		"poor" => "unknown",
		"ah" => "unknown",
		"god" => "unknown",
		"when" => "unknown",
		"with" => "unknown",
		"be" => "unknown",
		"get" => "unknown",
		"please" => "unknown",
		"then" => "unknown",
		"keep" => "unknown",
		"bye" => "unknown",
		"by" => "unknown",
		"mermaid" => "unknown",
		"her" => "unknown",
		"nothing" => "unknown",
		"too" => "unknown",
		"home" => "unknown",
		"love" => "unknown",
		"man" => "unknown",
		"morning" => "unknown",
		"from" => "unknown",
		"give" => "unknown",
		"tell" => "unknown",
		"his" => "unknown",
		"take" => "unknown",
		"three" => "unknown",
		"young" => "unknown",
		"do" => "unknown",
		"go" => "unknown",
		"come" => "unknown");
}

sub get_long_words
{
	my ($path, $file) = @_;

	my $errfile = $path . $file . '.errors';
	open(ERR, "$errfile");
	my $suppfile = $path . $file . '.supp';
	open(SUPP, "$suppfile");

	my @errors = <ERR>;
	close(ERR);
	my @supps = <SUPP>;
	close(SUPP);


	shift(@supps);
	pop(@supps);
	my $found = 0;
	if ($#supps >= 0)
	{
		foreach my $error (@errors)
		{
			chomp($error);
			if ($error =~ /too long at ref/)
			{
				my $temp = $error;
				$temp =~ s/^(.+) '(.+)' too long at ref (.+)$/$2/;
#print "$temp\n";
				foreach my $supper (@supps)
				{
					chomp($supper);

#Brackets cause problems
					if ($supper =~ /\(/ || $supper =~ /\)/ )
					{
						print "$supper\n";
						$supper =~ s/\)//g;
						$supper =~ s/\(//g;
						print "$supper\n";
					}
					if ($temp =~ /\(/ || $temp =~ /\)/ )
					{
						$temp =~ s/\)//g;
						$temp =~ s/\(//g;
					}

					if ($supper =~ /$temp/i)
					{
						$found++;
					}
				}
			}
		}
	}

	if ($found == $#supps + 1)
	{

	}
	else
	{
		print "Different number ($found <> $#supps) of long words in $errfile vs. $suppfile?\n";
	}

	return @supps;
}