

<?php

/* ARGH  the below doesn't do what I think it should do.  Even when it's in a .htaccess file*/

RewriteEngine on
RewriteRule ^alice.html(.*)$      /journal/index_shell.php?date=$1&type=
# RewriteRule   ^/journal/(\d\d\d/\d\d/\d\d)/([^/])
# RewriteRule   ^/journal/index_shell.php?type=([^&]+)&date=(.*)    /u/$1/$2  [R]
# RewriteRule   ^/~([^/]+)/?(.*)    /u/$1/$2  [R]


/* 21 March 2009
	Foolishly (without having written even a visual sketch nor pseudocode), I'm writing a bit of a possible engine for a PHP-based journal.

	The idea at the moment is just to see if I can use mod_rewrite to get 

		http://robnugen.com/journal/index_shell.php?type=all&date=2009/03/21#breakthrough_meditation

	to display as 

		http://robnugen.com/journal/2009/03/21/breakthrough_meditation

*/
function print_rob($what)
{
	echo "<pre>";
	print_r($what);
	echo "</pre>";
}

foreach(array('type','date') as $var)
{
	print_rob($var . " = " . $_REQUEST[$var]);
}

?>