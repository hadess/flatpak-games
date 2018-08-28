# game-to-flatpak

A script to automatically convert Linux game installers in various
formats to flatpak bundles.

## Requirements

 - lua
 - lua-posix
 - lua-socket
 - lua-archive ([from this location](https://github.com/hadess/lua-archive), [PR](https://github.com/brimworks/lua-archive/pull/2))
 - luasec
 - unzip
 - flatpak-builder

## Features

 - Supports the MojoSetup installer
 - Supports the MojoSetup + makeself installer (as used by GOG.com)

## Usage

This will add the game to the `repo` directory:
```
./game-to-flatpak [installer file]
```

You will only need to do this once:
```
flatpak --user remote-add --no-gpg-verify --if-not-exists game-repo repo
```

Check which games are available in the repo:
```
flatpak --user remote-ls game-repo
```

Install the game for that user:
```
flatpak --user install game-repo com.gog.Call_of_Cthulhu__Shadow_of_the_Comet
```

## Similar projects

 - [Unpacker classes](https://cgit.gentoo.org/proj/gamerlay.git/tree/eclass) from [Gentoo's gamerlay](https://cgit.gentoo.org/proj/gamerlay.git/)
 - [./play.it](http://wiki.dotslashplay.it/en/start)'s [Debianification scripts](http://www.dotslashplay.it/scripts/)
 - [flatpak-gog](https://github.com/kujeger/flatpak-gog/), a project with similar goals, written in Python

## Out of scope

 - WINE, DOSBox, etc. automagic wrappers are not planned, don't ask for them.
