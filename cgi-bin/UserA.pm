# UserA.pm
# Copyright 1999 Steve Ford (sford@geeky-boy.com) and made available under the
#   Steve Ford's "standard disclaimer, policy, and copyright" notice.  See
#   http://www.geeky-boy.com/standard.html for details.  It is based on
#   GNU's "copyleft" and basically says that you can have this for free and
#   give it to anybody else so long as you: 1. don't make a profit from it,
#   2. include this notice in it, and 3. you indicate any changes you made.
package UserA;

use strict;

use CgiUtils;
use FileHandle;

my $LOCK_SH = 1;
my $LOCK_EX = 2;
my $LOCK_NB = 4;
my $LOCK_UN = 8;

# standard constructor for objects.
sub new {
	my $class = shift;
	my(@parms) = @_;

	my $self = {};
	bless $self, $class;

	my($stat, $msg) = $self->_init(@parms);

	# This form of return allows for:
	#   my $obj = new ...
	# or:
	#   my($stat, $msg, $obj) = new ...
	# but will *NOT* work for:
	#   my($obj) = new ...

	# combine return msg (if any) with this funct name
	return ($stat, (length($msg) ? "UserA::new: $msg" : ""), $self);
}


my %default_new = (
	BASE => "../UserA",
	REALM => "UserA",	# cookie name; allows independant logins
	ACCESS => "rw",
	USERNAME => "",
	PASSWORD => "",
	CGIDIR => "/cgi-bin",
	TARFILE => "UserA.files.tar",
	UMASK => "007" );

sub _init {
	my $self = shift;
	my ($over) = @_;

	$self->{'STATE'} = "error";

	$self->{'USER_DATA'} = [];		# anonymous array
	my $user_data = $self->{'USER_DATA'};
	@$user_data = ();

	# Set defaults.
    foreach (keys %default_new) {
		$self->{$_} = $default_new{$_};
	}

	# Override defaults.
	if (defined $over) {
		foreach (keys %$over) {
			if (defined $self->{$_}) {
				$self->{$_} = $over->{$_};
			} else {
				return (0, "UserA::_init: illegal override $_");
			}
		}
	}


	if (! -d $self->{'BASE'}) {
		return (0, "UserA::_init: cant access base $self->{'BASE'}");
	}

	umask(oct($self->{'UMASK'}));

	$self->{'STATE'} = "closed";
	$self->{'USERDIR'} = "";
	$self->{'USERNAME'} = "";
	$self->{'PASSWORD'} = "";
	$self->{'DIRTY'} = 0;

	if (length($self->{'USERNAME'}) == 0) {
		return (1, "");
	}

	#
	# username supplied, open user file and verify password.
	#

	my($stat, $msg) = $self->open_user($self->{'USERNAME'}, $self->{'PASSWORD'});
	return ($stat, (length($msg) ? "UserA::_init: $msg" : ""));
}  # _init


sub open_user {
	my $self = shift;
	my ($username, $password) = @_;

	if ($self->{'STATE'} eq "open" || $self->{'STATE'} eq "locked") {
		$self->close_user;
	}

	$self->{'STATE'} = "error";
	$self->{'USERDIR'} = "";
	$self->{'USERNAME'} = "";
	$self->{'PASSWORD'} = "";
	$self->{'DIRTY'} = 0;

	my $user_data = $self->{'USER_DATA'};
	@$user_data = ();

	if (length(mkdef($username)) == 0) {
		return (0, "UserA::open_user: no username");
	}
	if (length(mkdef($password)) == 0) {
		return (0, "UserA::open_user: username without password");
	}

	my $userdir = "$self->{'BASE'}/$username";
	my $userfile = "$userdir/user_data.txt";
	if (! -r "$userfile") {
		return (0, "UserA::open_user: cant access $username");
	}

	if (! open(USERFILE, "+<$userfile")) {
		return (0, "UserA::open_user: $userfile: $!");
	}
	$self->{'FH'} = \*USERFILE;
	my $fh = $self->{'FH'};

	if (! flock($fh, $LOCK_EX)) {
		my $stat = $!;
		close($fh);
		return (0, "UserA::open_user: flock failed: $stat");
	}
	$self->{'STATE'} = "locked";

	@{$user_data} = <$fh>;

	foreach (@$user_data) {
		if (/^PASSWORD=(.*)\n$/) {
			if ($password eq $1) {
				$self->{'USERDIR'} = $userdir;
				$self->{'USERNAME'} = $username;
				$self->{'PASSWORD'} = $password;
				return (1, "");
			}
		}
	}

	close($fh);
	$self->{'STATE'} = "error";
	$self->{'USERDIR'} = "";
	$self->{'USERNAME'} = "";
	$self->{'PASSWORD'} = "";
	$self->{'DIRTY'} = 0;
	return (0, "UserA::open_user: password mismatch");
}  # open_user


sub open_session {
	my $self = shift;
	my ($username, $session) = @_;

	if ($self->{'STATE'} eq "open" || $self->{'STATE'} eq "locked") {
		$self->close_user;
	}

	$self->{'STATE'} = "error";
	$self->{'USERDIR'} = "";
	$self->{'USERNAME'} = "";
	$self->{'PASSWORD'} = "";
	$self->{'DIRTY'} = 0;

	my $user_data = $self->{'USER_DATA'};
	@$user_data = ();

	if (length(mkdef($username)) == 0) {
		return (0, "UserA::open_session: no username");
	}
	if (length(mkdef($session)) == 0) {
		return (0, "UserA::open_session: username without session");
	}

	my $userdir = "$self->{'BASE'}/$username";
	my $userfile = "$userdir/user_data.txt";
	if (! -r "$userfile") {
		return (0, "UserA::open_session: cant access $username");
	}

	if (! open(USERFILE, "+<$userfile")) {
		return (0, "UserA::open_session: $userfile: $!");
	}
	$self->{'FH'} = \*USERFILE;
	my $fh = $self->{'FH'};

	if (! flock($fh, $LOCK_EX)) {
		my $stat = $!;
		close($fh);
		return (0, "UserA::open_session: flock failed: $stat");
	}
	$self->{'STATE'} = "locked";

	@$user_data = <$fh>;

	# The "login" hash has the session ID
	my %login;
	my ($stat, $msg) = $self->read_userhash("login", \%login);
	$msg = (length($msg) ? "UserA::open_session: $msg" : "");
	return ($stat, $msg) unless ($stat);

	# Successful login?
	if ($session == $login{'SESSION'}) {
		# load up object data
		$self->{'USERDIR'} = $userdir;
		$self->{'USERNAME'} = $username;
		foreach (@$user_data) {
			if (/^PASSWORD=(.*)\n/) {
				$self->{'PASSWORD'} = $1;
			}
		}

		return (1, "");
	}

	close($fh);
	$self->{'STATE'} = "error";
	$self->{'USERDIR'} = "";
	$self->{'USERNAME'} = "";
	$self->{'PASSWORD'} = "";
	$self->{'DIRTY'} = 0;
	return (0, "UserA::open_session: session mismatch");
}  # open_session


sub create_user {
	my $self = shift;
	my ($username, $password) = @_;

	if ($self->{'STATE'} eq "open" || $self->{'STATE'} eq "locked") {
		$self->close_user;
	}

	$self->{'STATE'} = "error";
	$self->{'USERDIR'} = "";
	$self->{'USERNAME'} = "";
	$self->{'PASSWORD'} = "";
	$self->{'DIRTY'} = 0;

	my $user_data = $self->{'USER_DATA'};
	@$user_data = ();

	if (length(mkdef($username)) == 0) {
		return (0, "UserA::create_user: no username.  Try again.");
	}
	if (length(mkdef($password)) == 0) {
		return (0, "UserA::create_user: username without password.  Try again.");
	}
	if (! ($username =~ m/^[a-z0-9_\-]+$/i)) {
		my $t = $username;
		$t =~ s/[a-z0-9_\-]//gi;
		$t =~ s/ /(space)/;
		return (0, "UserA::create_user: Weird character(s) '$t' in Username '$username'; use alpha-numerics only.  Try again.");
	}

	my $userdir = "$self->{'BASE'}/$username";
	my $userfile = "$userdir/user_data.txt";
	my $tarpath = "$self->{'BASE'}/$self->{'TARFILE'}";
	if (-r "$userfile") {
		return (0, "UserA::create_user: $username already exists");
	}

	my $err_msg = "UserA::create_user: unknown error";

	push(@$user_data, "PASSWORD=$password\n");
	$self->{'DIRTY'} = 1;
	$err_msg = "";	# no error

	# No error, create the user
	if (! mkdir($userdir, oct("770"))) {
		return (0, "UserA::create_user: $userdir: $!");
	}
	chmod(oct("770"), "$userdir");
	if (! open(USERFILE, "+>$userfile")) {
		return (0, "UserA::create_user: $userfile: $!");
	}
	chmod(oct("770"), "$userfile");
	if (-f $tarpath) {
		system("cd $userdir;tar xf $tarpath");
	}
	$self->{'FH'} = \*USERFILE;
	my $fh = $self->{'FH'};

	if (! flock($fh, $LOCK_EX)) {
		my $stat = $!;
		close($fh);
		return (0, "UserA::create_user: flock failed: $stat");
	}
	$self->{'STATE'} = "locked";
	$self->{'USERDIR'} = $userdir;
	$self->{'USERNAME'} = $username;
	$self->{'PASSWORD'} = $password;

	$self->flush_user;

	return (1, "");
}  # create_user


sub close_user {
	my $self = shift;

	if ($self->{'STATE'} eq "open" || $self->{'STATE'} eq "locked") {
		$self->flush_user;

		close($self->{'FH'});
	}

	$self->{'STATE'} = "closed";
	$self->{'USERNAME'} = "";
	$self->{'PASSWORD'} = "";
	$self->{'DIRTY'} = 0;

	return (1, "");
}  # close_user


sub flush_user {
	my $self = shift;

	if ($self->{'STATE'} eq "open" || $self->{'STATE'} eq "locked") {
		my $fh = $self->{'FH'};
		if ($self->{'DIRTY'}) {
			seek($fh, 0, 0);
			print {$fh}  @{$self->{'USER_DATA'}};
			truncate($fh, tell($self->{'FH'}));
			$self->{'DIRTY'} = 0;
		}
	}

	return (1, "");
}  # flush_user


sub read_userhash {
	my $self = shift;
	my ($hash_name, $hash_ref) = @_;
	my $num_keys = 0;

	if ($self->{'STATE'} ne "locked" && $self->{'STATE'} ne "open") {
		return (0, "UserA::read_userhash: not open ($self->{'STATE'})");
	}

	my $l;	# I'm not sure why I need this.  When I use $_ it actually modifies
			# the user_data hash, replacing it with unescape_nl($2).
	foreach $l (@{$self->{'USER_DATA'}}) {
		if ($l =~ /^$hash_name-([^=]*)=(.*)\n$/) {
			$hash_ref->{$1} = unescape_nl($2);
			++ $num_keys;
		}
	}

	return (0, "UserA::read_userhash: no hash '$hash_name'") if ($num_keys == 0);

	return (1, "");
}  # read_userhash


sub write_userhash {
	my $self = shift;
	my ($hash_name, $hash_ref) = @_;

	if ($self->{'STATE'} ne "locked") {
		return (0, "UserA::write_userhash: not open ($self->{'STATE'})");
	}

	$self->rm_lines("$hash_name-");

	foreach (keys %$hash_ref) {
		push(@{$self->{'USER_DATA'}},
			 "$hash_name-$_=" . escape_nl($hash_ref->{$_}) . "\n");
		$self->{'DIRTY'} = 1;
	}

	return (1, "");
}  # write_userhash


sub set_pass {
	my $self = shift;
	my ($password) = @_;

	if ($self->{'STATE'} ne "locked") {
		return (0, "UserA::set_pass: not open ($self->{'STATE'})");
	}

	$self->rm_lines("PASSWORD=");
	push(@{$self->{'USER_DATA'}}, "PASSWORD=$password\n");

	$self->{'DIRTY'} = 1;
	return (1, "");
}  # set_pass


sub rm_lines {
	my $self = shift;
	my ($prefix) = @_;

    my $user_data = $self->{'USER_DATA'};

    my $ln = 0;

    while ($ln < @$user_data) {
        if (substr($user_data->[$ln], 0, length($prefix)) eq $prefix) {
            splice(@$user_data, $ln, 1);
			$self->{'DIRTY'} = 1;
        } else {
            ++$ln;
        }
    }

	return (1, "");
}  # rm_lines


sub try_login {
	my $self = shift;
	my ($username, $password) = @_;
	my ($stat, $msg);
	my $warning = "";

	my $cgidir = $self->{'CGIDIR'};

	if ($username =~ s/\W+//gs) {
		if (length($username) == 0) {
			return (0, "Invalid username - please use letters and numbers");
		}
		$warning .= "<p><b>Warning</b>, strange characters have been removed from your username.";
	}
	if ($username ne lc($username)) {
		$warning .= "<p><b>Warning</b>, your username has been converted to LOWER CASE.";
	}
	if (length($username) == 0) {
		return (0, "Hey, I don't require much, but you NEED to give me a username!");
	}

	if ($password =~ s/[\x00- \x80-\xff]+//gs) {
		if (length($password) == 0) {
			return (0, "Invalid password - please use normal characters");
		}
		$warning .= "<p><b>Warning</b>, strange characters have been removed from your password.";
	}
	if (length($password) == 0) {
		return (0, "Hey, I don't require much, but you NEED to give me a password!");
	}

	($stat, $msg) = $self->open_user($username, $password);
	if (!$stat) {
		if ($msg =~ /open_user:.*password mismatch/) {
			return (0, "Wrong password.  (Check caps-lock)");
		}
		if ($msg =~ /open_user:.*can'*t access/) {
			return(0, "Password mismatch or no such user.");
		}
	}

	return (1, $warning);
}  # try_login


sub try_session {
	my $self = shift;
	my ($username, $session) = @_;
	my ($stat, $msg);
	my $warning = "";

	my $cgidir = $self->{'CGIDIR'};

	if ($username =~ s/\W+//gs) {
		if (length($username) == 0) {
			return (0, "Invalid username - please use letters and numbers");
		}
		$warning .= "<p><b>Warning</b>, strange characters have been removed from your username.";
	}
	if ($username ne lc($username)) {
		$warning .= "<p><b>Warning</b>, your username has been converted to LOWER CASE.";
	}
	if (length($username) == 0) {
		return (0, "Hey, I don't require much, but you NEED to give me a username!");
	}

	($stat, $msg) = $self->open_session($username, $session);
	if (!$stat) {
		if ($msg =~ /open_session: session mismatch/) {
			return(0, "Lost session, please log in again.");
		}
	}

	return (1, $warning);
}  # try_session


# rtn stat: 0=error,msg|1=already logged in|2=login OK,set cookie|3=logged out
sub login_session {
	my $self = shift;
	my ($query, $env, $url) = @_;

	my $tool = "UserA::login_session";
	my $cgidir = $self->{'CGIDIR'};
	my $realm = $self->{'REALM'};
	my ($stat, $msg, $html) = (-1, "", "");

	# Get IP address
	my ($via_ip, $http_ip) = ("", "");
	if (defined($env->{'REMOTE_HOST'})) {
		$via_ip .= "$env->{'REMOTE_HOST'}";
	} elsif (defined($env->{'REMOTE_ADDR'})) {
		$via_ip .= "$env->{'REMOTE_ADDR'}";
	}
	if (defined($env->{'HTTP_X_FORWARDED_FOR'})) {
		$http_ip = $env->{'HTTP_X_FORWARDED_FOR'};
		if (length($via_ip) > 0) {
			$http_ip .= " via $via_ip";
		}
	} else {
		$http_ip = $via_ip;
	}

	my %cookie;
	$_ = mkdef($env->{'HTTP_COOKIE'});
	s/"//gs;
	$_ .= ";";
	if (/$realm=([^ ;]*)[ ;]/) {
		unstringify_hash(unescape_string($1), \%cookie);
	}
	my $username = lc(mkdef($cookie{'USERNAME'}));
	my $session = lc(mkdef($cookie{'SESSION'}));

	my $login_username = lc(mkdef($query->{'USERNAME'}));
	my $password = lc(mkdef($query->{'PASSWORD'}));
	my $newlogin_username = lc(mkdef($query->{'NEWUSERNAME'}));
	my $newpassword = lc(mkdef($query->{'NEWPASSWORD'}));

	# See if user is trying to create a new login.
###	if (length($newlogin_username) > 0 && $newlogin_username ne $username) {
	if (length($newlogin_username) > 0) {
		# User is trying to create.
		($stat, $msg) = $self->create_user($newlogin_username, $newpassword);
		if ($stat) {
			# Finish creating
			$query->{'DATETIME'} = scalar localtime;
			$self->write_userhash("newlogin", $query);

			# User succeeded in logging in, create session.
			srand(time() ^ ($$ + ($$ << 15)));
			my $session = int(rand(99999999));
			my %login = (DATETIME=>scalar localtime(), SESSION=>$session);
			($stat, my $msg1) = $self->write_userhash("login", \%login);
			html_die($tool, $msg1) unless ($stat);

			my %cookie = (USERNAME=>$newlogin_username, SESSION=>$session);
			my $set_cookie = escape_string(stringify_hash(\%cookie));

			$self->flush_user;
			cgi_log("$tool: ++$login_username $env->{'REQUEST_METHOD'} $url from $http_ip");
			return (2, "Set-Cookie: $realm=\"$set_cookie\"; Path=/;\n");
		}

		cgi_log("$tool: --$login_username $env->{'REQUEST_METHOD'} $url from $http_ip");
		return (0, $msg);
	}


	# See if user is trying to log in.
	if (length($login_username) > 0) {
		# User is trying to log in.
		($stat, $msg) = $self->try_login($login_username, $password);
		if ($stat) {
			# User succeeded in logging in, create session.
			srand(time() ^ ($$ + ($$ << 15)));
			my $session = int(rand(99999999));
			my %login = (DATETIME=>scalar localtime(), SESSION=>$session);
			($stat, my $msg1) = $self->write_userhash("login", \%login);
			html_die($tool, $msg1) unless ($stat);

			my %cookie = (USERNAME=>$login_username, SESSION=>$session);
			my $set_cookie = escape_string(stringify_hash(\%cookie));

			cgi_log("$tool: +$login_username $env->{'REQUEST_METHOD'} $url from $http_ip");
			return (2, "Set-Cookie: $realm=\"$set_cookie\"; Path=/;");
		}

		cgi_log("$tool: -$login_username $env->{'REQUEST_METHOD'} $url from $http_ip");
		return (0, $msg);
	}

	# User isn't trying to log in.  See if he already is.

	if (length($username) > 0) {
		# User thinks he is logged in
		my ($stat, $msg) = $self->try_session($username, $session);
		if ($stat) {
			# User is indeed logged in.
			cgi_log("$tool: $username $env->{'REQUEST_METHOD'} $url from $http_ip");
			return (1, $msg);
		}

		# invalid session.
		cgi_log("$tool: !$username $env->{'REQUEST_METHOD'} $url from $http_ip");
		return (0, $msg);
	}

	# User not logged in and not trying either.
	cgi_log("$tool: . $env->{'REQUEST_METHOD'} $url from $http_ip");
	return (3, $msg);
}  # login_session


sub find_userdir {
	my $self = shift;
	my ($username) = @_;

	if ( -d "$self->{'BASE'}/$username") {
		return "$self->{'BASE'}/$username";
	}

	return "";		# error
}  # find_userdir


sub logout_session {
	my $self = shift;
	my ($query, $env, $url) = @_;

	my $tool = "UserA::logout_session";
	my $cgidir = $self->{'CGIDIR'};
	my $realm = $self->{'REALM'};
	my ($stat, $msg, $html) = (-1, "", "");

	# Get IP address
	my ($via_ip, $http_ip) = ("", "");
	if (defined($env->{'REMOTE_HOST'})) {
		$via_ip .= "$env->{'REMOTE_HOST'}";
	} elsif (defined($env->{'REMOTE_ADDR'})) {
		$via_ip .= "$env->{'REMOTE_ADDR'}";
	}
	if (defined($env->{'HTTP_X_FORWARDED_FOR'})) {
		$http_ip = $env->{'HTTP_X_FORWARDED_FOR'};
		if (length($via_ip) > 0) {
			$http_ip .= " via $via_ip";
		}
	} else {
		$http_ip = $via_ip;
	}

	my %cookie;
	$_ = mkdef($env->{'HTTP_COOKIE'});
	s/"//gs;
	$_ .= ";";
	if (/$realm=([^ ;]*)[ ;]/) {
		unstringify_hash(unescape_string($1), \%cookie);
	}
	my $username = lc(mkdef($cookie{'USERNAME'}));
	my $session = lc(mkdef($cookie{'SESSION'}));

	cgi_log("$tool: $username $env->{'REQUEST_METHOD'} $url from $http_ip");

	return (1, "Set-Cookie: $realm=\"\"; Path=/;");
}  # logout_session


1;

