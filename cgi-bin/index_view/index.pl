#!/usr/bin/perl

use Slurper;

print "Content-type: text/html\n\n";

&getArgs;
if ($argHash{'URL'}) {
    &getListOfImages;
}
&printForm;

# end main

sub getListOfImages {

    my ($URL) = $argHash{'URL'};

    $body = `wget $URL -O -`;

    $imgtype = "(gif|png|jpg|jpeg)";
    print "can only do $imgtype files.  Change this in /cgi-bin/index_view/index.pl";
    while ( $body =~ m|
               <\s*
               [Aa]\s+
               [^>]*?                # See note 1 below
               [Hh][Rr][Ee][Ff]\s*   #
               =\s*
               (\"?)                 # the url \"? delimiter
               ([^\s\"\>]*)          # the url itself
               \1\s*                 # the delimiter again
               [^>]*?                # the non-greedy is key
               >
    # Note 1: The [^>]*? could soak up the rest of the url,
    # except that we are given that there is only one occurrence
    # of href outside the url.
              |xgs ) {

	    my $image = $2;
	    if ($image =~ m/$imgtype/i) {
		push (@image_list,$image);
	    }
	}
}

sub printForm {
    print '<form name="form1" action="">';

    &printURL;
    # not used yet    &printRadio;
    &printSelect;
    &printSubmit;

    print '</form>';
    print "<div id='pic'><img id='image' src='' /></div>";
}  # end printForm

sub printURL {
    my ($URL) = $argHash{'URL'};

    $URL = "http://sniffsniff:elbow\@robnugen.com/images/funny/comics/getfuzzy/" unless ($URL);

    if (!$URL) {
	print "Enter the full URL of a directory with images in it:";
    }
    else {
	print "Viewing URL:";
    }
    print "\n<input type=text name='URL' value='$URL' size='90'>";
}

sub printRadio {
    print "<br>\n";
    print "<input type=radio name=imageType value=all> all\n";
    print "<input type=radio name=imageType value=gif> .gif\n";
    print "<input type=radio name=imageType value=jpg> .jpg\n";
}

sub printSelect {

print <<EndText;
<select name='imageSelectList' onchange='getElementById("image").src=form1.imageSelectList.options[selectedIndex].value'>
EndText

    &printListOptionTags;

    print "</select>  choose picture\n";
} # end printSelect

sub printListOptionTags {
    # this will print all the values determined by getListOfImages

    my ($URL) = $argHash{'URL'};
    my ($image);

    foreach $image (@image_list) {

	print "<option value='$URL$image'>$image\n";
    }

}

sub getArgs {
    my @ARGV = split(/&/, $ENV{"QUERY_STRING"});
    foreach (@ARGV) {
	my ($key,$value) = split(/=/);

	# unsmurf %HEX chars from $value
	$value =~ s/%([a-fA-F0-9]{2})/chr(hex($1))/ge;
	$argHash{$key} = $value;
    }
}

sub printSubmit {
    print "\n<input type=submit>";
}

