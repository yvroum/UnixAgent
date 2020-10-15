package Ocsinventory::Agent::Backend::OS::Linux::Archs::ARM::Bios;
use warnings;

sub check { 
    my $params = shift;
    my $common = $params->{common};
    $common->can_read("/proc/cpuinfo");
    $common->can_run("vcgencmd"); 
}
 
sub run { 
    # Parsing /proc/cpuinfo
    # Using "type 0" section

    my $params = shift;
    my $common = $params->{common};

    my( $SystemSerial , $SystemModel, $SystemManufacturer, $BiosManufacturer,
      $BiosVersion, $BiosDate, $AssetTag, $MotherboardManufacturer, $MotherboardModel, $MotherboardSerial, $Type );

	my $bdate;

	my $mod;
	my $manuf;
 
    #System DMI
	$manuf = 'Raspberry';
    $SystemManufacturer = $manuf;

	$mod = `grep Model /proc/cpuinfo | cut -d ":" -f 2 | sed -e "s/^ Raspberry //"`;
	$SystemModel = $mod;

    $SystemSerial = `grep Serial /proc/cpuinfo | cut -d ":" -f 2`;

#    $AssetTag = `dmidecode -s chassis-asset-tag`;

    $Type = `grep Hardware /proc/cpuinfo | cut -d ":" -f 2 | sed -e "s/^ //"`;
    
    chomp($SystemModel);
    $SystemModel =~ s/^(#.*\n)+//g;

    chomp($SystemManufacturer);
    $SystemManufacturer =~ s/^(#.*\n)+//g;

    chomp($SystemSerial);
    $SystemSerial =~ s/^(#.*\n)+//g;

    # System serial number can be filled with whitespace (e.g. Intel NUC)
    $SystemSerial =~ s/^\s+|\s+$//g;
#    chomp($AssetTag);
#    $AssetTag =~ s/^(#.*\n)+//g;
#    $AssetTag =~ s/Invalid.*$//g;
    chomp($Type);
    $Type =~ s/^(#.*\n)+//g;
    $Type =~ s/Invalid.*$//g;
    
    #Motherboard DMI
    $MotherboardManufacturer = `vcgencmd version | grep Copyright | cut -d " " -f 4`;
#    $MotherboardModel = `dmidecode -s baseboard-product-name`;
#    $MotherboardSerial = `dmidecode -s baseboard-serial-number`;
    
#    chomp($MotherboardModel);
#    $MotherboardModel =~ s/^(#.*\n)+//g;
#    $MotherboardModel =~ s/Invalid.*$//g;
    chomp($MotherboardManufacturer);
    $MotherboardManufacturer =~ s/^(#.*\n)+//g;
    $MotherboardManufacturer =~ s/Invalid.*$//g;
#    chomp($MotherboardSerial);
#    $MotherboardSerial =~ s/^(#.*\n)+//g;
#    $MotherboardSerial =~ s/Invalid.*$//g;
    
    #BIOS DMI
#    $BiosManufacturer = `dmidecode -s bios-vendor`;
    $BiosVersion = `grep Revision /proc/cpuinfo | cut -d ":" -f 2 | sed -e 's/^ //'`;
    $bdate=`vcgencmd version | head -1`;
	$BiosDate = $bdate;
    
#    chomp($BiosManufacturer);
#    $BiosManufacturer =~ s/^(#.*\n)+//g;
#    $BiosManufacturer =~ s/Invalid.*$//g;
    chomp($BiosVersion);
    $BiosVersion =~ s/^(#.*\n)+//g;
    $BiosVersion =~ s/Invalid.*$//g;
    chomp($BiosDate);
    $BiosDate =~ s/^(#.*\n)+//g;
    $BiosDate =~ s/Invalid.*$//g;

    # If serial number is empty, assign mainboard serial (e.g Intel NUC)
#    if (!$SystemSerial) {
#        $SystemSerial = $MotherboardSerial;
#    }

    # Some bioses don't provide a serial number so I check for CPU ID (e.g: server from dedibox.fr)
#    my @cpu;
#    if (!$SystemSerial || $SystemSerial =~ /^0+$/) {
#        @cpu = `dmidecode -t processor`;
#        for (@cpu){
#            if (/ID:\s*(.*)/i){
#                $SystemSerial = $1;
#            }
#        }
#    }
  
    # Writing data
    $common->setBios ({
#        ASSETTAG => $AssetTag,
        SMANUFACTURER => $SystemManufacturer,
        SMODEL => $SystemModel,
        SSN => $SystemSerial,
#        BMANUFACTURER => $BiosManufacturer,
        BVERSION => $BiosVersion,
        BDATE => $BiosDate,
        MMANUFACTURER => $MotherboardManufacturer,
#        MMODEL => $MotherboardModel,
#        MSN => $MotherboardSerial,
        TYPE => $Type,
    });
}

1;
