# == Class: proxmox::hypervisor::preconfig
#
# Before installing Proxmox some modifications have to be applied on the system
#
class proxmox::hypervisor::preconfig {

  File {
    owner => root,
    group => root,
    mode  => 644,
  }

  # Hostname should be resolvable via /etc/hosts
  #/files/etc/hosts/2
  #/files/etc/hosts/2/ipaddr = '214.938.839.123'
  #/files/etc/hosts/2/canonical = 'hypervisor.domain.tld'
  #/files/etc/hosts/2/alias[1] = 'hypervisor'
  #/files/etc/hosts/1/ipaddr = '127.0.0.1'
  #/files/etc/hosts/1/canonical = 'localhost'
  augeas { $::fqdn:
    context => '/files/etc/hosts',
    changes => [
      #"ins ipaddr ${::ipaddress}",
      "set 02/ipaddr ${::ipaddress}",
      "set *[ipaddr = '${::ipaddress}']/canonical ${::fqdn}",
      "set *[ipaddr = '${::ipaddress}']/alias[1] ${::hostname}",
      "set *[ipaddr = '127.0.0.1']/canonical localhost",
      "rm *[ipaddr = '127.0.1.1']",
    ],
    onlyif  => "match *[ipaddr = '${::ipaddress}'] size == 0",
  }
  ->
  # Remove Enterprise repository (need a subscription)
  file { '/etc/apt/sources.list.d/pve-enterprise.list':
    ensure => $proxmox::hypervisor::pve_enterprise_repo_ensure,
    notify => Exec[apt_update],
  }
  ->
  # Add the standard repository (~community)
  apt::source {'proxmox':
    ensure      => present,
    location    => 'http://download.proxmox.com/debian',
    release     => $::lsbdistcodename,
    repos       => 'pve-no-subscription',
    include_src => false,
    key         => '9887F95A',
    key_server  => 'keyserver.ubuntu.com',
  }

  # Set the grub default to saved to be able to use grub-set-default during
  #  the installation
  if ! defined(Augeas['grub_default']) {
    augeas { 'grub_default':
      context => '/files/etc/default/grub',
      changes => [
        'set GRUB_DEFAULT saved',
      ],
    }
  }

  if ! defined(File['/etc/modules-load.d']) {
    file { '/etc/modules-load.d':
      ensure => directory,
    }
  }

  $values = [ 'v1', 'v2' ]

  file { $proxmox::hypervisor::pve_modules_file_path:
    ensure  => present,
    content => template($proxmox::hypervisor::pve_modules_file_content),
    require => File['/etc/modules-load.d'],
  }

} # Private class: proxmox::hypervisor::preconfig
