# ----------------------------------------------------------------------------------------------------------------------
# This is executed inside LXC 
# ----------------------------------------------------------------------------------------------------------------------

package {
  ['lxc', 'make', 'build-essential', 'libboost-test-dev']:
      ensure => present
}

# overlap with host group that supplies content
group {bs: gid => 10001}
group {sandbox: gid => 11111, require => Group[bs]}

user {sandbox:
    ensure => present,
    groups => [bs],
    home => '/home/sandbox',
    managehome => true,
    shell => '/bin/bash',
    uid => 11111,
    gid => 11111,
    require => Group[sandbox, bs]
}

# this is the main point of mounting - the space user sandbox access to is strongly limited
file {'/home/sandbox':               ensure => directory, mode => 755, owner => sandbox, group => sandbox, require => User[sandbox]}
file {'/home/sandbox/verification':  ensure => directory, mode => 771, owner => sandbox, group => bs, require => User[sandbox]}

