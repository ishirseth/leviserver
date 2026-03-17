#!/usr/bin/env python3
import socket
import threading

HOST = "::"
PORT = 23

add = 0
addnum = 0
lock = threading.Lock()

def handle_client(conn, addr):
    global add, addnum
    print("~Connection from", addr)
    conn.sendall(b"~Welcome to Ishir's Telnet Server!\r\n")
    buffer = ""
    try:
        while True:
            data = conn.recv(1)
            if not data:
                print(f"~Client disconnected: {addr}")
                break

            # Handle telnet IAC negotiation bytes
            if data == b'\xff':
                conn.recv(2)  # skip the next 2 negotiation bytes
                continue

            char = data.decode(errors='ignore')
            if not char:
                continue

            if char in ("\n", "\r"):
                message = buffer.strip()
                if not message:
                    continue
                print(f"~Client {addr}: {message}")
                buffer = ""
                response = b""
                with lock:
                    if message.lower() == "levi" and add == 0:
                        response = b"~Yay, Levi!\r\n"
                    elif message.lower() == "add" and add == 0:
                        response = b"~Addition\r\n"
                        add = 1
                    elif message.lower() == "noadd" and add == 1:
                        response = b"~No Addition\r\n"
                        add = 0
                    if add == 1:
                        if message.isdigit():
                            addnum += int(message)
                            response = f"~{addnum}\r\n".encode()
                        elif message.lower() == "clrnum":
                            addnum = 0
                            response = b"~Cleared\r\n"
                        elif message.isalpha() and message.lower() != "add" and message.lower() != "clrnum":
                            response = b"~Not a number\r\n"
                    elif message.lower() == "exit":
                        response = b"~Goodbye!\r\n"
                        conn.sendall(response)
                        break
                if response:
                    conn.sendall(response)
            else:
                buffer += char
    except Exception as e:
        print(f"~Error with client {addr}: {e}")
    finally:
        conn.close()

def main():
    with socket.socket(socket.AF_INET6, socket.SOCK_STREAM) as server:
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(("::", PORT))
        server.listen()
        print(f"~Telnet server listening on {PORT}")
        while True:
            conn, addr = server.accept()
            threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()

if __name__ == "__main__":
    main()