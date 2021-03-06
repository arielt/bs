#!/usr/bin/env ruby

$:.unshift '/opt/bs/lib'
require 'bs'
require 'bs/helpers'

cli_struct = {
  'status' => 'status',
  'make'   => 'make',
  'clean'  => 'clean',
  'task' => {
    'list'   => 'BS::Task.list',
    'add'    =>  {'.+' => 'task_add'},
    'del'    =>  {'.+' => 'task_del'},
    'verify' =>  {'.+' => {'.+' => 'verify'}}
  },
  'session' => {
    'status' => 'BS::Session.new.status',
    'make'   => {'.+' => 'session_make'},
    'clean'  => 'session_clean',
    'server' => 'session_server',
    'verify' => 'session_verify'
  }
}


def enforce_root
  unless Process.uid == 0
    puts "Root privileges are required" . red
    exit(-1)
  end
end

def enforce_not_root
  if Process.uid == 0
    puts "It's better not to be root" . red
    exit(-1)
  end
end

def print_usage
  puts 'Usage:'
  puts '  bs status'
  puts '  bs make'
  puts '  bs clean'
  puts ''
  puts '  bs task list'
  puts '  bs task add <git URL>'
  puts '  bs task del <task name>'
  puts '  bs task verify <task name> <solution file>'
  puts ''
  puts '  bs session status'
  puts '  bs session make <task name>'
  puts '  bs session clean'
  puts '  bs session server'
  puts '  bs session verify'
end

def quit_on_wrong_input
  print_usage
  exit(-1)
end

def status
  puts "Binary Score status"
  BS::Node::Desktop.new.print_status
  puts ''
  BS::Task.list
  puts ''
  BS::Session.new.status
end

def make
  enforce_root
  node = BS::Node::Desktop.new
  node.create
end

def clean
   enforce_root
   BS::Node::Desktop.new.destroy
end

def parse_arguments struct
  params = []
  while (struct && (arg = ARGV.shift)) do
    struct = struct[arg]
    while (struct.is_a?(Hash) && struct.keys[0] == '.+') do
      argv = ARGV.shift
      quit_on_wrong_input unless /.+/.match(argv)
      params.push(argv)
      struct = struct['.+']
    end
  end

  if struct 
    if params.count == 0
      quit_on_wrong_input if struct.class != String
      eval struct
    else
      eval "#{struct} params"
    end
  else
    quit_on_wrong_input
  end
end

def verify(params)
  enforce_root
  BS::Sandbox::Desktop.perform(params[0], params[1], false)
end

def task_add(args)
  enforce_root
  BS::Task.add(args)
end

def task_del
  enforce_root
  BS::Task.del
end

def session_make(args)
  enforce_root
  unless BS::Task.exists?(args[0])
    puts "Task #{args[0]} doesn't exist".red
    exit(-1)
  end
  BS::Session.new.make(args)
end

def session_clean
  enforce_root
  BS::Session.new.clean
end

def session_server
  node = BS::Node::Desktop.new
  unless node.exists?
    node.print_err 
    exit(-1)
  end

  session = BS::Session.new
  unless session.exists?
    puts "You need to create session first".red
    exit(-1)
  end

  system("cd /opt/bs/webapp && /usr/local/rvm/bin/rvmsudo rails s -p 4101")
end

def session_verify
  enforce_root
  BS::Sandbox::Desktop.perform(BS::Session.new.config['task'], "#{BS::Session::SESSION_DIR}/solution.cpp")
end


# entry point
if ARGV.empty?
  print_usage
else
  parse_arguments cli_struct
end

