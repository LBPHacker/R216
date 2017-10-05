local args = {...}

xpcall(function()

	local headID
	for partID in sim.parts() do
		if  sim.partProperty(partID, "ctype") == 0x1864A205
		and sim.partProperty(partID, "type") == elem.DEFAULT_PT_QRTZ then
			headID = partID
			-- * TODO: model selection; break won't do
			break
		end
	end
	if not headID then
		print("no model found in simulation")
		return
	end
	local head_x, head_y = sim.partPosition(headID)

	local tail_x, tail_y = head_x, head_y
	local model = ""
	while true do
		tail_x = tail_x + 1
		local tailID = sim.partID(tail_x, tail_y)
		if not tailID then
			break
		end
		local ctype = sim.partProperty(tailID, "ctype")
		if ctype == 0 then
			break
		end
		model = model .. string.char(ctype % 0x100)
	end

	local flash_func
	if model == "R216K2A" then
		local ram_x, ram_y, ram_w, ram_h = head_x + 70, head_y - 99, 128, 16
		flash_func = function(assembler_output)
			-- * TODO: add truncation warning
			local ao_ix = 0
			for py = ram_y, ram_y + ram_h - 1 do
				local skip = 0
				for px = ram_x, ram_x - ram_w + 1, -1 do
					local cellID = sim.partID(px - skip, py)
					if not cellID then
						skip = 1
						cellID = sim.partID(px - skip, py)
					end
					ao_ix = ao_ix + 1
					sim.partProperty(cellID, "ctype", assembler_output[ao_ix] or 0x20000000)
				end
			end
		end
	else
		print("model '" .. model .. "' is not supported")
		return
	end

	if not args[1] then
		print("no input file")
		return
	end

	local PATTERNS = {
		{"^%s*$",                                                           "em"},
		{"^%s*%%(.+)%s*$",                                                  "sf"},
		{"^%s*(%S+)%s*$",                                                   "mn"},
		{"^%s*(%S+)%s*%[%s*(%S+)%s*([%+%-])%s*(%S+)%s*%]%s*$",              "mn", "pb", "ps", "pm"},
		{"^%s*(%S+)%s*%[%s*(%S+)%s*%]%s*$",                                 "mn", "pm"},
		{"^%s*(%S+)%s*(%S+)%s*,%s*%[%s*(%S+)%s*([%+%-])%s*(%S+)%s*%]%s*$",  "mn", "pv", "sb", "ss", "sm"},
		{"^%s*(%S+)%s*(%S+)%s*,%s*%[%s*(%S+)%s*%]%s*$",                     "mn", "pv", "sm"},
		{"^%s*(%S+)%s*%[%s*(%S+)%s*([%+%-])%s*(%S+)%s*%]%s*,%s*(%S+)%s*$",  "mn", "pb", "ps", "pm", "sv"},
		{"^%s*(%S+)%s*%[%s*(%S+)%s*%]%s*,%s*(%S+)%s*$",                     "mn", "pm", "sv"},
		{"^%s*(%S+)%s*(%S+)%s*$",                                           "mn", "pv"},
		{"^%s*(%S+)%s*(%S+)%s*,%s*(%S+)%s*$",                               "mn", "pv", "sv"},
	}

	local REGISTERS = {
		[ "r0"] = 0x0, [ "r1"] = 0x1, [ "r2"] = 0x2, [ "r3"] = 0x3,
		[ "r4"] = 0x4, [ "r5"] = 0x5, [ "r6"] = 0x6, [ "r7"] = 0x7,
		[ "r8"] = 0x8, [ "r9"] = 0x9, ["r10"] = 0xA, ["r11"] = 0xB,
		["r12"] = 0xC, ["r13"] = 0xD, ["r14"] = 0xE, ["r15"] = 0xF,
		--[ "ax"] = 0x0, [ "bx"] = 0x1, [ "cx"] = 0x2, [ "dx"] = 0x3,
		--[ "ex"] = 0x4, [ "fx"] = 0x5, [ "gx"] = 0x6, [ "hx"] = 0x7,
		--[ "ix"] = 0x8, [ "jx"] = 0x9, [ "kx"] = 0xA, [ "lx"] = 0xB,
		--[ "mx"] = 0xC, [ "nx"] = 0xD, [ "ox"] = 0xE, [ "px"] = 0xF,
		               [ "bp"] = 0xD, [ "sp"] = 0xE, [ "ip"] = 0xF
	}

	local MNEMONICS = {
		["mov" ] = {0x20000000, "12"}, ["and" ] = {0x21000000, "12"}, ["test"] = {0x29000000, "12"}, ["or"  ] = {0x22000000, "12"},
		["xor" ] = {0x23000000, "12"}, ["add" ] = {0x24000000, "12"}, ["adc" ] = {0x25000000, "12"}, ["sub" ] = {0x26000000, "12"},
		["cmp" ] = {0x2E000000, "12"}, ["sbb" ] = {0x27000000, "12"}, ["hlt" ] = {0x30000000, "  "}, ["jmp" ] = {0x31000000, " 2"},
		["jb"  ] = {0x31000002, " 2"}, ["jnb" ] = {0x31000003, " 2"}, ["jo"  ] = {0x31000004, " 2"}, ["jno" ] = {0x31000005, " 2"},
		["js"  ] = {0x31000006, " 2"}, ["jns" ] = {0x31000007, " 2"}, ["je"  ] = {0x31000008, " 2"}, ["jne" ] = {0x31000009, " 2"},
		["jle" ] = {0x3100000A, " 2"}, ["jnle"] = {0x3100000B, " 2"}, ["jl"  ] = {0x3100000C, " 2"}, ["jnl" ] = {0x3100000D, " 2"},
		["jbe" ] = {0x3100000E, " 2"}, ["jnbe"] = {0x3100000F, " 2"}, ["swm" ] = {0x28000000, " 2"}, ["rol" ] = {0x32000000, "12"},
		["ror" ] = {0x33000000, "12"}, ["shl" ] = {0x34000000, "12"}, ["shr" ] = {0x35000000, "12"}, ["shld"] = {0x36000000, "12"},
		["shrd"] = {0x37000000, "12"}, ["bump"] = {0x38000000, "1 "}, ["wait"] = {0x39000000, "1 "}, ["send"] = {0x3A000000, "12"},
		["recv"] = {0x3B000000, "12"}, ["push"] = {0x3C000000, " 2"}, ["pop" ] = {0x3D000000, "1 "}, ["call"] = {0x3E000000, " 2"},
		["ret" ] = {0x3F000000, "  "}, ["nop" ] = {0x20000000, "  "}
	}
	MNEMONICS["jnae"] = MNEMONICS["jb"  ]
	MNEMONICS["jc"  ] = MNEMONICS["jb"  ]
	MNEMONICS["jae" ] = MNEMONICS["jnb" ]
	MNEMONICS["jnc" ] = MNEMONICS["jnb" ]
	MNEMONICS["jz"  ] = MNEMONICS["je"  ]
	MNEMONICS["jnz" ] = MNEMONICS["jne" ]
	MNEMONICS["jng" ] = MNEMONICS["jle" ]
	MNEMONICS["jg"  ] = MNEMONICS["jnle"]
	MNEMONICS["jnge"] = MNEMONICS["jl"  ]
	MNEMONICS["jge" ] = MNEMONICS["jnl" ]
	MNEMONICS["jna" ] = MNEMONICS["jbe" ]
	MNEMONICS["ja"  ] = MNEMONICS["jnbe"]

	local BITMAPS = {
				 --        mask,   soLS,   svLS,   poLS,   pvLS
		["rv rv"] = {0x00000000,  0,  0,  4,  4,  0,  0,  4,  0},
		["rv rm"] = {0x00100000,  0,  0,  4,  4,  0,  0,  4,  0},
		["rv rn"] = {0x00900000,  4, 16,  4,  4,  0,  0,  4,  0},
		["rv ro"] = {0x00908000,  4, 16,  4,  4,  0,  0,  4,  0},
		["rv iv"] = {0x00200000,  0,  0, 16,  4,  0,  0,  4,  0},
		["rv im"] = {0x00300000,  0,  0, 16,  4,  0,  0,  4,  0},
		["rv in"] = {0x00B00000,  4, 16, 11,  4,  0,  0,  4,  0},
		["rv io"] = {0x00B08000,  4, 16, 11,  4,  0,  0,  4,  0},
		["rm rv"] = {0x00400000,  0,  0,  4,  4,  0,  0,  4,  0},
		["rn rv"] = {0x00C00000,  0,  0,  4,  4,  4, 16,  4,  0},
		["ro rv"] = {0x00C08000,  0,  0,  4,  4,  4, 16,  4,  0},
		["im rv"] = {0x00500000,  0,  0,  4,  0,  0,  0, 16,  4},
		["in rv"] = {0x00D00000,  0,  0,  4,  0,  4, 16, 11,  4},
		["io rv"] = {0x00D08000,  0,  0,  4,  0,  4, 16, 11,  4},
		["rm iv"] = {0x00600000,  0,  0, 16,  4,  0,  0,  4,  0},
		["rn iv"] = {0x00E00000,  0,  0,  4,  4,  4, 16,  4,  0},
		["ro iv"] = {0x00E08000,  0,  0,  4,  4,  4, 16,  4,  0},
		["im iv"] = {0x00700000,  0,  0,  4,  0,  0,  0, 16,  4},
		["in iv"] = {0x00F00000,  0,  0,  4,  0,  4, 16, 11,  4},
		["io iv"] = {0x00F08000,  0,  0,  4,  0,  4, 16, 11,  4}
	}

	local failed = false

	local referencable_output = {}
	local labels = {}


	local function emit_message(src, row, severity, message)
		if     severity == "error" then
			failed = true
			print("\008l" .. src .. ": line " .. row .. ": error: \008w" .. message)
		elseif severity == "warning" then
			failed = true
			print("\008o" .. src .. ": line " .. row .. ": warning: \008w" .. message)
		elseif severity == "note" then
			failed = true
			print("\008t" .. src .. ": line " .. row .. ": note: \008w" .. message)
		end
	end

	for arg_ix = 1, #args do
		print("assembling: \008t\"" .. args[arg_ix] .. "\"")
		local handle = io.open(args[arg_ix], "r")
		if not handle then
			print("failed to open file for reading")
			return
		end
		local content = handle:read("*a"):gsub("[\1\2]", "%?")
		handle:close()

		local current_global_label
		local function globalize_label(command, label_name)
			if label_name:find("^%.") then
				if current_global_label then
					label_name = current_global_label .. label_name
				else
					emit_message(command.src, command.row, "note", "no current global label set, throwing error")
					label_name = false
				end
			end
			return label_name
		end

		local dw_spec_tbl_meta = {}
		local dw_fenv = {
			["false"] = true,
			["true"] = true,
			["nil"] = true
		}
		function dw_fenv._IS_SPEC(tbl)
			return type(tbl) == "table" and getmetatable(tbl) == dw_spec_tbl_meta
		end
		function dw_fenv.proper_unpack(...)
			local result = {}
			local input = {...}
			for ix = 1, #input do
				if type(input[ix]) == "number" or dw_fenv._IS_SPEC(input[ix]) then
					table.insert(result, input[ix])
				elseif type(input[ix]) == "table" then
					for nx = 1, #input[ix] do
						table.insert(result, input[ix][nx])
					end
				elseif type(input[ix]) == "string" then
					for letter in input[ix]:gmatch(".") do
						table.insert(result, letter:byte())
					end
				else
					error("cannot emit " .. tostring(input[ix]), 0)
				end
			end
			return result
		end
		function dw_fenv._LABEL(str)
			local label_name = globalize_label(dw_fenv._COMMAND, str)
			if not label_name then
				error("invalid label name '" .. str .. "'", 0)
			end
			return setmetatable({
				label = label_name
			}, dw_spec_tbl_meta)
		end
		function dw_fenv.duplicate(size, ...)
			local stuff = dw_fenv.proper_unpack(...)
			local result = {}
			for ix = 1, size do
				for sx = 1, #stuff do
					table.insert(result, stuff[sx])
				end
			end
			return result
		end
		function dw_fenv.pad(size, value, finish, ...)
			local result = dw_fenv.proper_unpack(...)
			if #result % size ~= 0 then
				for ix = 1, size - #result % size do
					table.insert(result, value)
				end
			end
			if finish then
				finish = dw_fenv.proper_unpack(finish)
				for ix = 1, #finish do
					table.insert(result, finish[ix])
				end
			end
			return result
		end

		local function query_bitmap(command)
			command.op1v, command.op1b, command.op1r = 0, 0, "rv"
			command.op2v, command.op2b, command.op2r = 0, 0, "rv"
			if     command.mnemonic_def[2]:find("12") then
				command.op1v = command.pv or command.pm or 0
				command.op1b = command.pb or               0
				command.op1r = command.pr or "rv"
				command.op2v = command.sv or command.sm or 0
				command.op2b = command.sb or               0
				command.op2r = command.sr or "rv"
			elseif command.mnemonic_def[2]:find( "1") then
				command.op1v = command.pv or command.pm or 0
				command.op1b = command.pb or               0
				command.op1r = command.pr or "rv"
			elseif command.mnemonic_def[2]:find( "2") then
				command.op2v = command.pv or command.pm or 0
				command.op2b = command.pb or               0
				command.op2r = command.pr or "rv"
			end

			command.bitmap = BITMAPS[command.op1r .. " " .. command.op2r]
			return command.bitmap and true
		end

		local function is_label(name)
			return name:sub(name:match("^[%a_][%w_]*%.()") or name:match("^%.()") or 1):find("^[%a_][%w_]*$") and true
		end

		local function parse_operand(command, key)
			local op_name, op_role = key:match("(.)(.)")
			if command[key] then
				local value_found = false

				if REGISTERS[command[key]] then
					command[key] = REGISTERS[command[key]]
					value_found = true
					if op_role == "b" then
						command[op_name .. "r"] = command[op_name .. "r"]:sub(1, 1) .. (command[op_name .. "s"] == "+" and "n" or "o")
					else
						command[op_name .. "r"] = "r" .. op_role
					end

				elseif op_role ~= "b" and tonumber(command[key]) then
					command[key] = tonumber(command[key])
					value_found = true
					command[op_name .. "r"] = "i" .. op_role
				elseif op_role ~= "b" and is_label(command[key]) then
					local label_name = globalize_label(command, command[key])
					if label_name then
						command[key] = label_name
						value_found = true
						command[op_name .. "r"] = "i" .. op_role
					end
				end

				if value_found then
					return true
				else
					emit_message(command.src, command.row, "error", "invalid operand '" .. command[key] .. "' (" .. key .. ")")
					return false
				end
			else
				if op_role == "v" and not command[op_name .. "r"] then
					command[op_name .. "r"] = "rv"
				end
				return true
			end
		end

		local command_labels = {}
		local lines = {""}
		local literals = {}
		local commands = {}
		local function unescape_literals(str)
			return str:gsub("\1%d+\2", function(cap)
				return literals[cap]
			end)
		end
		do
			local line_cnt = 1
			local literals_unique = 0
			for nl_a, nl_b, line in content:gmatch("()\n*()([^\n]+)") do
				for ix = 1, nl_b - nl_a do
					line_cnt = line_cnt + 1
					lines[line_cnt] = ""
				end
				lines[line_cnt] = (line .. ";'';\"\";"):gsub("('[^']*')", function(cap)
					literals_unique = literals_unique + 1
					local literal_index = "\1" .. literals_unique .. "\2"
					literals[literal_index] = cap
					return literal_index
				end):gsub("(\"[^\"]*\")", function(cap)
					literals_unique = literals_unique + 1
					local literal_index = "\1" .. literals_unique .. "\2"
					literals[literal_index] = cap
					return literal_index
				end):gsub(";.*$", "")

				if lines[line_cnt]:find("['\"]") then
					emit_message(args[arg_ix], line_cnt, "error", "quotation fail")
				end
				local line_clean = lines[line_cnt]

				while true do
					local label_name, rest = line_clean:match("^%s*(%S+)%s*:%s*(.*)$")
					if label_name then
						table.insert(command_labels, label_name)
						line_clean = rest
					else
						break
					end
				end

				local command_fields
				for ix = 1, #PATTERNS do
					local captures = {line_clean:match(PATTERNS[ix][1])}
					if captures[1] then
						command_fields = {
							row = line_cnt,
							src = args[arg_ix],
							labels = command_labels
						}
						for key, value in next, captures do
							command_fields[PATTERNS[ix][key + 1]] = value
						end
						break
					end
				end
				if command_fields then
					if not command_fields.em then
						table.insert(commands, command_fields)
						command_labels = {} -- * flush label store
					end
				else
					emit_message(args[arg_ix], line_cnt, "error", "pattern fail")
				end
			end
		end

		for ix = 1, #commands do
			local command = commands[ix]

			for lx = 1, #command.labels do
				local label_cm_name = command.labels[lx]
				if not is_label(label_cm_name) then
					emit_message(command.src, command.row, "error", "invalid label name '" .. label_cm_name .. "'")
				else
					local old_label_name = label_cm_name
					label_cm_name = globalize_label(command, old_label_name)
					if label_cm_name == old_label_name then
						current_global_label = label_cm_name
					end
					if label_cm_name then
						labels[label_cm_name] = #referencable_output
					else
						emit_message(command.src, command.row, "error", "invalid label name '" .. old_label_name .. "'")
					end
				end
			end

			if command.mn then
				local mnemonic_def = MNEMONICS[command.mn]
				command.mnemonic_def = mnemonic_def

				if not mnemonic_def then
					emit_message(command.src, command.row, "error", "unknown mnemonic")

				elseif (mnemonic_def[2]:find("%d"  ) and true) ~= ((command.pv or command.pm) and true) then
					emit_message(command.src, command.row, "error", "invalid operand list (primary)")
				elseif (mnemonic_def[2]:find("%d%d") and true) ~= ((command.sv or command.sm) and true) then
					emit_message(command.src, command.row, "error", "invalid operand list (secondary)")

				elseif not parse_operand(command, "pm") then
				elseif not parse_operand(command, "pb") then
				elseif not parse_operand(command, "pv") then
				elseif not parse_operand(command, "sm") then
				elseif not parse_operand(command, "sb") then
				elseif not parse_operand(command, "sv") then
				elseif not query_bitmap(command) then
					emit_message(command.src, command.row, "error", "invalid operand list (type)")

				else
					table.insert(referencable_output, command)
				end

			elseif command.sf then
				local command_str, rest = command.sf:match("^(%S*)%s*(.*)$")
				if command_str == "dw" then
					local rest_func, err = loadstring("return proper_unpack(" .. unescape_literals(rest:gsub("[%.A-Za-z_0-9\128-\255]+", function(cap)
						if cap:find("^[0-9]") then
							return cap
						elseif dw_fenv[cap] then
							return cap
						else
							return "_LABEL(\"" .. cap .. "\")"
						end
					end)) .. ")", "%dw")
					if rest_func then
						dw_fenv._COMMAND = command
						local results = {pcall(setfenv(rest_func, dw_fenv))}
						if results[1] then
							local emit_tbl = results[2]
							for ix = 1, #emit_tbl do
								if dw_fenv._IS_SPEC(emit_tbl[ix]) then
									if emit_tbl[ix].label then
										table.insert(referencable_output, {
											absolute = 0x20000000,
											op2v = emit_tbl[ix].label,
											row = command.row,
											src = command.src
										})
									end
								else
									table.insert(referencable_output, {
										absolute = 0x20000000 + math.floor(emit_tbl[ix]) % 0x10000
									})
								end
							end
						else
							emit_message(command.src, command.row, "error", "dw directive failed: " .. results[2])
						end
					else
						emit_message(command.src, command.row, "error", "invalid dw directive: " .. err)
					end

				else
					emit_message(command.src, command.row, "error", "invalid directive: " .. command_str)

				end

			else
				error("sanity check failure: no valid field in command")
			end
		end
	end

	if not failed then
		for ix = 1, #referencable_output do
			local command = referencable_output[ix]

			if type(command.op1v) == "string" then
				local label_name = command.op1v
				command.op1v = labels[label_name]
				if not command.op1v then
					emit_message(command.src, command.row, "error", "unknown label name '" .. label_name .. "'")
				end
			end

			if type(command.op2v) == "string" then
				local label_name = command.op2v
				command.op2v = labels[label_name]
				if not command.op2v then
					emit_message(command.src, command.row, "error", "unknown label name '" .. label_name .. "'")
				end
			end
		end
	end

	if not failed then
		local assembler_output = {}
		--flash_func(assembler_output)

		--local handle = io.open("log.log", "w")
		for ix = 1, #referencable_output do
			local command = referencable_output[ix]

			if command.absolute then
				if command.op2v then
					command.absolute = command.absolute + command.op2v
				end
				table.insert(assembler_output, command.absolute)
			else
				table.insert(assembler_output,
					command.mnemonic_def[1] + command.bitmap[1] +
					command.op1v % 2 ^ command.bitmap[8] * 2 ^ command.bitmap[9] +
					command.op1b % 2 ^ command.bitmap[6] * 2 ^ command.bitmap[7] +
					command.op2v % 2 ^ command.bitmap[4] * 2 ^ command.bitmap[5] +
					command.op2b % 2 ^ command.bitmap[2] * 2 ^ command.bitmap[3]
				)
			end

			--handle:write(("%08X\n"):format(assembler_output[ix]))
		end
		--handle:close()

		flash_func(assembler_output)
	end

end, function(err)
	print(err)
	print(debug.traceback())
end)

print("r2asm.lua has finished")
