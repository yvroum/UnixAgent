package Ocsinventory::Agent::Backend::OS::Generic::Packaging::RPM;

use strict;
use warnings;

sub check {
    my $params = shift;
    my $common = $params->{common};
    return unless $common->can_run("rpm");

    # Some time rpm is a wrapper or an alias for another
    `rpm --version 2>&1`;
    return if ($? >> 8)!=0;
    1;
}

sub run {
    my $params = shift;
    my $common = $params->{common};
    my $logger = $params->{logger};

    my @date;
    my @list;
    my $buff;
    foreach (`rpm -qa --queryformat "%{NAME} --%{ARCH}-- %{VERSION}-%{RELEASE} --%{INSTALLTIME}-- --%{SIZE}-- --%{VENDOR}-- %{SUMMARY}\n--\n" 2>/dev/null`) {
        if (! /^--/) {
            chomp;
            $buff .= $_;
        } elsif ($buff =~ s/^(.*)\s+--(.*)--\s+(\S+)\s+--(.*)--\s+--(.*)--\s+--(.*)--\s+(.*)//) {
            my ($name,$arch,$version,$installdate,$filesize,$vendor,$comments) = ( $1,$2,$3,$4,$5,$6,$7 );
            @date = localtime($installdate);
            $installdate = sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $date[5] + 1900, $date[4] + 1, $date[3], $date[2], $date[1], $date[0]);

            $common->addSoftware({
                'NAME'          => $name,
                'ARCHITECTURE'  => $arch,
                'VERSION'       => $version,
                'INSTALLDATE'   => $installdate,
                'FILESIZE'      => $filesize,
                'COMMENTS'      => $comments,
                'PUBLISHER'     => $vendor,
                'FROM'          => 'rpm'
            });
        } else {
            $logger->debug("Should never go here!");
            $buff = '';
        }
    }
}

1;
