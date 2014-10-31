-- 写入文件
local function writefile(filename, info)
    local wfile=io.open(filename, "w") --写入文件(w覆盖)
    assert(wfile)  --打开时验证是否出错		
    wfile:write(info)  --写入传入的内容
    wfile:close()  --调用结束后记得关闭
end

-- 检测路径是否目录
local function is_dir(sPath)
    if type(sPath) ~= "string" then return false end

    local response = os.execute( "cd " .. sPath )
    if response == 0 then
        return true
    end
    return false
end

-- 检测文件是否存在
local file_exists = function(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

local area = nil;
local extent = nil;
local scale = nil;
local flag = nil;
local originalUri = ngx.var.uri;
local originalFile = ngx.var.file;
local index = string.find(ngx.var.uri, "([0-9]+)x([0-9]+)");  
local command = nil;
if index then 
    originalUri = string.sub(ngx.var.uri, 0, index-2);  
    area = string.sub(ngx.var.uri, index);  
    index = string.find(area, "([.])"); 
    ext = string.sub(area, index); 
    area = string.sub(area, 0, index-1);
    local index = string.find(originalFile, "([0-9]+)x([0-9]+)");  
    originalFile = string.sub(originalFile, 0, index-2)
    originalFile = originalFile..ext;
    originalUri = originalUri..ext;
    flag = string.sub(area,string.len(area)-1,string.len(area)-1);
    ngx.say("flag="..flag.." area0="..area);
    if flag == "_" then
	
        flag = string.sub(area,string.len(area),string.len(area));
	area = string.sub(area,1,string.len(area)-2);
	ngx.say("flag1="..flag.." area="..area);
        if flag == "1" then
            command =  "/usr/local/graphicsMagick/bin/gm convert " .. originalFile  .. " -scale " .. area .. " -background white -gravity center " .. ngx.var.file;
        end
        if flag == "2" then
            command = "/usr/local/graphicsMagick/bin/gm convert " .. originalFile  .. " -scale " .. area .. " -background white -gravity center -extent " .. area .. " " .. ngx.var.file;
        end
        if flag == "3" then
            command = "/usr/local/graphicsMagick/bin/gm convert " .. originalFile  .. " -scale " .. area .. "^ -background white -gravity center -extent " .. area .. " " .. ngx.var.file;
        end
    else
        command = "/usr/local/graphicsMagick/bin/gm convert " .. originalFile  .. " -scale " .. area .. " -background white -gravity center -extent " .. area .. " " .. ngx.var.file;
    end

   ngx.say("orginalUri: "..originalUri.."; orignalFile: "..originalFile.."; ext:"..ext);
end
ngx.say(command);
-- check original file，检查原文件，如果没有，则从fdfs取过来，写入本地
--ngx.say("originalUri: "..originalUri..", image_dir: "..ngx.var.image_dir);
if not file_exists(originalFile) then
    local fileid = string.sub(originalUri, 2);
    --ngx.say("fileid: "..fileid);
    -- main
    local fastdfs = require('restyfastdfs')
    local fdfs = fastdfs:new()
    fdfs:set_tracker("192.168.5.250", 22122)
    fdfs:set_timeout(1000)
    fdfs:set_tracker_keepalive(0, 100)
    fdfs:set_storage_keepalive(0, 100)
    local data = fdfs:do_download(fileid)
    if data then
       -- check image dir
        if not is_dir(ngx.var.image_dir) then
            os.execute("mkdir -p " .. ngx.var.image_dir)
        end
        writefile(originalFile, data)
    end
end

-- 创建缩略图
local image_sizes = {"40x40","80x80","100x100","120x120","160x160","200x200","240x240","300x300","360x360","400x400","480x480","540x540","600x600","640x640","720x720","800x800","840x840","900x900","960x960","1000x1000","640x320","720x360"};  
function table.contains(table, element)  
    for _, value in pairs(table) do  
        if value == element then
            return true  
        end  
    end  
    return false  
end 

if table.contains(image_sizes, area) then  
--    local command1 = "/usr/local/graphicsMagick/bin/gm convert " .. originalFile  .. " -thumbnail " .. area .. " -background white -gravity center -extent " .. area .. " " .. ngx.var.file;  
--    ngx.say("command="..command);
    os.execute(command);  
end;

--ngx.say("hello 233");
if file_exists(ngx.var.file) then
  --  ngx.say("file_exists: "..ngx.var.file);
    --ngx.req.set_uri(ngx.var.uri, true);  
    ngx.exec(ngx.var.uri)
else
--    ngx.say("file not exist");
--    return ngx.exec("@defaultimage");
   ngx.exit(404)
end
