# Topology

![Full Suite](topology.png)

# Configuration

```json
{
    "variable": {
        "sites": {
            "default": {
                "site_a" : {
                    "dns_root": "prod.foletta.org",
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
                            "hostname": "fw",
                            "type": "fgt",
                            "interfaces": {
                                "external": { "subnet": "untrust" },
                                "internal": { "subnet": "trust"}
                            }
                        },
                        {
                            "hostname": "manager",
                            "type": "fmg",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        },
                        {
                            "hostname": "analyzer",
                            "type": "faz",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        },
                        {
                            "hostname": "auth",
                            "type": "fac",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        },
                        {
                            "hostname": "mail",
                            "type": "fml",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        },
                        {
                            "hostname": "tester",
                            "type": "fts",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        },
                        {
                            "hostname": "web",
                            "type": "fwb",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        }
                    ]
                }
            }
        }
    }
}
```
