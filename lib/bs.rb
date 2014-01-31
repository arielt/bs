module BS

  # verification status
  STATUS_OK       = 0
  STATUS_NOK      = 1
  STATUS_BUSY     = 2
  STATUS_NEW      = 3
  STATUS_ERR      = 4

  autoload :Config,      'bs/config'
  autoload :LXC,         'bs/lxc'
  autoload :Task,        'bs/task'
  autoload :Node,        'bs/node'
  autoload :Sandbox,     'bs/sandbox'
  autoload :Session,     'bs/session'
end

