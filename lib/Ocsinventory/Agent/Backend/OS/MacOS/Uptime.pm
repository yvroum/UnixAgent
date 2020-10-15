package Ocsinventory::Agent::Backend::OS::MacOS::Uptime;
use strict;

sub check {
    my $boottime = `sysctl -n kern.boottime 2>/dev/null`; # straight from the BSD module ;-)
    return 1 if $boottime;
    return;
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    # stolen code from bsd.
    chomp (my $boottime = `sysctl -n kern.boottime`);
    $boottime = $1 if $boottime =~ /sec\s*=\s*(\d+)/;
    chomp (my $currenttime = `date +%s`);
    my $uptime = $currenttime - $boottime;

    # Uptime conversion
    my ($UYEAR, $UMONTH , $UDAY, $UHOUR, $UMIN, $USEC) = (gmtime ($uptime))[5,4,3,2,1,0];

    # Write in ISO format
    $uptime=sprintf "%02d-%02d-%02d %02d:%02d:%02d", ($UYEAR-70), $UMONTH, ($UDAY-1), $UHOUR, $UMIN, $USEC;

    chomp(my $DeviceType =`uname -m`);
    $common->setHardware({ DESCRIPTION => "$DeviceType/$uptime" });
}
1;
