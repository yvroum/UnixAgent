package Ocsinventory::Agent::Backend::OS::Linux::Distro::NonLSB::Debian;
use strict;

sub check {-f "/etc/debian_version" && !-f "/etc/ubuntu_version"}

#####
sub findRelease {
    my $v;
  
    open V, "</etc/debian_version" or warn;
    chomp ($v=<V>);
    close V;
    return "Debian GNU/Linux $v";
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
