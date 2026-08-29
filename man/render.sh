#!/bin/bash
#: File: render.sh
#: Date: 29.08.2026
#: Author: Kjetil Kristoffer Solberg <post@ikjetil.no>
#: Description: Rendering md man page to man page using pandoc.
pandoc --standalone --to man cmplayer.1.md -o cmplayer.1
