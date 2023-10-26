"""
Environment plugin - prepare system & rootfs
"""

import json
import os
import subprocess


def basic_prepare(rootfs):
    # Mount /proc -> rootfs/proc
    mount_proc(rootfs)

    # echo core >/proc/sys/kernel/core_pattern
    set_core_pattern()

    # Mount /dev/urandom -> rootfs/dev/urandom
    mount_dev(rootfs, "urandom", "--rbind")

    # Mount /dev/random -> rootfs/dev/random
    mount_dev(rootfs, "random", "--rbind")

    # Mount /dev/null -> rootfs/dev/null
    mount_dev(rootfs, "null", "--rbind")

    # Create rootfs/tmp
    rootfs_tmp_dir = os.path.join(rootfs, "tmp")
    if not os.path.exists(rootfs_tmp_dir):
        os.mkdir(rootfs_tmp_dir)


def set_core_pattern():
    # echo core >/proc/sys/kernel/core_pattern
    core_pattern_file = "/proc/sys/kernel/core_pattern"
    core_pattern_data = open(core_pattern_file).read()
    if core_pattern_data != "core":
        open(core_pattern_file, "w").write("core")


def mount_proc(rootfs):
    """
    Mount /proc -> rootfs/proc
    :param rootfs: rootfs dir path
    :return:
    """

    rootfs_proc = os.path.join(rootfs, "proc")

    if not os.path.exists(rootfs_proc):
        os.mkdir(rootfs_proc)
        cmd = "sudo mount --bind /proc %s" % rootfs_proc
        subprocess.call(cmd, shell=True)


def mount_dev(rootfs, name, bind_opt):
    """
    Mount /dev/<name> -> rootfs/dev/<name>
    :param rootfs: rootfs dir path
    :param name: device's name, e.g. random, urandom
    :param bind_opt: bind option, e.g. --bind, --rbind
    :return:
    """

    dev = os.path.join("/dev/", name)
    rootfs_dev = os.path.join(rootfs, "dev", name)

    if not os.path.exists(rootfs_dev):
        f = open(rootfs_dev, "w")
        f.close()
        cmd = "sudo mount %s %s %s" % (bind_opt, dev, rootfs_dev)
        subprocess.call(cmd, shell=True)


def init(json_options):
    try:
        # Parse options
        jops = json.loads(json_options)
        target_args = jops["target_args"]

        # Set rootfs
        rootfs = target_args[1]

        # Basic prepare
        basic_prepare(rootfs)

        return True

    except Exception as e:
        print('init failed - %s' % str(e))
        return False


def get_error():
    return "error"


def write_log(message):
    return True


def finish():
    write_log("FINISH")
    return True


def setup():
    return True


def teardown():
    return True
