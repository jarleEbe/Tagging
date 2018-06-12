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
	if ($txt =~ /\.txt\.c7$/i)
	{
		$numFiles++;
		open(INN, "$basePath$txt");
		binmode INN, ":utf8";
		my @content = <INN>;
		close(INN);
		my $outputfile = $txt;
		$outputfile =~ s/_prepped\.txt\.c7/_cwb\.txt/;
		open(OUT, ">$resultPath$outputfile");
		binmode OUT, ":utf8";
		print "From CLAWS to CWB $txt\n";
		my $firstline = 0;
		foreach my $line (@content)
		{
		    chomp($line);
            if ($line =~ /------------------------/)
            {
                $firstline++;
                if ($firstline == 1)
                {
                    print OUT "<s>\n";
                }
                else
                {
                    print OUT "</s>\n<s>\n";
                }
            }
            elsif ($line =~ /;START   / || $line =~ /;text     /)
            {

            }
            else
            {
                #NB! Error + < > stuff
                $line =~ s/   ERROR\?    / /;
                $line =~ s/   <   / /;
                $line =~ s/   >   / /;
                $line =~ s/\s+/ /g;
			    $line = &convert_to_utf8($line);
                my @row = split/ /, $line;
                my $word = $row[2];
                my $pos = $row[4];
                if ($pos =~ /\[/)
                {
                    $pos =~ s/^\[//;
                    $pos =~ s/\]$//;
                    $pos =~ s/\/([0-9]+)$//;
                }
                my $lemma = 'dummy';
                $lemma = &lemmatize($word, $pos);

			    $line =~ s/&dollar;/\$/g;
			    $line =~ s/&pound;/\£/g;
			    $line =~ s/&mdash;/–/g;

			    $line =~ s/\s+/ /g;

        	    print OUT "$word\t$pos\t$lemma\n";
            }
		}
		print OUT "</s>\n";
		close(OUT);
	}
}
close(DS);
print "No. files processed: $numFiles\n";
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
#http://ucrel.lancs.ac.uk/claws7tags.html
sub lemmatize
{
    my ($w, $p) = @_;

    my $lemma = $w;
    
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

    if ($p =~ /^V/)
    {
        if (exists($lhash{$p}))
        {
            $lemma = $lhash{$p};
        }
    }

    if ($p =~ /^N/ && $p !~ /^NP/)
    {
        if ($w eq 'knives' || $w eq 'wives')
        {
            $lemma = $w;
            $lemma =~ s/ves$/fe/;
        }
        if ($p =~ /2$/ && $w =~ /s$/)
        {
            $lemma = $w;
            $lemma =~ s/s$//;
        }
    }
    
    $lemma = lc($lemma);
    return $lemma;
}