"""Call Godot MCP tools from a shell, through the @npgamedev/godot-mcp-server bridge.

    python3 -I scripts/mcp_call.py --list
    python3 -I scripts/mcp_call.py scene_open '{"file_path": "res://scenes/main.tscn"}' scene_get_tree '{}'

Each tool name is followed by its JSON arguments. All calls share one MCP session, in
order. The bridge talks to the editor registered for this checkout's game/ (start one
with scripts/mcp-editor.sh start). Set GODOT_MCP_PROJECT_PATH to target another
project; it must be an absolute path. Bridge stderr goes to _scratch/mcp-server.log.
"""
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
project = os.environ.get("GODOT_MCP_PROJECT_PATH", os.path.join(ROOT, "game"))
env = dict(os.environ, GODOT_MCP_CONFIG_VERSION="1", GODOT_MCP_PROJECT_PATH=project)
os.makedirs(os.path.join(ROOT, "_scratch"), exist_ok=True)
stderr = open(os.path.join(ROOT, "_scratch", "mcp-server.log"), "a")
proc = subprocess.Popen(["npx", "-y", "@npgamedev/godot-mcp-server"], cwd=project, env=env,
                        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=stderr, text=True)
next_id = 0


def send(method, params=None, notify=False):
    global next_id
    msg = {"jsonrpc": "2.0", "method": method}
    if params is not None:
        msg["params"] = params
    if not notify:
        next_id += 1
        msg["id"] = next_id
    proc.stdin.write(json.dumps(msg) + "\n")
    proc.stdin.flush()
    if notify:
        return None
    while True:
        line = proc.stdout.readline()
        if not line:
            sys.exit("bridge exited; see _scratch/mcp-server.log")
        reply = json.loads(line)
        if reply.get("id") == next_id:
            return reply


send("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                    "clientInfo": {"name": "wasteland-academy-scripts", "version": "0"}})
send("notifications/initialized", notify=True)

failed = False
args = sys.argv[1:]
if args == ["--list"]:
    for tool in send("tools/list", {})["result"]["tools"]:
        print(tool["name"])
else:
    if len(args) % 2:
        sys.exit("usage: mcp_call.py --list | <tool> '<json args>' [<tool> '<json args>' ...]")
    for name, raw in zip(args[::2], args[1::2]):
        reply = send("tools/call", {"name": name, "arguments": json.loads(raw)})
        result = reply.get("result", reply)
        for part in result.get("content", []):
            print(part.get("text", part))
        if result.get("isError") or "error" in reply:
            failed = True
proc.stdin.close()
proc.wait(timeout=10)
sys.exit(1 if failed else 0)
