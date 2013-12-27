# there are several gems that deal with lxc
# none of them worked for me, since they re-order conf file
module BS
  module LXC

    KNOBS = {
      :mem          => 'lxc.cgroup.memory.limit_in_bytes',
      :swap         => 'lxc.cgroup.memory.memsw.limit_in_bytes',
      :network_type => 'lxc.network.type'
    }

    autoload :Container,  'bs/lxc/container' 
  end
end

