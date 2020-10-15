package Ocsinventory::Agent::Backend::OS::Linux::Distro::NonLSB::Gentoo;
use strict;

sub check {-f "/etc/gentoo-release"}

#####
sub findRelease {
    my $v;
  
    open V, "</etc/gentoo-release" or warn;
    chomp ($v=<V>);
    close V;
    return "Gentoo Linux $v";
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
