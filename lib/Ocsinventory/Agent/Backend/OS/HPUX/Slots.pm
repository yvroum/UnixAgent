package Ocsinventory::Agent::Backend::OS::HPUX::Slots;
use strict;

sub check { $^O =~ /hpux/ }

sub run { 
    my $params = shift;
    my $common = $params->{common};
  
    my $name;
    my $interface;
    my $info;
    my $type;
    my @typeScaned=('ioa','ba');
    my $scaned;
  
    for (@typeScaned ) {
        $scaned=$_;
        for ( `ioscan -kFC $scaned| cut -d ':' -f 9,11,17,18` ) {
             if ( /(\S+):(\S+):(\S+):(.+)/ ) {
                 $name=$2;
                 $interface=$3;
                 $info=$4;
                 $type=$1;
                 $common->addSlots({
                     DESCRIPTION =>  "$name",
                     DESIGNATION =>  "$interface $info",
                     NAME            =>  "$type",
                     STATUS          =>  "OK",
                 });
             };
        };
    };
}

1;
