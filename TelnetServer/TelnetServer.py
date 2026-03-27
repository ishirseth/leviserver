#!/usr/bin/env python3
import socket
import threading
import json
import subprocess

HOST = "0.0.0.0"
PORT = 1437
clients = []

jsonpath = "saveddata.json"
with open(jsonpath, "r") as f:
    saveddata = json.load(f)
userdata = {}

lock = threading.Lock()



def is_logged_in(username):
    for port, data in userdata.items():
        if data.get("username") == username:
            return True
    return False

def find_port_by_username(username):
    for port, data in userdata.items():
        if data.get("username") == username:
            return port
    return None


# Command functions

def cmd_exit(conn, addr, argument):
    if argument:
        return b"~Unwanted argument\r\n"
    else:
        conn.sendall(b"~Goodbye!\r\n")
        return None  # signals to break

def cmd_login(addr, argument):
    if userdata[addr[1]]['save'] == True:
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
            userdata[addr[1]]['username'] = argument
            userdata[addr[1]]['save'] = True
            return f"~Welcome back, {argument}!\r\n".encode()
    else:
        return b"~Missing username\r\n"
    
def cmd_logout(addr, argument):
    if not argument:
        if userdata[addr[1]]['save'] == True:
            userdata[addr[1]]["username"] = ""
            userdata[addr[1]]["save"] = False
            return b"~Logged out\r\n"
        else:
            return b"~Already logged out\r\n"
    else:
        return b"~Unwanted argument\r\n"

def cmd_levi(argument):
    if argument:
        return b"~Unwanted argument\r\n"
    return b"~Yay, Levi!\r\n"

def cmd_ascii(argument):
    if argument:
        if len(argument) != 1:
            return b"~Argument must be a single character\r\n"
        else: 
            result = subprocess.run(['./asm/ascii', argument])
        return f"~ASCII assembly program exited with code: {result.returncode}\r\n".encode()
    else:
        return b"~Missing argument\r\n"

def cmd_help(argument):
    if argument:
        return b"~Unwanted argument\r\n"
    return b"~Commands: help, levi, ascii <char>, login <username>, logout, add <num>, clradd, echo <msg>, who, whoami, message <user> <msg>, inbox, clrinbox, prime <num>, note <msg>, clrnote <num>, notes, exit\r\n"

def cmd_echo(argument, echo):
    if not argument or not echo:
        return b"~Missing argument\r\n"
    return f"~{echo}\r\n".encode()

def cmd_message(addr, argument, message):
    if not argument:
        return b"~Missing user\r\n"
    else:
        target_port = find_port_by_username(argument)
        sender = userdata[addr[1]]["username"]

        if argument in saveddata and target_port is None:
            if userdata[addr[1]]["save"] == True:
                saveddata[argument]["messages"].append(f"From {sender}: {message}")
            elif userdata[addr[1]]["save"] == False:
                saveddata[argument]["messages"].append(f"From {addr[1]}: {message}")
            with open(jsonpath, "w") as f: #save data to json
                json.dump(saveddata, f)
            return f"~Message sent to {argument}\r\n".encode()
        elif target_port is None:
            return b"~User not found\r\n"
        else:
            if userdata[addr[1]]["save"] == True:
                userdata[target_port]["messages"].append(f"From {sender}: {message}")
            elif userdata[addr[1]]["save"] == False:
                userdata[target_port]["messages"].append(f"From {addr[1]}: {message}")
            return f"~Message sent to {argument}\r\n".encode()

def cmd_inbox(addr, argument):
    if argument:
        return b"~Unwanted argument\r\n"
    else:
        messages = userdata[addr[1]]["messages"]
        if not messages:
            return b"~No messages\r\n"
        else:
            response = ("~Inbox:\r\n" + "".join(f"~  {i+1}. {msg}\r\n" for i, msg in enumerate(userdata[addr[1]]["messages"])))
            return response.encode()
        
def cmd_clrinbox(addr, argument):
    if argument:
        return b"~Unwanted argument\r\n"
    else:
        userdata[addr[1]]["messages"] = [] # clear messages
        return b"~Inbox cleared\r\n"

def cmd_whoami(addr, argument):
    if argument:
        return b"~Unwanted argument\r\n"
    elif userdata[addr[1]]['save'] == False:
        return f"~You are {addr[0]}:{addr[1]}\r\n".encode()
    else:
        return f"~You are {addr[0]}:{addr[1]} with the username: {userdata[addr[1]]['username']}\r\n".encode()


def cmd_who(argument):
    if argument:
        return b"~Unwanted argument\r\n"
    return f"~{len(clients)} client/s connected\r\n".encode()

def cmd_prime(argument):
    if not argument:
        return b"~Missing argument\r\n"
    elif argument < 0:
        return b"~Argument is negative\r\n"
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
    userdata[addr[1]] = {"addnum": 0, "notes": [], "username": "", "save": False, "messages": []} # initialize userdata for this client



    try:
        while True:
            print(userdata[addr[1]])
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
                message = " ".join(parts[2:])

                resp = b""

                with lock:
                    if command == "exit":
                        resp = cmd_exit(conn, addr, argument)
                        if resp is None:
                            return
                    elif command == "login":
                        resp = cmd_login(addr, argument)
                    elif command == "logout":
                        resp = cmd_logout(addr, argument)
                    elif command == "levi":
                        resp = cmd_levi(argument)
                    elif command == "ascii":
                        resp = cmd_ascii(argument)
                    elif command == "help":
                        resp = cmd_help(argument)
                    elif command == "echo":
                        resp = cmd_echo(argument, echo)
                    elif command == "message":
                        resp = cmd_message(addr, argument, message)
                    elif command == "inbox":
                        resp = cmd_inbox(addr, argument)
                    elif command == "clrinbox":
                        resp = cmd_clrinbox(addr, argument)
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
