package Ocsinventory::Agent::Backend::OS::AIX::Drives;

use strict;
sub check {
    my $params = shift;
    my $common = $params->{common};
    return unless $common->can_run("df");
    1;
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $free;
    my $filesystem;
    my $total;
    my $type;
    my $volumn;  

    my @fs;
    my @fstype;
    #Looking for mount points and disk space
    # Aix option -kP 
    for (`df -kP`) {
        next if /^Filesystem\s*1024-blocks.*/;
        if (/^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\n/) {
            $volumn = $1;
            @fs=`lsfs -c $6`;
            @fstype = split /:/,$fs[1];     
            $filesystem = $fstype[2];
            $total = sprintf("%i",($2/1024));    
            $free = sprintf("%i",($4/1024));
            $type = $6;      
        }
        next if $filesystem =~ /procfs/;

        $common->addDrive({
            FREE => $free,
            FILESYSTEM => $filesystem,
            TOTAL => $total,
            TYPE => $type,
            VOLUMN => $volumn
        });
    }
}

1;
