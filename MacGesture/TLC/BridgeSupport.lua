-- Requires LuaExpat
local objc = require("objc")
local ffi = require("ffi")
local C = ffi.C
local lxp = require("lxp") -- LuaExpat

local bs = setmetatable({
    loadDependencies = false -- Load dependencies of bs files. Off by default since the base frameworks load a huge amount of dependencies.
}, { __index = ffi.C })

local typeKey
if ffi.abi("64bit") then
    typeKey = "type64"
else -- 32Bit (Only ARM these days)
    typeKey = "type"
end

local _loadingGlobally = false
-- Loads the bridgesupport file for the framework 'name'
function bs.loadFramework(name, global, absolute)
    _loadingGlobally = global
    objc.loadFramework(name, absolute)
    local canRead = bit.lshift(1,2)

    if absolute then
        local path = name
        local a,b, name = path:find("([^./]+).framework$")
        local bsPath = path.."/Resources/BridgeSupport/"
        local xmlPath = bsPath..name..".bridgesupport"
        local dylibPath = bsPath..name..".dylib"

        if C.access(dylibPath, canRead) == 0 then
            ffi.load(dylibPath, true)
        end
        if C.access(xmlPath, canRead) == 0 then
            bs.load(xmlPath)
        end
        return
    end

    for i,path in pairs(objc.frameworkSearchPaths) do
        local xmlPath = path:format(name, "Resources/BridgeSupport/"..name..".bridgesupport")
        local dylibPath = path:format(name, "Resources/BridgeSupport/"..name..".dylib")
        if C.access(dylibPath, canRead) == 0 then
            ffi.load(dylibPath, true)
        end
        if C.access(xmlPath, canRead) == 0 then
            return bs.load(xmlPath)
        end
    end
    print("[bs] Warning! Framework '"..name.."' not found.")
end

local _curObj = nil
local _parseCallbacks = {
    StartElement = function(p, name, attrs)
        -- Methods and classes don't really need to be loaded (keeping these here in case I find otherwise)
        --elseif name == "class" then
        --elseif name == "method" then
        --elseif name == "arg" then
        --elseif name == "retval" then
        --elseif name == "signatures" then
        if name == "string_constant" then
            rawset(bs, attrs.name, attrs.value)
            if _loadingGlobally == true then _G[attrs.name] = rawget(bs, attrs.name) end
        elseif name == "enum" then
            rawset(bs, attrs.name, tonumber(attrs.value))
            if _loadingGlobally == true then _G[attrs.name] = rawget(bs, attrs.name) end
        elseif name == "struct" then
            local type = objc.parseTypeEncoding(attrs[typeKey] or attrs.type)
            if type ~= nil and #type > 0 then
                type = objc.typeToCType(type[1])
                if type ~= nil then
                    local success, err = pcall(ffi.cdef, "typedef "..type.." "..attrs.name)
                    if success == false then
                        print("[bs] Error loading function "..attrs.name..": "..err)
                    else
                        rawset(bs, attrs.name, ffi.typeof(attrs.name))
                        if _loadingGlobally == true then _G[attrs.name] = rawget(bs, attrs.name) end
                    end
                end
            end
        --elseif name == "field" then
        --elseif name == "cftype" then
        elseif name == "constant" then
            local type = objc.parseTypeEncoding(attrs[typeKey] or attrs.type)
            if type ~= nil and #type > 0 then
                type = objc.typeToCType(type[1], attrs.name)
                if type ~= nil then
                    ffi.cdef(type)
                end
            end
        elseif name == "function" then
            _curObj = {}
            _curObj.type = "function"
            _curObj.name = attrs.name
            _curObj.args = {}
            _curObj.retval = "v"
        elseif _curObj ~= nil and name == "arg" then
            local type = attrs[typeKey]  or attrs.type
            if type == "@?" then type = "@" end -- Apple seems to have gone crazy and added a weird special case for block definitions
            table.insert(_curObj.args, type)
        elseif _curObj ~= nil and name == "retval" then
            _curObj.retval = attrs[typeKey] or attrs.type
        elseif name == "depends_on" then
            -- If dependency loading is off we still load nested frameworks
            local n = 0
            for o in attrs.path:gfind(".framework") do n=n+1 end
            if bs.loadDependencies == true or n >= 2 then
                bs.loadFramework(attrs.path, _loadingGlobally, true)
            end
        --elseif name == "opaque" then
        --elseif name == "informal_protocol" then
        --elseif name == "function_alias" then
        end
    end,
    EndElement = function(p, name)
        if name == "function" then
            local sig       = _curObj.retval..table.concat(_curObj.args)
            local signature = objc.impSignatureForTypeEncoding(sig, _curObj.name)
            if signature ~= nil then
                local obj = _curObj
                
                bs[_curObj.name] = function(...)
                    print("lazy loading fun")
                    bs[obj.name] = ffi.cdef(signature)
                    if _loadingGlobally == true then
                        _G[obj.name] = C[obj.name]
                    end
                    return bs[obj.name](...)
                end
                if _loadingGlobally == true then
                    _G[_curObj.name] = bs[_curObj.name]
                end
            end
            _curObj = nil
        end
    end
}

local _parsedBsFiles = {}
function bs.load(path)
    if _parsedBsFiles[path] == true then
        return
    end
    _parsedBsFiles[path] = true

    local parser = lxp.new(_parseCallbacks)
    for l in io.lines(path) do
        parser:parse(l)
    end
    parser:parse()
    parser:close()
end

return bs
