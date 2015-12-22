class guest_additions::params {
  $cd_image     = undef
  $cd_device    = undef

  $mount_point  = '/media/cdrom'

  $platform = $::virtual

  $remove_iso = true

  $use_repos = $platform ? {
    'vmware' => true,
    default  => false,
  }
}
