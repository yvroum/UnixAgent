package Ocsinventory::Agent::Backend::OS::MacOS::Drives;

use strict;

# yea BSD theft!!!!
# would have used Mac::SysProfile, but the xml isn't quite fully supported
# the drives come back in apple xml tree's, and the module can't handle it yet (soon as I find the time to fix the patch)

sub check {1}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $free;
    my $filesystem;
    my $total;
    my $type;
    my $volumn;


    for my $t ("apfs", "ffs","ufs", "hfs") {
  # OpenBSD has no -m option so use -k to obtain results in kilobytes
      for(`df -P -k -t $t`){ # darwin needs the -t to be last
        if(/^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\n/){
            $type = $1;
            $filesystem = $t;
            $total = sprintf("%i",$2/1024);
            $free = sprintf("%i",$4/1024);
            $volumn = $6;

          $common->addDrive({
              FREE => $free,
              FILESYSTEM => $filesystem,
              TOTAL => $total,
              TYPE => $type,
              VOLUMN => $volumn
            })
        }
      }
    }
}
1;
