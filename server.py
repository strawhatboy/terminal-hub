from flask import Flask, render_template, request, jsonify
from flask_socketio import SocketIO, emit
import json
from datetime import datetime, timedelta
import threading
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key-here'
socketio = SocketIO(app, cors_allowed_origins="*")

# Store client data
clients = {}
client_outputs = {}

def cleanup_stale_clients():
    """Remove clients that haven't sent heartbeat in a while"""
    while True:
        try:
            current_time = datetime.now()
            stale_threshold = timedelta(minutes=5)  # Remove clients inactive for 5+ minutes
            
            stale_clients = []
            for client_id, client_info in clients.items():
                last_heartbeat = datetime.fromisoformat(client_info.get('last_heartbeat', client_info.get('connected_at')))
                if current_time - last_heartbeat > stale_threshold:
                    stale_clients.append(client_id)
            
            for client_id in stale_clients:
                title = clients[client_id]['title']
                print(f"🧹 Removing stale client: {title} (no heartbeat for >5 min)")
                del clients[client_id]
                if client_id in client_outputs:
                    del client_outputs[client_id]
                
                # Notify web clients
                socketio.emit('client_disconnected', {'client_id': client_id})
                
        except Exception as e:
            print(f"Error in cleanup task: {e}")
        
        time.sleep(60)  # Check every minute

# Start cleanup task in background
cleanup_thread = threading.Thread(target=cleanup_stale_clients, daemon=True)
cleanup_thread.start()

@app.route('/')
def index():
    """Main web interface"""
    return render_template('index.html')

@app.route('/register', methods=['POST'])
def register_client():
    """Register a new client"""
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No JSON data provided'}), 400
        
    client_id = data.get('client_id')
    title = data.get('title')
    command = data.get('command')
    
    if not all([client_id, title, command]):
        return jsonify({'error': 'Missing required fields'}), 400
    
    clients[client_id] = {
        'title': title,
        'command': command,
        'connected_at': datetime.now().isoformat(),
        'last_update': datetime.now().isoformat(),
        'last_heartbeat': datetime.now().isoformat()
    }
    
    client_outputs[client_id] = ""
    
    # Notify all web clients about the new client
    socketio.emit('client_registered', {
        'client_id': client_id,
        'title': title,
        'command': command
    })
    
    print(f"✓ Client registered: {title} ({command})")
    return jsonify({'status': 'registered'})

@app.route('/heartbeat', methods=['POST'])
def heartbeat():
    """Handle client heartbeat to maintain registration"""
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No JSON data provided'}), 400
        
    client_id = data.get('client_id')
    timestamp = data.get('timestamp')
    
    if not client_id:
        return jsonify({'error': 'Missing client_id'}), 400
    
    if client_id not in clients:
        # Client not registered
        return jsonify({'error': 'Client not registered', 'action': 'register'}), 404
    
    # Update last heartbeat time
    clients[client_id]['last_heartbeat'] = timestamp or datetime.now().isoformat()
    
    return jsonify({'status': 'heartbeat_received'})

@app.route('/update', methods=['POST'])
def update_output():
    """Receive output update from client"""
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No JSON data provided'}), 400
        
    client_id = data.get('client_id')
    output = data.get('output')
    timestamp = data.get('timestamp')
    clear_before = data.get('clear_before', False)  # Option to clear before adding
    
    if not all([client_id, output]):
        return jsonify({'error': 'Missing required fields'}), 400
    
    if client_id not in clients:
        return jsonify({'error': 'Client not registered'}), 404
    
    # Update client info
    clients[client_id]['last_update'] = timestamp or datetime.now().isoformat()
    
    # Store the output as complete blocks instead of splitting by lines
    if client_id not in client_outputs:
        client_outputs[client_id] = ""
    
    # Clear existing output if requested (useful for interval commands)
    should_clear = clear_before or "===" in output
    if should_clear:
        client_outputs[client_id] = ""
    
    # Append the new output
    client_outputs[client_id] += output
    
    # Keep only the last 50000 characters to prevent memory issues
    max_chars = 50000
    if len(client_outputs[client_id]) > max_chars:
        client_outputs[client_id] = client_outputs[client_id][-max_chars:]
    
    # Send update to all web clients
    socketio.emit('output_update', {
        'client_id': client_id,
        'output': output,
        'timestamp': timestamp,
        'clear_before': should_clear
    })
    
    return jsonify({'status': 'updated'})

@app.route('/disconnect', methods=['POST'])
def disconnect_client():
    """Handle client disconnect"""
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No JSON data provided'}), 400
        
    client_id = data.get('client_id')
    
    if client_id in clients:
        title = clients[client_id]['title']
        del clients[client_id]
        if client_id in client_outputs:
            del client_outputs[client_id]
        
        # Notify web clients
        socketio.emit('client_disconnected', {'client_id': client_id})
        print(f"✓ Client disconnected: {title}")
    
    return jsonify({'status': 'disconnected'})

@app.route('/api/clients')
def get_clients():
    """Get list of connected clients"""
    return jsonify(clients)

@app.route('/api/output/<client_id>')
def get_client_output(client_id):
    """Get output for a specific client"""
    if client_id not in clients:
        return jsonify({'error': 'Client not found'}), 404
    
    return jsonify({
        'client_id': client_id,
        'output': client_outputs.get(client_id, ''),
        'client_info': clients[client_id]
    })

@socketio.on('connect')
def handle_connect():
    """Handle web client connection"""
    print("Web client connected")
    # Send current clients list
    emit('clients_list', {
        'clients': clients,
        'outputs': {cid: output for cid, output in client_outputs.items()}
    })

@socketio.on('disconnect')
def handle_disconnect():
    """Handle web client disconnection"""
    print("Web client disconnected")

if __name__ == '__main__':
    print("🚀 Starting TerminalHub Server")
    print("📡 Server will be available at: http://localhost:30080")
    print("💡 Use client.py to connect terminal outputs")
    print("-" * 50)
    
    socketio.run(app, host='0.0.0.0', port=30080, debug=True, allow_unsafe_werkzeug=True)
