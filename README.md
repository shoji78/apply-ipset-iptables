# apply-ipset-iptables
apply-ipset-iptables.py is a script to restore iptables and ipset form persistent files, and remove unnecessary "set" from memory.

## Description
- iptables and ipset's rules are not any restrincted, just write in standard rule format, like a "iptables-save" and "ipset list -save".
- iptables and ipset are loaded when boot automatically by standard netfilter-persistet
- This script allows reload iptable and ipset without unnecessary packets dropping.
- it doesn't remain unnecessary "set" in memory.


Following packages are installed automatically:
- iptables-persistent 
- ipset 

## Requirement
- Ubuntu 18.04

## Usage
```
sudo  apply-ipset-iptables.py
```

## Installation
```
curl https://raw.githubusercontent.com/shoji78/apply-ipset-iptables/master/setup.sh | sudo bash
```

