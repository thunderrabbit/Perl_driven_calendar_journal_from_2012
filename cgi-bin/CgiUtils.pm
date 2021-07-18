# CgiUtils.pm
# Copyright 99,00 Steve Ford (sford@geeky-boy.com) and made available under
#   Steve Ford's "standard disclaimer, policy, and copyright" notice.  See
#   http://www.geeky-boy.com/standard.html for details.  It is based on
#   GNU's "copyleft" and basically says that you can have this for free and
#   give it to anybody else so long as you: 1. don't make a profit from it,
#   2. include this notice in it, and 3. you indicate any changes you made.
package CgiUtils;

use Exporter ();
@ISA = qw(Exporter);
@EXPORT = qw(mkdef unstringify_hash unescape_string stringify_hash escape_string escape_nl unescape_nl htmlify html_die interp_string read_whole_file interp_whole_file merge_hash browser_type cgi_log set_cgi_log read_hash write_hash untaint_query untaint_path_info normalize_date);
###@EXPORT_OK = qw();

use Carp;


sub mkdef {
	my($ival, $repl) = @_;

	$repl = "" unless defined($repl);

	if (defined $ival) {
		return $ival;
	} else {
		return $repl;
	}
}  # mkdef


sub unstringify_hash {
	my($hashed_string, $hash) = @_;

	my($param, $value);

	my(@pairs) = split('&', (mkdef($hashed_string)));
	foreach (@pairs) {
		($param, $value) = split('=', $_, 2);
		$hash->{unescape_string(mkdef($param))} = unescape_string(mkdef($value));
	}
}  # unstringify_hash


sub unescape_string {
	($in_str) = @_;

	$_ = mkdef($in_str);

	tr/+/ /;       # pluses become spaces
	s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
	s/\r//g;       # we don't need no stinking CRs

	return ($_);
}  # unescape_string


sub stringify_hash {
	my($hash) = @_;

	my($parm, $value);
	my(@outlist) = ();

	foreach (keys %$hash) {
		$parm = escape_string($_);
		$value = escape_string($hash->{$_});
		push(@outlist, "$parm=$value");
	}

	return(join("\&", @outlist));
}  # stringify_hash


sub escape_string {
	($in_str) = @_;

	$_ = mkdef($in_str);

	s/([^a-zA-Z0-9_\-. ])/uc sprintf("%%%02x",ord($1))/eg;
	tr/ /+/;       # spaces become pluses

	return ($_);
}  # escape_string


sub escape_nl {
	($in_str) = @_;

	$_ = mkdef($in_str);

	s/\\/\\\\/gs;
	s/\n/\\n/gs;

	return ($_);
}  # escape_nl


sub unescape_nl {
	($in_str) = @_;

	$_ = mkdef($in_str);

	s/\\n/\n/gs;
	s/\\\\/\\/gs;

	return ($_);
}  # unescape_nl


sub htmlify {
	my($in_str) = @_;

	# get text, add leading and trailing space to make pattern matches easier.
	$_ = " " . mkdef($in_str) . " ";

	# Convert some special characters to html equiv
	s/\&/\&amp;/gs;
	s/</\&lt;/gs;
	s/>/\&gt;/gs;
	s/"/\&#34;/gs;

	# Handle some control characters
	s|.\cH||g;  # let backspace erase previous character

	# correct quoted normal links
	s|(\&\#34\;)(http:[/.,;:?&=~%+@#\-\w]+)(\&\#34\;)([^/~;\-\w])|"$2"$4|gis;

	# normal links
	s|\b(http:[/.,;:?&=~%+@#\-\w]+[/~;\-\w])([^/~;\-\w])|<a href="$1">$1</a>$2|gis;

	# correct quoted incomplete links
	s|([^:/-])(\&\#34\;)(www\.[/.,;:?&=~%+@#\-\w]+)(\&\#34\;)([^/~;\-\w])|$1"$3"$5|gis;
	s|([^:/])(\&\#34\;)(//www\.[/.,;:?&=~%+@#\-\w]+)(\&\#34\;)([^/~;\-\w])|$1"$3"$5|gis;

	# incomplete links
	s|([^:/-])\b(www\.[/.,;:?&=~%+@#\-\w]+[/~;\-\w])([^/~;\-\w])|$1<a href="http://$2">$2</a>$3|gis;
	s|([^:/])(//www\.[/.,;:?&=~%+@#\-\w]+[/~;\-\w])([^/~;\-\w])|$1<a href="http:$2">$2</a>$3|gis;

	# image links
	s|\bimg:([/.,;:?&=~%+@#\-\w]+[/~;\-\w])([^/~;\-\w])|<img src="http:$1">$2|gis;

	# correct for "&" in url
	s|(<a [^&>]+)\&amp\;([^>]*>)|$1\&$2|gis;

	# get rid of leading/trailing space
	s|^ ||gis;		s| $||gis;

	return $_;
}  # htmlify


sub html_die {
	my ($tool, $err_msg) = @_;

	print <<__EODIE__;
Content-Type: text/html
Expires: 0

<html>
<head><title>$tool Error</title></head>
<body bgcolor="#FFFFFF">
<h1>$tool Error</h1>
<hr>
<p>An error has occured and your submission could not be processed.
<b>Please examine the error message below, then use your browser
"back" function, fix the problem, and re-submit.</b>

<ul>
<h3><font color="#FF0000">$err_msg</font></h3>
</ul>
<hr>
</body>
</html>
__EODIE__

	cgi_log("$tool: $err_msg");

	croak("$tool: $err_msg");
}  # html_die


sub merge_hash {
	my ($dst_hash, $src_hash) = @_;

	foreach (keys %$src_hash) {
		$dst_hash->{$_} = $src_hash->{$_};
	}
}  # merge_hash


sub interp_string {
	my ($raw_str, $sym_hash) = @_;
	my ($sym, $val, $op, $tst, $body, $result);

	$_ = mkdef($raw_str);
	while (/<sym\s+(\w+)\s*>/is) {
		$sym = $1;
		if (defined $sym_hash->{$sym}) {
			$val = $sym_hash->{$sym};
		} else {
			$val = "$sym=*****";
		}
		s/<sym $sym>/$val/gis;
	}

	while (/<if\s+(\w+)\s*([=><!]+)\s*(\w+)\s*>(((?!<if)(?!<\/if>).)*)<\/if>/is) {
		$sym = $1;
		if (defined $sym_hash->{$sym}) {
			$val = $sym_hash->{$sym};
		} else {
			$val = 0;
		}
	  	$op = $2;
		$tst = $3;
		$body = $4;

		$result = ($val eq $tst) if ($op =~ /=+/);
		$result = ($val ne $tst) if ($op eq "!=");
		# == and != should work for strings and numbers.  The rest are numeric.
		$result = ($val > $tst) if ($op eq ">");
		$result = ($val >= $tst) if ($op eq ">=");
		$result = ($val < $tst) if ($op eq "<");
		$result = ($val <= $tst) if ($op eq "<=");
###print STDERR "if $val $op $tst, result=$result\n";

		if (!$result) {
			$body = "";
		}
		s/<if\s+(\w+)\s*([=><!]+)\s*(\w+)\s*>(((?!<if)(?!<\/if>).)*)<\/if>/$body/is;
	}

	# Catch any mal-formed if
	s/<if/\&lt;if/gis;  s/<\/if/\&lt;\/if/gis;

	return $_;
}  # interp_string


sub read_whole_file {
	my ($fname) = @_;

	open (RWF, $fname) || do {
		return (0, "read_whole_file: open $fname: $!");
	};

	my $big_string = join("", <RWF>);
	close(RWF);

	return (1, $big_string);
}  # read_whole_file


sub interp_whole_file {
	my ($fname, $sym_hash) = @_;

	my ($stat, $msg) = read_whole_file($fname);
	if (!$stat) {
		return (0, "interp_whole_file: $msg");
	}

	return (1, interp_string($msg, $sym_hash));
}


sub browser_type {
	my ($http_user_agent) = @_;

	$http_user_agent = mkdef($ENV{'HTTP_USER_AGENT'}) unless ($http_user_agent);

	if ($http_user_agent =~ /lynx/i) {
		$http_user_agent = "lynx";
	} elsif ($http_user_agent =~ /msie/i) {
		$http_user_agent = "ie";
	} elsif ($http_user_agent =~ /microsoft/i) {
		$http_user_agent = "ie";
	} elsif ($http_user_agent =~ /compatible/i) {
		$http_user_agent = "other";
	} elsif ($http_user_agent =~ /mozilla/i) {
		$http_user_agent = "netscape";
	} else {
		$http_user_agent = "other";
	}

	return $http_user_agent;
}  # browser_type


my $cgi_logfile = "";


sub set_cgi_log {
	($cgi_logfile) = @_;
}  # set_cgi_log


sub cgi_log {
	my ($msg) = @_;

	if (defined($cgi_logfile) and length($cgi_logfile) > 0) {
		if (open(CGILOG, ">>$cgi_logfile")) {
			print CGILOG (scalar localtime) . "; $msg\n";
			close(CGILOG);
		} else {
			carp("cgi_log: open($cgi_logfile), $!");
		}
	}
}  # cgi_log


sub read_hash {
	my ($hashfile, $inhash) = @_;
	my $stat;

	open(HASHFILE, $hashfile) || do {
		$stat = $!;
###		print STDERR "read_hash: open $hashfile failed ($stat)\n";
		return (0, "read_hash: open $hashfile failed ($stat)");
	};

	my @hash_lines = <HASHFILE>;
	close(HASHFILE);

	chomp(@hash_lines);

	foreach (@hash_lines) {
		if (/^\s*([^=#]+)=(.*)$/) {
			$inhash->{$1} = $2;
		}
	}

	return (1, "");
}  # read_hash


sub write_hash {
	my ($hashfile, $inhash) = @_;
	my $stat;

	open(HASHFILE, ">$hashfile") || do {
		$stat = $!;
		print STDERR "write_hash: open $hashfile failed ($stat)\n";
		return (0, "write_hash: open $hashfile failed ($stat)");
	};

	foreach (sort(keys %$inhash)) {
		print HASHFILE "$_=" . $inhash->{$_} . "\n";
	}
	close(HASHFILE);

	return (1, "");
}  # write_hash


# "arb_text" is anything and therefore is NOT safe for general use
# "safe_text" is alpha-numeric, dash, under-score, and space
# "sel_text" is for discrete sets of html-supplied values
# "date_text" is for flexible yyyy-mm-dd
# "wnum_text" is for whole numbers
sub untaint_query {
	my ($query_p, $key_defs_p) = @_;

	my $warn_str = "";
	my ($st, $key, $val);

	foreach $key (keys(%$query_p)) {
		$val = $query_p->{$key};

		# What kind of key is it?
		if (defined($key_defs_p->{$key})) {
			# switch on the key types
SWITCH:		for ($key_defs_p->{$key}) {
				/arb_text/ && do {
					$val =~ /^(.*)$/; $query_p->{$key} = $1;		# untaint
					last SWITCH;
				};
				/safe_text/ && do {
					if ($val =~ s/[^\w\-\.\/: ]+//gis) {
						$warn_str .= "unsafe text removed from value for $key\n";
					}
					$val =~ /^(.*)$/; $query_p->{$key} = $1;		# untaint
					last SWITCH;
				};
				/date_text/ && do {
					if ($val =~ s/[^\w\-\.\/: ]+//gis) {
						$warn_str .= "unsafe text removed from value for $key\n";
					}
					($st, $val) = normalize_date($val);	# untaint
					if ($st) {
						$query_p->{$key} = $val;
					} else {
						$warn_str .= "$val.\n";
						$query_p->{$key} = "";
					}
					last SWITCH;
				};
				/sel_text=(.*)$/ && do {
					foreach (split(/,/, $1)) {
						if ($_ eq $val) {
							$val =~ /^(.*)$/; $query_p->{$key} = $1;	# untaint
							last SWITCH;
						}
					}
					$warn_str .= "bad value for $key\n";
					$query_p->{$key} = "";
					last SWITCH;
				};
				/wnum_text/ && do {
					if ($val =~ s/[^\d]+//gis) {
						$warn_str .= "Non-numerics removed for $key\n";
					}
					$val =~ /^(.*)$/; $query_p->{$key} = $1;		# untaint
					last SWITCH;
				};
				do {
					html_die($tool, "untaint_query: bad key type ($_)");
				};
			}  # SWITCH
		} else {  # key not in valid_key_types
			$warn_str .= "unrecognized key ($key)\n";
			delete($query_p->{$key});
		}
	}  # foreach

	# Define any un-supplied queries
	foreach (keys(%$key_defs_p)) {
		$query_p->{$_} = "" unless exists($query_p->{$_});
	}

	return $warn_str;
}  # untaint_query


sub untaint_path_info {
	my ($path_info_p) = @_;

	# "safe_text" is alpha-numeric, dash, under-score, and space

	my $warn_str = "";

	foreach (@$path_info_p) {
		# Make it "safe text"
		if ($_ =~ s/[^\w\-\.\/: ]+//gis) {
			$warn_str .= "unsafe text removed in path_info; set to '$_'\n";
		}
		$_ =~ /^(.*)$/;  $_ = $1; 	# untaint
	}

	return $warn_str;
}  # untaint_path_info


# Expects yy-mm-dd or yyyy-mm-dd.  Month can also be 3-char alpha.
# Separator can be one of "- ./".  Leading zeros optional.
# Sanity checks dates between 1980-2030.
# Returns (1, "yyyy-mm-dd") or (0, "error msg")
sub normalize_date {
	my ($idate) = @_;

	my ($y, $m, $d);
	my @maxday = (-1, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	$_ = $idate;

	# convert 3-char month
	s/jan/ 01 /i;	s/feb/ 02 /i;	s/mar/ 03 /i;	s/apr/ 04 /i;
	s/may/ 05 /i;	s/jun/ 06 /i;	s/jul/ 07 /i;	s/aug/ 08 /i;
	s/sep/ 09 /i;	s/oct/ 10 /i;	s/nov/ 11 /i;	s/dec/ 12 /i;

	if (/^\s*(\d+)\s*[\.\/\- ]\s*(\d+)\s*[\.\/\- ]\s*(\d+)\s*$/) {
		($y, $m, $d) = ($1, $2, $3);	# untaint
	} else {
		return(0, "Bad date format ($idate)");
	}

	# Years 0-30 are 2000-2030, years 80-99 are 1980-1999
	if (($y > 30 && $y < 80) || ($y > 99 && $y < 1980) || ($y > 2030)) {
		return(0, "Bad year value ($idate)");
	}
	$y += 2000 if ($y <= 30);
	$y += 1900 if ($y <= 99);

	if ($m < 1 || $m > 12) {
		return(0, "Bad month value ($idate)");
	}
	if ($d < 1 || $d > $maxday[$m]) {
		return(0, "Bad day value ($idate)");
	}

	return(1, sprintf("%04d-%02d-%02d", $y, $m, $d));
}  # normalize_date

1;

