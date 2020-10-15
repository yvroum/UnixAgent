package Ocsinventory::Agent::Backend::OS::Solaris::IPv4;

sub check { 
    my $params = shift;
    my $common = $params->{common};
    $common->can_run ("ifconfig") 
}

# Initialise the distro entry
sub run {
    my $params = shift;
    my $common = $params->{common};
    my %ip;
    my $ip;
    my $hostn;

    #Looking for ip addresses with ifconfig, except loopback
    # Solaris need -a option
    for (`ifconfig -a`){#ifconfig in the path
        #Solarisligne inet
       if (/^\s*inet\s+(\S+).*/){($1=~/127.+/)?next:($ip{$1}=1)};
    }

    # Ok. Now, we have the list of IP addresses configured
    # We could have too many addresses to list them in HW
    # (details will be sent in Networks instead)
    # 
    #  How could we choose ?
    # 
    # Let's try to resolve the name of our server
    #  

    chomp( $hostn = `uname -n` );
    if ($hostn) {
      my $aip;
      foreach (`ping -s $hostn 10 1`) {
        unless ( $ip ) {
          if( /^.*\((\d+\.\d+\.\d+\.\d+)\):.*/ ) {
            $aip = $1;
            $ip = $aip  if( exists($ip{$aip}) );
          }
        }
      }
    }
    $common->setHardware({IPADDR => $ip});
}

1;
