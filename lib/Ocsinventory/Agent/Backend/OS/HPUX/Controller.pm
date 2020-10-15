package Ocsinventory::Agent::Backend::OS::HPUX::Controller;
use strict;

sub check { $^O =~ /hpux/ }

sub run { 
    my $params = shift;
    my $common = $params->{common};
  
    my $name;
    my $interface;
    my $info;
    my $type;
    my @typeScaned=('ext_bus','fc','psi');
    my $scaned;
  
    for (@typeScaned) {
        $scaned=$_;
        for ( `ioscan -kFC $scaned| cut -d ':' -f 9,11,17,18` ) {
            if ( /(\S+):(\S+):(\S+):(.+)/ ) {
               $name=$2;
               $interface=$3;
               $info=$4;
               $type=$1;
               $common->addController({
                   'NAME'          => $name,
                   'MANUFACTURER'  => "$interface $info",
                   'TYPE'          => $type,
               });
            };
        };
    };
}

1;
