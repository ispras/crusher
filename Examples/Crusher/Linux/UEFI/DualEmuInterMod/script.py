from pathlib import Path
import dual_emu
import os, sys
import json

dump_path = Path(__file__).parent / 'dump' / 'info.json'
args = dual_emu.parse_args_cli(input_file_required=True)

# return address
ex = [0x063042C1]
emu = dual_emu.make_emulator_with_input(args.angr, args.input, dump_file=dump_path, exits=ex,
                                        lighthouse_out_path=args.lighthouse)
flag = 1
if args.qiling:
    emu.hook_fuzzer_start(emu.start_addr)

def entry_hook(emu):
    print('Entry Hook')
    emu.write_reg('rcx', 4)

emu.hook_addr(emu.start_addr, entry_hook)

def WaitForEvent(emu):
    emu.funcman().ret()

emu.hook_addr(0x07E972B7, WaitForEvent)

def ReadKeyStroke(emu):
    ptr = emu.read_reg_i("rdx")
    emu.cur_input.mark_symbolic_span(0, 1)
    emu.write_mem_b(ptr+0x2, emu.cur_input.get_span(0, 1))
    emu.funcman().ret(0)

emu.hook_addr(0x0697C230, ReadKeyStroke)

def ShellPrintEx(emu):
    r8 = emu.read_reg_i("r8")
    r9 = emu.read_reg_i("r9")
    i = 0
    while (True):
        ch = emu.read_mem_u16(r8 + i)
        if (ch == ord('\n')):
            sys.stdout.write("<\\n>")
            i += 2
        elif (ch == ord('\r')):
            sys.stdout.write("<\\r>")
            i += 2
        elif (ch == ord('%')):
            if (nch := emu.read_mem_u16(r8+i+2) == ord('c')):
                sys.stdout.write(chr(r9))
                i += 4
            else:
                sys.stdout.write(chr(ch))
                i += 2
        else:
            sys.stdout.write(chr(ch))
            i += 2
        if (ch == ord('\0')):
            break
    sys.stdout.write('\n')
    emu.funcman().ret()

emu.hook_addr(0x062D693F, ShellPrintEx)

def ShellGetExecutionBreakFlag(emu):
    global flag
    if (flag):
        flag = False
        emu.funcman().ret(0)
    else:
        emu.funcman().ret(1)

emu.hook_addr(0x062D566E, ShellGetExecutionBreakFlag)

emu.run()

if args.angr:
    if emu.sim_man.errored:
        print('Crashes:')
        print(emu.sim_man.errored)

    dual_emu.dump_new_inputs(emu, args.out_dir, clean=True)
