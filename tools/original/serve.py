"""Static server for the js-dos page plus POST /upload?name=X to save recorded frames.

Bound to 127.0.0.1 only. Usage: python3 -I serve.py <webroot> <outdir> <port>
"""
import http.server
import os
import sys
import urllib.parse

WEB, OUT, PORT = sys.argv[1], sys.argv[2], int(sys.argv[3])


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=WEB, **k)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_POST(self):
        q = urllib.parse.urlparse(self.path)
        name = urllib.parse.parse_qs(q.query).get("name", ["x.bin"])[0]
        name = os.path.basename(name)
        n = int(self.headers.get("Content-Length", "0"))
        data = self.rfile.read(n)
        with open(os.path.join(OUT, name), "wb") as f:
            f.write(data)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, *a):
        pass


http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
