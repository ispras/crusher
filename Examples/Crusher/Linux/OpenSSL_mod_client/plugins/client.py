from subprocess import Popen, PIPE
import time
from pathlib import Path
import os


def process_is_alive(pid):
    """
    Check if process is alive
    """
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    return True


work_dir = Path(os.getenv("WORK_DIR"))
port = int(os.getenv("PORT"))

target_dir = os.path.join(os.path.dirname(__file__), os.pardir)

if __name__ == '__main__':
    # Run client parent (only once)
    client_parent_file = work_dir / "client_parent"
    if not client_parent_file.exists() or True:
        # TODO - clean ?
        command = [f"{target_dir}/client/openssl-clean", "s_client", "-tls1_2", "-connect", f"127.0.0.1:{str(port)}", "-legacy_renegotiation"]
        client = Popen(command, stdin=PIPE)
        print(f"Client PID = {client.pid}")
        client_parent_file.touch()

        # TODO - fix
        f = open(str(client_parent_file), "w")
        f.write(str(client.pid))
        f.close()

