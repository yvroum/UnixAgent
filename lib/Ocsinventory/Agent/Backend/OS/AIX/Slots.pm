package Ocsinventory::Agent::Backend::OS::AIX::Slots;
use strict;
sub check {
    my $params = shift;
    my $common = $params->{common};
    $common->can_run("lsdev")
}

sub run {
    my $params = shift;
    my $common = $params->{common};
  
    my $description;
    my $designation;
    my $name;
    my $status;  
    my @slot;
    my $flag=0;
 
    @slot=`lsdev -Cc bus -F 'name:description'`;
    for (@slot){    
        /^(.+):(.+)/;    
        $name = $1;
        $status = 'available';
        $designation = $2;    
        $flag=0;
        my @lsvpd = `lsvpd`;
        s/^\*// for (@lsvpd);
        for (@lsvpd){
            if ((/^AX $name/) ) {$flag=1}
            if ((/^YL (.+)/) && ($flag)){      
                $description = $2;
            }
            if ((/^FC .+/) && $flag) {$flag=0;last}
        }          
        $common->addSlot({
            DESCRIPTION =>  $description,
            DESIGNATION =>  $designation,
            NAME           =>  $name,
            STATUS      =>  $status,
        });
    }
}

1;
