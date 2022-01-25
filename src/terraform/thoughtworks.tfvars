vm_name = "mediawiki-vm"

rules = {
    "rule1" = {
        rule_name = "Allow_SSH"
        port      = "22"
        priority  = "100"
    }

    "rule2" = {
        rule_name = "Allow Webserver"
        port      = "80"
        priority  = "110"
    }
}

ssh_key = "<Please enter public key>"