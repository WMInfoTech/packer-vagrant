class guest_additions::vmware {
  if $guest_additions::use_repos {
    if $::osfamily == 'Debian' {
      apt::source { 'vmware-osps':
        location    => 'http://packages.vmware.com/tools/esx/5.1latest/ubuntu',
        release     => 'precise',
        repos       => 'main',
        key         => 'C0B5E0AB66FD4949',
        key_server  => 'keyserver.ubuntu.com',
        include_src => false,
        before      => Package['vmware-tools-esx'],
      }
    } elsif $::osfamily == 'RedHat' {
      package { 'vmware-tools-repo-RHEL6':
        ensure   => present,
        source   => 'http://packages.vmware.com/tools/esx/5.1latest/repos/vmware-tools-repo-RHEL6-9.0.10-1.el6.x86_64.rpm',
        provider => 'rpm',
        before   => Package['vmware-tools-esx'],
      }
    }

    package { 'vmware-tools-esx':
      ensure  => latest,
    }
  } elsif $guest_additions::use_cd {
    exec { 'extract-tools':
      command => "/bin/tar -zxf ${guest_additions::mount_point}/*.tar.gz -C /tmp",
      require => Exec['mount-cd'],
      creates => '/tmp/vmware-tools-distrib',
      before  => Exec['unmount'],
    }

    exec { 'install-vmware-tools':
      command => '/tmp/vmware-tools-distrib/vmware-install.pl -d',
      require => Exec['extract-tools'],
      creates => '/etc/vmware-tools',
    }

    file { '/tmp/vmware-tools-distrib':
      ensure  => absent,
      require => Exec['install-vmware-tools'],
    }

  } else {
    notice("No available way to install guest additons on ${guest_additions::platform}.")
  }

}
