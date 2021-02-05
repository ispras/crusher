require('hw.i386.luaqemu.core')
json = require('hw.i386.luaqemu.json')

machine_cpu = 'qemu32'

firmware_path = './CrusherTests/Linux/firmware_x86_32/firmware/test.bin'

memory_regions = {
    region_rom = {
        name = 'mem_rom',
        start = 0x08000000,
        size = 0x1000
    },
    region_ram = {
        name = 'mem_ram',
        start = 0x20000000,
        size = 0x100000
    }
}

file_mappings = {
    main_rom = {
        name = firmware_path,
        start = 0x08000000,
        size = 0x100
	}
}

cpu = {
    env = {
    }
}

function bp_init()
    print "Init"
    local stack_pointer = 0x20001000
    lua_set_register(4, stack_pointer)
    lua_set_pc(0x0800007a)
    local seed = read_file(fuzz_parameters.path_to_input)
    local fuzz_buffer = 0x20002000
    lua_write_memory(fuzz_buffer, seed, #seed)
    lua_continue()
end

function bp_end()
    print "Stop emulate"
    os.exit()
end

breakpoints = {
    [0x08000000] = bp_init,
    [0x0800008a] = bp_end
}


function post_init(config)
    fuzz_parameters = json.read_json(config)
    lua_continue()
end

