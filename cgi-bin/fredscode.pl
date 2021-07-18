#!/usr/bin/perl -w

#Biggest score wins. "w" (see below) is infinity.
$debug = 0;
$UniqueUnits = shift;
$x = shift;
while ($string = shift) {
    $calcstring .= $string . " ";
}

$Fred_might_hate_this_multiplier = 10;  #  This is to give scores a greater range

print "unique units: $UniqueUnits ";
print "x: $x || scores:";


if ($x<0) {
    #First make x>0 (rare, but it happens)
    $x = 1 - $x;
} elsif ($x<1) {
    #Second make x>1, so reversing the units achieves the same score:
    $x=1/$x;
}



if ($UniqueUnits == 0) {
	$closeness = "irrelevant";
       	$Bscore = $Ascore = $Fscore = "be more original"
} else {
    if($x==1) {
	#$x==1
	$closeness = "infinity";
	$Fscore = "w + 1/$UniqueUnits";     #more units means smaller increment
	$Ascore = "$closeness + $UniqueUnits";     #more units means smaller increment
	$Bscore = $Ascore;
    } else {
	# This counts the number of zeros past the decimal..
	$closeness = - (&log10($x-1));
	
	$Fscore = $Fred_might_hate_this_multiplier * ($closeness - 2*($UniqueUnits-3));
	$Ascore = ($closeness + $UniqueUnits);
	$Bscore = ($closeness + sqrt($UniqueUnits));
    }
} # $UniqueUnits != 0

## $debug && print "closeness: $closeness\n";
$debug && print "closeness: $closeness | ";
print "A: $Ascore | ";
print "B: $Bscore | ";
print "F: $Fscore | ";
print $calcstring . "\n";

sub log10 { log($_[0]) / log(10) }  
