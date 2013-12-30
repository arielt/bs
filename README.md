BS
==

Binary Score allows you to execute code verification in sandbox environment. It's available on any Ubuntu machine: bare metal, virtual on-premises or in the cloud. Binary Score protects your resources while executing not trusted code. 

Executed code will be limited by:

 * Memory / Swap
 * Disk Space
 * Time
 * Number of allowed forks
 * Number of opened files
 
Currently supported languages: C++

Merging code from old sources to github, functionality is not available yet.

## Quick Start

Check out on Ubuntu machine, build and install BS package:

    git clone <BS URL>
    cd bs
    dpkg-buildpackage -us -uc
    dpkg -i ../bs_1.0.0_all.deb

Prepare sandbox:

    bs make
        
Add task to task repository:

    bs task add https://github.com/arielt/cpp_hello_world.git
    
Check status:

    bs status

Run verification process, using sample file provided with the task:

    bs task verify cpp_hello_world /opt/bs/tasks/cpp_hello_world/solutions/solution.cpp

## Troubleshooting

To rebuild the environment and sandbox, use:

    bs clean
    bs make

## Advanced

To change sandbox resources, edit **/opt/bs/config/bs.yml** and rebuild sandbox:

    bs clean
    bs make

Example of /opt/bs/config/bs.yml:

    sandbox:
      memory:     262144
      disk_space: 262144
      nproc:      8
      nofile:     64

Parameter     | Description | Example of neutralized action
------------- | ----------- | -----------------
memory        | memory limit in kylobites | https://github.com/arielt/cpp_hello_world/blob/master/solutions/solution_malloc_bomb.cpp
disk_space    | disk space limit in kylobites | https://github.com/arielt/cpp_hello_world/blob/master/solutions/solution_hd_explosion.cpp
nproc       | max number of processes | https://github.com/arielt/cpp_hello_world/blob/master/solutions/solution_fork_bomb.cpp
nofile       | max number of open files | https://github.com/arielt/cpp_hello_world/blob/master/solutions/solution_multiple_files.cpp

## TODO

* Read timeout from configuration file
* Make task repository configurable
* Apply default policy
* Add tests
* remove postinstall ease of permissions

## License

BS is released under the MIT License. http://www.opensource.org/licenses/mit-license

