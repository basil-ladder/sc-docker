import os
import shutil

def find_vnc_executable() -> str:
    for name in ["vnc-viewer", "vncviewer"]:
        path = shutil.which(name)
        if path:
            return path
    raise Exception("Neither 'vnc-viewer' nor 'vncviewer' was found. Check your PATH.")

def check_vnc_exists() -> None:
    try:
        _ = find_vnc_executable()
    except Exception as e:
        raise Exception("An error occurred while trying to find VNC viewer executable.") from e

def launch_vnc_viewer(host: str, port: int) -> None:
    vnc_path = find_vnc_executable()
    os.spawnl(os.P_NOWAIT, vnc_path, os.path.basename(vnc_path), f"{host}:{port}")
