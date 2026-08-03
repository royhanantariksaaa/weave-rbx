--[=[
	@module Computed.spec
	@within Weave.tests

	Test coverage for Weave behavior.
]=]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local WeaveEcs = require(ReplicatedStorage.Libraries.Weave)
	local Engine = require(ReplicatedStorage.Libraries.Weave.Core.Engine)

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

		it("should coalesce multiple writes into one computed evaluation", function()
			local left, setLeft = WeaveEcs.value(1)
			local right, setRight = WeaveEcs.value(2)
			local evaluations = 0
			local total = WeaveEcs.computed(function()
				evaluations += 1
				return left() + right()
			end)

			expect(total()).to.equal(3)
			expect(evaluations).to.equal(1)

			Engine.batch(function()
				setLeft(10)
				setRight(20)
			end)

			expect(total()).to.equal(30)
			expect(evaluations).to.equal(2)
		end)

		it("should remove stale dependencies when a computed branch changes", function()
			local useLeft, setUseLeft = WeaveEcs.value(true)
			local left = WeaveEcs.value("left")
			local right = WeaveEcs.value("right")
			local selected = WeaveEcs.computed(function()
				return if useLeft() then left() else right()
			end)

			local selectedId = Engine.resolveId(selected)
			local leftId = Engine.resolveId(left)
			local rightId = Engine.resolveId(right)
			expect(table.find(Engine.Dependencies[leftId], selectedId)).to.be.ok()

			setUseLeft(false)

			expect(selected()).to.equal("right")
			expect(Engine.Dependencies[leftId] == nil
				or table.find(Engine.Dependencies[leftId], selectedId) == nil).to.equal(true)
			expect(table.find(Engine.Dependencies[rightId], selectedId)).to.be.ok()
		end)
	end)
end
