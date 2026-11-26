"""Synthetic TLS SMTP sink. Mail and activation codes live only in RAM."""
import email
import http.server
import json
import re
import socketserver
import ssl
import threading
import time
from urllib.parse import urlsplit, parse_qs

messages = {}
modes = {}
attempts = {}
lock = threading.Lock()


class SMTP(socketserver.StreamRequestHandler):
    def handle(self):
        self.wfile.write(b"220 laboratory ESMTP\r\n")
        recipient = None
        while True:
            line = self.rfile.readline()
            if not line:
                return
            command = line.decode(errors="replace").strip()
            verb = command.split(" ", 1)[0].upper()
            if verb in ("EHLO", "HELO"):
                self.wfile.write(b"250-laboratory\r\n250-AUTH PLAIN LOGIN\r\n250 SIZE 100000\r\n")
            elif verb == "AUTH":
                self.wfile.write(b"235 laboratory authentication accepted\r\n")
            elif verb == "RCPT":
                match = re.search(r"<([^>]+)>", command)
                recipient = match.group(1) if match else None
                allowed = recipient and recipient.endswith(("@example.invalid", "@demo.example"))
                self.wfile.write(b"250 synthetic recipient\r\n" if allowed else b"550 synthetic recipients only\r\n")
            elif verb == "DATA":
                self.wfile.write(b"354 end with dot\r\n")
                body = bytearray()
                while True:
                    part = self.rfile.readline()
                    if not part or part == b".\r\n":
                        break
                    body.extend(part)
                message = email.message_from_bytes(body)
                text = ""
                for part in message.walk():
                    if part.get_content_type() == "text/plain":
                        text += part.get_payload(decode=True).decode("utf-8", errors="replace")
                link = re.search(r"https://localhost:18643/#/activate\?code=([^\s]+)", text)
                if recipient and link:
                    with lock:
                        messages[recipient] = {"code": link.group(1)}
                self.wfile.write(b"250 accepted by laboratory transport\r\n")
            elif verb == "QUIT":
                self.wfile.write(b"221 goodbye\r\n")
                return
            else:
                self.wfile.write(b"250 ok\r\n")


class Mailbox(http.server.BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_GET(self):
        query = parse_qs(urlsplit(self.path).query)
        with lock:
            recipient = query.get("recipient", [""])[0]
            result = ({"attempts": attempts.get(recipient, 0)} if urlsplit(self.path).path == "/lab/stats"
                      else messages.get(recipient, {}))
        self.send_response(200)
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(json.dumps(result).encode())

    def do_DELETE(self):
        with lock:
            messages.clear()
        self.send_response(204)
        self.end_headers()

    def do_POST(self):
        if self.path == "/lab/control":
            payload = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
            recipient = payload.get("recipient", "")
            if not recipient.endswith("@example.invalid"):
                self.send_error(400)
                return
            with lock:
                modes[recipient] = payload.get("mode", 201)
            self.send_response(204)
            self.end_headers()
            return
        if self.path != "/v3/smtp/email":
            self.send_error(404)
            return
        payload = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
        recipient = payload.get("to", [{}])[0].get("email", "")
        link = re.search(r"https://localhost:18643/#/activate\?code=([^\s]+)", payload.get("textContent", ""))
        if not recipient.endswith(("@example.invalid", "@demo.example")) or not link:
            self.send_error(400)
            return
        with lock:
            attempts[recipient] = attempts.get(recipient, 0) + 1
            mode = modes.get(recipient, 201)
        if mode == "timeout":
            time.sleep(16)
            mode = 500
        if mode != 201:
            self.send_response(int(mode))
            self.end_headers()
            return
        with lock:
            messages[recipient] = {"code": link.group(1)}
        self.send_response(201)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"messageId":"synthetic-laboratory-accepted"}')


server = socketserver.ThreadingTCPServer(("0.0.0.0", 2465), SMTP)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain("/certs/server.crt", "/certs/server.key")
server.socket = context.wrap_socket(server.socket, server_side=True)
threading.Thread(target=server.serve_forever, daemon=True).start()
provider = http.server.HTTPServer(("0.0.0.0", 443), Mailbox)
provider_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
provider_context.load_cert_chain("/certs/provider.crt", "/certs/provider.key")
provider.socket = provider_context.wrap_socket(provider.socket, server_side=True)
threading.Thread(target=provider.serve_forever, daemon=True).start()
http.server.HTTPServer(("0.0.0.0", 8025), Mailbox).serve_forever()
