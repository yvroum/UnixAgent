package Ocsinventory::Agent::Backend::OS::Linux::Distro::LSB;

use vars qw($runMeIfTheseChecksFailed);
$runMeIfTheseChecksFailed = ["Ocsinventory::Agent::Backend::OS::Linux::Distro::NonLSB"];

sub check {
    my $params = shift;
    my $common = $params->{common};
    $common->can_run("lsb_release")
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $OSname;
    chomp($OSname =`lsb_release -is`);

    my $OSversion;
    chomp($OSversion =`lsb_release -rs`);
 
    my $OSComment;
    chomp($OSComment =`uname -v`);

    my $release = "$OSname $OSVersion";

    $common->setHardware({ 
        OSNAME => $release,
        OSVERSION => $OSversion,
        OSCOMMENTS => "$OSComment"
    });
}

1;
