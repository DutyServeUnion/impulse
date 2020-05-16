/*
** Copyright (c) 2017 Jake Green (TheVingard)
** This file is private and may not be shared, downloaded, used or sold.
*/

impulse.Schema = impulse.Schema or {}
HOOK_CACHE = {}

function impulse.Schema.Boot(name)
    SCHEMA_NAME = name
    MsgC(Color( 83, 143, 239 ), "[impulse] Loading '"..SCHEMA_NAME.."' schema...\n")

    local bootController = SCHEMA_NAME.."/schema/bootcontroller.lua"

    if file.Exists(bootController, "LUA") then
        MsgC(Color( 83, 143, 239 ), "[impulse] Loading bootcontroller...\n")

        if SERVER then
            include(bootController)
            AddCSLuaFile(bootController)
        else
            include(bootController)
        end
    end
    
    impulse.lib.includeDir(SCHEMA_NAME.."/schema/teams")
    impulse.lib.includeDir(SCHEMA_NAME.."/schema/items")
    impulse.lib.includeDir(SCHEMA_NAME.."/schema/benches")
    impulse.lib.includeDir(SCHEMA_NAME.."/schema/mixtures")
    impulse.lib.includeDir(SCHEMA_NAME.."/schema/buyables")
    impulse.lib.includeDir(SCHEMA_NAME.."/schema/vendors")
    impulse.lib.includeDir(SCHEMA_NAME.."/schema/config")

    local mapPath = SCHEMA_NAME.."/schema/config/maps/"..game.GetMap()..".lua"

    if SERVER and file.Exists("gamemodes/"..mapPath, "GAME") then
    	MsgC(Color( 83, 143, 239 ), "[impulse] Loading map config for '"..game.GetMap().."'\n")
    	include(mapPath)
    	AddCSLuaFile(mapPath)
        
        if impulse.Config.MapWorkshopID then
            resource.AddWorkshop(impulse.Config.MapWorkshopID)
        end

        if impulse.Config.MapContentWorkshopID then
            resource.AddWorkshop(impulse.Config.MapContentWorkshopID)
        end
    elseif CLIENT then
        include(mapPath)
        AddCSLuaFile(mapPath) 
    else
        MsgC(Color(255, 0, 0), "[impulse] No map config found!'\n")
	end

    hook.Run("PostConfigLoad")

    impulse.lib.includeDir(SCHEMA_NAME.."/schema/scripts", true, "SCHEMA", name)
    impulse.lib.includeDir(SCHEMA_NAME.."/schema/scripts/vgui", true, "SCHEMA", name)
    impulse.lib.includeDir(SCHEMA_NAME.."/schema/scripts/hooks", true, "SCHEMA", name)
    local files, plugins = file.Find(SCHEMA_NAME.."/plugins/*", "LUA")

    for v, dir in ipairs(plugins) do
        MsgC(Color( 83, 143, 239 ), "[impulse] ["..SCHEMA_NAME.."] Loading plugin '"..dir.."'\n")
        impulse.Schema.LoadPlugin(SCHEMA_NAME.."/plugins/"..dir, dir)
    end

    GM.Name = "impulse: "..impulse.Config.SchemaName

    hook.Call("OnSchemaLoaded", IMPULSE)
end

function impulse.Schema.PiggyBoot(schema, object)
    MsgC(Color( 83, 143, 239 ), "[impulse] Piggybacking "..object.." from '"..schema.."' schema...\n")
    impulse.lib.includeDir(schema.."/"..object)
end

function impulse.Schema.PiggyBootPlugin(schema, plugin)
    MsgC(Color( 83, 143, 239 ), "[impulse] ["..schema.."] Loading plugin (via PiggyBoot) '"..plugin.."'\n")
    impulse.Schema.LoadPlugin(schema.."/plugins/"..plugin, plugin)
end

function impulse.SchemaPiggyBootEntities(schema)
    impulse.Schema.LoadEntites(schema.."/entities")
end

-- taken from nutscript, cba to write this shit
function impulse.Schema.LoadEntites(path)
    local files, folders

    local function IncludeFiles(path2, clientOnly)
        if (SERVER and file.Exists(path2.."init.lua", "LUA") or CLIENT) then
            if (clientOnly and CLIENT) or SERVER then
                include(path2.."init.lua")
            end

            if (file.Exists(path2.."cl_init.lua", "LUA")) then
                if SERVER then
                    AddCSLuaFile(path2.."cl_init.lua")
                else
                    include(path2.."cl_init.lua")
                end
            end

            return true
        elseif (file.Exists(path2.."shared.lua", "LUA")) then
            AddCSLuaFile(path2.."shared.lua")
            include(path2.."shared.lua")

            return true
        end

        return false
    end

    local function HandleEntityInclusion(folder, variable, register, default, clientOnly)
        files, folders = file.Find(path.."/"..folder.."/*", "LUA")
        default = default or {}

        for k, v in ipairs(folders) do
            local path2 = path.."/"..folder.."/"..v.."/"

            _G[variable] = table.Copy(default)
                _G[variable].ClassName = v

                if (IncludeFiles(path2, clientOnly) and !client) then
                    if (clientOnly) then
                        if (CLIENT) then
                            register(_G[variable], v)
                        end
                    else
                        register(_G[variable], v)
                    end
                end
            _G[variable] = nil
        end

        for k, v in ipairs(files) do
            local niceName = string.StripExtension(v)

            _G[variable] = table.Copy(default)
                _G[variable].ClassName = niceName
                AddCSLuaFile(path.."/"..folder.."/"..v)
                include(path.."/"..folder.."/"..v)

                if (clientOnly) then
                    if (CLIENT) then
                        register(_G[variable], niceName)
                    end
                else
                    register(_G[variable], niceName)
                end
            _G[variable] = nil
        end
    end

    -- Include entities.
    HandleEntityInclusion("entities", "ENT", scripted_ents.Register, {
        Type = "anim",
        Base = "base_gmodentity",
        Spawnable = true
    })

    -- Include weapons.
    HandleEntityInclusion("weapons", "SWEP", weapons.Register, {
        Primary = {},
        Secondary = {},
        Base = "weapon_base"
    })

    -- Include effects.
    HandleEntityInclusion("effects", "EFFECT", effects and effects.Register, nil, true)
end

function impulse.Schema.LoadPlugin(path, name)
    impulse.lib.includeDir(path.."/setup", true, "PLUGIN", name)
    impulse.lib.includeDir(path, true, "PLUGIN", name)
    impulse.lib.includeDir(path.."/vgui", true, "PLUGIN", name)
    impulse.Schema.LoadEntites(path.."/entities")
    impulse.lib.includeDir(path.."/hooks", true, "PLUGIN", name)
end

function impulse.Schema.LoadHooks(file, variable, uid)
    local PLUGIN = {}
    _G[variable] = PLUGIN
    PLUGIN.impulseLoading = true

    impulse.lib.LoadFile(file)

    local c = 0

    for v,k in pairs(PLUGIN) do
        if type(k) == "function" then
            c = c + 1
            hook.Add(v, "impulse"..uid..c, function(...)
                k(nil, ...)
            end)
        end
    end

    if PLUGIN.OnLoaded then
        PLUGIN.OnLoaded()
    end

    PLUGIN.impulseLoading = nil
    _G[variable] = nil
end

function impulse.Schema.LoadEntities(path)

end