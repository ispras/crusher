require('hw.i386.luaqemu.fullsystem')
json = require('hw.i386.luaqemu.json')

client_cr3 = nil
server_cr3 = nil
is_bitmap_saved = false

struct = nil
send_req = nil
all_send = nil
all_get = nil
crash = nil

function translation_handler()
	local client_check = tonumber(lua_read_dword('0x402008'))
    if client_cr3 == nil and lua_op('==', client_check, '0xDEADBEEF') then
        client_cr3 = lua_get_cr3()
    end

	local server_check = tonumber(lua_read_dword('0x402004'))
    if server_cr3 == nil and lua_op('==', server_check, '0xBEEFDEAD') then
        server_cr3 = lua_get_cr3()
    end

    if client_cr3 ~= nil and lua_get_cr3() == client_cr3 then
        local pc = tonumber(lua_get_pc())

        if lua_op('<', '0x400000', pc) and lua_op('<', pc, '0x500000') then
            if lua_op('==', '0x4013a8', pc) then

                if struct == nil then
                    struct = lua_get_register(7)
                    send_req = struct
                    all_send = lua_op('+', struct, '4')
                    all_get = lua_op('+', struct, '8')
                    crash = lua_op('+', struct, '12')
                end

                lua_handle_exec()
            end
        end
    end

    if server_cr3 ~= nil and lua_get_cr3() == server_cr3 and not is_bitmap_saved then
        lua_gen_bitmap(server_cr3, '0x400000', '0x500000')
        is_bitmap_saved = true
    end

end

function execution_handler()

	local req = tonumber(lua_read_dword(send_req))
    if lua_op('!=', req, '0x1') then
        local seed = read_file(fuzz_parameters.path_to_input)

        lua_write_str('0x4040c0', seed)
        lua_write_dword(send_req, 1)
    else
		local get = tonumber(lua_read_dword(all_get))
		if lua_op('==', get, '0x1') then
            os.exit(0)
        end
    end

	local crh = tonumber(lua_read_dword(crash))
	if lua_op('==', crh, '0x1') then
        lua_invoke_crash()
    end
end

function post_init(config)
    fuzz_parameters = json.read_json(config)
end
