class guest_additions (
  $use_repos    = $guest_additions::params::use_repos,
  $cd_image     = $guest_additions::params::cd_image,
  $cd_device    = $guest_additions::params::cd_device,
  $mount_point  = $guest_additions::params::mount_point,
  $platform     = $guest_additions::params::platform,
  $remove_iso   = $guest_additions::params::remove_iso,
) inherits guest_additions::params {

  package { ['dkms', 'build-essential', 'linux-headers-generic']:
    ensure => installed,
    before  => Class["guest_additions::${platform}"],
  }

  if $use_repos and ($platform == 'vmware') {
    if $::osfamily == 'Debian' {
      class { 'apt': }
    }
    # Installing from repos
  } elsif $cd_image {
    file { $guest_additions::mount_point:
      ensure => directory,
    }
    exec { 'mount-cd':
      command => "/bin/mount -o loop ${guest_additions::cd_image} ${guest_additions::mount_point}",
      before  => Class["guest_additions::${platform}"],
      require => File[$guest_additions::mount_point],
    }
    exec { 'unmount':
      command => "/bin/umount ${guest_additions::mount_point}",
    }

    if $guest_additions::remove_iso {
      exec { 'remove_iso':
        command => "/bin/rm ${guest_additions::cd_image}",
        require => Exec['unmount'],
      }
    }
  } elsif $cd_device {
    exec { 'mount-cd':
      command => "/bin/mount ${guest_additions::cd_device} ${guest_additions::mount_point}",
      require => File[$guest_additions::mount_point],
      before  => Class["guest_additions::${platform}"],
    }
    exec { 'unmount':
      command => "/bin/umount ${guest_additions::mount_point}",
    }
  } else {
    notify { 'no-cd':
      message => 'No CD image or device specified - skipping guest additions',
    }
  }

  class { "guest_additions::${platform}": }
}
