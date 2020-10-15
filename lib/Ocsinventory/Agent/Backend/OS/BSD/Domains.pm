package Ocsinventory::Agent::Backend::OS::BSD::Domains;
use strict;

sub check {
    my $hostname;
    chomp ($hostname = `hostname`);
    my @domain = split (/\./, $hostname);
    shift (@domain);
    return 1 if @domain;
    -f "/etc/resolv.conf"
 }
sub run {
    my $params = shift;
    my $common = $params->{common};
  
    my $domain;
    my %domain;
    my @dns_list;
    my $dns;
    my $hostname;
    chomp ($hostname = `hostname`);
    my @domain = split (/\./, $hostname);
    shift (@domain);
    $domain = join ('.',@domain);
  
    open RESOLV, "/etc/resolv.conf" or warn;
  
    while(<RESOLV>){
        if (/^nameserver\s+(\S+)/i) {
            push(@dns_list,$1);
        } elsif (!$domain) {
            $domain{$2} = 1 if (/^(domain|search)\s+(.+)/);
        }
    }
    close RESOLV;
  
    if (!$domain) {
        $domain = join "/", keys %domain;
    }
  
    $dns=join("/",@dns_list);
    
    # If no domain name, we send "WORKGROUP"
    $domain = 'WORKGROUP' unless $domain;
  
    $common->setHardware({
        WORKGROUP => $domain,
        DNS => $dns
    });
}

1;
