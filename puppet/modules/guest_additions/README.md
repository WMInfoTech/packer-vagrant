# puppet-guest_additions
A puppet module for installing guest additions in VirtualBox and VMWare.

This module was originally intended to be used with [packer](http://packer.io) 
to install the guest additions as part of the puppet-masterless provisioner.

## Example
```
class {'guest_additions':
  cd_image => '/home/packer/linux.iso',
}
```

Will assume that a CD containing the guest additions is available 
at /home/packer/linux.iso.  It will auto-detect the hypervisor (using 
facter) and install the appropriate guest additions.  Automatic 
detection of the hypervisor can be turned off by using the `platform` 
attribute.

Other optional parameters are:
 
 - cd_device (must be used when cd_image is absent)
 - mount_point (by default this is /media/cdrom)
 - platform (by default this is auto-filled by detecting the hypervisor)
 - remove_iso (if installing from an ISO file, delete it when finished - Default: true)

## Notes

 - The mount puppet type is not used to avoid writing to fstab.
 - This module is not entirely idempotent since it was designed to run as part of a provisioner
