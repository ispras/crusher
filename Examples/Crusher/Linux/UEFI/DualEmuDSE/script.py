from pathlib import Path
import dual_emu
import os, sys
import json
import qiling

def entry_hook(emu):
    print('Entry Hook')
    # the packet's address - the third argument of the function
    ptr = emu.read_reg_i("rdx")
    size = 20
    emu.cur_input.mark_symbolic_span(0, emu.cur_input.len())
    emu.write_mem_b(ptr, emu.cur_input.get_span(0, min(emu.cur_input.len(), size)))

dump_path = Path(__file__).parent / 'dump' / 'info.json'
args = dual_emu.parse_args_cli(input_file_required=True)

arch_name = None
if args.qiling:
    arch_name = "x8664"
if args.angr:
    arch_name = "x86_64"
# set the "arch" field in the config
os.system(f'sed -i \' s/"arch":.*/"arch": "{arch_name}",/ \' dump/info.json')

orig_qiling = qiling.Qiling
def wrap_qiling(*args, **kw):
    ql = orig_qiling(*args, **kw)
    ql.mem.unmap_all() # to remove unneeded internal mappings
    return ql
qiling.Qiling = wrap_qiling

# return address
ex = [0x6896635]
emu = dual_emu.make_emulator_with_input(args.angr, args.input, dump_file=dump_path, exits=ex,
                                        lighthouse_out_path=args.lighthouse)

if args.qiling:
    emu.hook_fuzzer_start(emu.start_addr)

emu.hook_addr(emu.start_addr, entry_hook)

# skip a special instruction
def handle_spec(emu):
    rip = emu.read_reg_i("rip")
    rip += 2
    emu.write_reg("rip", rip)
emu.hook_addr(0x688c612, handle_spec)

emu.run()

if args.angr:
    if emu.sim_man.errored:
        print('Crashes:')
        print(emu.sim_man.errored)

    dual_emu.dump_new_inputs(emu, args.out_dir, clean=True)
