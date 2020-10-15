package Ocsinventory::Agent::Backend::OS::Linux::Archs::ARM::Memory;
use strict;
use warnings;
sub check { 
    my $params = shift;
    my $common = $params->{common};
    $common->can_run("vcgencmd"); 
} 

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $capacity;
    my $description;

	$description = "Mem arm";
	$capacity=`vcgencmd get_mem arm | cut -d "=" -f 2`;
	$capacity =~ s/\n//g;

	$common->addMemory({
		'DESCRIPTION' => $description,   
		'CAPACITY' => $capacity,    
	});

	$description = "Mem gpu";
	$capacity=`vcgencmd get_mem gpu | cut -d "=" -f 2`;
	$capacity =~ s/\n//g;

	$common->addMemory({
		'DESCRIPTION' => $description,   
		'CAPACITY' => $capacity,    
	});

}

1;
