Secure jumpbox to access your network infrastructure from remote locations
==========================================================================

A jump server or jump host or jumpbox is a (special-purpose) computer on a network
typically used to access devices in a separate security zone. The most common example
is managing a host in a DMZ from trusted networks or computers. This could be accessing
your home network from remote location. Access internet from your mobile device in public
locations via VPN and so on.

In this article I will demonstrate you some devops mashup - how to combine four ansible roles
to build such jump box based on Ubuntu box.

Let's briefly state our goal:

- Perform base box securing (i.e. firewall, key only login, ban failed ssh attempts, preparation for further provisioning)
- Optional install of the PPTP VPN service
- Optional install of the OpenVPN VPN service
- Optional install of the SoftEther VPN as an alternative to OpenVPN VPN service.
- If you want to be even more secure, you can add additional level of security via port knocking. This will make harder for portscanners to detect services on your box, althouth it would be more tricky to get in.


# Base box securing

Nowadays deployments moved from bare metal servers to a quickly started virtual machines,
like the one provided by Amazon, Digital Ocean, OpenStack based providers.
Thus no longer configuration of the box requires manual administration steps. At least it is overkilling in terms of time and money spent.
One of the options is ready to use pre-configured box images.  Another approach is to
start from initial system restart and provision it according to project needs with some provisioner like
Ansible or Chef .

The first step to proceed with custom provisioning - is to perform basic box securing,
as in some cases you are given with freshly installed box with the root password.

Let me share with you quick recipe on initial box securing , which should be good for most of web deployments.

What I usually do:  I strictly prohibit SSH login using password, as well as making sure than only strong keys are used. If I expose SSH port to public,
I would recommend installing tool like file2ban - daemon to ban hosts that cause multiple authentication errors. On my home jump box, ban list is longer than 100k hosts for a few years, thus I even had to compress list by banning larger networks to shorten it.

As for jumpbox it is important to have services up, I also might recommend installing monit tool - for lightweight proactive monitoring of Unix systems, network and cloud services.

Thus first component in our mashup is sa-box-bootstrap role, which can be found at  https://galaxy.ansible.com/softasap/sa-box-bootstrap/

You would need to amend following parameters: deploy_user (the user named different from root, that will be used for box accessing / provisioning). Hardly guessed user improves strength of your box. Depending on services you plan to run on jumpbox, you also can pre-configure few firewall rules. For example,
we will use 22 SSH ; 500/4500 - Softether with IPSec ; 1194 - OpenVPN; 1723 - PPTP;

More configuration options are available in role itself, but are out of scope for current example.

```YAML
my_deploy_user: slavko
my_deploy_authorized_keys:
  - "~/.ssh/id_rsa.pub"

  # revise port list for your use , consider securing by  custom_ufw_rules_allow_from_hosts
   custom_ports_allow:
      - {
          port: 22,
          proto: tcp
        }
      - {
          port: 500,
          proto: udp
        }
      - {
          port: 4500,
          proto: udp
        }
      - {
          port: 1194,
          proto: tcp
        }
      - {
          port: 1723,
          proto: tcp
        }
```

Thus our bootstrapping part will be:

```YAML
roles:
   - {
       role: "sa-box-bootstrap",
       deploy_user: "{{my_deploy_user}}",
       deploy_user_authorized_keys: "{{my_deploy_authorized_keys}}",
       ufw_rules_allow: "{{custom_ports_allow}}"
     }

```

Once this play executed, we would have ufw firewall up, file2ban ready to guard, monit ready to monitor. And your deploy user is configured for further provisioning with ansible.  


# Optional PPTP VPN

Even if PPTP is considered weak VPN protocol, it is most easy to configure by unexperienced users. Thus usually I enable it for my clients, but enforce
more strict policy for regular passwords rotation + password strength itself.  For home use, I just set long enough random password + additionally protect
with port knocking.

For PPTP we would use in our mashup sa-vpn-pptp role, which could be found at https://galaxy.ansible.com/softasap/sa-vpn-pptp/

To configure the role, we need only pass list of the users to create and type of the firewall used. (IPTables or ufw are supported at a moment)

```YAML
custom_pptp_vpn_users:
 - {
     name: "my_user",
     password: "my_password"
   }
```

Our PPTP VPN setup part would be:

```YAML
roles:
   - {
      role: "sa-vpn-pptp",
      pptp_vpn_users: "{{custom_pptp_vpn_users}}",
      firewall_used: "ufw",
      when: option_jumpbox_pptp
     }
```

At the end of the role play we would have our PPTP server up.

# Optional OpenVPN VPN

OpenVPN is considered a way stronger than PPTP, and considered to be secure for enterprise deployments.
For OpenVPN we would use in our mashup sa-vpn-openvpn role, which could be found at https://galaxy.ansible.com/softasap/sa-vpn-openvpn/

To configure the role, we need only pass list of the users to create and type of the firewall used. (IPTables or ufw are supported at a moment)

```YAML
custom_openvpn_vpn_users:
 - {
     name: "my_user"
   }
```

If you specify password in configuration above, it will be set for the key and asked each time on access.

Our OpenVPN setup part would be:

```YAML
roles:
  - {
     role: "sa-vpn-openvpn",
     openvpn_vpn_users: "{{custom_openvpn_vpn_users}}",
     firewall_used: "ufw",
     when: option_jumpbox_openvpn
    }
```

At the end of the play, playbook will download openvpn configuration files for each user you requested.
Now it is your responsibility to distribute your keys. If you create jumpbox for personal use, most likely you will need one key only.

More specifics about using OpenVPN might be found at role github repository.

# Optional SoftEther VPN

SoftEther VPN ("SoftEther" means "Software Ethernet") is one of the world's most powerful and easy-to-use multi-protocol VPN software. It runs on Windows, Linux, Mac. SoftEther VPN is open source. You can use SoftEther for any personal or commercial use for free charge.

It is believed to be able to work behind NAT by using project infrastructure, + sometimes it is easier to connect to it from windows boxes.
Number of supported VPN protocols is higher: SoftEther VPN Protocol (Ethernet over HTTPS), OpenVPN (L3-mode and L2-mode), L2TP/IPsec,
MS-SSTP (Microsoft Secure Socket Tunneling Protocol), L2TPv3/IPsec, EtherIP/IPsec. Note, that if you have your windows computer behind NAT, you will need additional registry tuning to get the ability to connect to IPSec VPN.

i.e. if you go with SoftEther, you can connect to your jumpbox into higher number of ways. Also, if you select SoftEther, you should not use sa-vpn-openvpn play.


For SoftEther we would use in our mashup sa-vpn-softether role, which could be found at https://galaxy.ansible.com/softasap/sa-vpn-softether/

Role is configurable by your own SoftEther setup script, but by default it configures OpenVPN and IPSec parts.

```YAML
custom_softether_vpn_users:
  - {
      name: "my_user",
      password: "my_password"
    }

custom_softether_ipsec_presharedkey: "[1KH;+r-X#cvhpv7Y6=#;[{u"

```

Our SoftEther setup part would be:

```YAML
roles:
  - {
      role: "sa-vpn-softether",
      softether_vpn_users: "{{custom_softether_vpn_users}}",
      softether_ipsec_presharedkey: "{{custom_softether_ipsec_presharedkey}}",
      firewall_used: "ufw",         
      when: option_jumpbox_softether
    }
```

More specifics about using SoftEther might be found at role github repository and even more - on project documentation.

Similarly to OpenVPN role, you will find connection details downloaded to your local computer for further distribution.


# Optional port knocking

Servers, by definition, are implemented as a means of providing services and making applications and resources accessible to users. However, any computer connected to the internet is inevitably targeted by malicious users and scripts hoping to take advantage of security vulnerabilities.

Firewalls exist and should be used to block access on ports not being utilized by a service, but there is still the question of what to do about services that you want access to, but do not want to expose to everybody. You want access when you need it, but want it blocked off otherwise.


Port knocking is a stealth method to externally open ports that, by default, the firewall keeps closed. It works by requiring connection attempts to a series of predefined closed port. From point of you of port scanning, you can make your host to be completely silent.

There are few utilities for port knocking. I find utility named knockd to be robust.

Thus, for port knock securing, we will use in our mashup sa-port-knock role, which could be found at https://galaxy.ansible.com/softasap/sa-port-knock/

To configure ports rules, we will need configuration like: "knock sequentially ports 16000, 15000, 17000 in 5 seconds to open ssh port for your address for 10 seconds".

You might use more sophisticated rules, like turning off by knock password, etc ;  Follow to knockd documentation.  Your pull request to role are highly appreciated.

```YAML
custom_knock_ports:
  - {
      "name": "ssh",
      "sequence": "16000, 15000, 17000",
      "seq_timeout": 5,
      "port": 22,
      "protocol": "tcp",
      "tcpflags": "syn",
      "cmd_timeout": 10
    }
```

Our port knock daemon setup part would be:

```YAML
roles:
  - {
      role: "sa-port-knock",
      knock_ports: "{{custom_knock_ports}}",
      when: option_jumpbox_port_knock
    }
```


# Full code in action

Full code in action can be found on Github at https://github.com/Voronenko/jumpbox ;
It configures jumpbox with PPTP / OpenVPN / SSH via keys by default, but can be adjusted using option switches, to deploy set of described above combinations.
```YAML
option_jumpbox_pptp: true     # install classic PPTP server

option_jumpbox_openvpn: true  # install OpenVPN server

option_jumpbox_softether: false # install openvpn SoftEther server (+ few more targeting windows)

option_jumpbox_port_knock: false # configure portknocking

```

# Points of interest

You can reuse this playbook to create your own jump box bootstaping projects, and
reuse the role to configure your environments quicker in secure way with ansible

Acceptable for home / small team use. For enterprise use - make sure you understand what you do,
as for your company you might need to follow different procedures.
