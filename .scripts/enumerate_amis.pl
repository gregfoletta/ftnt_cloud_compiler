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
    'help' => sub { pod2usage(1) }
) or pod2usage(2);

=pod

=head1 NAME

=head1 SYNOPSIS

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
    { name => "FortiGate", "search_string" => 'FortiGate-VM64-AWS build*' }, 
    { name => "FortiManager", "search_string" => 'FortiManager VM64-AWS build*' }, 
    { name => "FortiAnalyzer", "search_string" => 'FortiAnalyzer VM64-AWS build*'  }
);

foreach (@image_types) {
    say STDERR $_->{name};
    say encode_json( { get_hvm_images_from_description( $_->{search_string}, @aws_regions) } );
}

sub get_hvm_images_from_description {
    my ($description, @regions) = @_;

    my %amis_region_version;

    for my $region (@regions) {
        say STDERR "Region: $region";
        my $ec2 = Paws->service('EC2', region => $region);

        my $images = $ec2->DescribeImages(
            Filters => [
                { Name => 'description', Values => [$description]},
                { Name => 'virtualization-type', Values => ['hvm'] }
            ]
        );

        for my $img (@{ $images->Images() }) {
            # Strip out the version number
            my ($version) = $img->Name =~ m{build\d+ \((\d\.\d\.\d)\)};
            if (!$version) {
                warn "No version found for '".$img->Name."'";
                next;
            }

            $amis_region_version{locals}{amis}{ $region }{ $version } = $img->ImageId;
        }
    }

    return %amis_region_version;
}


