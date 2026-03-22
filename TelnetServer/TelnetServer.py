#!/usr/bin/env python3
import socket
import threading

HOST = "0.0.0.0"
PORT = 1437
clients = []

addnum = 0
lock = threading.Lock()

def handle_client(conn, addr):
    clients.append(addr)
    global addnum
    conn.sendall(b"~Welcome to Ishir's Telnet Server!\r\n")
    buf = ""

    try:
        while True:
            print (f"{clients}")
            ch = conn.recv(1).decode(errors="ignore")
            if not ch:
                break

            if ch in "\r\n":
                msg = buf.strip()
                buf = ""

                parts = msg.split()
                command = parts[0] if parts else "" # Handle empty input gracefully
                argument = parts[1] if len(parts) > 1 else "" # Handle missing argument gracefully
                echo = " ".join(parts[1:])

                print(f"~{addr}: {msg}")
                resp = b""


                with lock:
                    if command == "exit":
                        if argument:
                            resp = b"~Unwanted argument\r\n"
                        else:
                            conn.sendall(b"~Goodbye!\r\n")
                            return

                    elif command == "levi":
                        if argument:
                            resp = b"~Unwanted argument\r\n"
                        else:
                            resp = b"~Yay, Levi!\r\n"

                    elif command == "help":
                        if argument:
                            resp = b"~Unwanted argument\r\n"
                        else:
                            resp = b"~Commands: help, levi, add <num>, clrnum, echo <msg>, who, whoami, prime<arg>, exit\r\n"

                    elif command == "echo":
                        if not argument or not echo:
                            resp = b"~Missing argument\r\n"
                        else:
                            resp = f"~{echo}\r\n".encode()

                    elif command == "whoami":
                        if argument:
                            resp = b"~Unwanted argument\r\n"
                        else:
                            resp = f"~You are {addr[0]}:{addr[1]}\r\n".encode()
                    
                    elif command == "who":
                        if argument:
                            resp = b"~Unwanted argument\r\n"
                        else:
                            resp = f"~{len(clients)} clients connected\r\n".encode()

                    elif command == "prime":
                        if not argument:
                            resp = b"~Missing argument\r\n"
                        elif int(argument) > 1000000000000:
                            resp = b"~Argument is too large\r\n"
                        elif int(argument) < 0:
                            resp = b"~Argument is not a positive number\r\n"
                        elif argument.isdigit():
                            n = int(argument)
                            if n < 2:
                                resp = b"~Not prime\r\n"
                            else:
                                for i in range(2, int(n**0.5) + 1):
                                    if n % i == 0:
                                        resp = b"~Not prime\r\n"
                                        break
                                else:
                                    resp = b"~Prime\r\n"
                        else:
                            resp = b"~Argument is not a number\r\n"

                    elif command == "add":
                        if not argument:
                            resp = b"~Missing argument\r\n"
                        elif argument.isdigit():
                            addnum = addnum + int(argument)
                            resp = f"~{addnum}\r\n".encode()
                        else:
                            resp = b"~Argument is not a number\r\n"

                    elif command == "clr":
                        if argument:
                            resp = b"~Unwanted argument\r\n"
                        else:
                            addnum = 0
                            resp = b"~Cleared\r\n"

                    elif command:
                        resp = b"~Unknown command\r\n"


                if resp:
                    conn.sendall(resp)


            elif ch == "\x08":  # backspace - terminal already moved cursor back
                if buf:
                    buf = buf[:-1]
                    conn.sendall(b" \x08")  # just overwrite with space and stay
            elif ch == "\x7f":  # delete
                if buf:
                    buf = buf[:-1]
                    conn.sendall(b"\x08 \x08")

            else:
                buf += ch

    except Exception as e:
        print(f"~Error {addr}: {e}")
    finally:
        clients.remove(addr)
        conn.close()
        print(f"~Disconnected: {addr}")

def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind((HOST, PORT))
        server.listen()
        print(f"~Listening on {PORT}")
        while True:
            conn, addr = server.accept()
            threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()

if __name__ == "__main__":
    main()
