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

local posix = require "posix"
local socket = require "socket"
local http = require "socket.http"

-- From http://luci.subsignal.org/trac/browser/luci/trunk/libs/core/luasrc/fs.lua?rev=4103
--- Create a new directory, recursively on demand.
-- @param path      String with the name or path of the directory to create
-- @param recursive Create multiple directory levels (optional, default is true)
-- @return          Number with the return code, 0 on sucess or nil on error
-- @return          String containing the error description on error
-- @return          Number containing the os specific errno on error
function mkdir(path, recursive)
    if recursive then
        local base = "."

        if path:sub(1,1) == "/" then
            base = ""
            path = path:gsub("^/+","")
        end

        for elem in path:gmatch("([^/]+)/*") do
            base = base .. "/" .. elem

            local stat = posix.stat( base )

            if not stat then
                local stat, errmsg, errno = posix.mkdir( base )

                if type(stat) ~= "number" or stat ~= 0 then
                    return stat, errmsg, errno
                end
            else
                if stat.type ~= "directory" then
                    return nil, base .. ": File exists", 17
                end
            end
        end

        return 0
    else
        return posix.mkdir( path )
    end
end

function mkdir_with_parents(path)
	return mkdir (path, true)
end

function file_exists(path)
	local stat = posix.stat(path)
	if not stat then
		return false
	end
	return stat.type == 'regular'
end

function get_url(url)
	local body, code, headers = http.request(url)

	if code == 200 then
		return body
	else
		return nil
	end
end

function get_stdout(command)
	local f = io.popen(command, 'r')
	if not f then return nil end
	local s = f:read('*a')
	f:close()
	return s
end

function get_arch_for_path(path)
	local command = "file " .. path
	out = get_stdout(command)
	if not out then return nil end
	if out:match('ELF 32%-bit.-Intel 80386') then
		return 'i386'
	elseif out:match('ELF 64%-bit.-x86%-64') then
		return 'x86_64'
	end
	return nil
end

function get_arch_for_dir(dir)
	local files = posix.dir(dir)
	local ret = nil
	for i, name in ipairs(files) do
		if name ~= '.' and name ~= '..' then
			local full_name = string.format('%s/%s', dir, name)
			local info = posix.stat(full_name)
			local new_ret = nil
			if info and info.type == 'directory' then
				new_ret = get_arch_for_dir(full_name)
			elseif info and info.type == 'regular' then
				new_ret = get_arch_for_path(full_name)
			end

			if new_ret ~= nil then
				if ret == 'i386' or
				   ret == nil then
					ret = new_ret
				elseif new_ret == 'x86_64' then
					ret = new_ret
					break
				end
			end
		end
	end

	return ret
end

-- Similar to get_arch_for_dir()
function find_lib_dir(dir, arch)
	if not arch then
		error('arch is empty')
	end

	local ret = nil
	local files = posix.dir(dir)
	for i, name in ipairs(files) do
		if name ~= '.' and name ~= '..' then
			local full_name = string.format('%s/%s', dir, name)
			local info = posix.stat(full_name)
			if info and info.type == 'directory' then
				local libdir = find_lib_dir(full_name, arch)
				if libdir ~= nil then
					ret = libdir
					break
				end
			elseif info and info.type == 'regular' and name:match('lib.-%.so.-') then
				found_arch = get_arch_for_path(full_name)
				if found_arch == arch then
					ret = dir
				end
			end
		end
	end

	return ret
end

function remove_dir(dir)
	local files = posix.dir(dir)
	for i, name in ipairs(files) do
		if name ~= '.' and name ~= '..' then
			local full_name = string.format('%s/%s', dir, name)
			local info = posix.stat(full_name)
			if info and info.type == 'directory' then
				remove_dir(full_name)
			elseif info then
				posix.unlink(full_name)
			end
		end
	end
	posix.rmdir(dir)
end

function shell_quote(...)
	local command = type(...) == 'table' and ... or { ... }
	for i, s in ipairs(command) do
		s = (tostring(s) or ''):gsub("'", "'\\''")
		s = "'" .. s .. "'"
		command[i] = s
	end
	return table.concat(command, ' ')
end
