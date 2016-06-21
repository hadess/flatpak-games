local NOARCH_INSTALL_SIZE   = 23980270 -- Change to the size of the noarch folder in bytes
local X86_INSTALL_SIZE      = 7297307    -- Change to the size of the x86 folder in bytes
local X86_64_INSTALL_SIZE   = 5417530 -- Change to the size of the x86_64 folder in bytes (if you have it.. otherwise 0)
local _ = MojoSetup.translate

--  force 32bit only
local force32bit = X86_64_INSTALL_SIZE == 0 -- this forces 32bit if we have no x86_64 dir
local is32bit = force32bit or
        MojoSetup.cmdline("32bit") or
        MojoSetup.info.machine == "x86" or
        MojoSetup.info.machine == "i386" or
        MojoSetup.info.machine == "i586" or
        MojoSetup.info.machine == "i686"

local game_title = 'Baseball Stars 2' -- Change this to the full game name

Setup.Package
{
    vendor = "dotemu.com", -- DNS domain of the game
    id = "BaseballStars2", -- short ID of the game name (the install folder)
    description = game_title,
    version = "1.00",
--    splash = "splash.png", -- an image in the meta folder to display.
    splashpos = "top",
    superuser = false,
    write_manifest = true,
    support_uninstall = true,
    recommended_destinations =
    {
        MojoSetup.info.homedir,
        "/opt/games",
        "/usr/local/games"
    },

--    Setup.Eula -- add a EULA by uncommenting this section  source is relative to data/
--    {
--        description = _("EULA"),
--        source = _("EULA/en.txt"),
--    },

--    Setup.Readme -- a readme file (can occur multiple times)
--    {
--        description = _("Readme"),
--        source = _("noarch/README.linux")
--    },

    Setup.Option
    {
        value = true,
        required = true,
        disabled = false,
        bytes = NOARCH_INSTALL_SIZE,
        description = game_title,

        Setup.OptionGroup
        {
            description = _("CPU Architecture"),
            Setup.Option
            {
                value = is32bit,
                required = is32bit,
                disabled = false,
                bytes = X86_INSTALL_SIZE,
                description = "x86",
                Setup.File
                {
                    wildcards = "x86/*";
                    filter = function(fn)
                        return string.gsub(fn, "^x86/", "", 1), nil
                    end
                },
                Setup.DesktopMenuItem
                {
                    disabled = false,
                    name = game_title,
                    genericname = game_title,
                    tooltip = _(game_title),
                    builtin_icon = false,
                    icon = "BaseballStars2.png",                  -- Change the PNG Icon (relative to install dir)
                    commandline = "%0/NeogeoEmu.bin.x86",  -- Executable name (%0 is install dir)
                    workingdir = "%0",
                    category = "Game;"
                },
            },
            Setup.Option
            {
                value = not is32bit,
                required = false,
                disabled = is32bit,
                bytes = X86_64_INSTALL_SIZE,
                description = "x86_64",
                Setup.File
                {
                    wildcards = "x86_64/*";
                    filter = function(fn)
                        return string.gsub(fn, "^x86_64/", "", 1), nil
                    end
                },
                Setup.DesktopMenuItem
                {
                    disabled = false,
                    name = game_title,
                    genericname = game_title,
                    tooltip = _(game_title),
                    builtin_icon = false,
                    icon = "BaseballStars2.png",                      -- Change the PNG Icon (relative to install dir)
                    commandline = "%0/NeogeoEmu.bin.x86_64",   -- Executable name (%0 is install dir)
                    workingdir = "%0",
                    category = "Game;"
                },
            },
        },

        Setup.File
        {
            wildcards = "noarch/*";
            filter = function(fn)
                return string.gsub(fn, "^noarch/", "", 1), nil
            end
        },
    }
}

-- end of config.lua ...
