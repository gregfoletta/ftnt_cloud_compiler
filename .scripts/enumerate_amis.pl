#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use Pod::Usage;
use Getopt::Long;
use Paws;
use JSON;

my %args;
GetOptions(
    \%args,
    'device=s',
    'region=s',
    'help' => sub { pod2usage(1) }
) or pod2usage(2);

=pod

=head1 NAME

enumerate_amis - Enumerates the Fortinet device AMIs across regions

=head1 SYNOPSIS

./enumerate_amis [--device <device_tla>] [--region <region>]

=cut

my @search_strings = (
    "FortiGate VM64-AWS *",
    "FortiManager VM64-AWS *"
);

# Issues with these regions:
# af-south-1
# ap-east-1
# ap-south-1
# ap-southeast-3
# eu-south-1
# me-south-1
# us-gov-east-1 us-gov-west-1i

my @aws_regions = qw(
    us-east-1 us-east-2
    us-west-1 us-west-2
    ap-northeast-1 ap-northeast-2 ap-northeast-3 
    ap-southeast-1 ap-southeast-2 
    ca-central-1
    eu-central-1
    eu-west-1 eu-west-2 eu-west-3
    eu-north-1
    sa-east-1
);

my @image_types = (
    { name => "fgt", "name_filter" => 'FortiGate-VM64-AWS build*' }, 
    { name => "faz", "name_filter" => 'FortiManager VM64-AWS build*' }, 
    { name => "fmg", "name_filter" => 'FortiAnalyzer VM64-AWS build*'  },
    { name => "fml", "name_filter" => 'FortiMail*', version_regex => qr{\((\d+\.\d+\.\d+) GA\)} },
    { name => "fwb", "name_filter" => 'FortiWeb*BYOL*', version_regex => qr{FortiWeb-AWS-(\d+\.\d+\.\d+)} },
    { name => "fac", "name_filter" => 'FAC-*', version_regex => qr{FAC-XEN-v?(\d+(\.\d+)*)} },
    { name => "fts", "name_filter" => 'FortiTester-AWS-BYOL*' },
    { name => "fpc", "name_filter" => 'FortiPortal*' },
);

if ($args{device}) {
    @image_types = grep { $_->{name} eq $args{device} } @image_types;
    warn "No device '$args{device}' found" unless @image_types;
}

if ($args{region}) {
    @aws_regions = grep { $_ eq $args{region} } @aws_regions;
    warn "No region '$args{region}' found" unless @aws_regions
}

my %amis_of_device;

foreach (@image_types) {
    say STDERR $_->{name};

    $amis_of_device{locals}{amis}{ $_->{name} } = get_hvm_images_from_description(
            $_->{name_filter},
            $_->{version_regex},
            @aws_regions
    );

}

print JSON->new->pretty->encode( \%amis_of_device );








sub get_hvm_images_from_description {
    my ($name_filter, $version_regex, @regions) = @_;

    $version_regex //= qr{\((\d+\.\d+\.\d+)\)};

    my %amis_region_version;
    for my $region (@regions) {
        say STDERR "Region: $region";
        my $ec2 = Paws->service('EC2', region => $region);

        my $images = $ec2->DescribeImages(
            Filters => [
                { Name => 'name', Values => [$name_filter]},
                { Name => 'virtualization-type', Values => ['hvm'] }
            ]
        );

        for my $img (@{ $images->Images() }) {
            # Strip out the version number
            my ($version) = ($img->Name =~ m{$version_regex});
            if (!$version) {
                warn "No version found for '".$img->Name."'";
                next;
            }

            $amis_region_version{ $region }{ $version } = $img->ImageId;
        }
    }

    return \%amis_region_version;
}


