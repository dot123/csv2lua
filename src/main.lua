cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"

local TableMgr = require("src/TableMgr")

-- 去掉字符串左空白
local function trim_left(s)
	return string.gsub(s,"^%s+","")
end

-- 去掉字符串右空白
local function trim_right(s)
	return string.gsub(s,"%s+$","")
end

-- 解析一行
local function parseline(line, key, info)
	local ret = {}
	local s = line .. "," 	-- 添加逗号，保证能得到最后一个字段
	local idx = 1 			-- 添加信息时统计索引
	while (s ~= "") do
		local v = ""
		local tl = true
		local tr = true
		while(s ~= "" and string.find(s,"^,") == nil) do
			if(string.find(s,"^\"")) then
				local _,_,vx,vz = string.find(s,"^\"(.-)\"(.*)")
				if (vx == nil) then
					return nil --不完整的一行
				end
				-- 引导开头的不去空白
				if (v == "") then
					tl = false
				end
				-- 去掉特殊多余符号
				for var in string.gfind(vx,"CLASS_ID[(](.*)[)]") do
					vx = var
				end
				v = v .. vx
				s = vz
				while(string.find(s,"^\"")) do
					local _,_vx,vz = string.find(s,"^\"(.-)\"(.*)")
					if (vx == nil) then
						return nil
					end
					-- 去掉特殊多余符号
					for var in string.gfind(vx,"CLASS_ID[(](.*)[)]") do
						vx = var
					end
					v = v .. "\'" .. vx
					s = vz
				end
				tr = true
			else
				local _,_,vx,vz = string.find(s,"^(.-)([,\"].*)")
				if (vx ~= nil) then
					-- 去掉特殊多余符号
					for var in string.gfind(vx,"CLASS_ID[(](.*)[)]") do
						vx = var
					end
					v = v .. vx
					s = vz
				else
					v = v .. s
					s = ""
				end
				tr = false
			end
		end
		if tl then v = trim_left(v) end
		if tr then v = trim_right(v) end
		if key then
			local tbData = info.spilth ~= nil and loadstring("return " .. info.spilth) or loadstring("return {} ")
			if not tbData()[key[idx]] and v ~= "" then -- 禁用的，和 空的 不列出来
				ret[key[idx]] = v
			end
			idx = idx + 1
		else
			ret[table.getn(ret) + 1] = v
		end
		if(string.find(s,"^,")) then
			s = string.gsub(s,"^,","")
		end
	end
	return ret
end

-- 解析csv文件的每一行
local function getRowContent(file)
	local count = 0 
	local content = file:read()
	if not content then return nil end
	-- 判断双引号的个数
	local i = 1
	while true do
		local index = string.find(content,"\"",i)
		if not index then break end
		i = index + 1
		count = count + 1
	end
	if count % 2 == 1 then
		assert(false,"Double quotation marks is singular, please check line text = " .. content)
	end
	return content
end

-- 解析csv文件
local function loadCsv(fileName, info)
	print("开始 解析csv文件[" .. fileName .. "]================================")
	local ret = {}
	local file = io.open(fileName,"r")
	assert(file,fileName .. "is open failed, please check ")
	local key = 	{}  -- 索引KEY
	local content = {} 	-- 信息内容
	local idx = 1
	while true do
		local line = getRowContent(file)
		if not line then break end
		if idx == tonumber(info.key_line) then
			key = line
		elseif idx >= tonumber(info.content_line) then --大于content_line 行时才开始读取（第content_line 行才是真实数据）
			if line ~= "" then
				table.insert(content, line)
			end
		end
		idx = idx + 1
	end
	-- 解析key
	key = parseline(key)
	-- 解析内容
	for i, v in ipairs(content) do
		print("解析csv文件[" .. fileName .. "]中，当前第[" ..(i + info.content_line -1) .. "]行")
		local tbData = loadstring("return " .. tostring(info.keyValue))
		if tbData() == nil and tostring(info.keyValue) ~= "nil" and type(info.keyValue) == "string" then
			-- 填string为直接键值
			local data = parseline(v, key, info)
			if data[info.keyValue] then
				ret[data[info.keyValue]] = data
				idx = idx + 1
			end
		elseif type(tbData()) == "table" then
			-- 填table为两键值以"_"合并成新键
			local data = parseline(v, key, info)
			local strKey = ""
			for i = 1,#tbData() do
				if i == 1 then
					strKey = data[tbData()[i]]
				else
					strKey = strKey .. "_" .. data[tbData()[i]]
				end
			end
			ret[strKey] = data
		else
			-- 不设置默认为有序表
			ret[table.getn(ret) + 1] = parseline(v, key, info)
		end
	end
	file:close()
	return ret
end

local function checkDirectory(filepath)
	if not cc.FileUtils:getInstance():isDirectoryExist(filepath) then
		cc.FileUtils:getInstance():createDirectory(filepath)
	end
end

local function csv2Lua(filePath, desFilePath, info)
	local t = loadCsv(filePath,info)
	TableMgr:saveTable(desFilePath, t)
end

-- 获取配置表
local function getConfig(filePath)
	local tb = {
		keyValue 		= "dictionary", -- 索引键值，1.填string为直接键值，2.填table为两键值以"_"合并成新键，3.不设置默认为有序表
		key_line 		= 6, 			-- key的行数
		content_line 	= 7, 			-- 内容起始行数
		spilth 			= "{}" 			-- 多余项
	}
	local config = loadCsv(filePath, tb)
	return config
end

local function main()
	local CSV_PATH = "CSV/"
	local LUA_PATH = "LUA/"
	local CONFIG = "CSV/config.csv"
	checkDirectory(CSV_PATH)
	checkDirectory(LUA_PATH)

	local config = getConfig(CONFIG)
	for key,var in pairs(config) do
		print("\n\n")
		print("当前操作的是[" .. key .. ".csv]========================================")
		csv2Lua(CSV_PATH .. config[key].fileName .. ".csv", LUA_PATH .. config[key].fileName .. ".lua", config[key])
		print("[" .. key ..".csv]导出结束============================================")
	end
	os.exit()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
