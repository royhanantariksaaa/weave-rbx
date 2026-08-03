--[=[
	@module RuntimeSmoke
	@within Weave.tests

	Standalone Roblox Studio smoke coverage for the reactive engine. Run this
	file through Studio's RunScript task against a place containing Weave and
	its runtime dependencies under ReplicatedStorage.Libraries.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local Weave = require(Libraries:WaitForChild("Weave"))
local Engine = require(Libraries.Weave.Core.Engine)

local checks = 0

local function check(condition: boolean, message: string)
	assert(condition, message)
	checks += 1
end

local function equal(actual: any, expected: any, message: string)
	assert(actual == expected, `{message}: expected {tostring(expected)}, got {tostring(actual)}`)
	checks += 1
end

-- Every scope factory supports both the documented colon form and dot form.
local apiScope = Weave.scope()
local colonValue, setColonValue = apiScope:Value(4)
local dotValue = apiScope.Value(6)
equal(colonValue(), 4, "scope colon Value initial value")
equal(dotValue(), 6, "scope dot Value initial value")
local colonComputed = apiScope:Computed(function(use)
	return use(colonValue) + use(dotValue)
end)
equal(colonComputed(), 10, "scope colon Computed dependencies")
setColonValue(5)
equal(colonComputed(), 11, "scope colon state update")
local colonSpring = apiScope:Spring(colonValue, 30, 1)
equal(colonSpring(), 5, "scope colon Spring target")
apiScope:Destroy()

-- Batches should defer propagation, coalesce writes, preserve return values,
-- and unwind correctly after a callback error.
local left, setLeft = Weave.value(1)
local right, setRight = Weave.value(2)
check(not Weave.isState(1), "ordinary numbers must not alias internal state IDs")
local evaluations = 0
local total = Weave.computed(function()
	evaluations += 1
	return left() + right()
end)

equal(total(), 3, "initial computed value")
equal(evaluations, 1, "initial computed evaluation count")

local firstResult, secondResult = Weave.batch(function()
	setLeft(10)
	setRight(20)
	equal(total(), 3, "computed value remains deferred inside a batch")
	return "first", "second"
end)

equal(firstResult, "first", "first batch return value")
equal(secondResult, "second", "second batch return value")
equal(total(), 30, "batched computed value")
equal(evaluations, 2, "batched computed evaluation count")

local failedBatch = pcall(Weave.batch, function()
	setLeft(11)
	error("intentional smoke-test failure")
end)
check(not failedBatch, "batch should propagate callback errors")
setLeft(12)
equal(total(), 32, "batch depth should unwind after an error")

-- Dynamic branches should remove old graph edges and subscribe to new ones.
local useLeft, setUseLeft = Weave.value(true)
local leftBranch, setLeftBranch = Weave.value("left")
local rightBranch, setRightBranch = Weave.value("right")
local branchEvaluations = 0
local selected = Weave.computed(function()
	branchEvaluations += 1
	return if useLeft() then leftBranch() else rightBranch()
end)

equal(selected(), "left", "initial computed branch")
setUseLeft(false)
equal(selected(), "right", "switched computed branch")
local evaluationsAfterSwitch = branchEvaluations
setLeftBranch("ignored")
equal(branchEvaluations, evaluationsAfterSwitch, "stale branch should not invalidate")
setRightBranch("updated")
equal(selected(), "updated", "active branch should invalidate")

-- Destroyed closures must never alias a state that recycles their numeric ID.
local stale, setStale = Weave.value("old")
local staleId = Engine.resolveId(stale)
Weave.destroy(stale)
Weave.destroy(stale)
local replacement = Weave.value("replacement")
local another = Weave.value("another")

equal(Engine.resolveId(replacement), staleId, "destroyed state ID should be reusable")
check(Engine.resolveId(another) ~= staleId, "double destroy must not duplicate a free ID")
check(Engine.resolveId(stale) == nil, "destroyed getter should be stale")
check(not pcall(stale), "destroyed getter should reject reads")
check(not pcall(setStale, "corrupt"), "destroyed setter should reject writes")
equal(replacement(), "replacement", "stale setter must not corrupt replacement")

-- Reconciler bindings should update while mounted and disappear on cleanup.
local parent = Instance.new("Folder")
local labelText, setLabelText = Weave.value("Initial")
local labelTextId = Engine.resolveId(labelText)
local unmount = Weave.mount(parent, function(scope)
	return scope:TextLabel({
		Text = labelText,
	})
end)
local label = parent:FindFirstChildWhichIsA("TextLabel", true)

check(label ~= nil, "mount should create a TextLabel")
equal(label.Text, "Initial", "binding should apply its initial value")
setLabelText("Updated")
equal(label.Text, "Updated", "binding should apply state updates")
equal(#Engine.Bindings[labelTextId], 1, "mounted state should have one binding")
unmount()
check(Engine.Bindings[labelTextId] == nil or #Engine.Bindings[labelTextId] == 0,
	"unmount should remove the binding record")
setLabelText("AfterUnmount")

-- Animation states participate in the same dependency graph as ordinary
-- state. Strings use AnimationState's synchronous passthrough path, which
-- keeps this smoke test compatible with Studio's non-yielding RunScript task.
local target, setTarget = Weave.value("before")
local spring = Weave.spring(target, 30, 1)
local springEvaluations = 0
local springLabel = Weave.computed(function()
	springEvaluations += 1
	return "spring:" .. spring:Get()
end)

equal(springLabel(), "spring:before", "initial spring-derived value")
equal(spring(), "before", "animation state should be callable")
setTarget("after")
equal(spring:Get(), "after", "animation state should forward unsupported values")
equal(springLabel(), "spring:after", "animation state should invalidate downstream computed state")
equal(springEvaluations, 2, "animation update should re-evaluate downstream state once")
spring:Destroy()
spring:Destroy()
check(not pcall(function()
	spring:Get()
end), "destroyed animation state should reject reads")

parent:Destroy()
print(`[Weave RuntimeSmoke] PASS ({checks} checks)`)
