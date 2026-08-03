--!optimize 2

local Engine = require(script.Parent.Parent.Core.Engine)

local Shared = {}

function Shared.read(source: any): any
	if type(source) == "function" then
		return source()
	end
	if type(source) == "table" and type(source.Get) == "function" then
		return source:Get()
	end
	return source
end

function Shared.peek(source: any): any
	if Engine.resolveId(source) ~= nil then
		return Engine.peek(source)
	end
	if type(source) == "table" and type(source.Peek) == "function" then
		return source:Peek()
	end
	if type(source) == "table" and type(source.Get) == "function" then
		return source:Get()
	end
	if type(source) == "function" then
		return source()
	end
	return source
end

return Shared
