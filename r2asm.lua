#!/usr/bin/env lua

-- * This is a really ugly assembler. I wanted to write a much better one for
--   the R2, but I didn't have the time. Or, rather, I would have had to
--   postpone publishing the R2. I really, really didn't want to do that, so
--   much that I made peace with having to write a bad assembler instead.
--        -- LBPHacker

-- * I don't care that ipairs is deprecated. Using ipairs is way more concise
--   than the whole for x = 1, # do ... end dance where every time I need the
--   thing at index x I must use [x]. Chances are I end up caching it into a
--   local anyway and then I might as well just use a damn iterator.
local function ipairs(tbl_param)
    return function(tbl, idx)
        idx = (idx or 0) + 1
        if #tbl >= idx then
            return idx, tbl[idx]
        end
    end, tbl_param
end

local named_args = {}
local unnamed_args = {...}
if tpt then
    if type(unnamed_args[#unnamed_args]) == "table" then
        named_args = unnamed_args[#unnamed_args]
        unnamed_args[#unnamed_args] = nil
    end
else
    -- * This branch assumes that we're being run from a shell as a standalone
    --   program through a Lua interpreter and thus all our arguments are
    --   strings.
    local cmdline_unnamed_args = {}
    for ix, arg in ipairs(unnamed_args) do
        local key, value = arg:match("^([^=]+)=(.-)$")
        if key then
            named_args[key] = value
        else
            table.insert(cmdline_unnamed_args, arg)
        end
    end
    unnamed_args = cmdline_unnamed_args
end


-- * A list of unnamed arguments:
--   * `source_path` is, unsurprisingly enough, the path to the assembly source.
--   * `target_cpu_id` is a FILT ctype used to select which CPU to upload the
--     program to; all my computers have a QRTZ particle whose ctype is
--     0x1864A205, and on the right of this is a row of FILT that stores in
--     ctype the model number of the CPU in a zero-terminated ASCII string,
--     which the assembler looks for; if it finds more than one supported CPU in
--     the simulation, it reads the ctype of the FILT particle on the *left* of
--     this QRTZ particle and matches it against `target_cpu_id`.
--   * `log_path` is the path to the file the log should be redirected to.
-- * A list of named arguments:
--   * `headless_model` switches the assembler to non-TPT mode; that is, no TPT
--     API will be called and the opcodes will be flashed to /dev/stdout by
--     default (each opcode as 4 bytes in little endian).
--   * `headless_out` overrides the /dev/stdout default for the above named
--     argument.
local source_path, target_cpu_id, log_path = unpack(unnamed_args)

-- * File handles that are written to if they are open. Weird mechanism, but it
--   works perfectly.
local redirect_log, headless_out_bin

-- * Shadow print. This forces me to use one of the functions defined below.
local print_ = print
if not tpt then
    print_ = function(stuff)
        io.stderr:write(stuff .. "\n")
    end
end
local function print_log(sugar, no_sugar, str)
    if redirect_log then
        redirect_log:write(no_sugar .. str .. "\n")
    else
        print_((tpt and sugar or no_sugar) .. str)
    end
end
local function print_e(...)
    print_log("\008l[r2asm] \008w", "[r2asm] [EE] ", string.format(...))
end
local function print_w(...)
    print_log("\008o[r2asm] \008w", "[r2asm] [WW] ", string.format(...))
end
local function print_i(...)
    print_log("\008t[r2asm] \008w", "[r2asm] [II] ", string.format(...))
end
local print = nil

if log_path then
    local handle, err = io.open(log_path, "w")
    if handle then
        redirect_log = handle
    else
        print_w("failed redirect log: %s", err)
    end
end


-- * Supported model and flash mode table with some info about how each model
--   has to be programmed.
local supported_models = {
    ["R216K2A"] = {
        flash_mode = "skip_one_rtl",
        ram_x = 70,
        ram_y = -99,
        ram_width = 128,
        ram_height = 16
    },
    ["R216K4A"] = {
        flash_mode = "skip_one_rtl",
        ram_x = 70,
        ram_y = -115,
        ram_width = 128,
        ram_height = 32
    },
    ["R216K8B"] = {
        flash_mode = "skip_one_rtl",
        ram_x = 70,
        ram_y = -147,
        ram_width = 128,
        ram_height = 64
    },
    ["R216DVM"] = {
        flash_mode = "headless_bin",
        ram_size = 65536
    }
}
local supported_flash_modes = {
    ["headless_bin"] = function(anchor, model, code)
        -- * The headless_bin mode is a model-agnostic mode which writes the
        --   opcodes to a file as little-endian 4-byte values. See the
        --   `headless_model` named argument way above in the source.

        local model_data = supported_models[model]
        if model_data.ram_size then
            -- * Pad remaining cells with 0x20000000 (if we know how many cells
            --   to pad to).
            for ix = #code + 1, model_data.ram_size do
                table.insert(code, 0x20000000)
            end
        end

        -- * Write opcodes to `headless_out_bin` as little-endian 4-byte values.
        for ix, opcode in ipairs(code) do
            for bx = 1, 4 do
                headless_out_bin:write(string.char(opcode % 0x100))
                opcode = math.floor(opcode / 0x100)
            end
        end

        -- * Flashing succeeded.
        return true
    end,
    ["skip_one_rtl"] = function(anchor, model, code)
        -- * The skip_one_rtl mode writes to the RAM from left to right, top to
        --   bottom when a row is filled. Due to the way some RAMs work, this
        --   mode tolerates if at most one particle is missing from the row.

        local model_data = supported_models[model]
        if #code > model_data.ram_width * model_data.ram_height then
            print_e("code size exceeds RAM capacity")
            return
        end

        -- * Pad remaining cells with 0x20000000.
        for ix = #code + 1, model_data.ram_width * model_data.ram_height do
            table.insert(code, 0x20000000)
        end

        -- * `row` and `column` index the RAM cells, `cursor` the `code` array.
        local row, column = 0, 0
        local cursor = 0
        local skipped = 0
        local x, y = sim.partPosition(anchor)
        x, y = x + model_data.ram_x, y + model_data.ram_y
        while cursor < #code do
            cursor = cursor + 1
            local filt_id
            while not filt_id do
                filt_id = sim.partID(x - column, y + row)
                if filt_id then
                    if sim.partProperty(filt_id, "type") ~=
                        elem.DEFAULT_PT_FILT then
                        filt_id = nil
                    end
                end
                if not filt_id then
                    column = column + 1
                    skipped = skipped + 1
                    if skipped > 1 then
                        print_e("missing FILT particle in row %i", row)
                        return
                    end
                end
            end
            sim.partProperty(filt_id, "ctype", code[cursor])
            column = column + 1
            if cursor % model_data.ram_width == 0 then
                row = row + 1
                column = 0
                skipped = 0
            end
        end

        -- * Flashing succeeded.
        return true
    end
}

-- * Huge operation and operand tables.
local mnemonic_to_class = {
    ["adc" ] = {code = 0x25000000, class =  "2"},
    ["adcs"] = {code = 0x2D000000, class =  "2"},
    ["add" ] = {code = 0x24000000, class =  "2"},
    ["adds"] = {code = 0x2C000000, class =  "2"},
    ["and" ] = {code = 0x21000000, class =  "2"},
    ["ands"] = {code = 0x29000000, class =  "2"},
    ["bump"] = {code = 0x38000000, class =  "1"},
    ["call"] = {code = 0x3E000000, class = "1*"},
    ["cmb" ] = {code = 0x2F000000, class =  "2"},
    ["cmp" ] = {code = 0x2E000000, class =  "2"},
    ["hlt" ] = {code = 0x30000000, class =  "0"},
    ["ja"  ] = {code = 0x3100000F, class = "1*"},
    ["jae" ] = {code = 0x31000003, class = "1*"},
    ["jb"  ] = {code = 0x31000002, class = "1*"},
    ["jbe" ] = {code = 0x3100000E, class = "1*"},
    ["jc"  ] = {code = 0x31000002, class = "1*"},
    ["je"  ] = {code = 0x31000008, class = "1*"},
    ["jg"  ] = {code = 0x3100000B, class = "1*"},
    ["jge" ] = {code = 0x3100000D, class = "1*"},
    ["jl"  ] = {code = 0x3100000C, class = "1*"},
    ["jle" ] = {code = 0x3100000A, class = "1*"},
    ["jmp" ] = {code = 0x31000000, class = "1*"},
    ["jn"  ] = {code = 0x31000001, class = "1*"},
    ["jna" ] = {code = 0x3100000E, class = "1*"},
    ["jnae"] = {code = 0x31000002, class = "1*"},
    ["jnb" ] = {code = 0x31000003, class = "1*"},
    ["jnbe"] = {code = 0x3100000F, class = "1*"},
    ["jnc" ] = {code = 0x31000003, class = "1*"},
    ["jne" ] = {code = 0x31000009, class = "1*"},
    ["jng" ] = {code = 0x3100000A, class = "1*"},
    ["jnge"] = {code = 0x3100000C, class = "1*"},
    ["jnl" ] = {code = 0x3100000D, class = "1*"},
    ["jnle"] = {code = 0x3100000B, class = "1*"},
    ["jno" ] = {code = 0x31000005, class = "1*"},
    ["jns" ] = {code = 0x31000007, class = "1*"},
    ["jnz" ] = {code = 0x31000009, class = "1*"},
    ["jo"  ] = {code = 0x31000004, class = "1*"},
    ["js"  ] = {code = 0x31000006, class = "1*"},
    ["jz"  ] = {code = 0x31000008, class = "1*"},
    ["mov" ] = {code = 0x20000000, class =  "2"},
    ["nop" ] = {code = 0x31000001, class =  "0"},
    ["or"  ] = {code = 0x22000000, class =  "2"},
    ["ors" ] = {code = 0x2A000000, class =  "2"},
    ["pop" ] = {code = 0x3D000000, class =  "1"},
    ["push"] = {code = 0x3C000000, class = "1*"},
    ["recv"] = {code = 0x3B000000, class =  "2"},
    ["ret" ] = {code = 0x3F000000, class =  "0"},
    ["rol" ] = {code = 0x32000000, class =  "2"},
    ["ror" ] = {code = 0x33000000, class =  "2"},
    ["sbb" ] = {code = 0x27000000, class =  "2"},
    ["sbbs"] = {code = 0x2F000000, class =  "2"},
    ["send"] = {code = 0x3A000000, class =  "2"},
    ["shl" ] = {code = 0x34000000, class =  "2"},
    ["scl" ] = {code = 0x36000000, class =  "2"},
    ["shr" ] = {code = 0x35000000, class =  "2"},
    ["scr" ] = {code = 0x37000000, class =  "2"},
    ["sub" ] = {code = 0x26000000, class =  "2"},
    ["subs"] = {code = 0x2E000000, class =  "2"},
    ["swm" ] = {code = 0x28000000, class = "1*"},
    ["test"] = {code = 0x29000000, class =  "2"},
    ["wait"] = {code = 0x39000000, class =  "1"},
    ["xor" ] = {code = 0x23000000, class =  "2"},
    ["xors"] = {code = 0x2B000000, class =  "2"},
}
local class_to_modes = {
    ["0"] = {
        {pattern = {},                                      code = 0x00000000},
    },
    ["1"] = {
        {pattern = {"r0"},                                  code = 0x00000000},
        {pattern = {"[", "r0", "]"},                        code = 0x00400000},
        {pattern = {"[", "r16", "+", "r0", "]"},            code = 0x00C00000},
        {pattern = {"[", "r16", "-", "r0", "]"},            code = 0x00C08000},
        {pattern = {"[", "64", "]"},                        code = 0x00500000},
        {pattern = {"[", "14", "+", "r16", "]"},            code = 0x00D00000},
        {pattern = {"[", "r16", "+", "14", "]"},            code = 0x00D00000},
        {pattern = {"[", "r16", "-", "14", "]"},            code = 0x00D08000},
    },
    ["1*"] = {
        {pattern = {"r4"},                                  code = 0x00000000},
        {pattern = {"[", "r4", "]"},                        code = 0x00100000},
        {pattern = {"[", "r16", "+", "r4", "]"},            code = 0x00900000},
        {pattern = {"[", "r16", "-", "r4", "]"},            code = 0x00908000},
        {pattern = {"64"},                                  code = 0x00200000},
        {pattern = {"[", "64", "]"},                        code = 0x00300000},
        {pattern = {"[", "14", "+", "r16", "]"},            code = 0x00B00000},
        {pattern = {"[", "r16", "+", "14", "]"},            code = 0x00B00000},
        {pattern = {"[", "r16", "-", "14", "]"},            code = 0x00B08000},
    },
    ["2"] = {
        {pattern = {"r0", ",", "r4"},                       code = 0x00000000},
        {pattern = {"r0", ",", "[", "r4", "]"},             code = 0x00100000},
        {pattern = {"r0", ",", "[", "r16", "+", "r4", "]"}, code = 0x00900000},
        {pattern = {"r0", ",", "[", "r16", "-", "r4", "]"}, code = 0x00908000},
        {pattern = {"r0", ",", "64"},                       code = 0x00200000},
        {pattern = {"r0", ",", "[", "64", "]"},             code = 0x00300000},
        {pattern = {"r0", ",", "[", "14", "+", "r16", "]"}, code = 0x00B00000},
        {pattern = {"r0", ",", "[", "r16", "+", "14", "]"}, code = 0x00B00000},
        {pattern = {"r0", ",", "[", "r16", "-", "14", "]"}, code = 0x00B08000},
        {pattern = {"[", "r0", "]", ",", "r4"},             code = 0x00400000},
        {pattern = {"[", "r16", "+", "r0", "]", ",", "r4"}, code = 0x00C00000},
        {pattern = {"[", "r16", "-", "r0", "]", ",", "r4"}, code = 0x00C08000},
        {pattern = {"[", "64", "]", ",", "r0"},             code = 0x00500000},
        {pattern = {"[", "14", "+", "r16", "]", ",", "r0"}, code = 0x00D00000},
        {pattern = {"[", "r16", "+", "14", "]", ",", "r0"}, code = 0x00D00000},
        {pattern = {"[", "r16", "-", "14", "]", ",", "r0"}, code = 0x00D08000},
        {pattern = {"[", "r0", "]", ",", "64"},             code = 0x00600000},
        {pattern = {"[", "r16", "+", "r0", "]", ",", "14"}, code = 0x00E00000},
        {pattern = {"[", "r16", "-", "r0", "]", ",", "14"}, code = 0x00E08000},
        {pattern = {"[", "64", "]", ",", "40"},             code = 0x00700000},
        {pattern = {"[", "14", "+", "r16", "]", ",", "40"}, code = 0x00F00000},
        {pattern = {"[", "r16", "+", "14", "]", ",", "40"}, code = 0x00F00000},
        {pattern = {"[", "r16", "-", "14", "]", ",", "40"}, code = 0x00F08000},
    },
}
local register_to_name = {
    [ "r0"] =  0, [ "r1"] =  1, [ "r2"] =  2, [ "r3"] =  3,
    [ "r4"] =  4, [ "r5"] =  5, [ "r6"] =  6, [ "r7"] =  7,
    [ "r8"] =  8, [ "r9"] =  9, ["r10"] = 10, ["r11"] = 11,
    ["r12"] = 12, ["r13"] = 13, ["r14"] = 14, ["r15"] = 15,
                  [ "bp"] = 13, [ "sp"] = 14, [ "ip"] = 15,
}

local function get_cpu()

    -- * Store the ids of anchors that match both the model number and the CPU
    --   id. If there ends up being more than one, we'll bail out later.
    local anchors_found = {}
    for partID in sim.parts() do

        -- * Look for the QRTZ particle with a ctype of 0x1864A205.
        -- * Check ctype first as it's more unlikely to find a particle with
        --   this ctype than to find a QRTZ particle.
        if  sim.partProperty(partID, "ctype") == 0x1864A205
        and sim.partProperty(partID, "type") == elem.DEFAULT_PT_QRTZ then
            local x, y = sim.partPosition(partID)

            -- * Extract the model number.
            -- * `model_number` will only get assigned a proper value if the
            --   extraction succeeds, i.e. the string in the row of particles is
            --   zero-terminated. Extraction also fails if particles are
            --   missing. I don't care if the row is not made from FILT though.
            local model_number, model_checksum
            do
                local mn_probably = ""
                local read_checksum = false
                local mn_x, mn_y = x, y
                while true do
                    -- * Check the next particle in the row.
                    mn_x = mn_x + 1
                    local mn_id = sim.partID(mn_x, mn_y)
                    if not mn_id then

                        -- * Bail out without assigning anything to
                        --   `model_number` if the row ends earlier than
                        --   expected.
                        break
                    end
                    local mn_ct = sim.partProperty(mn_id, "ctype") % 0x100
                    if read_checksum then

                        -- * Assign buffer to `model_number` if the row ends
                        --   properly, in a null-terminator.
                        model_number = mn_probably
                        model_checksum = mn_ct
                        break
                    end

                    if mn_ct == 0 then
                        -- * We reached the end of the model name, read the
                        --   checksum in the next iteration and then exit.
                        read_checksum = true
                    else
                        -- * Append byte to buffer.
                        mn_probably = mn_probably .. string.char(mn_ct)
                    end
                end
            end

            -- * Calculate checksum, ignore the model if it's invalid.
            if model_number then
                local local_checksum = 0
                for ix = 1, #model_number do
                    local_checksum = local_checksum + model_number:byte(ix)
                end
                if local_checksum % 0x100 ~= model_checksum then
                    model_number = nil
                end
            end

            if model_number then
                -- * Look for the particle on the left with the CPU's id. I
                --   don't really care if it's not a FILT. There must be a
                --   particle though.
                local cpu_id
                do
                    local cid_id = sim.partID(x - 1, y)
                    if cid_id then
                        cpu_id = sim.partProperty(cid_id, "ctype")
                    end
                end

                -- * Save anchor id if both the model number and the CPU id
                --   match.
                if  supported_models[model_number]
                and (not target_cpu_id or cpu_id == target_cpu_id) then
                    anchors_found[partID] = model_number
                end
            end
        end
    end

    -- * Bail out if no CPU matched.
    if not next(anchors_found) then
        print_e("no supported CPU detected in the simulation")
        if target_cpu_id then
            print_i("(or none match the CPU id supplied)")
        end
        return
    end

    -- * Bail out if multiple CPUs matched.
    if next(anchors_found, next(anchors_found)) then
        print_e("more than one supported CPUs detected in the simulation")
        if not target_cpu_id then
            print_i("maybe try supplying a CPU id?")
        end
        return
    end

    -- * Continue if only one CPU matched.
    return next(anchors_found)
end

local function assemble_source()

    local errors_encountered = false
    local function print_el(line, ...)
        print_e("line %i: %s", line, string.format(...))
        errors_encountered = true
    end
    local function print_wl(line, ...)
        print_w("line %i: %s", line, string.format(...))
    end

    -- * The `lines` table stores tables with the following fields:
    --   * str: the string of characters in the original source constituting the
    --          line,
    --   * global_label: the name of the last global label
    local lines = {}
    -- * The `labels` table maps label names to line numbers.
    local labels = {}
    -- * Should be pretty obvious.
    local line_to_offset = {}
    -- * The `literals` table maps unique identifiers to single and double quote
    --   strings. These need to be removed so comments can be eliminated easily.
    local literals = {}
    -- * A table with keys pointing to lines where one or more immediate values
    --   have been truncated. A bunch of warnings are issued from this table
    --   after the label patch pass.
    local truncated = {}
    -- * A table with machine code offsets for keys and {label, width, shift}
    --   triples for values. The label patch pass uses this to patch the machine
    --   code with label addresses and possibly emit more truncation warnings.
    local patch_label = {}
        
    -- * Bunch of operand matching functions. I was too lazy to write a proper
    --   tokenizer. Told you, it's a bad assembler.
    local function match_register(operands_str)
        local register, remainder = operands_str:match("^%s*(%w+)%s*(.*)%s*$")
        if not register then
            return
        end
        -- * Needed due to the case-insensitive nature of assembly.
        local register_name = register_to_name[register:lower()]
        if not register_name then
            return
        end
        return register_name, remainder
    end
    local function match_imm_impl(operands_str, line)
        local immval, remainder = operands_str:match(
            "^%s*([%-%w._']+)%s*(.*)%s*$")
        if not immval then
            return
        end
        -- * Try to match a number. This will accept both decimal and
        --   hexadecimal integers. Range checks are not done here.
        local number = tonumber(immval)
        if number then
            return number, remainder
        end
        -- * The immediate still may be a label name.
        local label_name = immval:match("^%.?[%a_][%w_]*$")
        if not label_name then
            label_name = immval:match("^[%a_][%w_]*%.[%a_][%w_]*$")
        end
        if mnemonic_to_class[label_name] or register_to_name[label_name] then
            return
        end
        if label_name then
            -- * Return 0, patch label address later.
            return 0, remainder, label_name
        end
        -- * The immediate still may be a literal.
        local lit_idx, remainder = operands_str:match("^%s*'(%d+)'%s*(.*)%s*$")
        lit_idx = tonumber(lit_idx)
        if not lit_idx then
            return
        end
        local literal_value = 0
        local literal_data = literals[lit_idx].data
        if #literal_data == 0 then
            print_w(line, "empty literal, assuming \\0")
        end
        -- * Convert at most 4 bytes (no idea what use that'd be but meh).
        for ix = 1, math.min(4, #literal_data) do
            literal_value = literal_value * 0x100 + literal_data:byte(ix)
        end
        return literal_value, remainder
    end
    local function match_imm(operands_str, width, offset, line, shift)
        local number, remainder, label = match_imm_impl(operands_str, line)
        if not number then
            return
        end
        local sane_number = math.floor(number) % (2 ^ width)
        if number ~= sane_number then
            if not (width == 16
                and number >= -32768
                and number + 0x10000 == sane_number) then
                truncated[line] = width
            end
        end
        -- * Queue for later patching.
        if label then
            patch_label[offset] = {
                label = label,
                width = width,
                shift = shift,
                invoker = line
            }
        end
        return sane_number, remainder
    end
    local function match_punctuator(operands_str, punctuator)
        local nonspace, remainder = operands_str:match("^%s*(%S)%s*(.*)%s*$")
        if nonspace ~= punctuator then
            return
        end
        return remainder
    end
    local function match_dw_string(operands, line)
        local lit_idx, remainder = operands:match("^%s*\"(%d+)\"%s*(.*)%s*$")
        lit_idx = tonumber(lit_idx)
        if not lit_idx then
            return
        end
        return literals[lit_idx].data, remainder
    end

    -- * Utility function to substitute operands into operand mode patterns.
    local function match_operand_mode(operands, offset, line, mode)
        local code = mode.code
        for ix_token, token in ipairs(mode.pattern) do
            if #token == 1 then
                operands = match_punctuator(operands, token)
            else
                local bits
                local pos = tonumber(token:sub(2))
                if token:find("^r") then
                    bits, operands = match_register(operands, token)
                elseif token:find("^6") then
                    bits, operands = match_imm(operands, 16, offset, line, pos)
                elseif token:find("^1") then
                    bits, operands = match_imm(operands, 11, offset, line, pos)
                elseif token:find("^4") then
                    bits, operands = match_imm(operands, 4, offset, line, pos)
                end
                if bits then
                    code = code + bits * 2 ^ pos
                end
            end
            if not operands then
                return
            end
        end
        if operands:match("^%s*$") then
            return code
        end
    end

    -- * Try to open the headless output if required, bail out if we can't.
    if named_args.headless_model then
        -- * Default to /dev/stdout (it's not a real default of the named
        --   argument but rather a default of the file handle, so it'll work on
        --   systems where /dev/stdout doesn't exist).
        headless_out_bin = io.stdout
        if named_args.headless_out then
            local err
            headless_out_bin, err = io.open(named_args.headless_out, "wb")
            if not headless_out_bin then
                print_e("failed to open headless output: %s", err)
                return
            end
        end
    end

    -- * Try to load the source, bail out if we can't.
    local source
    do
        local handle, err = io.open(source_path, "r")
        if not handle then
            print_e("failed to open source: %s", err)
            return
        end
        source = handle:read("*a"):gsub("\r\n?", "\n")
        handle:close()
    end

    -- * Extract lines and labels from source.
    do
        local last_global_label = false
        local ix_line = 0
        for line in (source .. "\n"):gmatch("([^\n]*)\n") do
            ix_line = ix_line + 1

            -- * Move literals to `literals` and eliminate comments.
            line = line:gsub("\"([^\"]*)\"", function(cap)
                table.insert(literals, {
                    data = cap,
                    line = ix_line
                })
                return "\"" .. #literals .. "\""
            end):gsub("'([^']*)'", function(cap)
                table.insert(literals, {
                    data = cap,
                    line = ix_line
                })
                return "'" .. #literals .. "'"
            end):gsub(";.*$", "")

            -- * Process labels, update `last_global_label` if needed.
            line = line:gsub("%s*(%.?[%a_][%w_]*)%s*:", function(cap)
                local label_name
                if cap:find("^%.") then
                    -- * Handle local labels.
                    if last_global_label then
                        label_name = last_global_label .. cap
                    else
                        print_el(ix_line, "local label without global label")
                    end
                else
                    -- * Handle global labels.
                    label_name = cap
                    last_global_label = label_name
                end
                if label_name then
                    -- * Map label name to line number.
                    labels[label_name] = ix_line
                end
                -- * Eliminate label from line.
                return ""
            end)

            table.insert(lines, {
                str = line,
                global_label = last_global_label
            })
        end
    end

    -- * Handle escape sequences in literals.
    for ix_literal, literal in ipairs(literals) do
        literals[ix_literal].data = literal.data
            :gsub("\\a", "\a")
            :gsub("\\b", "\b")
            :gsub("\\f", "\f")
            :gsub("\\n", "\n")
            :gsub("\\r", "\r")
            :gsub("\\t", "\t")
            :gsub("\\v", "\v")
            :gsub("\\x(.?.?)", function(cap)
                local code = #cap == 2 and tonumber(cap, 16)
                if not code then
                    print_el(literal.line, "invalid escape sequence \\x%s", cap)
                    return "\\x" .. cap
                end
                return string.char(code)
            end)
            :gsub("\\(%d%d?%d?)", function(cap)
                local code = tonumber(cap)
                if code > 255 then
                    print_el(literal.line, "invalid escape sequence \\%s", cap)
                    return "\\" .. cap
                end
                return string.char(code)
            end)
            :gsub("\\.", function(cap)
                print_el(literal.line, "invalid escape sequence %s", cap)
                return cap
            end)
            :gsub("\\\\", "\\")
    end

    local machine_code = {}
    -- * Small utility functions that manage the `machine_code` table.
    local commit_value, pad_holes
    do
        local max_pos = 0
        function commit_value(pos, value)
            -- * `pos` is a 0-based index, `value` is the value to be written to
            --   the cell indexed by `pos`.
            pos = pos + 1
            machine_code[pos] = value
            if max_pos < pos then
                max_pos = pos
            end
        end
        function pad_holes()
            -- * Pad holes with 0x20000000.
            for ix = 1, max_pos do
                machine_code[ix] = machine_code[ix] or 0x20000000
            end
        end
    end

    -- * Translate lines.
    do
        local ram_offset = 0
        for ix_line, line in ipairs(lines) do
            line_to_offset[ix_line] = ram_offset
            if line.str:find("%S") then
                local mnemonic, operands = line.str:match(
                    "^%s*(%w+)%s*(.*)%s*$")
                if mnemonic then
                    -- * Needed due to the case-insensitive nature of assembly.
                    mnemonic = mnemonic:lower()
                    local op_code_class = mnemonic_to_class[mnemonic]
                    if op_code_class then
                        -- * This is a known mnemonic.
                        local op_code = op_code_class.code
                        local op_class = op_code_class.class
                        local operand_modes = class_to_modes[op_class]
                        local mode_code

                        -- * Try to find an operand mode that matches the
                        --   operand list, get mode data into `matching_mode`
                        --   and matches to be substituted into
                        --   `operand_matches` on success.
                        local matching_mode, operand_matches
                        for ix_mode, mode in ipairs(operand_modes) do
                            mode_code = match_operand_mode(
                                operands,
                                ram_offset,
                                ix_line,
                                mode
                            )
                            if mode_code then
                                break
                            end
                        end
                        if mode_code then
                            commit_value(ram_offset, mode_code + op_code)
                            ram_offset = ram_offset + 1
                        else
                            print_el(
                                ix_line,
                                "invalid operand list (class %s)",
                                op_class
                            )
                        end

                    elseif mnemonic == "dw" then
                        -- * Handle dw directive.
                        while true do
                            -- * Try to parse an immediate value or a string
                            --   literal.
                            local number, remainder = match_imm(operands, 16,
                                ram_offset, ix_line, 0)
                            if number then
                                commit_value(ram_offset, 0x20000000 + number)
                                ram_offset = ram_offset + 1
                                operands = remainder
                            else
                                local literal_data, remainder = match_dw_string(
                                    operands, ix_line)
                                if literal_data then
                                    for ix = 1, #literal_data do
                                        commit_value(ram_offset, 0x20000000 +
                                            literal_data:byte(ix))
                                        ram_offset = ram_offset + 1
                                    end
                                    operands = remainder
                                else
                                    print_el(ix_line,
                                        "expected immediate or string literal")
                                    break
                                end
                            end

                            -- * If that worked, try to parse a comma, or break
                            --   the loop with a success status if there's
                            --   nothing else.
                            if operands:match("^%s*$") then
                                break
                            end
                            operands = match_punctuator(operands, ",")
                            if not operands then
                                print_el(ix_line, "expected ','")
                                break
                            end
                        end

                    elseif mnemonic == "org" then
                        -- * Handle org directive. It takes any number it finds
                        --   and then converts it to an integer. No further
                        --   checks are done because I'm lazy.
                        local new_origin = tonumber(operands)
                        if new_origin then
                            new_origin = math.floor(new_origin)
                            if new_origin < 0 then
                                print_el(ix_line, "origin below 0")
                            else
                                ram_offset = new_origin
                            end
                        else
                            print_el(ix_line, "malformed number")
                        end

                    else
                        -- * No clue what this might be.
                        print_el(ix_line, "unknown mnemonic")
                    end
                else
                    -- * What the hell is this?
                    print_el(ix_line, "expected mnemonic, 'dw' or 'org'")
                end
            end
        end
    end

    -- * Patch label addresses.
    for offset, label_data in pairs(patch_label) do
        -- * Technically we should get the shift amount in `label_data` too, but
        --   that'd require passing another
        local label_name = label_data.label
        if label_name:find("^%.") then
            local global_label = lines[label_data.invoker].global_label
            if global_label then
                label_name = global_label .. label_name
            else
                print_el(label_data.invoker, "local label without global label")
                label_name = false
            end
        end
        if label_name then
            local label_line = labels[label_name]
            if label_line then
                local address = line_to_offset[label_line]
                local shift = label_data.shift
                if address >= 2 ^ label_data.width then
                    truncated[label_data.invoker] = width
                end
                address = (address % 2 ^ label_data.width) * 2 ^ shift
                machine_code[offset + 1] = machine_code[offset + 1] + address
            else
                print_el(label_data.invoker, "unknown label %s", label_name)
            end
        end
    end

    -- * Emit truncation warnings.
    for line, width in pairs(truncated) do
        print_wl(line, "immediate value truncated to %i bits", width)
    end

    -- * Bail out if anything nasty happened.
    if errors_encountered then
        return
    end

    pad_holes()
    return machine_code
end

local function machine_code_from_source()

    local handle, err = io.open(source_path, "r")
    if not handle then
        print_e("failed to open source: %s", err)
        return
    end

    local machine_code = {}
    while true do
        -- * Read opcodes from `source_path` as little-endian 4-byte values.
        local four_bytes = handle:read(4)
        if not four_bytes or #four_bytes ~= 4 then
            break
        end
        local   value = four_bytes:byte(1)
        value = value + four_bytes:byte(2) * 0x100
        value = value + four_bytes:byte(3) * 0x10000
        value = value + four_bytes:byte(4) * 0x1000000
        table.insert(machine_code, value % 0x20000000 + 0x20000000)
    end

    handle:close()
    return machine_code
end

-- * The xpcall magic is here because someone might run this through a script
--   runner tool, like I do (mine runs this when I press Ctrl+Return); which may
--   or may not handle errors correctly. Mine sort of does, but it's better to
--   catch them here.
xpcall(function()

    -- * First we figure out where the CPU is.
    local qrtz_anchor_id, target_model_number
    if named_args.headless_model then
        -- * `qrtz_anchor_id` is left empty as we're not even running under TPT,
        --   as apparent from the fact that the headless_model named parameter
        --   was passed.
        target_model_number = named_args.headless_model
    else
        -- * `qrtz_anchor_id` gets assigned the id of the QRTZ particle in the
        --   CPU selected, if there's any.
        qrtz_anchor_id, target_model_number = get_cpu()
        if not qrtz_anchor_id then
            return
        end
    end

    -- * Then we get get an array of ctypes from somewhere.
    local machine_code
    if named_args.source_type == "binary_32le" then
        machine_code = machine_code_from_source()
    else
        -- * In this case we assemble the source into an array of ctypes.
        -- * `machine_code` only gets assigned if the translation succeeds.
        machine_code = assemble_source()
    end
    if not machine_code then
        return
    end

    -- * Finally we try to "flash" the machine code.
    local flash_mode
    if headless_out_bin then
        if not supported_models[target_model_number] then
            print_e("model not supported")
            return
        end
        flash_mode = "headless_bin"
    else
        flash_mode = supported_models[target_model_number].flash_mode
    end
    local flasher = supported_flash_modes[flash_mode]
    if not flasher then
        -- * This shouldn't happen.
        error("flash mode not supported")
    end
    if not flasher(qrtz_anchor_id, target_model_number, machine_code) then
        return
    end

    if named_args.headless_out then
        headless_out_bin:close()
    end

    -- * We're allowed to feel good now.
    print_i("source assembled and flashed without errors")

end, function(err)
    print_e(err)
    print_e(debug.traceback())
    print_i("this is a serious problem in the assembler")
end)

-- * Yay, we're done.
if redirect_log then
    redirect_log:close()
    redirect_log = nil
    print_i("log written to %s", log_path)
end
print_i("finished assembling")
