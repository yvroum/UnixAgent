package Ocsinventory::Agent::Backend::OS::AIX::CPU;
use strict;
use warnings;

sub check { 1 }

# try to simulate a modern lsattr output on AIX4
sub lsattrForAIX4 {
    my $device = shift;

    my @lsattr;
    my @lsattrtemp=`lsattr -EOl $device -a 'state:type'`;
    for (@lsattrtemp) {
        chomp;

        my $frequency;

        my (undef,$type)=split /:/;
        #
        # On older models, frequency is based on cpu model and uname
        #
        if ( $type eq "PowerPC" or $type eq "PowerPC_601" or $type eq "PowerPC_604") {
            my $uname=`uname -m`;
            $frequency=112000000 if ($uname=~/E1D|EAD|C1D|R04|C4D|R4D/);
            $frequency=133000000 if ($uname=~/34M/);
            $frequency=150000000 if ($uname=~/N4D/);
            $frequency=200000000 if ($uname=~/X4M|X4D/);
            $frequency=225000000 if ($uname=~/N4E|K04|K44/);
            $frequency=320000000 if ($uname=~/N4F/);
            $frequency=360000000 if ($uname=~/K45/);
        } elsif ( $type eq "PowerPC_RS64_III" ) {
            $frequency=400000000;
        } elsif ( $type eq "PowerPC_620" ) {
            $frequency=172000000;
        } else {
            $frequency=225000000;
        }
        push @lsattr,"$device:$frequency\n";
    }
}

sub run {
  my $params = shift;
  my $common = $params->{common};
  
  # TODO Need to be able to register different CPU speed!
  
  my $processort;
  my $processorn;
  my $processors; 
  my $frequency;
  my @lsdev; 
  my @lsattr;

  #lsdev -Cc processor -F name
  #lsattr -EOl proc16
  my $aixversion=`uname -v`;
  for (`lsdev -Cc processor -F name`){
    chomp(my $device = $_);

    if ( $aixversion < 5 ) {
      @lsattr=lsattrForAIX4($device);
    } else {
      @lsattr=`lsattr -EOl $device -a 'state:type:frequency'`;
    }

    for (@lsattr) {
      if ( ! /^#/ && /(.+):(.+):(.+)/ ) {
        $processorn++;
        $processort=$2;
        if ( ($3 % 1000000) >= 50000){
          $processors=int (($3/1000000) +1); 
        }
        else {
          $processors=int (($3/1000000)); 
        }
      }
    }
  }
  $processort =~ s/_/ /;
  
  $common->setHardware({

      PROCESSORT => $processort,
      PROCESSORN => $processorn,
      PROCESSORS => $processors

    });

}

1
