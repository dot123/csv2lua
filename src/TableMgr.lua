local TableMgr = class("TableMgr")

-- 储存table
function TableMgr:saveTable(filename, data)
	local filehandle = assert(io.open(filename,"w+"))
	filehandle:write("return ")
	self:saveTableContent(filehandle, data, 1)
	filehandle:close()
end

-- 储存数据
function TableMgr:saveTableContent(filehandle, data, idx)
	if type(tonumber(data)) == "number" then
		filehandle:write(tonumber(data))
	elseif type(data) == "string" then
		filehandle:write(string.format("%q", data))
	elseif type(data) == "table" then
		filehandle:write("{\n")
		for k,v in pairs(data) do
			self:AddTabs(filehandle, idx)
			filehandle:write("[")
			self:saveTableContent(filehandle, k, idx + 1)
			filehandle:write("] = ")
			self:saveTableContent(filehandle, v, idx + 1)
			filehandle:write(",\n")
		end
		self:AddTabs(filehandle, idx -1)
		filehandle:write("}")
	else
		error("cannot print table a " .. type(data))
	end
end

-- 在文件中添加制表符
function TableMgr:AddTabs(filehandle, idx)
	for i = 1, idx do
		filehandle:write("\t")
	end
end

return TableMgr