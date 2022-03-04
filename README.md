# Fortinet Cloud Compiler (FCC)

'Fortinet Cloud Compiler' is a tool that allows you to easily define and provision Fortinet devices in the cloud. The network and devices are defined in JSON, which is then ingested by [Terraform](https://www.terraform.io/) and translated into infrastructure in the cloud. It is more 'infrastructure as data' rather than 'infrastructure as code'. Yes [we've come around full circle again](http://mikehadlow.blogspot.com/2012/05/configuration-complexity-clock.html).

The goal of FCC was to be able to define your infrastructure in a single place, in a format that can be ingested by other tools (e.g. Ansible or scripts), while still being flexible enough to support different configurations.

The original purpose was to allow me (Greg Foletta) to quickly spin up lab environments, but I feel it will have use in the broader community.

# Version

Version 0.2

# Limitations / Caveats

With simplicity comes limitations, so we'll be up-front about these:

- Only supports AWS (Azure to come)
- Public/Private network split
- Traffic between public/private routed through a single firewall
    - You can provision multiple firewalls, however traffic between inside/outside is not routed through them.
- Route53 zone is required for DNS FQDNs

# How Does It Work?

Using a sinlge JSON file in the root directory, you define theinfrastructure you want to spin up. The JSON file is made up of a number if 'sites', each site containing 'site config' and 'device config'. Two example configuration files have been created that you can use as a starting point:

- [Single Site](examples/single_site.tf.json) - provisions a single FortiGate firewall in a VPC in AWS.
- [Dual Hub / Dual Spokes](examples/dual_hub_spokes.tf.json) - provisions:
    - 2 x Hubs, each containing a FortiGate, FortiManager, FortiAnalyzer, and FortiTester
    - 2 x Spokes, each containing a FortiGate

# What Can I Configure

You can configure:

- Zero or more 'sites', each one of which is an AWS VPC:
    - Two routing tables (public/private)
    - One or more subnets within the routing tables
- Within each site you can configure zero or more 'devices':
    - FortiGate
    - FortiManager
    - FortiAnalyzer
    - FortiTesters
- FQDNs are automatically generated for each device
- AN RSA key is generated and used to authenticate to each device
- Licensing is automatically performed by specifying paths to local license files

# What About The AWS Region / Availability Zone

One of the only things that is *not* configured in the JSON file is the AWS region you would like to provision into. This is configured in the `main.tf` file in the root directory.

The different AMIs for each device is taken carte of within the code.

At this stage all infra is provisioned in the 'first' availability zone in each region (e.g. ap-southeast-2a for Australia) and cannot be configured.

# What Do I Need To Run It?

The key prerequisite is terraform, with download information for various platforms [located here](https://www.terraform.io/downloads).

You should also install the [AWS CLI tool](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

You dont *need* it, but I would also install [git](https://git-scm.com/download) so you can continue to get updates.

Once that's done you can do the following:

```
# Clone down the repo 
git clone https://github.com/gregfoletta/ftnt_cloud_compiler.git
cd ftnt_cloud_compiler

# Initialise Terraform
terraform init

# Add a configuration file - look in the 'examples' directory for some starting points
cp examples/single_site.tf.json .

# Modify the configuration file to your satisfaction

# Ensure each device has a path to a license file

# Ensure you've configured a valid AWS access key in ~/.aws/credentials
# aws cli tool can do this for you
aws configure

# Provision your infrastructure
terraform apply

# Tear down your infrastructure
terraform destroy
```



## Site Config 

Here's an example of the site configuration section:

```json
"site_a" : {
    "dns_root": "dev.example.org",
    "vpc_cidr": "10.254.0.0/16",
     "networks": {
        "public": {
            "untrust": [ 8, 0 ]
        },
        "private": {
            "trust": {
                "subnet": [ 8, 1 ],
                "public_ipv4": true
            }
        }
    }
}
}
```

This can be further broken down into the DNS and network sections.

### DNS

The `dns_root` needs to be a domain that has it's nameservers pointed at AWS Route53. It's main purpose is to provide FDQNs that resolve the public IPs of eachd device. The FQDN is built up using `<device_hostname>.<site_name>.<dns_root>`. So for example a FortiGate with hostname 'fw' in the above site would be resolvable using the FQDN 'fw.site_a.dev.example.org'.

The second purpose is to tag all of the elements in AWS so they're easily identifiable. For example the VPC itself will be named `vpc.<site_name>.<dns_root>`, and the subnets are called 

### Network

Each site is simply a VPC in AWS, and thus a VPC IP range needs to be defined. Within this VPC there are 'public' and a 'private' networks (routing tables), each sitting on either side of the FortiGate firewall(s). *These are one of the only mandatory sections in the config and cannot be renamed.*



Within each of these you define one or more subnets. The two numbers are their subnets relative to the VPC addressing. The first number is the subnet length relative to the VPC subnet, the second number is the index. So in the above example 
- The 'untrust' subnet is the zero'th (/16 + /8 = /24) of the VPC: 10.254.0.0/24
- The 'trust' subnet is the first (/16 + /8 = /24) of the VPC: 10.254.1.0/24

You can also choose, for private subnets, whether they receive a public IP address or not. [VPC ingress routing](https://aws.amazon.com/blogs/aws/new-vpc-ingress-routing-simplifying-integration-of-third-party-appliances/) is automatically configured, so traffic to public IPs within the private network will traverse the FortiGate firewall.


## Device Config

within each site, there is a device configuration section. Here is an example:

```json
"site_a": {
    "devices": [
        {
            "type": "fgt",
            "hostname": "fw",
            "fortios": "6.4.8",
            "instance_type": "m4.4xlarge",
            "license_file": "licenses/FGVM02TM21017453.lic",
            "interfaces": {
                "external": { "subnet": "untrust" },
                "internal": { "subnet": "trust"}
            }
        }
    ]
}
```

The `type` defines the type of device you want to provision. Currently there are four options:

- fgt:  FortiGate
- fmg: FortiManager
- faz: FortiAnalyzer
- fts: FortiTester

The `hostname` is used in the FQDN for the device to (refer to the DNS section above).

The `fortios` and `instance_type` define the FortiOS version and AWS instance type the device will run/run on. These are optional and each device has sensible defaults:

| Device | Default FortiOS | Default Instance | Disk Size |
| -----  | --------------- | ---------------- | --------- |
| FGT    | 7.0.3           | t2.small         | 30Gb EBS  |
| FMG    | 7.0.3           | m4.large         | 80Gb EBS  |
| FAZ    | 7.0.3           | m4.large         | 80Gb EBS  |
| FAZ    | 4.1.1           | c5.xlarge        | 80Gb EBS  |

At this stage disk sizes are fixed and cannot be JSON configured

The `license_file` is a path (relative to the root directory) in which the license file for the device resides. This is uploaded during the provisioning process.

The `interfaces` define the subnets that the device is tethered in:

- FortiGates have two hardcoded interfaces `external` and `internal`. The external must be tethered in a subnet in the *public* network, and the internal must be tethered in subnet in the *private* network. 
- All other devices have a `mgmt` interface, which must be tethered in subnet in the *private* network.

The subnets are referenced by name.

# Further Info

For more information please contact me on greg@foletta.org
