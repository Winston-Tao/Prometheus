local function recursive_loader(name)
    local function search_path(dir, filename)
        local lfs = require("lfs") -- 使用 LuaFileSystem 来遍历文件
        for file in lfs.dir(dir) do
            if file ~= "." and file ~= ".." then
                local full_path = dir .. "/" .. file
                local attr = lfs.attributes(full_path)
                if attr.mode == "directory" then
                    -- 递归子目录
                    local result = search_path(full_path, filename)
                    if result then return result end
                elseif attr.mode == "file" and file == filename then
                    return full_path
                end
            end
        end
        return nil
    end

    local dirs = {
        root .. "slg_server/service/",
        root .. "test/",
        root .. "test/init/"
    }

    for _, dir in ipairs(dirs) do
        local full_path = search_path(dir, name .. ".lua")
        if full_path then return full_path end
    end

    return nil
end

package.searchers[#package.searchers + 1] = function(name)
    local path = recursive_loader(name)
    if path then
        return loadfile(path)
    end
    return "\n\tno module '" .. name .. "' found in recursive loader"
end
