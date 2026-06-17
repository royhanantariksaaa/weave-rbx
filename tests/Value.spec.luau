--[=[
	@module Value.spec
	@within Weave.tests

	Test coverage for Weave behavior.
]=]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local WeaveEcs = require(ReplicatedStorage.Libraries.WeaveEcs)
	local Engine = require(ReplicatedStorage.Libraries.WeaveEcs.Core.Engine)

	describe("Value", function()
		it("should initialize with a value", function()
			local num, setNum = WeaveEcs.value(42)
			expect(num()).to.equal(42)
			expect(type(num)).to.equal("function") -- Pure closure, not a table
			expect(type(setNum)).to.equal("function")
		end)

		it("should update its value over time", function()
			local text, setText = WeaveEcs.value("Hello")
			setText("World")
			expect(text()).to.equal("World")
		end)

		it("should flag Engine.Changed when modified", function()
			local val, setVal = WeaveEcs.value(10)
			setVal(20)
			expect(val()).to.equal(20)
		end)

		it("should use the explicit updater callback", function()
			local count, setCount = WeaveEcs.value(0)
			-- updater-style: resolve ID and use Engine.update
			local id = Engine.resolveId(count)
			Engine.update(id, function(c) return c + 1 end)
			expect(count()).to.equal(1)
		end)

		it("should correctly clean up from the Engine when destroyed", function()
			local val, setVal = WeaveEcs.value("DeleteMe")
			local id = Engine.resolveId(val)
			
			expect(Engine.Values[id]).to.equal("DeleteMe")
			WeaveEcs.destroy(val)
			expect(Engine.Values[id]).to.equal(nil)
		end)
	end)
end
