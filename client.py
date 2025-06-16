import argparse
import subprocess
import threading
import time
import requests
import json
import uuid
import signal
import sys
import os
from datetime import datetime

class TerminalClient:
    def __init__(self, server_url, command, title, interval=None):
        self.server_url = server_url
        self.command = command
        self.title = title
        self.interval = interval  # If set, run command repeatedly
        self.client_id = str(uuid.uuid4())
        self.process = None
        self.running = True
        self.registered = False
        self.last_heartbeat = 0
        self.heartbeat_interval = 30  # Send heartbeat every 30 seconds
        self.max_retries = 3
        self.retry_delay = 5  # Wait 5 seconds between retries
        
    def register_client(self):
        """Register this client with the server with retry logic"""
        for attempt in range(self.max_retries):
            try:
                response = requests.post(f"{self.server_url}/register", 
                                       json={
                                           "client_id": self.client_id,
                                           "title": self.title,
                                           "command": self.command
                                       }, timeout=10)
                if response.status_code == 200:
                    print(f"✓ Registered with server: {self.title}")
                    self.registered = True
                    self.last_heartbeat = time.time()
                    return True
                else:
                    print(f"✗ Failed to register with server: {response.text}")
            except Exception as e:
                print(f"✗ Error connecting to server (attempt {attempt + 1}/{self.max_retries}): {e}")
                if attempt < self.max_retries - 1:
                    print(f"⏳ Retrying in {self.retry_delay} seconds...")
                    time.sleep(self.retry_delay)
        
        self.registered = False
        return False
    
    def send_output(self, output, clear_before=False):
        """Send command output to the server with auto-reconnection"""
        # Ensure we're registered before sending output
        if not self.ensure_registered():
            print("❌ Could not register with server, output not sent")
            return False
            
        try:
            response = requests.post(f"{self.server_url}/update", 
                         json={
                             "client_id": self.client_id,
                             "output": output,
                             "timestamp": datetime.now().isoformat(),
                             "clear_before": clear_before
                         }, timeout=10)
            
            if response.status_code == 404:
                # Server doesn't know about us - re-register and retry
                print("⚠️  Server lost our registration, re-registering...")
                self.registered = False
                if self.ensure_registered():
                    return self.send_output(output, clear_before)  # Retry once
            elif response.status_code == 200:
                return True
            else:
                print(f"⚠️  Failed to send output: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Error sending output: {e}")
            return False
    
    def send_heartbeat(self):
        """Send heartbeat to server to maintain registration"""
        try:
            response = requests.post(f"{self.server_url}/heartbeat", 
                                   json={
                                       "client_id": self.client_id,
                                       "timestamp": datetime.now().isoformat()
                                   }, timeout=5)
            if response.status_code == 200:
                self.last_heartbeat = time.time()
                return True
            elif response.status_code == 404:
                # Server doesn't know about us - need to re-register
                print("⚠️  Server doesn't recognize client, re-registering...")
                self.registered = False
                return False
            else:
                print(f"⚠️  Heartbeat failed: {response.status_code}")
                return False
        except Exception as e:
            print(f"⚠️  Heartbeat error: {e}")
            return False
    
    def ensure_registered(self):
        """Ensure client is registered, re-register if necessary"""
        current_time = time.time()
        
        # Check if we need to send heartbeat
        if current_time - self.last_heartbeat > self.heartbeat_interval:
            if not self.send_heartbeat():
                self.registered = False
        
        # Re-register if needed
        if not self.registered:
            print("🔄 Re-registering with server...")
            return self.register_client()
        
        return True
    
    def run_command(self):
        """Run the command and capture its output"""
        if self.interval:
            self.run_interval_command()
        else:
            self.run_single_command()
    
    def run_interval_command(self):
        """Run command at specified intervals"""
        print(f"Started interval command: {self.command} (every {self.interval}s)")
        
        while self.running:
            try:
                # Run the command once
                result = subprocess.run(
                    self.command,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=30,
                    env=self.get_clean_env()
                )
                
                # Combine timestamp header with output in a single message
                timestamp_header = f"=== {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===\n"
                full_output = timestamp_header
                
                if result.stdout:
                    full_output += result.stdout
                if result.stderr:
                    full_output += f"\nSTDERR: {result.stderr}"
                
                # Send everything together with clear_before flag
                self.send_output(full_output, clear_before=True)
                
                # Wait for the interval
                if self.interval:
                    for _ in range(int(self.interval * 10)):  # Check every 0.1s
                        if not self.running:
                            break
                        time.sleep(0.1)
                    
            except subprocess.TimeoutExpired:
                self.send_output(f"\n[Command timed out after 30s]\n")
            except Exception as e:
                self.send_output(f"\n[Error running command: {e}]\n")
                if self.interval:
                    time.sleep(self.interval)
                else:
                    break
    
    def run_single_command(self):
        """Run a single long-running command"""
        try:
            self.process = subprocess.Popen(
                self.command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=False,
                bufsize=0,
                env=self.get_clean_env()
            )
            
            if not self.process.stdout:
                print("Error: Could not capture stdout")
                return
                
            print(f"Started command: {self.command}")
            
            output_buffer = b""
            last_send_time = time.time()
            
            while self.running and self.process.poll() is None:
                try:
                    import select
                    ready, _, _ = select.select([self.process.stdout], [], [], 0.1)
                    if ready:
                        chunk = self.process.stdout.read(1024)
                        if chunk:
                            output_buffer += chunk
                except (ImportError, OSError):
                    try:
                        chunk = self.process.stdout.read(1024)
                        if chunk:
                            output_buffer += chunk
                        else:
                            time.sleep(0.1)
                    except:
                        time.sleep(0.1)
                
                current_time = time.time()
                if (current_time - last_send_time >= 0.5) or len(output_buffer) >= 2048:
                    if output_buffer:
                        try:
                            decoded_output = output_buffer.decode('utf-8', errors='replace')
                            cleaned_output = self.clean_output(decoded_output)
                            if cleaned_output.strip():
                                self.send_output(cleaned_output)
                            output_buffer = b""
                            last_send_time = current_time
                        except Exception as e:
                            print(f"Error decoding output: {e}")
                            output_buffer = b""
                
                time.sleep(0.01)
            
            if output_buffer:
                try:
                    decoded_output = output_buffer.decode('utf-8', errors='replace')
                    cleaned_output = self.clean_output(decoded_output)
                    if cleaned_output.strip():
                        self.send_output(cleaned_output)
                except Exception as e:
                    print(f"Error decoding final output: {e}")
                    
        except Exception as e:
            print(f"Error running command: {e}")
        finally:
            if self.process:
                try:
                    self.process.terminate()
                    self.process.wait(timeout=5)
                except:
                    try:
                        self.process.kill()
                    except:
                        pass
    
    def get_clean_env(self):
        """Get environment with proper terminal settings"""
        env = dict(os.environ)
        env.update({
            'TERM': 'xterm',
            'COLUMNS': '180',
            'LINES': '50',
            'DEBIAN_FRONTEND': 'noninteractive',
            'NVIDIA_SMI_OPTS': '--format=csv,noheader,nounits'
        })
        return env
    
    def clean_output(self, text):
        """Minimal cleaning - preserve terminal sequences for web UI processing"""
        if not text:
            return ''
        
        import re
        
        # Remove only the most problematic control characters
        # Keep all ANSI escape sequences for the web UI terminal emulator
        
        # Remove null bytes and other problematic characters
        text = re.sub(r'[\x00]', '', text)  # Remove null bytes
        
        # Keep character set sequences like (B, )0, etc. for proper terminal emulation
        # The web UI terminal emulator will handle these properly
        
        return text
    
    def cleanup(self):
        """Clean up resources"""
        self.running = False
        if self.process:
            self.process.terminate()
        try:
            requests.post(f"{self.server_url}/disconnect", 
                         json={"client_id": self.client_id})
        except:
            pass
        print("\n✓ Client disconnected cleanly")
    
    def reconnect(self):
        """Attempt to reconnect to the server"""
        for attempt in range(self.max_retries):
            try:
                print(f"Attempting to reconnect to server (Attempt {attempt + 1}/{self.max_retries})...")
                response = requests.post(f"{self.server_url}/register", 
                                       json={
                                           "client_id": self.client_id,
                                           "title": self.title,
                                           "command": self.command
                                       })
                if response.status_code == 200:
                    print("✓ Reconnected to server")
                    self.registered = True
                    return True
                else:
                    print(f"✗ Failed to reconnect: {response.text}")
            except Exception as e:
                print(f"✗ Error connecting to server: {e}")
            
            time.sleep(self.retry_delay)
        
        print("✗ Max reconnection attempts reached. Giving up.")
        return False

def signal_handler(signum, frame):
    """Handle Ctrl+C gracefully"""
    global client
    print("\n⚠ Received interrupt signal...")
    if client:
        client.cleanup()
    sys.exit(0)

def main():
    global client
    parser = argparse.ArgumentParser(description='TerminalHub client - Connect terminal outputs to web monitoring dashboard')
    parser.add_argument('--cmd', required=True, help='Command to run (e.g., "nvidia-smi", "nvitop")')
    parser.add_argument('--server', required=True, help='Server address (e.g., "192.168.1.100:30080")')
    parser.add_argument('--title', required=True, help='Title for this client tab')
    parser.add_argument('--interval', type=float, help='Run command repeatedly at this interval (seconds)')
    
    args = parser.parse_args()
    
    # Ensure server URL has http:// prefix
    server_url = args.server
    if not server_url.startswith('http'):
        server_url = f"http://{server_url}"
    
    # Detect if user is trying to use 'watch' command and suggest interval instead
    if args.cmd.startswith('watch '):
        print("⚠️  Detected 'watch' command. Consider using --interval instead for better output.")
        print(f"   Suggested: python client.py --cmd '{args.cmd.split('watch')[1].strip()}' --interval 1 --server {args.server} --title '{args.title}'")
        proceed = input("Continue anyway? (y/N): ")
        if proceed.lower() != 'y':
            sys.exit(0)
    
    client = TerminalClient(server_url, args.cmd, args.title, args.interval)
    
    # Set up signal handler for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Register with server
    if not client.register_client():
        print("❌ Failed to register with server. Will retry during operation...")
        # Don't exit - we'll keep trying to register during operation
    
    # Start running the command
    try:
        client.run_command()
    except KeyboardInterrupt:
        signal_handler(None, None)

if __name__ == "__main__":
    client = None
    main()
