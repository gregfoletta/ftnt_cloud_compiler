# Topology

![Hub and Spoke](topology.png)

# Configuration

```json
{
    "variable": {
        "sites": {
            "default": {
                "hub_a" : {
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
                    },
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
                        },
                        {
                            "type": "fmg",
                            "hostname": "manager",
                            "fortios": "6.4.7",
                            "instance_type": "m4.4xlarge",
                            "license_file": "licenses/FMG-VMTM21014620.lic",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        },
                        {
                            "type": "faz",
                            "hostname": "analyzer",
                            "fortios": "6.4.7",
                            "instance_type": "m4.4xlarge",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        }
                    ]
                },
                "hub_b" : {
                    "dns_root": "dev.example.org",
                    "vpc_cidr": "10.253.0.0/16",
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
                    },
                    "devices": [
                        {
                            "type": "fgt",
                            "hostname": "fw",
                            "fortios": "6.4.8",
                            "instance_type": "m4.4xlarge",
                            "interfaces": {
                                "external": { "subnet": "untrust" },
                                "internal": { "subnet": "trust"}
                            }
                        },
                        {
                            "type": "fmg",
                            "hostname": "manager",
                            "fortios": "6.4.7",
                            "instance_type": "m4.4xlarge",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        },
                        {
                            "type": "faz",
                            "hostname": "analyzer",
                            "fortios": "6.4.7",
                            "instance_type": "m4.4xlarge",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        },
                        {
                            "type": "fts",
                            "hostname": "tester",
                            "fortios": "6.4.7",
                            "instance_type": "m4.4xlarge",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        }
                    ]
                },
                "spoke_a" : {
                    "dns_root": "dev.example.org",
                    "vpc_cidr": "10.252.0.0/16",
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
                    },
                    "devices": [
                        {
                            "hostname": "firewall",
                            "type": "fgt",
                            "interfaces": {
                                "external": { "subnet": "untrust" },
                                "internal": { "subnet": "trust"}
                            }
                        }
                    ]
                }
            }
        }
    }
}
```
