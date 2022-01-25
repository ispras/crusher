from pathlib import Path

import dual_emu
from dual_emu import IEmulatorWithInput, parse_args_cli


def entry_hook(emu: IEmulatorWithInput):
    print('Entry hook')

    ptr = emu.read_mem_u32(emu.read_reg_i('r1') + 4)
    print(f'Ptr = 0x{ptr:x}')

    emu.cur_input.mark_symbolic_span(0, 4)
    emu.write_mem_b(ptr, emu.cur_input.get_span(0, 4))
    print(f'Memory written: {emu.read_mem_b(ptr, 4)}')

    lr = emu.read_reg_i('lr')
    print(f'LR = 0x{lr:x}')


def check_hw_hook(emu: IEmulatorWithInput):
    print('Check hw')
    emu.write_reg('r0', 1)
    emu.write_reg('pc', emu.read_reg_i('lr'))


dump_path = Path(__file__).parent / 'dump' / 'dump_info.json'
args = parse_args_cli(input_file_required=True)

emu = dual_emu.make_emulator_with_input(args.angr, args.input, dump_file=dump_path, exits=[0x138],
                                        lighthouse_out_path=args.lighthouse)

if args.qiling:
    emu.hook_fuzzer_start(emu.start_addr)

emu.hook_addr(emu.start_addr, entry_hook)
emu.hook_addr(0x140, check_hw_hook)

emu.run()

if args.angr:
    if emu.sim_man.errored:
        print('Crashes:')
        print(emu.sim_man.errored)

    dual_emu.dump_new_inputs(emu, args.out_dir, clean=True)
