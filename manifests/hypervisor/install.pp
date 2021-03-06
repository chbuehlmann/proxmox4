# == Class: proxmox4::hypervisor::install
#
# Install Proxmox and inform the user he needs to reboot the system on the PVE kernel
#
class proxmox4::hypervisor::install {

  Exec {
    path      => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    logoutput => 'on_failure',
  }

  notify { 'Kernel-Type':
    message  => "Your Kernel is: ${::kernelrelease} pve-kernel?: ${::is_pve_kernel} ...",
    loglevel => warning,
  }

  
  # If the system already run a PVE kernel
  ## Quoted boolean value because can't return "true" boolean with personal fact
  if $::is_pve_kernel == 'true' {

    # Installation of Virtual Environnment
    package { $proxmox4::hypervisor::ve_pkg_name:
      ensure => $proxmox4::hypervisor::ve_pkg_ensure,
	  install_options => ['--allow-unauthenticated', '-f'],
    } ->

    # Remove useless packages (such as the standard kernel, acpid, ...)
    package { $proxmox4::hypervisor::old_pkg_name:
      ensure => $proxmox4::hypervisor::old_pkg_ensure,
	  install_options => ['--allow-unauthenticated', '-f'],
      notify => Exec['update_grub'],
    }

    # Ensure that some recommended packages are present on the system
    ensure_packages( $proxmox4::hypervisor::rec_pkg_name )

  }
  else { # If the system run on a standard Debian Kernel

    # Ensure to upgrade all packages to latest version from Proxmox repository
	
    exec { 'Upgrade package from PVE repo':
      command => 'apt-get -y --allow-unauthenticated dist-upgrade',
    } ->

    # To avoid unwanted reboot (kernel update for example), the PVE kernel is
    #  installed only if the system run on a standard Debian.
    # You will need to update your PVE kernel manually.

    # Installation of the PVE Kernel
    notify { 'Please REBOOT':
      message  => "Need to REBOOT the system on the new PVE kernel (${proxmox4::hypervisor::kernel_pkg_name}) ...",
      loglevel => warning,
    } ->

    package { $proxmox4::hypervisor::kernel_pkg_name:
      ensure => $proxmox4::hypervisor::ve_pkg_ensure,
	  install_options => ['--allow-unauthenticated', '-f'],
      notify => Exec['update_grub'],
    }

  }

  # Ensure the grub is update
  exec { 'update_grub':
    command     => 'update-grub',
    refreshonly => true,
	notify => Reboot['installed'],
  }
  
  reboot { 'installed':
    apply  => finished,
  }

} # Private class: proxmox4::hypervisor::install
