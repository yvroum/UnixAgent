package Ocsinventory::Agent::Config;

use strict;
use Getopt::Long;

our $VERSION = '2.8.0';

my $basedir = '';
my $default = {
    'daemon'    =>  0,
    'debug'     =>  0,
    'devlib'    =>  0,
    'force'     =>  0,
    'help'      =>  0,
    'info'      =>  1,
    'lazy'      =>  0,
    'local'     =>  '',
#   'logger'    =>  'Syslog,File,Stderr',
    'logger'    =>  'Stderr',
    'logfacility' => 'LOG_USER',
    'logfile'   =>  '',
    'password'  =>  '',
    'proxy'     =>  '',
    'realm'     =>  '',
    'remotedir' =>  '/ocsinventory', # deprecated, give a complete URL to
                                     # --server instead
    'server'    =>  'http://ocsinventory-ng/ocsinventory',
    'stdout'    =>  0,
    'tag'       =>  '',
    'user'      =>  '',
    'version'   =>  0,
    'wait'      =>  '',
#   'xml'       =>  0,
    'nosoftware'=>  0,
    'delaytime' =>  '3600', # max delay time (seconds)
    'backendCollectTimeout'   => '600',   # timeOut of process : see Backend.pm
    'scanhomedirs' => 0,
    'ssl' => 1,
    'ca' => '',
    'snmp' => 0,

    # Other values that can't be changed with the
    # CLI parameters
    'VERSION'   => $VERSION,
    'deviceid'  => '',
    'basevardir'=>  $basedir.'/var/lib/ocsinventory-agent',
    'logdir'    =>  $basedir.'/var/log/ocsinventory-agent',
#   'pidfile'   =>  $basedir.'/var/run/ocsinventory-agent.pid',
};


sub new {
	my (undef, $params) = @_;


	my $self = {};

	bless $self;
	$self->{file} = $params->{file};

	$self->{config} = $default;
	$self->loadFromCfgFile();

	return $self;
}

sub loadFromCfgFile {
    my $self = shift;

    my $config;

    $self->{config}{etcdir} = [];

    push (@{$self->{config}{etcdir}}, '/etc/ocsinventory');
    push (@{$self->{config}{etcdir}}, '/usr/local/etc/ocsinventory');
    push (@{$self->{config}{etcdir}}, '/etc/ocsinventory-agent');
    push (@{$self->{config}{etcdir}}, $ENV{HOME}.'/.ocsinventory'); # Should I?

    my $file;
    if (!$file || !-f $file) {
        foreach (@{$self->{config}{etcdir}}) {
            $file = $_.'/ocsinventory-agent.cfg';
            last if -f $file;
        }
        return $config unless -f $file;
    }

    $self->{configfile} = $file;

    if (!open (CONFIG, "<".$file)) {
        print(STDERR "Config: Failed to open $file\n");
	    return $config;
    }

    foreach (<CONFIG>) {
        s/^#.+//;
        if (/(\w+)\s*=\s*(.+)/) {
            my $key = $1;
            my $val = $2;
            # Remove the quotes
            $val =~ s/\s+$//;
            $val =~ s/^'(.*)'$/$1/;
            $val =~ s/^"(.*)"$/$1/;
            $self->{config}{$key} = $val;
        }
    }
    close CONFIG;
}

sub loadUserParams {
	my $self = shift;
	my %options = (
		"backend-collect-timeout=s"  =>   \$self->{config}{backendCollectTimeout},
		"basevardir=s"    =>   \$self->{config}{basevardir},
		"d|daemon"        =>   \$self->{config}{daemon},
		"debug"           =>   \$self->{config}{debug},
		"devlib"          =>   \$self->{config}{devlib},
		"f|force"         =>   \$self->{config}{force},
		"h|help"          =>   \$self->{config}{help},
		"i|info"          =>   \$self->{config}{info},
		"lazy"            =>   \$self->{config}{lazy},
		"l|local=s"       =>   \$self->{config}{local},
		"logfile=s"       =>   \$self->{config}{logfile},
		"nosoftware"      =>   \$self->{config}{nosoftware},
		"p|password=s"    =>   \$self->{config}{password},
		"P|proxy=s"       =>   \$self->{config}{proxy},
		"r|realm=s"       =>   \$self->{config}{realm},
		"R|remotedir=s"   =>   \$self->{config}{remotedir},
		"s|server=s"      =>   \$self->{config}{server},
		"stdout"          =>   \$self->{config}{stdout},
		"t|tag=s"         =>   \$self->{config}{tag},
		"u|user=s"        =>   \$self->{config}{user},
		"version"         =>   \$self->{config}{version},
		"w|wait=s"        =>   \$self->{config}{wait},
#       "x|xml"          =>   \$self->{config}{xml},
		"delaytime"       =>   \$self->{config}{delaytime},
		"scan-homedirs"   =>   \$self->{config}{scanhomedirs},
		"nolocal"        =>   \$self->{config}{nolocal},
		"ssl=s"            =>   \$self->{config}{ssl},
		"ca=s"            =>   \$self->{config}{ca},
        "snmp=s"            =>   \$self->{config}{snmp},
	);

	$self->help() if (!GetOptions(%options) || $self->{config}{help});
	$self->version() if $self->{config}{version};
}


sub help {
    my ($self, $error) = @_;
    if ($error) {
        chomp $error;
        print "ERROR: $error\n\n";
    }

    if ($self->{configfile}) {
        print STDERR "Setting initialised with values retrieved from ".
        "the config found at ".$self->{configfile}."\n";
    }

    print STDERR "\n";
    print STDERR "Usage:\n";
    print STDERR "\t--backend-collect-timeout set a max delay time of one action (search package id, ...) is set (".$self->{config}{backendCollectTimeout}.")\n";
    print STDERR "\t--basevardir=/path  indicate the directory where should the agent store its files (".$self->{config}{basevardir}.")\n";
    print STDERR "\t-d  --daemon        detach the agent in background (".$self->{config}{daemon}.")\n";
    print STDERR "\t    --debug         debug mode (".$self->{config}{debug}.")\n";
    print STDERR "\t    --devlib        search for Backend mod in ./lib only (".$self->{config}{devlib}.")\n";
    print STDERR "\t-f --force          always send data to server (Don't ask before) (".$self->{config}{force}.")\n";
    print STDERR "\t-i --info           verbose mode (".$self->{config}{info}.")\n";
    print STDERR "\t--lazy              do not contact the server more than one time during the PROLOG_FREQ (".$self->{config}{lazy}.")\n";
    print STDERR "\t-l --local=DIR      do not contact server but write inventory in DIR directory in XML (".$self->{config}{local}.")\n";
    print STDERR "\t   --logfile=FILE   log message in FILE (".$self->{config}{logfile}.")\n";
    print STDERR "\t-p --password=PWD   password for server auth\n";
    print STDERR "\t-P --proxy=PROXY    proxy address. e.g: http://user:pass\@proxy:port (".$self->{config}{proxy}.")\n";
    print STDERR "\t-r --realm=REALM    realm for server auth. e.g: 'Restricted Area' (".$self->{config}{realm}.")\n";
    print STDERR "\t-s --server=uri     server uri (".$self->{config}{server}.")\n";
    print STDERR "\t   --stdout         do not write or post the inventory but print it on STDOUT\n";
    print STDERR "\t-t --tag=TAG        use TAG as tag (".$self->{config}{tag}."). Will be ignored by server if a value already exists.\n";
    print STDERR "\t-u --user=USER      user for server auth (".$self->{config}{user}.")\n";
    print STDERR "\t   --version        print the version\n";
    print STDERR "\t-w --wait=seconds   wait a random period before contacting server like --daemon does (".$self->{config}{wait}.")\n";
#   print STDERR "\t-x --xml            write output in a xml file ($self->{config}{xml})\n";
    print STDERR "\t--nosoftware        do not return installed software list (".$self->{config}{nosoftware}.")\n";
    print STDERR "\t--delaytime	      set a max delay time (in second) if no PROLOG_FREQ is set (".$self->{config}{delaytime}.")\n";
    print STDERR "\t--scan-homedirs     permit to scan home user directories (".$self->{config}{scanhomedirs}.")\n" ;
    print STDERR "\t--ssl=0|1           disable or enable SSL communications check\n" ;
    print STDERR "\t--ca=FILE           path to CA certificates file in PEM format\n" ;

    print STDERR "\n";
    print STDERR "Manpage:\n";
    print STDERR "\tSee man ocsinventory-agent\n";

    print STDERR "\n";
    print STDERR "Ocsinventory-Agent is released under GNU GPL 2 license\n";
    exit 1;
}

sub version {
    print "Ocsinventory unified agent for UNIX, Linux and MacOSX (".$VERSION.")\n";
    exit 0;
}


1;
