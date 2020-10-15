package Ocsinventory::Agent::Backend::OS::HPUX::Drives;

sub check  { $^O =~ /hpux/ }

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $type;
    my $fs;
    my $lv;
    my $total;
    my $free;

    for ( `fstyp -l | grep -v nfs` ) {
        if ( /^\s*$/ ) {         #Blank line 
            next;
        }  

        $type=$_;
        for ( `bdf -t $type `) {
            if ( /Filesystem/ ) { ;  } ;
            if ( /^(\S+)\s(\d+)\s+(\d+)\s+(\d+)\s+(\d+%)\s+(\S+)/ ) {
                $lv=$1;
                $total=$2;
                $free=$3;
                $fs=$6;
                $common->addDrives({
                    FREE => $free,
                    FILESYSTEM => $fs,
                    TOTAL => $total,
                    TYPE => $type,
                    VOLUMN => $lv,
                });
            };
            if ( /^(\S+)\s/) {
                $lv=$1;
            };
            if ( /(\d+)\s+(\d+)\s+(\d+)\s+(\d+%)\s+(\S+)/) {
                $total=$1;
                $free=$3;
                $fs=$5;
                # print "fs $fs lv $lv total $total free $free type $type\n";
                $common->addDrives({
                    FREE => $free,
                    FILESYSTEM => $fs,
                    TOTAL => $total,
                    TYPE => $type,
                    VOLUMN => $lv,
                });
            };
        };
    };
}

1;
