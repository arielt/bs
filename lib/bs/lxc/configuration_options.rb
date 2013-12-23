module LXC
  module ConfigurationOptions
    VALID_OPTIONS = [
      'lxc.arch',
      'lxc.utsname',
      'lxc.network.type',
      'lxc.network.flags',
      'lxc.network.link',
      'lxc.network.name',
      'lxc.network.hwaddr',
      'lxc.network.ipv4',
      'lxc.network.ipv6',
      'lxc.pts',
      'lxc.tty',
      'lxc.mount',
      'lxc.mount.entry',
      'lxc.rootfs',
      'lxc.cgroup',
      'lxc.cap.drop',
      'lxc.pivotdir',
      'lxc.cgroup.memory.limit_in_bytes',
      'lxc.cgroup.memory.memsw.limit_in_bytes',
      'lxc.cgroup.cpu.shares',
      'lxc.devttydir'
    ]

    protected

    def valid_option?(name)
      VALID_OPTIONS.include?(name) || name =~ /^lxc.cgroup/
    end
  end
end

