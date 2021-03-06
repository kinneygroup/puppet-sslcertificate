# Author::    Paul Stack (mailto:pstack@opentable.com)
# Copyright:: Copyright (c) 2013 OpenTable Inc
# License::   MIT
# == Define: sslcertificate
#
# This defined type will install SSL Certs on windows
#
# === Requirements/Dependencies
#
# Currently reequires the puppetlabs/stdlib module on the Puppet Forge in
# order to validate much of the the provided configuration.
#
# === Parameters
#
# [*password*]
# The password for the given certificate
# By default is undef
#
# [*location*]
# The location to store intermediate certificates.
# Do not end the string with any forward or backslash.
#
# [*thumbprint*]
# The thumbprint used to verify the certificate
#
# [*friendly_name*]
# The alias of the certificate... 'friendly_name' is the cert store property in Windows
# friendly_name => 'SomeCertAlias',
#
# [*store_dir*]
# The certificate store where the certificate will be installed to
#
# [*root_store*]
# The store location for the given certification store. Either LocalMachine or CurrentUser
#
# [*scripts_dir*]
# This parameter has been deprecated and is no longer used.
#
# [*keystore_flags*]
# Flags to set on the keys, such as MachineKeySet, Exportable, or PersistKeySet.  Provide
# a comma delimted list of flags.
# To set one flag:         keystore_flags => 'Exportable',
# To set multiple flags:   keystore_flags => 'Exportable,PersistKeySet',
#
# === Examples
#
# To install a certificate in the My directory of the LocalMachine root store:
#
#  sslcertificate { "Install-PFX-Certificate" :
#    name       => 'mycert.pfx',
#    password   => 'password123',
#    location   => 'C:',
#    thumbprint => '07E5C1AF7F5223CB975CC29B5455642F5570798B'
#  }
#
# To install a certifcate in an alternative directory:
#
#  sslcertificate { "Install-Intermediate-Certificate" :
#    name       => 'go_daddy_intermediate.p7b',
#    location   => 'C:',
#    store_dir  => 'CA',
#    root_store => 'LocalMachine',
#    thumbprint => '07E5C1AF7F5223CB975CC29B5455642F5570798B'
#  }
#
# To install a certificate in the My directory of the LocalMachine root store
# using a different directory to store the scripts:
#
#  sslcertificate { "Install-PFX-Certificate" :
#    name         => 'mycert.pfx',
#    password     => 'password123',
#    location     => 'C:',
#    thumbprint   => '07E5C1AF7F5223CB975CC29B5455642F5570798B',
#    scripts_dir  => 'C:\scripts_dir'
#  }
#
# To install a certificate in the My directory of the LocalMachine root store
# and set the key as exportable:
#
#  sslcertificate { "Install-PFX-Certificate" :
#    name           => 'mycert.pfx',
#    password       => 'password123',
#    location       => 'C:',
#    thumbprint     => '07E5C1AF7F5223CB975CC29B5455642F5570798B',
#    keystore_flags => 'exportable',
#  }
#
define sslcertificate (
  String[1] $location,
  String[1] $thumbprint,
  String[1] $keystore_flags,
  String[1] $friendly_name,
  Optional[String[1]] $password    = undef,
  String[1] $root_store            = 'LocalMachine',
  String[1] $store_dir             = 'My',
  Stdlib::Windowspath $scripts_dir = 'C:\temp',
) {

  ensure_resource('file', $scripts_dir, {
    ensure => directory
  })

  # These two file resources are just here to leave a copy of what was run behind
  file { "inspect-${name}-certificate.ps1":
    ensure  => present,
    path    => "${scripts_dir}\\inspect-${name}.ps1",
    content => template('sslcertificate/inspect.ps1.erb'),
    require => File[$scripts_dir],
    mode    => '0600',
  }

  file { "import-${name}-certificate.ps1":
    ensure  => present,
    path    => "${scripts_dir}\\import-${name}.ps1",
    content => template('sslcertificate/import.ps1.erb'),
    require => File[$scripts_dir],
    mode    => '0600',
  }

  exec { "Install-${name}-SSLCert":
    provider  => powershell,
    command   => template('sslcertificate/import.ps1.erb'),
    onlyif    => template('sslcertificate/inspect.ps1.erb'),
    logoutput => true,
  }
}
