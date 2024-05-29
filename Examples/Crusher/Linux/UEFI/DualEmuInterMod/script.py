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

# NOTE: pay attention to the UEFI calling convention and 2-byte chars

def entry_hook(emu):
    print('Entry Hook')
    emu.write_reg('rcx', 4)
    # TODO: set Type to ShellPromptResponseTypeYesNoAllCancel

emu.hook_addr(emu.start_addr, entry_hook)

def WaitForEvent(emu):
    print("Skipped")
    emu.funcman().ret()
    # TODO: skip this function

emu.hook_addr(0x07E972B7, WaitForEvent)

def ReadKeyStroke(emu):
    print("ReadKey")
    ptr = emu.read_reg_i("rdx")
    #emu.cur_input.mark_symbolic_span(0, 1)
    emu.write_mem_b(ptr+0x2, emu.cur_input.get_span(0, 1))
    emu.funcman().ret(0)
    # TODO: put the first input byte to Key.UnicodeChar and return EFI_SUCCESS

emu.hook_addr(0x0697C230, ReadKeyStroke)

def ShellPrintEx(emu):
    print("ShellPrint")
    r8 = emu.read_reg_i("r8")
    r9 = emu.read_reg_i("r9")
    print(r9)
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
                sys.stdout.write(unichr(r9))
                i += 4
            else:
                sys.stdout.write(unichr(ch))
                i += 2
        else:
            sys.stdout.write(unichr(ch))
            i += 2
        if (ch == '\0'):
            break
    # TODO: print some prefix and the argument string here;
    # substitute one %c if necessary;
    # print \n as " <\n> ", \r as " <\r> "
    # (i.e. implement a simplified printf ad hoc)

emu.hook_addr(0x062D693F, ShellPrintEx)

def ShellGetExecutionBreakFlag(emu):
    global flag
    if (flag):
        print("Exec 1")
        flag = 0
        emu.funcman().ret(0)
    else:
        print("Exec >1")
        emu.funcman().ret(1)
    # TODO: for the first time return false, for the next times return true

def foo(state):
    print(hex(state.addr))

#emu.state.inspect.b('instruction', action=foo)
emu.hook_addr(0x062D566E, ShellGetExecutionBreakFlag)

emu.run()

if args.angr:
    if emu.sim_man.errored:
        print('Crashes:')
        print(emu.sim_man.errored)

    dual_emu.dump_new_inputs(emu, args.out_dir, clean=True)
