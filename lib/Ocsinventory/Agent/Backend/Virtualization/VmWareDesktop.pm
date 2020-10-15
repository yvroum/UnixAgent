package Ocsinventory::Agent::Backend::Virtualization::VmWareDesktop;
#
# initial version: Walid Nouh
#

use strict;

sub check { 
    my $params = shift;
    my $common = $params->{common};
    return $common->can_run('/Library/Application\ Support/VMware\ Fusion/vmrun') 
}

sub run {
    my $params = shift;
    my $common = $params->{common};
    my $logger = $params->{logger};

    my $uuid;
    my $mem;
    my $status;
    my $name;
    my $i = 0;

    my $commande = "/Library/Application\\ Support/VMware\\ Fusion\/vmrun list";
    foreach my $vmxpath ( `$commande` ) {
        next unless $i++ > 0; # Ignore the first line
        if (!open TMP, "<$vmxpath") {
            $logger->debug("Can't open $vmxpath\n");
            next;
        }
        my @vminfos = <TMP>;
        close TMP;

        foreach my $line (@vminfos) {
            if ($line =~ m/^displayName =\s\"+(.*)\"/) {
                $name = $1;
            } elsif ($line =~ m/^memsize =\s\"+(.*)\"/) {
                $mem = $1;
            } elsif ($line =~ m/^uuid.bios =\s\"+(.*)\"/) {
                $uuid = $1;
            }
        }

        $common->addVirtualMachine ({
            NAME      => $name,
            VCPU      => 1,
            UUID      => $uuid,
            MEMORY    => $mem,
            STATUS    => "running",
            SUBSYSTEM => "VmWare Fusion",
            VMTYPE    => "VmWare",
        });
    }
}

1;
