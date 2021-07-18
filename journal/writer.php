<?php

$master_password = array();
$master_password['pre'] = "<!-- md5:";    // what will be before the md5 of master PW
$master_password['post'] = " -->";	// what will be after the md5 of master PW
$master_password['min_length'] = 8;	// of the non md5 version
$master_password['max_length'] = 18;	// of the non md5 version



try
{

	if (!find_master_PW_in_source($master_password))
	{
		// Look for 2 master passwords.  if they match and fit our criteria, then write them to the file

		if(!$_POST)
			throw new Exception("Welcome to journal writer.  Enter your master password twice:",1);

		if(!good_password($_POST['PW1'],$master_password))
			throw new Exception("bad first password",1);

		if(!good_password($_POST['PW2'],$master_password))
			throw new Exception("bad second password",1);

		if ($_POST['PW1'] != $_POST['PW2'])
			throw new Exception("passwords don't match",1);

		$master_password['md5'] = md5($_POST['PW1']);
		append_master_password_to_source($master_password);

		throw new Exception("wrote master password to this source code",2);
	}
	else
	{
		// look for password
		// look for title
		// don't allow overwrite unless we are encrypted via HTTPS (cookies / IP are not secure: they can be faked if this source is given away freely)
		// preferably fill in textarea with date and such
		throw new Exception("Enter your journal entry, if you dare!<br/>And by this I mean simply I don't know how to save yet.  Not even close.",2);
	}
}
catch (Exception $e)
{
	echo $e->getMessage();

	switch($e->getCode())
	{
		case 1: write_2PW_fields();
			break;
		case 2: write_journal_entry_fields();
			break;
		default:  echo "dead";
	}

}

function find_master_PW_in_source($master_password)
{

	$master_password['md5'] = "";						// if we find the md5 of master password, put it here
	$my_source_filename = getenv('SCRIPT_FILENAME');			// get the unix filename of this source code
	$my_source_handle = fopen($my_source_filename, 'r');			// open this source code
	$my_source = fread($my_source_handle, filesize($my_source_filename));	// read this source code

	$master_pattern = "/" . $master_password['pre'] . '(.{32})' . $master_password['post'] . "/";	// this will look for a master password in the source code

	$matches = array();
	if(preg_match($master_pattern, $my_source, $matches))
	{
		// we found a master password in the file
		$master_password['md5'] = $matches[1];
	}

	return $master_password['md5'];
}

function append_master_password_to_source($master_password)
{
	// append this line to the end of this file
	$master_password_line = "\n" . $master_password['pre'] . $master_password['md5'] . $master_password['post'] . "\n";
	$my_source_filename = getenv('SCRIPT_FILENAME');			// get the unix filename of this source code
	$my_source_handle = fopen($my_source_filename, 'a');			// open this source code for append
	fwrite($my_source_handle, $master_password_line);
}


function write_2PW_fields()
{
?>
	<form method="POST" action="<?=$_SERVER['PHP_SELF']?>">
	<input type="password" name="PW1">
	<input type="password" name="PW2">
	<input type="submit">
	</form>
<?php
}

function write_journal_entry_fields()
{
?>
	<form method="POST" action="<?=$_SERVER['PHP_SELF']?>">
	<br/>password: <input type="password" name="PW">
	<br/>title: <input type="text" name="title">
	<br/>entry: <textarea name="entry_data" rows="35" cols="85"><?=date("g:iA J\S\T l j F Y", time() + (17 * 60 * 60))?> (day 13800)

really should not hardcode the days old!
</textarea>
	<br/><input type="submit">
	</form>
<?php
}


function good_password($pw,$master_password)
{
	$pattern = "/[A-Za-z0-9]{" . $master_password['min_length'] . "," . $master_password['max_length'] . "}/";
	return preg_match($pattern,$pw);
}

function print_rob($item)
{
	echo "<pre>";
	print_r($item);
	echo "</pre>";
}
?>
<!-- md5:f24aed6191e5e38a33c574b3fb161fdf -->
