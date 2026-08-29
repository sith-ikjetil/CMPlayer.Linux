#!/bin/bash
#: File: test.sh
#: Date: 29.08.2026
#: Author: Kjetil Kristoffer Solberg <post@ikjetil.no>
#: Description: Test render man page.
pandoc cmplayer.1.md -s -t man | /usr/bin/man -l -
