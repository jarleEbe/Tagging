#!/usr/bin/perl

use strict;
use utf8;
use XML::Parser;

my ($basePath) = @ARGV;

my $myencoding = "UTF-8";

opendir(DS, $basePath) or die $!;
my $numFiles = 0;
while (my $txt = readdir(DS))
{
	if ($txt =~ /_tokenized\.txt$/i || $txt =~ /_tagged\.txt$/i || $txt =~ /_cwb\.txt$/i)
	{
		$numFiles++;
		open(INN, "$basePath$txt");
        my $thefile = '';
        if ($txt =~ /_tokenized\.txt$/i)
        {
            my @content = <INN>;
            $thefile = join("\n", @content);
        }
        elsif ($txt =~ /_tagged\.txt$/i)
        {
            my @content = <INN>;
            $thefile = join("\n", @content); 
        }
        elsif ($txt =~ /_cwb\.txt$/i)
        {
            my @content = <INN>;
            $thefile = join("\n", @content); 
        }
        close(INN);
#        $thefile =~ s/&/&amp;/g;
        $thefile =~ s/&mdash;/--/g;
        $thefile =~ s/&lsqb;/\[/g;
        $thefile =~ s/&rsqb;/\]/g;
        $thefile =~ s/\–/--/g;
        $thefile = '<?xml version="1.0" encoding="utf-8"?>' . "\n" . '<text>' . "\n" . $thefile . "\n" . '</text>';
        print "Validating $basePath$txt in encoding $myencoding... \n";

        my $p1 = XML::Parser->new(ErrorContext => 2);

        unless ($p1->parse($thefile, ProtocolEncoding => $myencoding))
        {
            print "Error: $txt\n";
        }
    }
}
print "Validated $numFiles files\n";
exit;
