# == Define: proxmox4::hypervisor::group
#
# Manage groups and permissions to access the PVE ressources
#
# === Parameters
#
# [*group*]
#   _default_: +$title+, the title/name of the ressource
#
#   Is the group's name.
#
# [*role*]
#   _default_: +undef+
#
# [*acl_path*]
#   _default_: +/+
#
#   The objects in Proxmox form a tree, virtual machines (/vms/$vmid), storage
#   (/storage/$storageid) or ressource (/pool/$poolname). The role for this
#   group will be applied on this path.
#
# [*permission_file*]
#   _default_: +/etc/pve/user.cfg+
#
#   The file where group's informations are stored.
#
# [*users*]
#   _default_: +undef+
#
#   The user list members of this group. A user will be created if not exist.
#
define proxmox4::hypervisor::group ( $group = $title, $acl_path = '/', $permission_file = '/etc/pve/user.cfg', $users = '', $role ) {

  File {
    owner  => root,
    group  => www-data,
    mode   => '0640',
  }

  Exec {
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin'],
    logoutput => 'on_failure',
  }

  # Manage group only if Proxmox is available
  if $::is_proxmox == 'true' {

    # Create the group in Proxmox
    exec { "create_${group}_group":
      command => "pveum groupadd ${group}",
      unless  => "grep '^group:${group}' ${permission_file}",
    }
    ->
    # Define the permission
    exec { "add_${group}_permission":
      command => "pveum aclmod ${acl_path} -group ${group} -role ${role}",
      unless  => "grep '@${group}' ${permission_file}",
    }
    ->
    # Create user(s) and add it to this group
    proxmox4::hypervisor::user { $users:
      group => $group,
    }

    # The permissions file
    if ! defined(File[$permission_file]) {
      file { $permission_file:
        ensure => present,
      }
    }

  }

} # Public ressource: proxmox4::hypervisor::group
