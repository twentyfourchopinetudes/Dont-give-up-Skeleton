# Rebuild script sources dumped out of the open Studio session (execute_luau results saved by the harness as text
# files: "@@@@BEGIN <name> <part> <total> <len> <sum>\n<chunk>\n@@@@STOP\n<padding>") and write them into src/.
# Every chunk is checked against the length and checksum Studio computed, so a mangled byte is caught, not written.
import glob, os, re, sys

RES = sys.argv[1]  # the folder the harness saves large tool results in
DEST = {
    "OssariaHeir": "src/ReplicatedStorage/Characters/OssariaHeir.luau",
    "Ossaria": "src/ServerScriptService/GameServer/Ossaria.luau",
    "OssariaMoves": "src/ServerScriptService/GameServer/OssariaMoves.luau",
    "SoulsClient": "src/StarterPlayer/StarterPlayerScripts/SoulsClient.client.luau",
}
since = float(sys.argv[2]) if len(sys.argv) > 2 else 0
parts = {}
for path in sorted(glob.glob(os.path.join(RES, "mcp-Roblox_Studio-execute_luau-*.txt")), key=os.path.getmtime):
    if os.path.getmtime(path) < since:
        continue
    data = open(path, "rb").read()
    m = re.match(rb"@@@@BEGIN (\S+) (\d+) (\d+) (\d+) (\d+)\r?\n", data)
    if not m:
        continue
    name, part, total, ln, want = m.group(1).decode(), int(m.group(2)), int(m.group(3)), int(m.group(4)), int(m.group(5))
    body = data[m.end():]
    stop = body.rfind(b"\n@@@@STOP")
    chunk = body[:stop].replace(b"\r\n", b"\n") if b"\r\n" in body[:stop] and len(body[:stop]) != ln else body[:stop]
    s = 0
    for i, c in enumerate(chunk, 1):
        s = (s + c * (i % 251 + 1)) % 1000000007
    ok = len(chunk) == ln and s == want
    print(f"{name} part {part}: {len(chunk)}/{ln} bytes, checksum {'ok' if ok else 'MISMATCH'}")
    if not ok:
        sys.exit("chunk does not match what Studio sent: nothing written")
    parts.setdefault(name, {})[part] = (total, chunk)
for name, ps in parts.items():
    src = b"".join(ps[k][1] for k in sorted(ps))
    total = next(iter(ps.values()))[0]
    if len(src) != total:
        sys.exit(f"{name}: have {len(src)} of {total} bytes: nothing written")
    dest = DEST.get(name, name)  # (a name above, or a path under the repo)
    old = open(dest, "rb").read() if os.path.exists(dest) else b""
    nl = b"\r\n" if b"\r\n" in old else b"\n"
    out = src.replace(b"\r\n", b"\n").replace(b"\n", nl)
    open(dest, "wb").write(out)
    print(f"wrote {dest} ({len(out)} bytes, was {len(old)})")
