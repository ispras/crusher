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

if args.qiling:
    emu.hook_fuzzer_start(emu.start_addr)

# NOTE: pay attention to the UEFI calling convention and 2-byte chars

def entry_hook(emu):
    print('Entry Hook')
    # TODO: set Type to ShellPromptResponseTypeYesNoAllCancel
    raise

emu.hook_addr(emu.start_addr, entry_hook)

def WaitForEvent(emu):
    # TODO: skip this function
    raise

emu.hook_addr(0x07E972B7, WaitForEvent)

def ReadKeyStroke(emu):
    # TODO: put the first input byte to Key.UnicodeChar and return EFI_SUCCESS
    raise

emu.hook_addr(0x0697C230, ReadKeyStroke)

def ShellPrintEx(emu):
    # TODO: print some prefix and the argument string here;
    # substitute one %c if necessary;
    # print \n as " <\n> ", \r as " <\r> "
    # (i.e. implement a simplified printf ad hoc)
    raise

emu.hook_addr(0x062D693F, ShellPrintEx)

def ShellGetExecutionBreakFlag(emu):
    # TODO: for the first time return false, for the next times return true
    raise

emu.hook_addr(0x062D566E, ShellGetExecutionBreakFlag)

emu.run()

if args.angr:
    if emu.sim_man.errored:
        print('Crashes:')
        print(emu.sim_man.errored)

    dual_emu.dump_new_inputs(emu, args.out_dir, clean=True)
