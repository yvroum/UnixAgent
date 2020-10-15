package Ocsinventory::Agent::Backend::OS::Linux::Archs::ARM::CPU;

use strict;
use warnings;
use Data::Dumper;

sub check { 
    my $params = shift;
    my $common = $params->{common};
    $common->can_run("lscpu"); 
    $common->can_read("/proc/cpuinfo");
}

sub run {

    my $params = shift;
    my $common = $params->{common};

    my @cpuinfos=`LANG=C lscpu`;
    my $cpu;
    my $vcpus;
	my $freq;

    foreach my $info (@cpuinfos){
        chomp $info;
        $cpu->{CPUARCH}=$1 if ($info =~ /Architecture:\s*(.*)/i);
        $cpu->{NBCPUS}=$1 if ($info =~ /^CPU\(s\):\s*(\d)/i);
        $cpu->{THREADS}=$1 if ($info =~ /Thread\(s\)\sper\score:\s*(\d)/i);
        $cpu->{CORES}=$1 if ($info =~ /Core\(s\)\sper\ssocket:\s*(\d)/i);
        $cpu->{NBSOCKET}=$1 if ($info =~ /Socket\(s\):\s*(\d)/i);
        $cpu->{TYPE}=$1 if ($info =~ /Model\sname:\s*(.*)/i);
        $cpu->{MANUFACTURER}=$1 if ($info =~ /Vendor ID:\s*(.*)/i);
        $cpu->{CURRENT_SPEED}=$1 if ($info =~ /CPU\smax\sMHz:\s*(.*)/i);
		$freq=`vcgencmd get_config arm_freq | cut -d "=" -f 2`;
    }

	$freq =~ s/\n//g;
    $cpu->{SPEED}=$freq;
   
    # Total Threads = number of cores x number of threads per core
    $cpu->{THREADS}=$cpu->{CORES}*$cpu->{THREADS};

    # Set LOGICAL_CPUS with THREADS value
    $cpu->{LOGICAL_CPUS}=$cpu->{THREADS};

 
    my $current;
    my @vcpus = "";

#	open CPUINFO, "/proc/cpuinfo";

#	while(<CPUINFO>){
#        $cpu->{SERIALNUMBER}=$1 if  /^Serial\s*:\s/;
#}
#		my $serial = `grep Serial /proc/cpuinfo | cut -d ":" -f 2`;
#		my $serial = `grep Serial /proc/cpuinfo | cut -d ":" -f 2 | sed -e 's/^ //'`;
#		$serial =~ s/\n+$//g;
#		$cpu->{SERIALNUMBER}=$serial;

   $common->addCPU($cpu);  
  # The last one
  #  $common->addCPU($current);
}

1;
