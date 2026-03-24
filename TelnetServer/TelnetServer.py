#!/usr/bin/env python3
import socket
import threading
import json

HOST = "0.0.0.0"
PORT = 1437
clients = []

jsonpath = "TelnetServer/saveddata.json"
with open(jsonpath, "r") as f:
    saveddata = json.load(f)
userdata = {}

lock = threading.Lock()



def is_logged_in(username):
    for port, data in userdata.items():
        if data.get("username") == username:
            return True
    return False

# Command functions

def cmd_exit(conn, addr, argument):
    if argument:
        return b"~Unwanted argument\r\n"
    else:
        conn.sendall(b"~Goodbye!\r\n")
        return None  # signals to break

def cmd_login(addr, argument):
    if "username" in userdata[addr[1]]:
        return f"~Already logged in under: {userdata[addr[1]]['username']}\r\n".encode()
    elif argument:
        if is_logged_in(argument):
            return b"~Username already in use\r\n"
        elif argument not in saveddata:
            userdata[addr[1]]['username'] = argument
            userdata[addr[1]]['save'] = True
            return f"~Account created and logged in under: {argument}\r\n".encode()
        else:
            userdata[addr[1]] = saveddata[argument]
            userdata[addr[1]]['save'] = True
            return f"~Welcome back, {argument}!\r\n".encode()
    else:
        return b"~Missing username\r\n"

def cmd_levi(argument):
    if argument:
        return b"~Unwanted argument\r\n"
    return b"~Yay, Levi!\r\n"

def cmd_help(argument):
    if argument:
        return b"~Unwanted argument\r\n"
    return b"~Commands: help, levi, login <username>, add <num>, clradd, echo <msg>, who, whoami, prime <arg>, note <msg>, clrnote <num>, notes, exit\r\n"

def cmd_echo(argument, echo):
    if not argument or not echo:
        return b"~Missing argument\r\n"
    return f"~{echo}\r\n".encode()

def cmd_whoami(addr, argument):
    if argument:
        return b"~Unwanted argument\r\n"
    return f"~You are {addr[0]}:{addr[1]}\r\n".encode()

def cmd_who(argument):
    if argument:
        return b"~Unwanted argument\r\n"
    return f"~{len(clients)} client/s connected\r\n".encode()

def cmd_prime(argument):
    if not argument:
        return b"~Missing argument\r\n"
    elif not argument.isdigit():
        return b"~Argument is not a number\r\n"
    elif int(argument) > 1000000000000:
        return b"~Argument is too large\r\n"
    elif int(argument) < 2:
        return b"~Not prime\r\n"
    else:
        n = int(argument)
        for i in range(2, int(n**0.5) + 1):
            if n % i == 0:
                return b"~Not prime\r\n"
        return b"~Prime\r\n"

def cmd_add(addr, argument):
    if not argument:
        return b"~Missing argument\r\n"
    elif argument.isdigit():
        userdata[addr[1]]["addnum"] = userdata[addr[1]]["addnum"] + int(argument)
        return f"~{userdata[addr[1]]['addnum']}\r\n".encode()
    else:
        return b"~Argument is not a number\r\n"

def cmd_clradd(addr, argument):
    if argument:
        return b"~Unwanted argument\r\n"
    userdata[addr[1]]["addnum"] = 0
    return b"~Cleared\r\n"

def cmd_note(addr, note):
    if not note:
        return b"~Missing note\r\n"
    else:
        userdata[addr[1]]["notes"].append(note)
        return b"~Note saved\r\n"

def cmd_notes(addr, argument):
    if argument:
        return b"~Unwanted argument\r\n"
    elif not userdata[addr[1]]["notes"]:
        return b"~No notes\r\n"
    else:
        return ("~Notes:\r\n" + "".join(f"~  {i+1}. {note}\r\n" for i, note in enumerate(userdata[addr[1]]["notes"]))).encode()
    
def cmd_clrnote(addr, argument):
    if not argument:
        return b"~Missing argument\r\n"
    elif not argument.isdigit():
        return b"~Argument is not a number\r\n"
    elif int(argument) < 1 or int(argument) > len(userdata[addr[1]]["notes"]):
        return b"~Invalid note number\r\n"
    else:
        del userdata[addr[1]]["notes"][int(argument) - 1]
        return f"~Note {argument} cleared\r\n".encode()

def handle_client(conn, addr):
    clients.append(addr)
    conn.sendall(b"~Welcome to Ishir's Telnet Server!\r\n")
    conn.sendall(b"~Type 'help' for a list of commands.\r\n")
    conn.sendall(b"~Login to have your data saved for the next time you connect.\r\n")
    buf = ""
    userdata[addr[1]] = {"addnum": 0, "notes": []}




    try:
        while True:
            ch = conn.recv(1).decode(errors="ignore")
            if not ch:
                break

            if ch in "\r\n":
                msg = buf.strip()
                buf = ""

                parts = msg.split()
                command = parts[0] if parts else ""
                argument = parts[1] if len(parts) > 1 else ""
                echo = " ".join(parts[1:])
                note = " ".join(parts[1:])

                print(f"~{addr}: {msg}")
                resp = b""

                with lock:
                    if command == "exit":
                        resp = cmd_exit(conn, addr, argument)
                        if resp is None:
                            return
                    elif command == "login":
                        resp = cmd_login(addr, argument)
                    elif command == "levi":
                        resp = cmd_levi(argument)
                    elif command == "help":
                        resp = cmd_help(argument)
                    elif command == "echo":
                        resp = cmd_echo(argument, echo)
                    elif command == "whoami":
                        resp = cmd_whoami(addr, argument)
                    elif command == "who":
                        resp = cmd_who(argument)
                    elif command == "prime":
                        resp = cmd_prime(argument)
                    elif command == "add":
                        resp = cmd_add(addr, argument)
                    elif command == "clradd":
                        resp = cmd_clradd(addr, argument)
                    elif command == "note":
                        resp = cmd_note(addr, note)
                    elif command == "clrnote":
                        resp = cmd_clrnote(addr, argument)
                    elif command == "notes":
                        resp = cmd_notes(addr, argument)
                    elif command:
                        resp = b"~Unknown command\r\n"

                if userdata[addr[1]].get('save') == True:
                    saveddata[userdata[addr[1]]['username']] = userdata[addr[1]]
                    with open(jsonpath, "w") as f:
                        json.dump(saveddata, f)



                if resp:
                    conn.sendall(resp)

            elif ch == "\x08":
                if buf:
                    buf = buf[:-1]
                    conn.sendall(b" \x08")
            elif ch == "\x7f":
                if buf:
                    buf = buf[:-1]
                    conn.sendall(b"\x08 \x08")
            else:
                buf += ch

    except Exception as e:
        print(f"~Error {addr}: {e}")
    finally:
        clients.remove(addr)
        if userdata[addr[1]].get('save') == True: # save data
            saveddata[userdata[addr[1]]['username']] = userdata[addr[1]]
        del userdata[addr[1]]
        with open(jsonpath, "w") as f: #save data to json
            json.dump(saveddata, f)

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