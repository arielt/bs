BS
==

Binary Score Core


Merging code from old sources to github, functionality is not available yet.

## Quick Start

Check out on Ubuntu machine, build and install BS package:

    dpkg-buildpackage -us -uc
    dpkg -i ../bs_1.0.0_all.deb
    
Check status:

    bs status
    
Prepare tasks:

    bs task ....
    
Prepare sandbox:

    bs sandbox ... 


## TODO

LXC config is sensitive to reordering.

Config should keep the order / be templetazed

## License

BS is released under the MIT License. http://www.opensource.org/licenses/mit-license

