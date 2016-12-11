Prepare secure jumpbox to access your network infrastructure from remote locations
=================================================================================

# Background

Nowadays deployments moved from bare metal servers to a quickly started virtual machines,
like the one provided by Amazon, Digital Ocean, OpenStack based providers.
Thus no longer configuration of the box requires manual administration steps.
One of the options is ready to use pre-configured box images.  Another approach is to
start from initial system restart and provision it according to project needs with some provisioner like
Ansible, Chef or Puppet.

The first step to proceed with custom provisioning - is to perform basic box securing,
as in some cases you are given with freshly installed box with the root password.

Let me share with you quick recipe on initial box securing , which should be good for most of web deployments.

## Challenges to address
  At the end of the article we should be able secure  Ubuntu 14.04 LTS / 16.04 LTS virtual server

- configure firewall, allow only 22 in.
- register your public key(s) for deploy user
- secure ssh to allow only authorization by keys.
- put automatic process in play to ban open ssh port lovers from the internet.
- install optional PPTP vpn
- install optional OpenVPN vpn
- install optional IPSec vpn (with SoftEther)
- add additional level of secure by implementing port knocking


# Points of interest

You can reuse this playbook to create your own box bootstaping projects, and
reuse the role to configure your environments quicker in secure way with ansible
