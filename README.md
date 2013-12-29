BS
==

Binary Score allows you to execute code verification in sandbox environment. 

Executed code will be limited by:

 * Memory / Swap
 * Disk Space
 * Time
 
Currently supported languages:

 * C++

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

    bs task add git@github.com:arielt/cpp_hello_world.git
    
Check status:

    bs status

Run verification process, using sample file provided with the task:

    bs task verify cpp_hello_world /opt/bs/tasks/cpp_hello_world/solutions/simple.cpp

## Troubleshooting

To rebuild the environment and sandbox, use:

    bs clean
    bs make

## Advanced

To change sandbox resources, edit

    /opt/bs/config/bs.yml

Parameters:

    memory: in Kilobytes
    disk_space: in Kilobytes

Rebuild sandbox:

    bs clean
    bs make


## TODO

Check if invoking user is sudoer

## License

BS is released under the MIT License. http://www.opensource.org/licenses/mit-license

