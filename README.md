BS
==

Binary Score Core


Merging code from old sources to github, functionality is not available yet.

## Quick Start

Check out on Ubuntu machine, build and install BS package:

    dpkg-buildpackage -us -uc
    dpkg -i ../bs_1.0.0_all.deb
   

Prepare sandbox:

    sudo bs make
        
Prepare tasks:

    bs task ....
    
Check status:

    bs status

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

## License

BS is released under the MIT License. http://www.opensource.org/licenses/mit-license

