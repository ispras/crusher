from pathlib import Path
import dual_emu
import os, sys
import json
import qiling

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
ex = [0x48D3F48E]
emu = dual_emu.make_emulator_with_input(args.angr, args.input, dump_file=dump_path, exits=ex,
                                        lighthouse_out_path=args.lighthouse)
if args.qiling:
    emu.hook_fuzzer_start(emu.start_addr)

# NOTE: considering the UEFI calling convention and 2-byte chars

# at ShellPromptForResponse
def entry_hook(emu):
    print('Entry Hook')
    # set Type to ShellPromptResponseTypeYesNoAllCancel
    emu.write_reg('rcx', 4)

emu.hook_addr(emu.start_addr, entry_hook)

# helper to return from a function
def retfun(emu, val=None):
    sp = emu.read_reg_i("rsp")
    ra = emu.read_mem_u64(sp)
    if val != None:
        emu.write_reg("rax", val)
    emu.write_reg("rip", ra)
    emu.write_reg("rsp", sp + 8)

# replacing WaitForEvent
def WaitForEvent(emu):
    print("WaitForEvent")
    # skipping this function
    retfun(emu)

emu.hook_addr(0x44F9D2C3, WaitForEvent)

# replacing ReadKeyStroke
def ReadKeyStroke(emu):
    # put the first input byte to Key.UnicodeChar and return EFI_SUCCESS
    print("ReadKeyStroke")
    ptr = emu.read_reg_i("rdx")
    emu.cur_input.mark_symbolic_span(0, 1)
    emu.write_mem_b(ptr+0x2, emu.cur_input.get_span(0, 1))
    retfun(emu, 0)

emu.hook_addr(0x4407A669, ReadKeyStroke)

# replacing ShellPrintEx
def ShellPrintEx(emu):
    # printing the given message to the screen
    sys.stdout.write("ShellPrintEx: ")
    fmt = emu.read_reg_i("r8")
    arg = emu.read_reg_i("r9")
    i = 0
    while (True):
        ch = emu.read_mem_u16(fmt + i)
        if (ch == ord('\n')):
            sys.stdout.write(" <\\n> ")
            i += 2
        elif (ch == ord('\r')):
            sys.stdout.write(" <\\r> ")
            i += 2
        elif (ch == ord('%')):
            if (nch := emu.read_mem_u16(fmt+i+2) == ord('c')):
                sys.stdout.write(chr(arg))
                i += 4
            else:
                sys.stdout.write(chr(ch))
                i += 2
        elif (ch == ord('\0')):
            break
        else:
            sys.stdout.write(chr(ch))
            i += 2
    sys.stdout.write('\n')
    retfun(emu)

emu.hook_addr(0x48D0C5A3, ShellPrintEx)

flag = False

# replacing ShellGetExecutionBreakFlag
def ShellGetExecutionBreakFlag(emu):
    print("ShellGetExecutionBreakFlag")
    # for the first time return false, for the next times return true
    global flag
    if (not flag):
        flag = True
        retfun(emu, 0)
    else:
        retfun(emu, 1)

emu.hook_addr(0x48D09C6E, ShellGetExecutionBreakFlag)

# replacing AllocateZeroPool
def AllocateZeroPool(emu):
    print("AllocateZeroPool")
    # return any unused address
    retfun(emu, 0x40000000)

emu.hook_addr(0x48D09D3C, AllocateZeroPool)

emu.run()

if args.angr:
    if emu.sim_man.errored:
        print('Crashes:')
        print(emu.sim_man.errored)

    dual_emu.dump_new_inputs(emu, args.out_dir, clean=True)
