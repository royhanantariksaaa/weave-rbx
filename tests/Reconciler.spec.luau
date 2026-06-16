return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local WeaveEcs = require(ReplicatedStorage.Libraries.WeaveEcs)
	local Engine = require(ReplicatedStorage.Libraries.WeaveEcs.Core.Engine)

	describe("Reconciler", function()
		it("should mount and bind reactive properties to a DOM instance", function()
			local parent = Instance.new("Folder")
			local mountClean
			
			local text, setText = WeaveEcs.value("Initial")
			
			local function app()
				local scope = WeaveEcs.Scope()
				return scope:TextLabel({
					Text = text  -- pass the getter closure
				})
			end
			
			mountClean = WeaveEcs.Mount(parent, "TestApp", app)
			
			local label = parent:FindFirstChild("TextLabel", true)
			expect(label).to.be.ok()
			expect(label.Text).to.equal("Initial")
			
			local textId = Engine.resolveId(text)
			local binds = Engine.Bindings[textId]
			expect(binds).to.be.ok()
			expect(#binds).to.equal(1)
			expect(binds[1].prop).to.equal("Text")
			expect(binds[1].instance).to.equal(label)
			
			setText("Updated")
			expect(label.Text).to.equal("Updated")
			
			mountClean()
		end)

		it("should support Computed DOM properties derived from multiple values", function()
			local parent = Instance.new("Folder")
			local mountClean
			
			local firstName, setFirstName = WeaveEcs.value("John")
			local lastName, setLastName = WeaveEcs.value("Doe")
			
			local fullName = WeaveEcs.computed(function()
				return firstName() .. " " .. lastName()
			end)
			
			local function app()
				local scope = WeaveEcs.Scope()
				return scope:TextLabel({
					Text = fullName
				})
			end
			
			mountClean = WeaveEcs.Mount(parent, "TestApp", app)
			
			local label = parent:FindFirstChild("TextLabel", true)
			expect(label.Text).to.equal("John Doe")
			
			setLastName("Smith")
			expect(label.Text).to.equal("John Smith")
			
			mountClean()
		end)
	end)
end
