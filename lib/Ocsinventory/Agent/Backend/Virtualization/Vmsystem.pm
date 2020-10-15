package Ocsinventory::Agent::Backend::Virtualization::Vmsystem;

# Initial Ocsinventory::Agent::Backend::Virtualization::Vmsystem version: Nicolas EISEN
#
# Code include from imvirt - I'm virtualized?
#   http://micky.ibh.net/~liske/imvirt.html
#
# Authors:
#   Thomas Liske <liske@ibh.de>
#
# Copyright Holder:
#   2008 (C) IBH IT-Service GmbH [http://www.ibh.de/]
#
# License:
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this package; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
#


##
#
# Outputs:
#   Xen
#   VirtualBox
#   Virtual Machine
#   VMware
#   QEMU
#   SolarisZone
#
# If no virtualization has been detected:
#   Physical
#
##

use strict;

sub check { 
    my $params = shift;
    my $common = $params->{common};

    if ( $common->can_run("zoneadm")){ # Is a solaris zone system capable ?
        return 1; 
    }
    if ( $common->can_run ("dmidecode") ) {
        # 2.6 and under haven't -t parameter   
        my $dmidecode_ver = `dmidecode -V 2>/dev/null`; 
        my @SplitVersion = split(/\./, $dmidecode_ver);

        if (@SplitVersion[0] > 2) {
            return 1;
        } elsif (@SplitVersion[0] == 2 && @SplitVersion[1] >= 7) {
            return 1;
        }
    } 
    return 0;
} 

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $dmidecode = '/usr/sbin/dmidecode';
    my $cmd = '$dmidecode -t system';

    my $dmesg = '/bin/dmesg | head -n 750';

    my $status = "Physical";
    my $found = 0;
    # Solaris zones
    my @solaris_zones;
    @solaris_zones = `/usr/sbin/zoneadm list`;
    @solaris_zones = grep (!/global/,@solaris_zones);
    if(@solaris_zones){
        $status = "SolarisZone";
        $found = 1;
    }

    if ( -d '/proc/xen' || check_file_content('/sys/devices/system/clocksource/clocksource0/available_clocksource','xen')) {
        $found = 1 ;
        if (check_file_content('/proc/xen/capabilities', 'control_d')) {
          # dom0 host
        } else {
          # domU PV host
          $status = "Xen";

          # those information can't be extracted from dmidecode
          $common->setBios ({
            SMANUFACTURER => 'Xen',
            SMODEL => 'PVM domU'
          });
        }
    }

    # dmidecode needs root to work :(
    if ($found == 0 and -r '/dev/mem' && -x $dmidecode) {
        my $sysprod = `$dmidecode -s system-product-name`;
        if ($sysprod =~ /^VMware/) {
          $status = "VMware";
          $found = 1;
        } elsif ($sysprod =~ /^Virtual Machine/) {
          $status = "Virtual Machine";
          $found = 1;
        } elsif ($sysprod =~ /^Microsoft Corporation/) {
            $status = "Hyper-V";
            $found=1; 
        } else {
            my $biosvend = `$dmidecode -s bios-vendor`;
            if ($biosvend =~ /^QEMU/) {
                $status = "QEMU";
                $found = 1;
            } elsif ($biosvend =~ /^Xen/) { # virtualized Xen
                $status = "Xen";
                $found = 1;
            }
        }
    }

    # Parse loaded modules
    my %modmap = (
        '^vmxnet\s' => 'VMware',
        '^xen_\w+front\s' => 'Xen',
    );

    if ($found == 0 and open(HMODS, '/proc/modules')) {
        while(<HMODS>) {
          foreach my $str (keys %modmap) {
            if (/$str/) {
              $status = "$modmap{$str}";
              $found = 1;
              last;
            }
          }
        }
        close(HMODS);
    }

    # Let's parse some logs & /proc files for well known strings
    my %msgmap = (
        'VMware vmxnet virtual NIC driver' => 'VMware',
        'Vendor: VMware\s+Model: Virtual disk' => 'VMware',
        'Vendor: VMware,\s+Model: VMware Virtual ' => 'VMware',
        ': VMware Virtual IDE CDROM Drive' => 'VMware',

        ' QEMUAPIC ' => 'QEMU',
        'QEMU Virtual CPU' => 'QEMU',
        ': QEMU HARDDISK,' => 'QEMU',
        ': QEMU CD-ROM,' => 'QEMU',

        ': Virtual HD,' => 'Virtual Machine',
        ': Virtual CD,' => 'Virtual Machine',

        ' VBOXBIOS ' => 'VirtualBox',
        ': VBOX HARDDISK,' => 'VirtualBox',
        ': VBOX CD-ROM,' => 'VirtualBox',

        'Hypervisor signature: xen' => 'Xen',
        'Xen virtual console successfully installed' => 'Xen',
        'Xen reported:' => 'Xen',
        'Xen: \d+ - \d+' => 'Xen',
        'xen-vbd: registered block device' => 'Xen',
        'ACPI: RSDP \(v\d+\s+Xen ' => 'Xen',
        'ACPI: XSDT \(v\d+\s+Xen ' => 'Xen',
        'ACPI: FADT \(v\d+\s+Xen ' => 'Xen',
        'ACPI: MADT \(v\d+\s+Xen ' => 'Xen',
        'ACPI: HPET \(v\d+\s+Xen ' => 'Xen',
        'ACPI: SSDT \(v\d+\s+Xen ' => 'Xen',
        'ACPI: DSDT \(v\d+\s+Xen ' => 'Xen',
    );

    if ($found == 0 and open(HDMSG, '/var/log/dmesg')) {
        while(<HDMSG>) {
            foreach my $str (keys %msgmap) {
                if (/$str/) {
                    $status = "$msgmap{$str}";
                    $found = 1;
                    last;
                }
            }
        }
        close(HDMSG);
    }

    # Read kernel ringbuffer directly
    if ($found == 0 and open(HDMSG, '$dmesg |')) {
        while(<HDMSG>) {
            foreach my $str (keys %msgmap) {
                if (/$str/) {
                    $status = "$msgmap{$str}";
                    $found = 1;
                    last;
                }
            }
        }
        close(HDMSG);
    }

    if ($found == 0 and open(HSCSI, '/proc/scsi/scsi')) {
        while(<HSCSI>) {
            foreach my $str (keys %msgmap) {
                if (/$str/) {
                    $status = "$msgmap{$str}";
                    $found = 1;
                    last;
                }
            }
        }
        close(HSCSI);
    }

    $common->setHardware ({
        VMSYSTEM => $status,
    });
}

sub check_file_content {
    my ($file, $pattern) = @_;

    return 0 unless -r $file;

    my $found = 0;
    open (my $fh, '<', $file) or die "Can't open file $file: $!";
    while (my $line = <$fh>) {
        if ($line =~ /$pattern/) {
            $found = 1;
            last;
        }
    }
    close ($fh);

    return $found;
}

1;
