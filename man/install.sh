#!/bin/bash
#: File: install.sh
#: Date: 29.08.2026
#: Author: Kjetil Kristoffer Solberg <post@ikjetil.no>
#: Description: Installing man page.
printf "Installing man page\n"
./render.sh
if [ ! -d "/usr/local/man/man1" ]
then
    sudo mkdir /usr/local/man/man1
fi
sudo cp cmplayer.1 /usr/local/man/man1
sudo chmod go+r /usr/local/man/man1/cmplayer.1
printf "...install complete\n"
