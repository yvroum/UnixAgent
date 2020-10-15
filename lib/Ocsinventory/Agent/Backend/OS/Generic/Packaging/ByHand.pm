package Ocsinventory::Agent::Backend::OS::Generic::Packaging::ByHand;
#How does it work ?
#
#Create a directory called software in place where you have your
#"modules.conf" file.
#Put your scripts in this directory.
#The scripts have to write on the STDIO with the following format :
#publisher#software#version#comment
#

use strict;
use warnings;


sub check { 
    return(1);
    1;
}
sub run() {
    my $params = shift;
    my $common = $params->{common};
    my $ligne;
    my $soft;
    my $comm;
    my $version;
    my $file;
    my $vendor;
    my $commentaire;
    my @dots;

    #if (!$file || !-d $file) {
        foreach (@{$common->{config}{etcdir}}) {
            $file = $_.'/softwares';
            last if -d $file;
        }
    #}
    my $logger = $params->{logger};

    if ( opendir(my $dh, $file) ){
        @dots = readdir($dh);
        foreach (@dots) { 
            if ( -f $file."/".$_ ){
                $comm = $file."/".$_;
                $logger->debug("Running appli detection scripts from ".$comm);
                foreach (`$comm`){
                    $ligne = $_;
                    chomp($ligne);
                    ($vendor,$soft,$version,$commentaire) = split(/\#/,$ligne);
                    $common->addSoftware ({
                        'PUBLISHER' => $vendor,
                        'NAME'          => $soft,
                        'VERSION'       => $version,
                        'FILESIZE'      => "",
                        'COMMENTS'      => $commentaire,
                        'FROM'          => 'ByHand'
                    });
                }
            }
        }
        closedir $dh;
    }
    1;
}
1;
