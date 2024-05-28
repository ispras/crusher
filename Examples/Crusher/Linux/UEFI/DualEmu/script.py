from pathlib import Path
import dual_emu
import os, sys
import json
import qiling

def entry_hook(emu):
    print('Entry Hook')
    ptr = 0x01000000
    sz = 0x1000
    emu.cur_input.mark_symbolic_span(0, emu.cur_input.len())
    emu.write_mem_b(ptr, b'\x00' * sz)
    emu.write_mem_b(ptr, emu.cur_input.get_span(0, min(emu.cur_input.len(), sz-1)))
    # to the first argument of grub_script_parse
    emu.write_reg("rdi", ptr)

dump_path = Path(__file__).parent / 'dump' / 'info.json'
args = dual_emu.parse_args_cli(input_file_required=True)

orig_qiling = qiling.Qiling
def wrap_qiling(*args, **kw):
    ql = orig_qiling(*args, **kw)
    ql.mem.unmap_all() # to remove unneeded internal mappings
    return ql
qiling.Qiling = wrap_qiling

# return address, grub_normal_read_line, grub_print_error
ex = [0x39AA24E, 0x39A0ABD, 0x5E1D638]
emu = dual_emu.make_emulator_with_input(args.angr, args.input, dump_file=dump_path, exits=ex,
                                        lighthouse_out_path=args.lighthouse)

if args.qiling:
    emu.hook_fuzzer_start(emu.start_addr)

emu.hook_addr(emu.start_addr, entry_hook)

emu.run()

if args.angr:
    if emu.sim_man.errored:
        print('Crashes:')
        print(emu.sim_man.errored)

    dual_emu.dump_new_inputs(emu, args.out_dir, clean=True)
