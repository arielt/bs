module BS
  module Node

    CONF_FILE_NAME  = "node.yml"
    CONF_FILE       = "/opt/bs/conf/node.yml"
    TMP             = "/opt/bs/tmp"

    #
    # we will strive to find the minimum required for small container (first type)
    # 64 Mb of memory is required to be at least decent provisioned by puppet
    # 256 Mb of memory is required to finish the test CPP in 30 seconds. 
    # looks like we'll need to make it 512 Mb
    #

    # all units are kilobytes
    TYPES = {
        first: {
            mem:        262144,
            swap:       524288,
            cpu_share:  1024,
            hd:         16384 
        },
        second: {
            mem:        262144,
            swap:       524288,
            cpu_share:  2048,
            hd:         65536 
        },
        third: {
            mem:        262144,
            swap:       524288,
            cpu_share:  4096,
            hd:         524288
        }
    }

    autoload :Local,     'bs/node/local'

  end
end
