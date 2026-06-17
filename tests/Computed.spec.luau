--[=[
	@module Computed.spec
	@within Weave.tests

	Test coverage for Weave behavior.
]=]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local WeaveEcs = require(ReplicatedStorage.Libraries.WeaveEcs)
	local Engine = require(ReplicatedStorage.Libraries.WeaveEcs.Core.Engine)

	describe("Computed", function()
		it("should resolve a simple derived function", function()
			local num, setNum = WeaveEcs.value(5)
			local double = WeaveEcs.computed(function()
				return num() * 2
			end)
			expect(double()).to.equal(10)
		end)

		it("should allocate a dependency tree inside Engine arrays", function()
			local a, setA = WeaveEcs.value(10)
			local b = WeaveEcs.computed(function() return a() + 5 end)
			
			b() -- force evaluation
			
			local aId = Engine.resolveId(a)
			local bId = Engine.resolveId(b)
			expect(Engine.Dependencies[aId]).to.be.a("table")
			local found = false
			for _, dep in ipairs(Engine.Dependencies[aId]) do
				if dep == bId then found = true end
			end
			expect(found).to.equal(true)
		end)

		it("should reactively update when a parent Value explicitly flushes", function()
			local count, setCount = WeaveEcs.value(0)
			local formatted = WeaveEcs.computed(function()
				return "Count is " .. tostring(count())
			end)
			
			expect(formatted()).to.equal("Count is 0")
			setCount(5)
			expect(formatted()).to.equal("Count is 5")
		end)

		it("should support deeply nested dependencies", function()
			local v, setV = WeaveEcs.value(1)
			local d1 = WeaveEcs.computed(function() return v() * 2 end)
			local d2 = WeaveEcs.computed(function() return d1() * 3 end)
			local d3 = WeaveEcs.computed(function() return d2() + 10 end)
			
			expect(d3()).to.equal(16)
			setV(5)
			expect(d3()).to.equal(40)
		end)
	end)
end
