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
local posix = require "posix"

-- Test the luac metadata parser
data = read_all('tests/lugaru-full-linux-x86-1.0c.bin-config.luac')
local metadata = get_metadata_mojo_compiled_parse(data)
assert(metadata)
assert(metadata.id_prefix == 'com.wolfire')
assert(metadata.version == '1.0c')

-- Test the lua metadata parser
data = read_all('tests/BaseballStars2.sh-config.lua')
local metadata = get_metadata_mojo_parse(data)
assert(metadata)
assert(metadata.id_prefix == 'com.dotemu')
assert(metadata.version == '1.00')
assert(metadata.name == 'Baseball Stars 2')

-- Test the identification
assert(identify('tests/gog_another_world_20th_anniversary_edition_2.0.0.2.sh-header') == 'gog')
assert(identify('tests/lugaru-full-linux-x86-1.0c.bin-header') == 'mojo')

-- Test the reverse DNS
assert(reverse_dns('gog.com') == 'com.gog')
assert(reverse_dns('wolfire.com') == 'com.wolfire')

-- Test file exists
assert(file_exists('run-tests.lua'))
assert(not file_exists('DOES NOT EXIST.lua'))

-- Add and remove a directory
assert(mkdir_with_parents('tests/foo/bar/baz/foobazbar') == 0)
local fd = io.output('tests/foo/bar/baz/foobazbar/contents')
fd:write('full of contents')
fd:close()
remove_dir('tests/foo')
assert(not posix.stat('tests/foo'))

-- Architecture detection
assert(get_arch_for_path('tests/hello_2.9-2+deb8u1_amd64') == 'x86_64')
assert(get_arch_for_path('tests/hello_2.9-2+deb8u1_arm64') == nil)
assert(get_arch_for_path('tests/hello_2.9-2+deb8u1_i386') == 'i386')

assert(get_arch_for_dir('tests/x86_64') == 'x86_64')
assert(get_arch_for_dir('tests/mixed') == 'x86_64')
assert(get_arch_for_dir('tests/i386') == 'i386')

-- Verify deb patch URLs
assert(verify_missing_lib_args('bleh', '1.4', 'x86_64'))
local ret, error = verify_missing_lib_args('bleh', '1.1', 'x86_64')
assert(not ret)
assert(error == 'Unsupported framework version 1.1')
ret, error = verify_missing_lib_args('bleh', '1.2', 'super8')
assert(not ret)
assert(error == 'Unsupported architecture super8')
assert(get_libcaca_dl_page_url('1.2', 'x86_64'))

local body = read_all('tests/deb-download.html')
assert(parse_deb_download_page(body) == 'http://mirrors.kernel.org/ubuntu/pool/main/libc/libcaca/libcaca0_0.99.beta18-1ubuntu5_i386.deb')

local deb = read_all('tests/libcaca0_0.99.beta18-1ubuntu5_i386.deb')
local lib = unpack_libcaca_deb(deb)
local lib_ref = read_all('tests/libcaca.so.0')
assert (#lib == 813364)
assert (#lib == #lib_ref)
assert(lib_ref == lib)

local deb = read_all('tests/libcaca0_0.99.beta17-2.1ubuntu2_amd64.deb')
local lib = unpack_libcaca_deb(deb)
assert(lib)

assert(find_lib_dir('tests', 'i386') == 'tests')

-- Shell quoting
-- Tests ported from GLib
assert(shell_quote("") == "''")
assert(shell_quote("a") == "'a'")
assert(shell_quote("(") == "'('")
assert(shell_quote("'a") == "''\\''a'")
assert(shell_quote("'") == "''\\'''")
assert(shell_quote("a'") == "'a'\\'''")
assert(shell_quote("a'a") == "'a'\\''a'")

-- Won't work offline
-- assert(get_url('http://packages.ubuntu.com/precise/amd64/libcaca0/download'))
