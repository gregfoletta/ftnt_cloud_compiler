#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use Pod::Usage;
use Getopt::Long;
use JSON;
use Net::SSH::Perl;


my %args;
GetOptions(
    \%args,
    'identity=s',
    'config=s',
    'no-api-key',
    'verbose',
    'help' => sub { pod2usage(1) }
) or pod2usage(2);

=pod

=head1 NAME

=head1 SYNOPSIS

=cut

main();


sub main {
    # Open the JSON configuration and slurp the contents
    my $json;
    open( my $fh, "<:encoding(UTF-8)", $args{config} ) or die "Could not open configuration '$args{c}'";
    { local $/; $json = <$fh>; }

    # Decode the JSON
    my $tf_config = decode_json($json);

    # Build the inventory
    my $inventory = build_ansible_inventory($tf_config);

    # Get the API keys for the FGTs, unless our cmd line argument determines we skip
    unless ($args{'no-api-key'}) {
        my $hosts = $inventory->{all}{hosts};
        for my $device_fqdn (keys %{ $hosts  }) {
            next unless $hosts->{ $device_fqdn }{type} eq 'fgt';
            $hosts->{ $device_fqdn }{api_key} = generate_fgt_api_key($device_fqdn);
        }
    }
    
    print encode_json( $inventory );


} 

# $tf_config is the parsed JSON configuration
# $return is the return helper.
#       First argument has the per-site hash in it
#       Second argument has the per device hash in it.
# $filter allows you to filter the device. Gets passed the
# per device hash

sub tf_config_iterate {
    my ($tf_config, $return, $filter) = @_;

    $return //= sub { return $_[0] };
    $filter //= sub { return 1 };

    my @stack;

    # Iterate through sites and devices
    my $sites = $tf_config->{variable}{sites}{default};
    for my $site (keys %{ $sites }) {
        # Add the site name to the hash.
        $sites->{ $site }{name} = $site;
        DEVICE:
        for my $device (@{ $sites->{ $site }{devices} }) {
            next DEVICE unless $filter->($device);
            push @stack, $return->($sites->{$site}, $device);
        }
    }

    return @stack;
}


sub generate_fgt_api_key {
    my ($fgt_fqdn, %opts) = @_;

    $opts{rsa_key} //= "id_rsa";
    $opts{username} //= "admin";

    my $ssh_c = Net::SSH::Perl->new(
        $fgt_fqdn,
        identity_files => [ $opts{rsa_key} ],
        debug => $args{v},
        options => [
            "StrictHostKeyChecking=no"
        ]
    );

    $ssh_c->login($opts{username});
    
    # Generate the new API key and extract it from the cmd output
    my ($cmd_output) = $ssh_c->cmd("execute api-user generate-key api_admin");
    my ($api_key) = $cmd_output =~ m{New API key: (\w{30})};

    return $api_key;
}

sub build_ansible_inventory {
    my ($tf_config) = @_;

    my $inventory = { all => { hosts => {}, vars => {}, children => {} } };

    # Add in all the hosts from each site
    $inventory->{all}{hosts} = {
        tf_config_iterate(
            $tf_config,
            \&ansible_hosts,
        )
    };

    # Add in groups based on the device type
    foreach ( tf_config_iterate($tf_config, \&ansible_device_type) ) {
        $inventory->{all}{children}{ $_->[0] }{hosts}{$_->[1]} = {};
    }

    # Add in groups based on the site
    foreach ( tf_config_iterate($tf_config, \&ansible_device_site) ) {
        $inventory->{all}{children}{ $_->[0] }{hosts}{$_->[1]} = {};
    }

    return $inventory;
}

sub ansible_hosts {
    my ($site, $device) = @_;
    my $device_fqdn = device_fqdn($site, $device);

    return ( $device_fqdn => { type => $device->{type} } );
}

sub ansible_device_type {
    my ($site, $device) = @_;
    my $device_fqdn = device_fqdn($site, $device);

    return [ $device->{type}, $device_fqdn ];
}

sub ansible_device_site {
    my ($site, $device) = @_;
    my $device_fqdn = device_fqdn($site, $device);

    return [ $site->{name}, $device_fqdn ];
}

sub device_fqdn {
    my ($s, $d) = @_;
    return join(".", $d->{hostname}, $s->{name}, $s->{dns_root});
}

    
