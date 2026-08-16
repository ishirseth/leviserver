from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        subprocess.run(["/root/leviserver/deploy.sh"])
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Deployed")

if __name__ == "__main__":
    server = HTTPServer(('0.0.0.0', 7000), WebhookHandler)
    print("webhook listener running on port 7000")
    server.serve_forever()