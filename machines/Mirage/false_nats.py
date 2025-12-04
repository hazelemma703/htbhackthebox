#!/usr/bin/env python3
import socket
import json
import re

def extract_creds(data):
    if b"CONNECT" in data:
        try:
            # Find JSON in CONNECT message
            text = data.decode('utf-8', errors='ignore')
            match = re.search(r'CONNECT\s+({[^}]+})', text)
            if match:
                creds = json.loads(match.group(1))
                if 'user' in creds and 'pass' in creds:
                    print(f"🎯 FOUND: {creds['user']}:{creds['pass']}")
                    return True
        except:
            pass
    return False

def run_honeypot(host="0.0.0.0", port=4222):
    with socket.socket() as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((host, port))
        s.listen(5)
        
        print(f"🍯 NATS Honeypot on {host}:{port}")
        
        while True:
            try:
                client, addr = s.accept()
                print(f"📡 {addr[0]}:{addr[1]}")
                
                with client:
                    # Send minimal NATS INFO
                    info = '{"server_id":"HONEY","version":"2.11.3","auth_required":true}'
                    client.send(f"INFO {info}\r\n".encode())
                    
                    # Read client data
                    data = client.recv(2048)
                    if data:
                        print(f"📨 {data[:100]}...")
                        extract_creds(data)
                    
                    # Send auth error
                    client.send(b"-ERR 'Bad Credentials'\r\n")
                    
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"❌ {e}")

if __name__ == "__main__":
    run_honeypot()
