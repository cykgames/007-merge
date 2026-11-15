"""本地跑 Web 导出产物。

Web 版不能用 file:// 直接打开——Godot 的启动代码要 fetch() 去取 index.wasm 和
index.pck，而浏览器把 file:// 当成不透明源，这些请求会被 CORS 拦掉。

另外 Python 自带的 http.server 不一定认识 .wasm，会当 application/octet-stream
发出去，WebAssembly.instantiateStreaming 会直接失败，所以这里显式补上 MIME 类型。

用法（默认伺候 dist/web，端口 8123）:
    python tools/serve.py
    python tools/serve.py dist/web 9000
"""
import functools
import os
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

DEFAULT_ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                            "dist", "web")
DEFAULT_PORT = 8123


class Handler(SimpleHTTPRequestHandler):
    extensions_map = dict(SimpleHTTPRequestHandler.extensions_map)
    extensions_map.update({
        ".wasm": "application/wasm",
        ".js": "text/javascript",
        ".pck": "application/octet-stream",
    })

    def end_headers(self):
        # 开了 Thread Support 的话浏览器需要这两个头才给 SharedArrayBuffer；
        # 没开也无害，留着省事
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        SimpleHTTPRequestHandler.end_headers(self)

    def log_message(self, fmt, *args):
        sys.stderr.write("  %s\n" % (fmt % args))


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_ROOT
    port = int(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_PORT

    if not os.path.isdir(root):
        sys.exit("找不到目录 %s\n先导出：godot --headless --path . "
                 "--export-release \"Web\" dist/web/index.html" % root)
    if not os.path.exists(os.path.join(root, "index.html")):
        sys.exit("%s 里没有 index.html" % root)

    handler = functools.partial(Handler, directory=root)
    print("伺候 %s" % root)
    print("打开 http://localhost:%d/index.html  （Ctrl+C 停止）" % port)
    try:
        ThreadingHTTPServer(("127.0.0.1", port), handler).serve_forever()
    except KeyboardInterrupt:
        print("\n已停止")


if __name__ == "__main__":
    main()
