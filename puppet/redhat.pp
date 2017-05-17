$install_packages = [
  'vim',
  'openssh-server',
  'git',
  'bash-completion',
  # Cloud init
  'cloud-init',
  'ruby',
]

package { $install_packages:
  ensure => installed,
}

sudo::conf { 'root':
  content  => 'root ALL=(ALL) NOPASSWD: ALL',
}

sudo::conf { 'sudo':
  priority => '10',
  content  => '%sudo ALL=(ALL) NOPASSWD: ALL',
}

$packages_to_purge = [
  'aspell',
  'command-not-found',
  'dictionaries-common',
  'dosfstools',
  'euca2ools',
  'fontconfig-config',
  'ftp',
  'fonts-dejavu-core',
  'gdisk',
  'genisoimage',
  'geoip-database',
  'language-pack-gnome-en',
  'language-pack-gnome-en-base',
  'laptop-detect',
  'mlocate',
  'nano',
  'parted',
  # 'plymouth',
  'popularity-contest',
  'powermgmt-base',
  'ppp',
  'pppconfig',
  'pppoeconf',
  'qemu-utils',
  'telnet',
  'x11-common',
  'xserver-common',
  'xserver-xorg-core',
  'linux-image-generic-lts-saucy',
  'bc',
  'medusa',
  'mtr-tiny',
  'tcpdump',
  'ufw',
  'wireless-tools',
  'wpasupplicant',
  'w3m',
]

package { $packages_to_purge:
  ensure => absent,
}

include ::sudo

sudo::conf { 'env-defaults':
  content => 'Defaults        env_reset',
}

sudo::conf { 'secure-path':
  content => 'Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/puppetlabs/bin"',
}

sudo::conf { 'default-timeout':
  content => 'Defaults timestamp_timeout=120',
}

augeas { 'ssh_no_dns':
  context => '/files/etc/ssh/sshd_config',
  changes => 'set UseDNS no',
}

augeas { 'low_vm.swappiness':
  context => '/files/etc/sysctl.conf',
  changes => 'set vm.swappiness 7',
}

user { 'maint':
  groups     => ['adm', 'sudo'],
  password   => $maint_hash,
  comment    => 'Nix Maintenance User',
  home       => '/home/maint',
  managehome => true,
  shell      => '/bin/bash',
}

group { 'sudo':
  ensure => present,
  system => true,
}
