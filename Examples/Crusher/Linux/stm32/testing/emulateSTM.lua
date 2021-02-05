local core = require('hw.arm.luaqemu.core')
local json = require('hw.arm.luaqemu.json')

machine_cpu = 'cortex-r4'

memory_regions = {
    region_rom = {
        name = 'mem_rom',
        start = 0x8000000,
        size = 0x20000
    },
    region_ram = {
        name = 'mem_ram',
        start = 0x20000000,
        size = 0x20000
    }
}

file_mappings = {
    main_rom = {
        name = 'main.bin',
        start = 0x8000000,
        size = 0x1548
	}
}

cpu = {
    env = {
        thumb = true,
        cpsr = 0x400001ff,
        regs = {}
    },
    reset_pc = 0x8000000
}



function bp_main()
    local fuzz_buffer = 0x20001000
    local stack_pointer = 0x20020000
    lua_set_register(0, fuzz_buffer)
    lua_set_register(13, stack_pointer)
    
    local seed = read_file(fuzz_parameters.path_to_input)
    lua_write_memory(fuzz_buffer, seed, #seed)
    lua_set_register(1, #seed)

    print "\nStart emulate"
    C.printf("Input file - %s\n", fuzz_parameters.path_to_input)
    lua_set_pc(0x80003ac)
    lua_continue()
end

function bp_memcpy()
    local fuzz_buffer = tonumber(lua_get_register(1))
    local fuzz_buffer_size = tonumber(lua_get_register(2))
    print "-----------------------------------------------------------"
    hex_dump(lua_read_mem(fuzz_buffer, fuzz_buffer_size), fuzz_buffer)
    print "-----------------------------------------------------------"
    C.printf("Destination address 0x%x, size of source buffer 0x%x\n", lua_get_register(0), lua_get_register(2))
    lua_continue()
end

function bp_end()
    print "Stop emulate"
    os.exit()
end

breakpoints = {
    -- breakpoint on main function
    [0x8000000] = bp_main,
    -- breakpoint on memcmpy function
    [0x8000312] = bp_memcpy,
    -- breakpoint on end emulation
    [0x80003b0] = bp_end
}


function post_init(config)
    fuzz_parameters = json.read_json(config)
    lua_continue()
end

