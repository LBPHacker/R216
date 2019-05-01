#!/usr/bin/env luajit

local https = require("ssl.https") -- luarocks install luasec

local debug = false -- set to true to render code points to stderr (with Unicode box-drawing characters)
local texter_asm_path = "texter.asm"

local code_points_to_extract = {}
for code_point = 32, 126 do -- everything from ' ' to '~'
	table.insert(code_points_to_extract, code_point)
end
table.insert(code_points_to_extract, 0xFFFD) -- and the broken character

local original_texter_content
do
	local texter_asm = assert(io.open(texter_asm_path, "r"), "failed to open " .. texter_asm_path .. " for reading")
	original_texter_content = texter_asm:read("*a")
	texter_asm:close()
end

local font_height, font_data, font_ptrs, font_ranges
do
	local function extract_from_body(body, pattern)
		return setfenv(assert(loadstring("return " .. assert(body:match(pattern), "pattern " .. pattern .. " didn't match"))), {})()
	end

	do
		print("fetching font.h ...")
		local body, code = https.request("https://raw.githubusercontent.com/ThePowderToy/The-Powder-Toy/master/data/font.h")
		assert(code == 200, "response code is " .. code)

		font_height = extract_from_body(body, "FONT_H%s(%d+)")
	end

	do
		print("fetching font.cpp ...")
		local body, code = https.request("https://raw.githubusercontent.com/ThePowderToy/The-Powder-Toy/master/data/font.cpp")
		assert(code == 200, "response code is " .. code)

		font_data = extract_from_body(body, "font_data[^{]+(%b{})")
		font_ptrs = extract_from_body(body, "font_ptrs[^{]+(%b{})")
		font_ranges = extract_from_body(body, "font_ranges[^{]+(%b{})")
	end
end

local code_points_available = {}
local ptr_counter = 0
table.remove(font_ranges, #font_ranges)
for _, range in ipairs(font_ranges) do
	local range_length = range[2] - range[1] + 1
	for code_point = range[1], range[2] do
		ptr_counter = ptr_counter + 1
		code_points_available[code_point] = font_ptrs[ptr_counter]
	end
end

local replacement = {}
local function dwify_insert(data)
	local data_copy = {}
	for _, thing in ipairs(data) do
		table.insert(data_copy, ("0x%04X"):format(thing))
	end
	local in_line = 9
	for ix = 1, #data_copy, in_line do
		table.insert(replacement, "    dw " .. table.concat(data_copy, ", ", ix, math.min(ix + in_line - 1, #data_copy)))
	end
end

local pointer_data = {}
local last_pointer = 0

table.insert(replacement, ".code_point_base:")
for _, code_point in ipairs(code_points_to_extract) do
	local character_ptr = assert(code_points_available[code_point], "code point " .. code_point .. " is not available")
	local function next_byte()
		character_ptr = character_ptr + 1
		return font_data[character_ptr]
	end

	local width = next_byte()

	local bits_left = 0
	local bits
	local function next_intensity()
		if bits_left == 0 then
			bits = next_byte()
			bits_left = 8
		end
		bits_left = bits_left - 2
		local result = bit.band(bits, 3)
		bits = bit.rshift(bits, 2)
		return result
	end

	local rows = {}
	for _ = 1, font_height do
		local row = {}
		for _ = 1, width do
			table.insert(row, next_intensity())
		end
		table.insert(rows, row)
	end

	if debug then
		local intensity_map = { "  ", "░░", "▒▒", "▓▓" }
		for _, row in ipairs(rows) do
			for _, intensity in ipairs(row) do
				io.stderr:write(intensity_map[intensity + 1])
			end
			io.stderr:write("\n")
		end
	end

	assert(font_height == 12, "this part needs to be rewritten")
	local code_point_data = {}
	for x = 1, width do
		table.insert(code_point_data,
			rows[ 1][x] * 0x400 +
			rows[ 2][x] * 0x100 +
			rows[ 3][x] *  0x40 +
			rows[ 4][x] *  0x10 +
			rows[ 5][x] *   0x4 +
			rows[ 6][x])
		table.insert(code_point_data,
			rows[ 7][x] * 0x400 +
			rows[ 8][x] * 0x100 +
			rows[ 9][x] *  0x40 +
			rows[10][x] *  0x10 +
			rows[11][x] *   0x4 +
			rows[12][x] + 0x1000)
	end

	table.insert(replacement, ".code_point_" .. code_point .. ":")
	dwify_insert(code_point_data)

	assert(last_pointer < 0x1000, "this part needs to be rewritten")
	table.insert(pointer_data, last_pointer + 0x1000 * width)
	last_pointer = last_pointer + #code_point_data
end

table.insert(replacement, ".code_point_ptrs:")
dwify_insert(pointer_data)

assert(original_texter_content:match("\ncode_points:\n.*code_points_end:\n"), "code_points boundary not found in " .. texter_asm_path)

do
	local texter_asm = assert(io.open(texter_asm_path, "w"), "failed to open " .. texter_asm_path .. " for writing")
	texter_asm:write((original_texter_content:gsub("\ncode_points:\n.*code_points_end:\n", "\ncode_points:\n" .. table.concat(replacement, "\n") .. "\ncode_points_end:\n")))
	texter_asm:close()
end

print(texter_asm_path .. " updated")

