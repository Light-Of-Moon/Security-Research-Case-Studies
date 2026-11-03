"""Loopback-only lab UI publisher; forwards bytes without inspecting them."""
import os
import selectors
import socket
import threading

LISTEN = int(os.getenv("LISTEN_PORT", "8080"))
UPSTREAM = (os.getenv("UPSTREAM_HOST", "waf"), int(os.getenv("UPSTREAM_PORT", "8080")))


def bridge(client):
    upstream = socket.create_connection(UPSTREAM, timeout=10)
    client.setblocking(False)
    upstream.setblocking(False)
    selector = selectors.DefaultSelector()
    selector.register(client, selectors.EVENT_READ, upstream)
    selector.register(upstream, selectors.EVENT_READ, client)
    try:
        while selector.get_map():
            for key, _ in selector.select(timeout=30):
                data = key.fileobj.recv(65536)
                if not data:
                    return
                key.data.sendall(data)
    finally:
        selector.close()
        client.close()
        upstream.close()


with socket.create_server(("0.0.0.0", LISTEN)) as server:
    while True:
        connection, _ = server.accept()
        threading.Thread(target=bridge, args=(connection,), daemon=True).start()
