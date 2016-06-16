--[[
 * Copyright (C) 2016 Red Hat, Inc.
 * Author: Bastien Nocera <hadess@hadess.net>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA.
 *
--]]

local fg = require "lib.flatpak-game"

-- Test the luac metadata parser
data = read_all('tests/lugaru-full-linux-x86-1.0c.bin-config.luac')
local metadata = get_metadata_mojo_compiled_parse(data)
assert(metadata)
assert(metadata.id_prefix == 'com.wolfire')
assert(metadata.version == '1.0c')

-- Test the identification
assert(identify('tests/gog_another_world_20th_anniversary_edition_2.0.0.2.sh-header') == 'gog')
assert(identify('tests/lugaru-full-linux-x86-1.0c.bin-header') == 'mojo')
