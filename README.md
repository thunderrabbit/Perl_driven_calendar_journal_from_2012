Localhost>  ssh perl

perl.robnugen.com server on DH> cpan


cpan[1]> o conf init

cpan[2]> o conf makepl_arg "install_base=/home/dh_r2ixxd/perl5 \
     LIB=/home/dh_r2ixxd/perl5/lib \
     INSTALLMAN1DIR=/home/dh_r2ixxd/perl5/man/man1 \
     INSTALLMAN3DIR=/home/dh_r2ixxd/perl5/man/man3"

cpan[3]> o conf commit

cpan[4]> install Text::MultiMarkdown  <---- this didn't work so I created `/home/dh_r2ixxd/dev/Text-RobMiniMarkdown/lib/Text/RobMiniMarkdown.pm`;