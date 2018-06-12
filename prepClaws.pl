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
		$outputfile =~ s/\.txt/_prepped\.txt/;
		open(OUT, ">$resultPath$outputfile");
		binmode OUT, ":utf8";
		print "Preprocessing for CLAWS $txt\n";
		print OUT "<text>\n";
		foreach my $line (@content)
		{
		    chomp($line);
			$line =~ s/^\x{FEFF}//;
			$line =~ s/\x{000B}//g;

			$line =~ s/<([^>]+?)>//g;
			$line =~ s/^\s+//;
			$line =~ s/\s+$//;
			$line =~ s/([\t\n\f\r\p{IsZ}]+)/ /g;
			$line =~ s/(\p{isAlnum})_(\p{isAlnum})/$1$2/g;
			$line =~ s/_/ /g;
			$line =~ s/\*//g;
			$line =~ s/\|//g;

			$line =~ s/\$/&dollar;/g;
			$line =~ s/&/&amp;/g;

			$line =~ s/--/&mdash;/g;
			$line =~ s/−/&mdash;/g;
			$line =~ s/–/&mdash;/g;
			$line =~ s/—/&mdash;/g;
			$line =~ s/–/&mdash;/g;
			$line =~ s/&mdash;/ &mdash; /g;

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

			$line = &convert_to_entities($line);

			$line =~ s/\s+/ /g;

        	print OUT "$line ";
		}
		print OUT "\n</text>";
		close(OUT);
	}
}
close(DS);
print "No. files processed: $numFiles\n";
exit;


sub convert_to_entities
{
	my $string = shift(@_);

    my %hasj = (
		'Š' => '&Scaron;',
		'Œ' => '&OElig;',
		'Ž' => '&Zcaron;',
		'š' => '&scaron;',
		'œ' => '&oelig;',
		'ž' => '&zcaron;',
		'Ÿ' => '&Yuml;',
		'¡' => '&iexcl;',
		'¢' => '&cent;',
		'£' => '&pound;',
		'¥' => '&yen;',
		'§' => '&sect;',
		'¿' => '&iquest;',
		'À' => '&Agrave;',
		'Á' => '&Aacute;',
		'Â' => '&Acirc;',
		'Ã' => '&Atilde;',
		'Ä' => '&Auml;',
		'Å' => '&Aring;',
		'Æ' => '&AElig;',
		'Ç' => '&Ccedil;',
		'È' => '&Egrave;',
		'É' => '&Eacute;',
		'Ê' => '&Ecirc;',
		'Ë' => '&Euml;',
		'Ì' => '&Igrave;',
		'Í' => '&Iacute;',,
		'Î' => '&Icirc;',
		'Ï' => '&Iuml;',
		'Ð' => '&ETH;',
		'Ñ' => '&Ntilde;',
		'Ò' => '&Ograve;',
		'Ó' => '&Oacute;',
		'Ô' => '&Ocirc;',
		'Õ' => '&Otilde;',
		'Ö' => '&Ouml;',
		'×' => '&times;',
		'Ø' => '&Oslash;',
		'Ù' => '&Ugrave;',
		'Ú' => '&Uacute;',
		'Û' => '&Ucirc;',
		'Ü' => '&Uuml;',
		'Ý' => '&Yacute;',
		'Þ' => '&THORN;',
		'ß' => '&szlig;',
		'à' => '&agrave;',
		'á' => '&aacute;',
		'â' => '&acirc;',
		'ã' => '&atilde;',
		'ä' => '&auml;',
		'å' => '&aring;',
		'æ' => '&aelig;',
		'ç' => '&ccedil;',
		'è' => '&egrave;',
		'é' => '&eacute;',
		'ê' => '&ecirc;',
		'ë' => '&euml;',
		'ì' => '&igrave;',
		'í' => '&iacute;',
		'î' => '&icirc;',
		'ï' => '&iuml;',
		'ð' => '&eth;',
		'ñ' => '&ntilde;',
		'ò' => '&ograve;',
		'ó' => '&oacute;',
		'ô' => '&ocirc;',
		'õ' => '&otilde;',
		'ö' => '&ouml;',
		'÷' => '&divide;',
		'ø' => '&oslash;',
		'ù' => '&ugrave;',
		'ú' => '&uacute;',
		'û' => '&ucirc;',
		'ü' => '&uuml;',
		'ý' => '&yacute;',
		'þ' => '&thorn;',
		'ÿ' => '&yuml;');

    foreach my $key (keys(%hasj))
    {
		my $char = $key;
		my $entity = $hasj{$key};
        $string =~ s/$char/$entity/g;
    }

    return $string;

}


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
