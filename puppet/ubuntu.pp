include ::apt

$install_packages = [
  'vim',
  'openssh-server',
  'nfs-common',
  'iptables-persistent',
  'git',
  'cron',
  # Cloud init
  'cloud-init',
  'cloud-initramfs-growroot',
  'cloud-guest-utils',
]

package { $install_packages:
  ensure => installed,
}

file { '/etc/cloud/cloud.cfg.d/90_dpkg.cfg':
  ensure  => file,
  content => 'datasource_list: [ NoCloud ]',
  require => Package['cloud-init'],
}

exec { 'create-seed-dir':
  command => '/bin/mkdir -p /var/lib/cloud/seed/nocloud-net',
  creates => '/var/lib/cloud/seed/nocloud-net',
  require => Package['cloud-init'],
}

$packages_to_purge = [
  'aspell',
  'command-not-found',
  'dictionaries-common',
  'dosfstools',
  'eject',
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
  'plymouth',
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

sudo::conf { 'root':
  content  => 'root ALL=(ALL) ALL',
}

sudo::conf { 'sudo':
  priority => '10',
  content  => '%sudo ALL=(ALL) ALL',
}

augeas { 'ssh_no_dns':
  context => '/files/etc/ssh/sshd_config',
  changes => 'set UseDNS no',
}

class { 'unattended_upgrades':
  origins   => [
    '${distro_id}:${distro_codename}-security',
  ],
  blacklist => [
    'linux-image-generic-lts-*',
    'linux-headers-generic',
  ],
}

# Virtualbox 5.0 identifies as KVM
if $::virtual == 'virtualbox' or $::virtual == 'kvm' {
  sudo::conf { 'sudo-vagrant':
    priority => '10',
    content  => 'vagrant ALL=(ALL) NOPASSWD: ALL',
  }

  user { 'vagrant':
    groups     => ['adm', 'sudo'],
    password   => sha1('vagrant'),
    comment    => 'vagrant',
    home       => '/home/vagrant',
    managehome => true,
    shell      => '/bin/bash',
  }

  file { '/var/lib/cloud/seed/nocloud-net/user-data':
    ensure  => file,
    require => Exec['create-seed-dir'],
    content =>
'#cloud-config
output: {all: \'| tee -a /var/log/cloud-init-output.log\'}
users:
  - default
runcmd:
 - [/sbin/btrfs, filesystem, resize, max, /]
 - [/usr/sbin/userdel, -r, maint]',
  }

  class { 'guest_additions':
    use_repos => true,
    cd_image  => '/home/vagrant/linux.iso',
    platform  => 'virtualbox',
  }

  ssh_authorized_key { 'vagrant-insecure':
    ensure => present,
    key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ==',
    user   => 'vagrant',
    type   => 'ssh-rsa',
  }
}

if $::virtual == 'vmware' {
  package { 'open-vm-tools':
    ensure => present,
  }

  file { '/var/lib/cloud/seed/nocloud-net/user-data':
    ensure  => file,
    require => Exec['create-seed-dir'],
    content =>
'#cloud-config
output: {all: \'| tee -a /var/log/cloud-init-output.log\'}
users:
  - default
runcmd:
 - [/sbin/btrfs, filesystem, resize, max, /]
 - [/usr/sbin/userdel, -r, vagrant]',
  }

  file { '/var/lib/cloud/seed/nocloud-net/meta-data':
    ensure  => file,
    require => Exec['create-seed-dir'],
    content =>
  "instance-id: vmware-vm
  local-hostname: template-${::lsbdistcodename}",
  }

  exec { 'change-default-cloud-user':
    command => '/bin/sed -i \'s/name: ubuntu$/name: maint/g\' /etc/cloud/cloud.cfg',
    unless  => '/bin/grep -qF \'name: maint\' /etc/cloud/cloud.cfg',
    require => Package['cloud-init'],
  }

  exec { 'dont-lock-cloud-passwd':
    command => '/bin/sed -i \'s/lock_passwd: True$/lock_passwd: false/g\' /etc/cloud/cloud.cfg',
    unless  => '/bin/grep -qF \'lock_passwd: false\' /etc/cloud/cloud.cfg',
    require => Package['cloud-init'],
  }

  exec { 'remove-sudoers-line-from-cloud-config':
    command => '/bin/sed -i \'/sudo:/d\' /etc/cloud/cloud.cfg',
    onlyif  => '/bin/grep -q \'sudo:\' /etc/cloud/cloud.cfg',
    require => Package['cloud-init'],
  }
}
