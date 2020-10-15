package Ocsinventory::Agent::Backend::OS::HPUX;

use strict;
use vars qw($runAfter);
$runAfter = ["Ocsinventory::Agent::Backend::OS::Generic"];

sub check  { $^O =~ /hpux/ }

sub run {
    my $params = shift;
    my $common = $params->{common};
    my $OSName;
    my $OSVersion;
    my $OSComment;
    #my $uname_path          = &_get_path('uname');
    
    # Operating systeminformations
    
    chomp($OSName = `uname -s`);
    chomp($OSVersion = `uname -r`);
    chomp($OSComment = `uname -l`);
  
    $common->setHardware({
        OSNAME => $OSName,
        OSCOMMENTS => $OSComment,
        OSVERSION => $OSVersion,
    });
}

1;
