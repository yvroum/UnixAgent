package Ocsinventory::Agent::Backend::OS::Linux::Distro::NonLSB::Ubuntu;
use strict;

use vars qw($runAfter);
$runAfter = ["Ocsinventory::Agent::Backend::OS::Linux::Distro::NonLSB::Debian"];

sub check {-f "/etc/ubuntu_version"}

#####
sub findRelease {
    my $v;
  
    open V, "</etc/ubuntu_version" or warn;
    chomp ($v=<V>);
    close V;
    return "Ubuntu $v";
}

sub run {
    my $params = shift;
    my $common = $params->{common};
  
    my $OSComment;
    chomp($OSComment =`uname -v`);
  
    $common->setHardware({ 
        OSNAME => findRelease(),
        OSCOMMENTS => "$OSComment"
    });
}

1;
