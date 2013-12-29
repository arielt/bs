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

    git clone [BS URL]
    cd bs
    dpkg-buildpackage -us -uc
    dpkg -i ../bs_1.0.0_all.deb

Prepare sandbox:

    sudo bs make
        
You will need to create task repository. Example of such task:

    bs task add git@github.com:arielt/cpp_hello_world.git
    bs task list
    bs task del cpp_hello_world
    
Check status:

    bs status

To run verification process, you will need to specify the task and solution file.
Example of verification using solution supplied along with sample task:


    sudo bs task verify cpp_hello_world /opt/bs/tasks/cpp_hello_world/solutions/simple.cpp

Solution is not necessary the part of the task.


## Troubleshooting

To rebuild the environment and sandbox, use:

    sudo bs clean
    sudo bs make

## Advanced

To change sandbox resources, edit

    /opt/bs/config/bs.yml

Parameters:

    memory: in Kilobytes
    disk_space: in Kilobytes

Rebuild sandbox:

    sudo bs clean
    sudo bs make


## TODO

Check if invoking user is sudoer

## License

BS is released under the MIT License. http://www.opensource.org/licenses/mit-license

