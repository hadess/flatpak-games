# game-to-flatpak

A script to automatically convert Linux game installers in various
formats to flatpak bundles.

## Requirements

 - lua
 - lua-posix
 - lua-socket
 - lua-archive
 - unzip
 - flatpak
 
## Features

 - Supports the MojoSetup installer
 - Supports the MojoSetup + makeself installer (as used by GOG.com)

## Usage

### Adding the game to your local repo

You can define which repo to add the game to by using the `--repo` option:
```
./game-to-flatpak --repo=[repo directory] [installer file]
```

If the specified directory is not already a repo, it will be created. If the 
`--repo` option is not used, it will use the directory `repo`.

If the repo you defined is new, you will need to add it to your Flatpak configuration
before you can install it. This only needs to be run once:
```
flatpak --user remote-add --no-gpg-verify --if-not-exists [repo name] [repo directory]
```

`game-to-flatpak` should print the game's name as it is running, but it can also
be found with:
```
flatpak --user remote-ls [repo name]
```

Finally, you can install the game from the repository:
```
flatpak --user install [repo name] [game name]
```

### Building and installing a bundle

You can also build a redistributable bundle with the `--bundle` option:
```
./game-to-flatpak --bundle [installer file]
```

These can be installed directly without a repo:

```
flatpak --user install [bundle filename]
```

## Similar projects

 - [Unpacker classes](https://cgit.gentoo.org/proj/gamerlay.git/tree/eclass) from [Gentoo's gamerlay](https://cgit.gentoo.org/proj/gamerlay.git/)
 - [./play.it](http://wiki.dotslashplay.it/en/start)'s [Debianification scripts](http://www.dotslashplay.it/scripts/)

## Out of scope

 - WINE, DOSBox, etc. automagic wrappers are not planned, don't ask for them.
