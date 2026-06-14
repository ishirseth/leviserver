import subprocess
import time
import threading
import os

# Base directory
base_repo = os.path.dirname(os.path.abspath(__file__))
web_root_dir = os.path.join(base_repo, "WebRoot")
levis_web_dir = os.path.join(base_repo, "LeviServerWeb")

def start_server(port, directory):
    # This runs the server and lets the output stream directly to your terminal
    subprocess.run(["python3", "-m", "http.server", port, "--directory", directory])

def git_manager():
    # Runs the git pull every 30 seconds
    while True:
        try:
            subprocess.run(["git", "pull"], capture_output=True)
            time.sleep(30)
        except Exception:
            time.sleep(30)

# Start Git Thread
threading.Thread(target=git_manager, daemon=True).start()

# Start Server Threads (Raw output)
threading.Thread(target=start_server, args=("8071", web_root_dir), daemon=True).start()
threading.Thread(target=start_server, args=("8072", levis_web_dir), daemon=True).start()

print("LeviServer is running. Showing ALL logs (including 404s).")

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("\nShutting down LeviServer...")
