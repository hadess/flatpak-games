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
