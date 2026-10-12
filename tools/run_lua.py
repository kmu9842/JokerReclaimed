"""Run LuaJIT checks using Balatro's own installed lua51.dll (no extra runtime)."""
import argparse
import ctypes
import os
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('scripts', nargs='*')
parser.add_argument('--syntax', action='store_true')
parser.add_argument('--game-dir', default=r'E:\SteamLibrary\steamapps\common\Balatro')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
os.chdir(root)
lua = ctypes.CDLL(str(Path(args.game_dir) / 'lua51.dll'))
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate()
lua.luaL_openlibs(state)
files = list(root.joinpath('JokerReclaimed').rglob('*.lua')) if args.syntax else [Path(p) for p in args.scripts]
try:
    for path in files:
        status = lua.luaL_loadfile(state, str(path).encode())
        if not status and not args.syntax:
            status = lua.lua_pcall(state, 0, 0, 0)
        if status:
            raise SystemExit(lua.lua_tolstring(state, -1, None).decode('utf-8', errors='replace'))
        lua.lua_settop(state, 0)
    print(f'PASS: {len(files)} LuaJIT ' + ('syntax checks' if args.syntax else 'test scripts'))
finally:
    lua.lua_close(state)
