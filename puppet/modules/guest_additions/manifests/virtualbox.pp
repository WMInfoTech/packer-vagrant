class guest_additions::virtualbox {
  exec { "${guest_additions::mount_point}/VBoxLinuxAdditions.run":
    require => Exec['mount-cd'],
    creates => '/etc/init.d/vboxadd',
    returns => [0, 1],
    before  => Exec['unmount'],
  }
}
