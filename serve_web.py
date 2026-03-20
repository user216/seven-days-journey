#!/usr/bin/env python3
"""Simple HTTP server with correct MIME types for Godot web export."""
import http.server
import sys

class GodotHTTPHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        '.wasm': 'application/wasm',
        '.pck': 'application/octet-stream',
        '.js': 'application/javascript',
    }

    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 9999
    server = http.server.HTTPServer(('0.0.0.0', port), GodotHTTPHandler)
    print(f'Serving Godot web export at http://localhost:{port}')
    server.serve_forever()
