package Ocsinventory::Agent::Backend::OS::Generic::Hostname;

sub check {
    my $params = shift;
    my $common = $params->{common};
    return 1 if $common->can_load ("Sys::Hostname");
    return 1 if $common->can_run ("hostname");
    0;
}

# Initialise the distro entry
sub run {
    my $params = shift;
    my $common = $params->{common};
  
    my $hostname;
  
    if ($common->can_load("Sys::Hostname")) {
        $hostname = Sys::Hostname::hostname();
    } else {
        chomp ( $hostname = `hostname` ); # TODO: This is not generic.
    }
    $hostname =~ s/\..*//; # keep just the hostname
  
    $common->setHardware ({NAME => $hostname});
}

1;
