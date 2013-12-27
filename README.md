BS
==

Binary Score Core Gem


Merging code from old sources to github, functionality is not available yet.

## Quick Start

Check out on Ubuntu machine, build and install BS package

    dpkg-buildpackage -us -uc
    dpkg -i ../bs_1.0.0_all.deb
    
Get Ubuntu machine

LXC is required:

    apt-get install lxc
  
Prepare the environment:

    bs make

Prepare sandbox:

    sudo env PATH=$PATH GEM_HOME=$GEM_HOME bs sandbox make
## License

BS is released under the MIT License. http://www.opensource.org/licenses/mit-license

