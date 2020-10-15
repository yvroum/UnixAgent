package Ocsinventory::Agent::Backend::OS::MacOS::Networks;

# I think I hijacked most of this from the BSD/Linux modules


use strict;

sub check {
    my $params = shift;
    my $common = $params->{common};
    $common->can_run("ifconfig") && $common->can_load("Net::IP qw(:PROC)")
}


sub _ipdhcp {
    my $if = shift;

    my $path;
    my $ipdhcp;
    my $leasepath;

    foreach ( # XXX BSD paths
        "/var/db/dhclient.leases.%s",
        "/var/db/dhclient.leases",
        # Linux path for some kFreeBSD based GNU system
        "/var/lib/dhcp3/dhclient.%s.leases",
        "/var/lib/dhcp3/dhclient.%s.leases",
        "/var/lib/dhcp/dhclient.leases") {

        $leasepath = sprintf($_,$if);
        last if (-e $leasepath);
    }
    return undef unless -e $leasepath;

    if (open DHCP, $leasepath) {
      my $lease;
      my $dhcp;
      my $expire;
      # find the last lease for the interface with its expire date
      while(<DHCP>){
        $lease = 1 if(/lease\s*{/i);
        $lease = 0 if(/^\s*}\s*$/);
        if ($lease) { #inside a lease section
            if(/interface\s+"(.+?)"\s*/){
                $dhcp = ($1 =~ /^$if$/);
            }
            #Server IP
            if(/option\s+dhcp-server-identifier\s+(\d{1,3}(?:\.\d{1,3}){3})\s*;/
               and $dhcp){
                $ipdhcp = $1;
            }
            if (/^\s*expire\s*\d\s*(\d*)\/(\d*)\/(\d*)\s*(\d*):(\d*):(\d*)/
                and $dhcp) {
                $expire=sprintf "%04d%02d%02d%02d%02d%02d",$1,$2,$3,$4,$5,$6;
            }
        }
    }
      close DHCP or warn;
      chomp (my $currenttime = `date +"%Y%m%d%H%M%S"`);
      undef $ipdhcp unless $currenttime <= $expire;
  } else {
      warn "Can't open $leasepath\n";
  }
    return $ipdhcp;
}

# Initialise the distro entry
sub run {
    my $params = shift;
    my $common = $params->{common};

    my $description;
    my $ipaddress;
    my $ipgateway;
    my $ipmask;
    my $ipsubnet;
    my $macaddr;
    my $status;
    my $type;
    my $speed;


    # Looking for the gateway
    # 'route show' doesn't work on FreeBSD so we use netstat
    # XXX IPV4 only
    for(`netstat -nr -f inet`){
      $ipgateway=$1 if /^default\s+(\S+)/i;
    }

    my @ifconfig = `ifconfig -a`; # -a option required on *BSD


    # first make the list available interfaces
    # too bad there's no -l option on OpenBSD
    my @list;
    foreach (@ifconfig){
        # skip loopback, pseudo-devices and point-to-point interfaces
        #next if /^(lo|fwe|vmnet|sit|pflog|pfsync|enc|strip|plip|sl|ppp)\d+/;
        next unless(/^en([0-9])/); # darwin has a lot of interfaces, for this purpose we only want to deal with eth0 and eth1
        if (/^(\S+):/) { push @list , $1; } # new interface name
    }

    # for each interface get it's parameters
    foreach $description (@list) {
        $ipaddress = $ipmask = $macaddr = $status =  $type = undef;
        # search interface infos
        @ifconfig = `ifconfig $description`;
        foreach (@ifconfig){
            $ipaddress = $1 if /inet (\S+)/i;
            $ipmask = $1 if /netmask\s+(\S+)/i;
            $macaddr = $2 if /(address:|ether|lladdr)\s+(\S+)/i;
            $status = 1 if /status:\s+active/i;
            $type = $1 if /media:\s+(\S+)/i;
            $speed = $1 if /media:\s+(\S+)\s+(\S+)/i && ! /supported media:/;
            if ($speed =~ /autoselect/i) {
              $speed = $2 if /media:\s+(\S+)\s+(\S+)/i && ! /supported media:/;
              $speed .= " $3" if /media:\s+(\S+)\s+(\S+)\s+(\S+)/i && ! /supported media:/;
            } else {
              $speed .= " $2" if /media:\s+(\S+)\s+(\S+)/i && ! /supported media:/;
            }
        }
        if ($status != 1) {
            $speed = "";
        } else {
            $speed =~ s/\(|\)|\<|\>|baseTX|baseT|,flow-control//g;
            $speed =~ s/1000 /1 Gb\/s /g;
            $speed =~ s/100 /100 Mb\/s /g;
            $speed =~ s/10 /10 Mb\/s /g;
            $speed =~ s/full-duplex/FDX/g;
            $speed =~ s/half-duplex/HDX/g;
        }

        my $binip = &ip_iptobin ($ipaddress ,4);
        # In BSD, netmask is given in hex form
        my $binmask = sprintf("%b", oct($ipmask));
        my $binsubnet = $binip & $binmask;
        $ipsubnet = ip_bintoip($binsubnet,4);
        my $mask = ip_bintoip($binmask,4);
        $common->addNetwork({
            DESCRIPTION => $description,
            IPADDRESS => ($status?$ipaddress:undef),
            IPDHCP => _ipdhcp($description),
            IPGATEWAY => ($status?$ipgateway:undef),
            IPMASK => ($status?$mask:undef),
            IPSUBNET => ($status?$ipsubnet:undef),
            MACADDR => $macaddr,
            STATUS => ($status?"Up":"Down"),
            TYPE => ($status?$type:undef),
            SPEED => $speed,
        });
    }
}

1;
