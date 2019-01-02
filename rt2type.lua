-- * Usage: rt2type("things to type")
-- * Lua escape sequences are accepted.
-- * Some programs (like quadratic.asm) clear the input buffer on startup and
--   before they enter input mode (when the cursor is blinking), so characters
--   in the rt2type queue may be lost. You have to prepare your queue with this
--   in mind.
-- * Example: to test quadratic.asm, issue rt2type("  4\r 5\r -6\r"). This will
--   solve 4xx + 5x - 6 = 0, so you should get 0.75 and -2.

pcall(tpt.unregister_step, rt2type and rt2type.step_func)
rt2type = setmetatable({}, {__call = function(self, str)
	pcall(tpt.unregister_step, rt2type.step_func)
	if str then
		local x, y
		for i in sim.parts() do
			if sim.partProperty(i, "ctype") == 0x20813F2F then
				local x_, y_ = sim.partPosition(i)
				if select(2, pcall(sim.partProperty, sim.partID(x_ + 5, y_ - 10), "ctype")) == 0x20812227 then
					x, y = x_, y_
					break
				end
			end
		end
		if not x then
			return false, "no RT2 found"
		end
		local free_to_inject = true
		local injection_in_progress = false
		rt2type.step_func = function()
			if injection_in_progress then
				if free_to_inject then
					-- * Data has been injected but the keyboard has not bumped the host yet.
					if sim.partProperty(sim.partID(x + 32, y + 3), "ctype") ~= 0x20000000 then
						free_to_inject = false
						injection_in_progress = false
					end
				end
			else
				if free_to_inject then
					-- * Nothing interesting going on, inject data.
					if str == "" then
						pcall(tpt.unregister_step, rt2type.step_func)
						return
					end
					local injected_data = str:byte()
					for iy = y + 3, y + 6 do
						sim.partProperty(sim.partID(x - 4, iy), "ctype", injected_data + 0x20800000)
						sim.partProperty(sim.partID(x - 2, iy), "ctype", injected_data + 0x20800000)
						sim.partProperty(sim.partID(x    , iy), "ctype", injected_data + 0x20800000)
						sim.partProperty(sim.partID(x + 3, iy), "ctype", injected_data + 0x20800000)
					end
					str = str:sub(2)
					print(("\bt[rt2type]\bw injected '%s', %i more characters in queue"):format(injected_data >= 32 and injected_data < 127 and string.char(injected_data) or ("\\x%02X"):format(injected_data), #str))
					injection_in_progress = true
				else
					-- * The host accepted the bump and has read the injected data.
					if sim.partProperty(sim.partID(x + 32, y + 3), "ctype") == 0x20000000 then
						free_to_inject = true
					end
				end
			end
		end
		return pcall(tpt.register_step, rt2type.step_func)
	end
end})


