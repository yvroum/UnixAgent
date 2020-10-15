package Ocsinventory::Agent::Backend::Virtualization::Xen::XM;

use strict;

sub check { 

    my $params = shift;
    my $common = $params->{common};
    my $can_run = $common->can_run('xm');
    if ($can_run) { 
       system('xm list');
       my $exit_val = $? >> 8;
       return $exit_val eq 0;
    }
    return $can_run;
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    # output: xm list
    #
    #    Name                         ID Mem(MiB) VCPUs State  Time(s)
    #    Domain-0                      0       98     1 r-----  5068.6
    #    Fedora3                     164      128     1 r-----     7.6
    #    Fedora4                     165      128     1 ------     0.6
    #    Mandrake2006                166      128     1 -b----     3.6
    #    Mandrake10.2                167      128     1 ------     2.5
    #    Suse9.2                     168      100     1 ------     1.8

    # xm status
    my %status_list = (
        'r' => 'running',
        'b' => 'blocked',
        'p' => 'paused',
        's' => 'shutdown',
        'c' => 'crashed',
        'd' => 'dying',
    );

    my $vmtype    = 'xen';
    my $subsystem = 'xm';

    my @xm_list = `xm list`;

    # remove first line
    shift @xm_list;

    foreach my $vm (@xm_list) {
        chomp $vm;
        my ($name, $vmid, $memory, $vcpu, $status, $time) = split(' ',$vm);

        $status =~ s/-//g;
        $status = ( $status ? $status_list{$status} : 'off');

        my @vm_info =  `xm list -l $name`;
        my $uuid;
        foreach my $value (@vm_info) {
            chomp $value;
            if ($value =~ /uuid/) {
                $value =~ s/\(|\)//g;
                $value =~ s/\s+.*uuid\s+(.*)/\1/;
                $uuid = $value;
                last;
            }
        }

        my $machine = {
            MEMORY    => $memory,
            NAME      => $name,
            UUID      => $uuid,
            STATUS    => $status,
            SUBSYSTEM => $subsystem,
            VMTYPE    => $vmtype,
            VCPU      => $vcpu,
            VMID      => $vmid,
        };
        $common->addVirtualMachine($machine);
    }
}

1;
