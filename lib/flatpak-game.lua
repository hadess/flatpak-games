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

local io = require "io"
require "lib.utils"
require "lib.libraries-cleanup"

TYPE_SNIFFING_BUFFER_SIZE = 256 * 1024
ROOT_DIR = 'exploded-flatpak-game/'

-- FIXME should be in separate modules
function identify_gog(buffer)
	-- the GOG.com installers use MojoSetup inside a self-extracting
	-- to provide archive integrity checks
	if buffer:match('with modifications for mojosetup and GOG%.com installer%.') then
		return true
	end
	return false
end

function identify_mojo(buffer)
	if buffer:match('mojosetup,') and
	   buffer:match('MOJOSETUP_LOGLEVEL') then
		return true
	end
	return false
end

function identify(file)
	local f = io.open(file, "rb")
	if not f then
		return nil
	end

	local buffer = f:read(TYPE_SNIFFING_BUFFER_SIZE)
	f:close()
	if identify_gog(buffer) then
		return 'gog'
	elseif identify_mojo(buffer) then
		return 'mojo'
	else
		return nil
	end
end

function verify_gog(file)
	-- FIXME verify the quoting
	local command = 'sh ' .. file .. ' --check'
	local f = io.popen(command, 'r')
	if not f then
		return false
	end
	local s = f:read('*a')
	local exit_code = f:close()
	if exit_code or
	   exit_code == 0 then
		return true
	end
	return false
end

function verify_mojo(file)
	-- FIXME verify the quoting
	local command = 'unzip -t ' .. file
	local f = io.popen(command, 'r')
	if not f then
		return false
	end
	local s = f:read('*a')
	local exit_code = f:close()
	if exit_code or
	   exit_code == 0 then
		return true
	end

	-- FIXME return true here until we can skip forward
	-- in the file to avoid errors
	return true
end

function verify(archive_type, file)
	if archive_type == 'gog' then
		return verify_gog(file)
	elseif archive_type == 'mojo' then
		return verify_mojo(file)
	else
		error('Can not verify unhandled archive_type ' .. (archive_type or '<unset>'))
	end
end

function unpack_mojo(file)
	-- FIXME replace with lua-archive:
	-- https://github.com/brimworks/lua-archive
	local command = 'unzip -d ' .. ROOT_DIR .. '/files/lib/game/ ' .. file
	local f = io.popen(command, 'r')
	if not f then return false end
	f:read('*a')
	f:close()

	return true
end

function unpack(archive_type, file)
	if archive_type == 'gog' or
	   archive_type == 'mojo' then
		return unpack_mojo(file)
	else
		error('Can not unpack unhandled archive_type ' .. (archive_type or '<unset>'))
	end
end

function get_id(metadata)
	local name = metadata.name:gsub('%W','_')
	return metadata.id_prefix .. '.' .. name
end

-- From https://rosettacode.org/wiki/Reverse_words_in_a_string#Lua
function table.reverse(a)
	local res = {}
	for i = #a, 1, -1 do
		res[#res+1] = a[i]
	end
	return res
end

function splittokens(s)
	local res = {}
	for w in s:gmatch("%w+") do
		res[#res+1] = w
	end
	return res
end

function reverse_dns(vendor)
	local tokens = splittokens(vendor)
	return table.concat(table.reverse(tokens), '.')
end

function splitfields(s)
	local res = {}
	for w in s:gmatch("[%g ]+") do
		res[#res+1] = w
	end
	return res
end

function is_keyword(str)
	if str == 'vendor' or
	   str == 'id' or
	   str == 'description' or
	   str == 'version' or
	   str == 'name' or
	   str == 'icon' or
	   str == 'commandline' or
	   str == 'category' then
		return true
	end
	return false
end

function get_metadata_mojo_compiled_parse(data)
	local metadata = {}
	local tokens = splitfields(data)
	local vendor
	local executable
	local skip_next = false
	for index,value in ipairs(tokens) do
		if skip_next then
			skip_next = false
		elseif value == 'vendor' and
		       not is_keyword(tokens[index + 1]) then
			vendor = tokens[index + 1]
		elseif value == 'description' and
		       not is_keyword(tokens[index + 1]) then
			metadata.name = tokens[index + 1]
		elseif value == 'version' and
		       not is_keyword(tokens[index + 1]) then
			metadata.version = tokens[index + 1]
		elseif value == 'icon' and
		       not is_keyword(tokens[index + 1]) then
			metadata.icon = tokens[index + 1]
		elseif value == 'commandline' and
		       not is_keyword(tokens[index + 1]) then
			executable = tokens[index + 1]
		end
	end

	metadata.id_prefix = reverse_dns(vendor)
	metadata.executable = string.gsub(executable, '%%0', '/app/lib/game/data/noarch/')
	metadata.id = get_id(metadata)

	return metadata
end

function get_metadata_mojo_compiled(file)
	data = read_all(ROOT_DIR .. '/files/lib/game/scripts/config.luac')
	if not data then
		return nil
	end

	local metadata = get_metadata_mojo_compiled_parse(data)
	metadata.arch = get_arch_for_dir(ROOT_DIR)
	return metadata
end

function get_metadata_mojo(file)
	local metadata = {}
	data = read_all(ROOT_DIR .. '/files/lib/game/scripts/config.lua')
	if not data then
		return nil
	end

	local vendor = data:match('vendor = "(.-)"')
	metadata.id_prefix = reverse_dns(vendor)
	metadata.name = data:match('game_title = "(.-)"')
	metadata.version = data:match('version = "(.-)"')
	local executable = data:match('commandline = "(.-)"')
	metadata.executable = string.gsub(executable, '%%0', '/app/lib/game/data/noarch/')
	metadata.icon = data:match('icon = "(.-)"')
	metadata.id = get_id(metadata)
	metadata.arch = get_arch_for_dir(ROOT_DIR)

	return metadata
end

function get_metadata(archive_type, file)
	local metadata

	if archive_type == 'gog' or
	   archive_type == 'mojo' then
		metadata = get_metadata_mojo(file)
		if not metadata then
			metadata = get_metadata_mojo_compiled(file)
		end
	else
		error('Can not get metadata for unhandled archive_type ' .. (archive_type or '<unset>'))
	end

	-- Verify that the metadata is complete
	if not metadata or
	   not metadata.id_prefix or
	   not metadata.name or
	   not metadata.version or
	   not metadata.executable or
	   not metadata.icon or
	   not metadata.arch then
		return nil
	end

	return metadata
end


function create_hier()
	return mkdir_with_parents (ROOT_DIR .. '/files/bin') and
	       mkdir_with_parents (ROOT_DIR .. '/files/lib/game') and
	       mkdir_with_parents (ROOT_DIR .. '/export/share/applications') and
	       mkdir_with_parents (ROOT_DIR .. '/export/share/icons/')
end

function read_all(file)
	local f = io.open(file, "r")
	if not f then return nil end
	local t = f:read("*all")
	f:close()
	return t
end

function save_desktop(metadata)
	local f = io.open(ROOT_DIR .. '/export/share/applications/' .. metadata.id .. '.desktop', "w")
	if not f then return false end

	write_line(f, '[Desktop Entry]')
	write_line(f, 'Type=Application')
	write_line(f, 'Name=' .. metadata.name)
	write_line(f, 'Icon=' .. metadata.id)
	write_line(f, 'Exec=' .. metadata.executable)
	write_line(f, 'Categories=Game;')
	f:close()
	return true
end

function save_icon_mojo(metadata)
	path = ROOT_DIR .. 'files/lib/game/data/noarch/' .. metadata.icon
	if not file_exists(path) then
		path = ROOT_DIR .. 'files/lib/game/data/' .. metadata.icon
	end
	local ret = os.rename(path, ROOT_DIR .. 'export/share/icons/' .. metadata.id .. '.png')
	if not ret then return false end
	return true
end

function save_icon(archive_type, metadata)
	if archive_type == 'gog' or
	   archive_type == 'mojo' then
		return save_icon_mojo(metadata)
	else
		error('Can not save icon for unhandled archive_type ' .. (archive_type or '<unset>'))
	end
end

function write_line(f, line)
	f:write(line .. '\n')
end

function save_manifest(metadata, enable_network)
	local f = io.open(ROOT_DIR .. '/metadata', "w")
	if not f then return false end

	-- http://flatpak.org/developer.html#Anatomy_of_a_Flatpak_App
	write_line(f, '[Application]')
	write_line(f, 'name=' .. metadata.id)
	write_line(f, 'runtime=org.freedesktop.Platform/' .. metadata.arch .. '/1.4')
	-- FIXME is that going to work?
	write_line(f, 'command=' .. metadata.executable)
	f:write('\n')

	write_line(f, '[Context]')
	if enable_network then
		write_line(f, 'shared=network;ipc;')
	else
		write_line(f, 'shared=ipc;')
	end
	write_line(f, 'sockets=x11;wayland;pulseaudio;')
	write_line(f, 'devices=dri;')

	f:close()
	return true
end

function build_export()
	local command = 'flatpak build-export repo ' .. ROOT_DIR
	local f = io.popen(command, 'r')
	if not f then
		return false
	end
	f:close()

	return true
end

function handle(file, options)
	local archive_type = identify(file)

	if archive_type == nil then
		print("Could not find archive type for file " .. file)
		return 1
	end

	if not create_hier() then
		print ("Could not create directory hierarchy")
		return 1
	end

	if not verify(archive_type, file) then
		print ("Failed to verify file " .. file)
		return 1
	end

	if not unpack(archive_type, file) then
		print ("Failed to unpack file " .. file)
		return 1
	end

	local metadata = get_metadata(archive_type, file)
	if not metadata then
		print ("Failed to gather metadata for file " .. file)
		return 1
	end

	if not save_manifest(metadata, options.network) then
		print ("Failed to create metadata file for " .. file)
		return 1
	end

	if not save_desktop(metadata) then
		print ("Failed to save desktop file for " .. file)
		return 1
	end

	if not save_icon(archive_type, metadata) then
		print ("Failed to save icon file for " .. file)
		return 1
	end

	-- FIXME cleanup

	if not build_export() then
		print ("Could not export build for " .. file)
		return 1
	end

	-- FIXME remove the temp dir
end


