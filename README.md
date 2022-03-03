# Fortinet Cloud Compiler (FCC)

'Fortinet Cloud Compiler' is a tool that allows you to easily define and provision Fortinet devices in the cloud. The network and devices are defined in JSON, which is then ingested by [Terraform](https://www.terraform.io/) and translated into infrastructure in the cloud. It is more 'infrastructure as data' rather than 'infrastructure as code'. Yes [we've come around full circle again](http://mikehadlow.blogspot.com/2012/05/configuration-complexity-clock.html).

The goal of FCC was to be able to define your infrastructure in a single place, in a format that can be ingested by other tools (e.g. Ansible or scripts), while still being flexible enough to support different configurations.

The original purpose was to allow me (Greg Foletta) to quickly spin up lab environments, but 

# How Does It Work?

A JSON file in this root directory defines the infrastructure you want to spin up. The JSON file is made up of a number if 'sites', each site containing 'site config' and 'device config'. Two example configuration files have been created that you can use as a starting point:

- [Single Site](examples/single_site.tf.json) - provisions a single FortiGate firewall in a VPC in AWS.
- [Dual Hub / Dual Spokes](examples/dual_hub_spokes.tf.json) - provisions:
    - 2 x Hubs, each containing a FortiGate, FortiManager, FortiAnalyzer, and FortiTester
    - 2 x Spokes, each containing a FortiGate

Let's take a look at the individual configuration sections.

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

You can also choose, for private subnets, whether they receive a public IP address or not.






