#!/usr/bin/env python3
"""Serve the Sunday Reset setup page on this computer and save the answers to config.json.

Usage: python3 setup_server.py [--folder "~/Documents/Sunday Reset"] [--no-open] [--timeout 2700]

- Serves web/index.html in setup mode at http://127.0.0.1:<random port>/?mode=setup&token=<random>
- Listens on 127.0.0.1 only. Saves require the one-time token, a JSON body under 256 KB, and a
  request from the page itself (Host and Origin must be this server).
- Writes config.json, or config.new.json if a config already exists (setup then asks which to keep).
- Prints SETUP_URL <url> on start, SAVED <path> [EXISTING] after a save, TIMEOUT if nobody finishes.
  Exits after a save or the timeout, so it can run in the background while Claude Code waits.
"""
import argparse, json, os, secrets, sys, threading, time, webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PAGE = Path(__file__).resolve().parent.parent / "web" / "index.html"
MAX_BODY = 256 * 1024


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--folder", default="~/Documents/Sunday Reset")
    ap.add_argument("--no-open", action="store_true")
    ap.add_argument("--timeout", type=int, default=2700)
    args = ap.parse_args()

    folder = Path(os.path.expanduser(args.folder))
    folder.mkdir(parents=True, exist_ok=True)
    token = secrets.token_urlsafe(24)
    html = PAGE.read_bytes()
    done = threading.Event()

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *a):  # keep the terminal quiet
            pass

        def _local_host(self):
            host = self.headers.get("Host", "")
            return host in (f"127.0.0.1:{port}", f"localhost:{port}")

        def _send(self, code, body, ctype="application/json"):
            data = body if isinstance(body, bytes) else json.dumps(body).encode()
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            self.wfile.write(data)

        def do_GET(self):
            if not self._local_host():
                return self._send(403, {"error": "wrong host"})
            if self.path.split("?")[0] in ("/", "/index.html"):
                return self._send(200, html, "text/html; charset=utf-8")
            return self._send(404, {"error": "not found"})

        def do_POST(self):
            if self.path != "/save" or not self._local_host():
                return self._send(403, {"error": "Not allowed."})
            origin = self.headers.get("Origin", "")
            if origin not in (f"http://127.0.0.1:{port}", f"http://localhost:{port}"):
                return self._send(403, {"error": "Saves must come from the setup page."})
            if not secrets.compare_digest(self.headers.get("X-Setup-Token", ""), token):
                return self._send(403, {"error": "This setup link has expired. Rerun /sunday-reset:setup."})
            length = int(self.headers.get("Content-Length", "0") or 0)
            if length <= 0 or length > MAX_BODY:
                return self._send(413, {"error": "Answers were empty or too large to save."})
            try:
                cfg = json.loads(self.rfile.read(length))
                email = cfg["user"]["email"].strip()
                assert "@" in email and "." in email.split("@")[-1]
            except Exception:
                return self._send(400, {"error": "Add a valid email address on the first step, then save again."})
            existing = (folder / "config.json").exists()
            target = folder / ("config.new.json" if existing else "config.json")
            tmp = target.with_suffix(".tmp")
            tmp.write_text(json.dumps(cfg, indent=2) + "\n")
            os.replace(tmp, target)
            shown = str(target).replace(str(Path.home()), "~", 1)
            self._send(200, {"path": shown, "existing": existing})
            print(f"SAVED {target}{' EXISTING' if existing else ''}", flush=True)
            done.set()

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    port = server.server_address[1]
    url = f"http://127.0.0.1:{port}/?mode=setup&token={token}"
    threading.Thread(target=server.serve_forever, daemon=True).start()
    print(f"SETUP_URL {url}", flush=True)
    if not args.no_open:
        try:
            webbrowser.open(url)
        except Exception:
            pass

    finished = done.wait(args.timeout)
    time.sleep(0.5)  # let the browser receive the response
    server.shutdown()
    if not finished:
        print("TIMEOUT", flush=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
