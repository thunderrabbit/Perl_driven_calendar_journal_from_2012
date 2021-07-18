package mkdef;

##  I don't know how ths works, but I understand I need to put the names of functions I want to use in the @EXPORT array
use Exporter ();
@ISA = qw(Exporter);
@EXPORT = qw(mkdef);

sub mkdef {
    my($ival) = @_;

    if (defined $ival) {
	return $ival;
    } else {
	return "";
    }
}
1;
