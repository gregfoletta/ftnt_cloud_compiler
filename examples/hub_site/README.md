# Topology

![Hub Site](topology.png)

# Configuration

```json
{
    "variable": {
        "sites": {
            "default": {
               "hub" : {
                    "dns_root": "dev.foletta.org",
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
                            "hostname": "mgr",
                            "type": "fmg",
                            "interfaces": {
                                "mgmt": { "subnet": "trust" }
                            }
                        },
                        {
                            "hostname": "anlz",
                            "type": "faz",
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
