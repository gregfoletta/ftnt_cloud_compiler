# Fortinet Cloud Compiler (FCC)

'Fortinet Cloud Compiler' is a tool that allows you to easily define and provision Fortinet devices in the cloud. The network and devices are defined in JSON, which is then ingested by [Terraform](https://www.terraform.io/) and translated into infrastructure in the cloud. It is more 'infrastructure as data' rather than 'infrastructure as code'. Yes [we've come around full circle again](http://mikehadlow.blogspot.com/2012/05/configuration-complexity-clock.html).

The key goals are:

- Definition of network and infrastructure in one place.
- Remove as much repitition as possible.
- Standard format (JSON) so it can be ingested by other tools (Ansible, scripts, etc).
- Automatic generation of FQDNs.

The original purpose was to allow me (Greg Foletta) to quickly spin up lab environments, but I feel it will have use in the broader community.

# Version

Version 0.2

# Disclaimer

This the contents of this repository is based on the author's own experiences and does not reflect the official views of any platform or vendor.


# How Does It Work?

Using a sinlge JSON file in the root directory, you define theinfrastructure you want to spin up. The JSON file is made up of a number if 'sites', each site containing 'site config' and 'device config'. Here are some example topologies and configurations which should demonstrate how it works: 

- [Firewall Only](examples/firewall_only) - Single FortiGate firewall.
- [Hub Site](examples/hub_site) - Hub Site with a FortiManager and FortiAnalyzer behind a FortiGate firewall.
- [Hub and Spoke](examples/hub_and_spoke) - Two hub sites with FortiManagers and FortiAnalyzers behind FortiGate firewalls, and a spoke site with a single FortiGate firewall.
- [Full Suite](examples/full_suite) - Single site with full suite of products behind a FortiGate firewall.

# Limitations

With simplicity comes limitations, so we'll be up-front about these:

- Only supports AWS (Azure to come)
- Single firewall, no HA
    - Multiple firewalls can be prodvisioned, however traffic between inside/outside is not routed through them.
- Route53 zone is required for DNS FQDNs.

# Licensing

Devices can have their licenses applied automatically. By default terraform will search for a license file using the 'reverse FQDN'. For example if the FQDN of the device was `fw.site_a.prod.foletta.org` then it will search for a file `./licenses/prod.foletta.org/site_a/fw`.

You can also specify the path manually using the `"license_file:" "<path>"` option under each device's configuration.

I recommend keeping license files in a separate repository.

# Regions / Availability Zones

One of the only things that is *not* configured in the JSON file is the AWS region you would like to provision into. This is configured in the `main.tf` file in the root directory.

The different AMIs for each device is taken carte of within the code.

At this stage all infra is provisioned in the 'first' availability zone in each region (e.g. ap-southeast-2a for Australia) and cannot be configured.

# What Do I Need To Run It?

The key prerequisite is terraform, with download information for various platforms [located here](https://www.terraform.io/downloads).

You should also install the [AWS CLI tool](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

You dont *need* it, but I would also install [git](https://git-scm.com/download) so you can continue to get updates.

Once that's done you can do the following:

```sh
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

# Further Info

For more information please contact me on greg@foletta.org
