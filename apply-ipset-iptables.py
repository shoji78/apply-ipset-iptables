#!/usr/bin/env python

from subprocess import run, PIPE
import os


def parse_ipset_saverules(text):
    # TODO: implement for variouse set types. 'hash/net' is only supported now.

    rules = {}
    for i, line in enumerate(text.splitlines()):
        l = line.strip()
        if l == "" or l.startswith("#"):
            continue

        words = l.split()
        if words[0] == "create":
            setname = words[1]
            settype = words[2]
            setopt = " ".join(words[2:])
            if setname in rules.keys():
                raise Exception("Already exists the setname. '%s'" % setname)
            rules[setname] = { "type": settype, "options": setopt, "members": [] }

        elif words[0] == "add":
            setname = words[1]
            member = words[2]
            if member in rules[setname]:
                raise Exception("Already exists the member in the ipset. setname=%s member=%s" % (setname, member))

            rule = rules[setname]
            if rule["type"] == "hash:net":
                if member.endswith("/32"):
                    member = member.split("/")[0]
            else:
                raise NotImplementedError
            rule["members"].append(member)

        else:
            raise Exception("format error. lineno=%s line=[%s]" % (i+1, line))

    return rules


def load_ipset_from_cfg(filename="/etc/iptables/rules.ipset"):
    if os.path.exists(filename) is False:
        return None

    with open(filename) as f:
        text = f.read()

    return parse_ipset_saverules(text)


def load_ipset_from_memory():
    r = run(["ipset","list","-o","save"], stdout=PIPE)
    return parse_ipset_saverules(r.stdout.decode())


def exec_iptables_restore():
    with open("/etc/iptables/rules.v4") as f:
        iptables_cfg = f.read()
    run(["iptables-restore"], input=iptables_cfg.encode(), check=True)


def exec_ipset_restore():
    run(["ipset","restore","-exist", "-file", "/etc/iptables/rules.ipset"], check=True)


def exec_ipset_destroy(setname):
    run(["ipset", "destroy", setname], check=True)


def exec_ipset_member_add(setname, member):
    run(["ipset", "add", setname, member], check=True)


def exec_ipset_member_del(setname, member):
    run(["ipset", "del", setname, member], check=True)


def apply_ipset():
    rules_cfg = load_ipset_from_cfg()
    rules_mem = load_ipset_from_memory()

    setnames_cfg = set(rules_cfg.keys())
    setnames_mem = set(rules_mem.keys())
    setnames_add = setnames_cfg - setnames_mem
    setnames_del = setnames_mem - setnames_cfg
    setnames_exists = setnames_mem & setnames_cfg

    exec_ipset_restore()
    for setname in setnames_exists:
        mems_cfg = set(rules_cfg[setname]["members"])
        mems_mem = set(rules_mem[setname]["members"])
        mems_add = mems_cfg - mems_mem
        mems_del = mems_mem - mems_cfg
        for mem in mems_add:
            exec_ipset_member_add(setname, member)
        for mem in mems_del:
            exec_ipset_member_del(setname, member)

    exec_iptables_restore()
    for setname in setnames_del:
        exec_ipset_destroy(setname)


if __name__ == '__main__':
    from pprint import pprint

    apply_ipset()

