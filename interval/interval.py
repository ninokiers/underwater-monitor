import subprocess
import time
import json
import os
from pathlib import Path

from sensor import collect_sensor_data

CONFIG_PATH = Path("/home/admin/server/config.json")
FFMPEG_PIDFILE = "/tmp/stream_ffmpeg.pid"
FFMPEG_LOG= "/home/admin/interval/ffmpeg.log"

def load_config():
    with open(CONFIG_PATH) as f:
        return json.load(f)

def start_ffmpeg(framerate, resolution):
    width, height = resolution
    cmd = [
        "ffmpeg",
        "-f", "v4l2",
        "-framerate", str(framerate),
        "-video_size", f"{width}x{height}",
        "-i", "/dev/video2",
        "-vf",
        "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:"
        "textfile=/tmp/stream_overlay.txt:"
        "fontcolor=white:fontsize=24:box=1:boxcolor=black@0.5:x=10:y=10,"
        "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:"
        "text='%{localtime\:%Y-%m-%d %H\\\\\:%M\\\\\:%S}':"
        "fontcolor=white:fontsize=24:box=1:boxcolor=black@0.5:x=10:y=40",
        "-vcodec", "libx264",
        "-preset", "veryfast",
        "-tune", "zerolatency",
        "-f", "hls",
        "-hls_time", "2",
        "-hls_list_size", "5",
        "/home/admin/server/stream/stream.m3u8"
    ]
    
    # Stop existing ffmpeg process if any
    if Path(FFMPEG_PIDFILE).exists():
        try:
            with open(FFMPEG_PIDFILE) as f:
                pid = int(f.read().strip())
            os.kill(pid, 9)
        except Exception:
            pass
        Path(FFMPEG_PIDFILE).unlink()

    # Start new ffmpeg process
    proc = subprocess.Popen(cmd, stderr=open(FFMPEG_LOG, 'ab'))
    with open(FFMPEG_PIDFILE, "w") as f:
        f.write(str(proc.pid))
    print(f"Started FFmpeg with PID {proc.pid}")

def main():
    previous_config = {}
    while True:
        try:
            config = load_config()
            framerate = config.get("framerate", 15)
            resolution = config.get("resolution", [640, 360])
            interval = config.get("env_sensor_interval", 60)
            
            # Read sensors
            collect_sensor_data()

            # If config has changed, restart ffmpeg
            if config.get("framerate") != previous_config.get("framerate") or \
               config.get("resolution") != previous_config.get("resolution"):
                print("Config changed: restarting FFmpeg")
                start_ffmpeg(framerate, resolution)

            previous_config = config
            time.sleep(interval * 60)
        except Exception as e:
            print(f"Loop error: {e}")
            time.sleep(60)

if __name__ == "__main__":
    main()
