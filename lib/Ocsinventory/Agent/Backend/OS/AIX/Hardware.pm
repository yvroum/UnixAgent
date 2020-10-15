package Ocsinventory::Agent::Backend::OS::AIX::Hardware;
use strict;
sub check { 1 }

# NOTE:
# Q: SSN can also use `uname -n`? What is the best?
# A: uname -n since it doesn't need root priv

sub run {
    my $params = shift;
    my $common = $params->{common};

    # Using "type 0" section
    my( $SystemSerial , $SystemModel, $SystemManufacturer, $BiosManufacturer, $BiosVersion, $BiosDate);

    # lsvpd
    my @lsvpd = `lsvpd`;
    # Remove * (star) at the beginning of lines
    s/^\*// for (@lsvpd);
    # Search Firmware Hard 
    my $flag=0;
    my $fw;
    for (@lsvpd){
        if (/^DS Platform Firmware/) { $flag=1 };
        if ( ($flag) && /^RM (.+)/) {$fw=$1;chomp($fw);$fw =~ s/(\s+)$//g;last};
    }
    $flag=0;
    for (@lsvpd){
        if (/^DS System Firmware/) { $flag=1 };
        if ( ($flag) && /^RM (.+)/) {$BiosVersion=$1;chomp($BiosVersion);$BiosVersion =~ s/(\s+)$//g;last};
    }
    $flag=0;
    for (@lsvpd){
        if (/^DS System VPD/) { $flag=1 };
        if ( ($flag) && /^TM (.+)/) {$SystemModel=$1;chomp($SystemModel);$SystemModel =~ s/(\s+)$//g;};
        if ( ($flag) && /^SE (.+)/) {$SystemSerial=$1;chomp($SystemSerial);$SystemSerial =~ s/(\s+)$//g;};
        if ( ($flag) && /^FC .+/) {$flag=0;last}
    }

    # Fetch the serial number like prtconf do
    if (! $SystemSerial) {
        $flag=0;
        foreach (`lscfg -vpl sysplanar0`) {
            if ($flag) {
                if (/\.+(\S*?)$/) {
                    $SystemSerial = $1;
                }
                last;
            } else {
                $flag = 1 if /\s+System\ VPD/;
            }
        }
    }

    $BiosManufacturer='IBM';
    $SystemManufacturer='IBM';
    $BiosVersion .= "(Firmware :".$fw.")";

    # Writing data
    $common->setBios ({
        SMANUFACTURER => $SystemManufacturer,
        SMODEL => $SystemModel,
        SSN => $SystemSerial,
        BMANUFACTURER => $BiosManufacturer,
        BVERSION => $BiosVersion,
        BDATE => $BiosDate,
    });
}

1;
