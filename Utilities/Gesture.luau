--[=[
	@within Weave
	@module Gesture

	Reactive input recognition for swipes, taps, and long presses on an
	instance. Returns reactive states describing the recognized gesture.

	@param instance Instance -- the input target
	@param options { swipe: boolean, longPress: number, doubleTap: number }? -- which gestures to recognize
	@return { SwipeDirection, IsLongPressing, GesturePhase, TapCount } -- reactive gesture states
]=]

return function(_Scope, _Signal)
	return function(self, instance, options)
		local opts = options or {}
		
		local swipeEnabled = opts.swipe == true
		local longPressDuration = opts.longPress or 0.5
		local doubleTapWindow = opts.doubleTap or 0.3
		
		local getSwipeDirection, setSwipeDirection = self.value(nil)
		local getIsLongPressing, setIsLongPressing = self.value(false)
		local getGesturePhase, setGesturePhase = self.value("None")
		local getTapCount, setTapCount = self.value(0)
		
		local _touchId = nil
		local _startPos = nil
		local _startTime = 0
		local _longPressThread = nil
		local _lastTapTime = 0
		
		local function cancelLongPress()
			if _longPressThread then
				task.cancel(_longPressThread)
				_longPressThread = nil
			end
			setIsLongPressing(false)
		end
		
		local function cleanupInput()
			_touchId = nil
			_startPos = nil
			cancelLongPress()
			setGesturePhase("None")
		end
		
		self._trove:Add(instance.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				if _touchId ~= nil then return end -- Already tracking
				
				_touchId = input.UserInputType == Enum.UserInputType.Touch and input.UserInputState or input
				_startPos = input.Position
				_startTime = os.clock()
				setGesturePhase("Began")
				
				cancelLongPress()
				if longPressDuration > 0 then
					_longPressThread = task.delay(longPressDuration, function()
						if _touchId ~= nil then
							setIsLongPressing(true)
							setGesturePhase("LongPress")
						end
					end)
				end
			end
		end))
		
		self._trove:Add(instance.InputChanged:Connect(function(input)
			if _touchId == nil then return end
			
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - _startPos
				if delta.Magnitude > 10 then -- Drag threshold, cancel long press
					cancelLongPress()
					setGesturePhase("Changed")
				end
			end
		end))
		
		self._trove:Add(instance.InputEnded:Connect(function(input)
			if _touchId ~= nil and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
				setGesturePhase("Ended")
				
				local endTime = os.clock()
				local duration = endTime - _startTime
				local endPos = input.Position
				local delta = endPos - _startPos
				
				-- Detect Swipe
				if swipeEnabled and delta.Magnitude > 30 and duration < 0.5 then
					local angle = math.deg(math.atan2(delta.Y, delta.X))
					if angle > -45 and angle <= 45 then setSwipeDirection(Enum.SwipeDirection.Right)
					elseif angle > 45 and angle <= 135 then setSwipeDirection(Enum.SwipeDirection.Down)
					elseif angle > 135 or angle <= -135 then setSwipeDirection(Enum.SwipeDirection.Left)
					else setSwipeDirection(Enum.SwipeDirection.Up) end
				end
				
				-- Detect Taps
				if delta.Magnitude < 10 and not getIsLongPressing() then
					if endTime - _lastTapTime < doubleTapWindow then
						setTapCount(getTapCount() + 1)
					else
						setTapCount(1)
					end
					_lastTapTime = endTime
				end
				
				cleanupInput()
			end
		end))
		
		self.OnDestroy(cleanupInput)
		
		return {
			SwipeDirection = getSwipeDirection,
			IsLongPressing = getIsLongPressing,
			GesturePhase = getGesturePhase,
			TapCount = getTapCount,
		}
	end
end
