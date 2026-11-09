#!/usr/bin/env python3
"""PreToolUse guard for roast critics: they read and observe, never change state.

Two layers. File writes are left to the operating system: on macOS every Bash command
runs inside sandbox-exec, which allows writes only under temp folders, a .roast/ run
folder and tool caches, whatever program makes them. Network and account actions
cannot be told apart from reads at that level, so the command is parsed to deny
sends, pushes, POST-style requests and account or network switches.
"""
import json
import os
import re
import shlex
import shutil
import sys

SANDBOX_PROFILE = """(version 1)
(allow default)
(deny file-write*)
(allow file-write*
  (subpath "/private/tmp") (subpath "/private/var/folders") (subpath "/dev")
  (regex #"/\\.roast/")
  (subpath (param "CACHE")) (subpath (param "NPM")))"""

SEPARATORS = {";", "&&", "||", "|", "&", "(", ")", "()", "|&", ";;"}
SUBSTITUTIONS = re.compile(r"\$\(([^()]*)\)|`([^`]*)`|[<>]\(([^()]*)\)")
HEREDOC = re.compile(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")
KEYWORDS = {"if", "then", "else", "elif", "fi", "do", "done", "while", "until", "for",
            "!", "{", "}", "case", "esac", "select", "function"}
WRAPPERS = {"sudo", "command", "env", "nice", "nohup", "time", "exec", "builtin", "timeout", "xargs"}
WRAPPER_VALUE_FLAGS = {"sudo": {"-u", "-g", "-p", "-C", "-U", "-h", "-r", "-t"},
                       "timeout": {"-s", "-k", "--signal", "--kill-after"},
                       "nice": {"-n"}, "env": {"-u", "-C", "-S"}, "xargs": {"-I", "-n", "-P", "-L", "-d", "-E"}}
DENIED_TOOLS = {"sandbox-exec", "open", "op", "ssh", "scp", "sftp", "rsync", "osascript", "sendmail", "mail", "mailx",
                "kubectl", "fly", "flyctl", "vercel", "wrangler", "terraform", "networksetup",
                "shutdown", "reboot", "defaults", "security", "crontab", "kill", "pkill", "killall"}
GIT_NETWORK_WRITES = {"push", "send-email", "request-pull"}
READ_METHODS = {"GET", "HEAD", "OPTIONS"}


class Denied(Exception):
    pass


def inside_quotes(line, pos):
    quote = None
    for ch in line[:pos]:
        if quote:
            quote = None if ch == quote else quote
        elif ch in "'\"":
            quote = ch
    return quote is not None


def split_heredocs(command):
    """Joins lines with ';' so every line is checked; heredoc bodies are data, except
    that an unquoted body still expands $(...) and backticks."""
    kept, expanded, ending, quoted = [], [], None, False
    for line in command.split("\n"):
        if ending is not None:
            if line.strip() == ending:
                ending = None
            elif not quoted:
                expanded.append(line)
            continue
        kept.append(line)
        found = [(m.group(1), m.group(2)) for m in HEREDOC.finditer(line) if not inside_quotes(line, m.start())]
        if found:
            quoted, ending = bool(found[-1][0]), found[-1][1]
    return " ; ".join(kept), "\n".join(expanded)


def commands_in(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()<>")
    lexer.whitespace_split = True
    lexer.commenters = "#"
    try:
        tokens = list(lexer)
    except ValueError:
        raise Denied("a command the guard cannot parse")
    current, i = [], 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in SEPARATORS:
            if current:
                yield current
            current = []
        elif set(tok) <= set("<>&0123456789") and any(c in tok for c in "<>"):
            i += 1
        else:
            current.append(tok)
        i += 1
    if current:
        yield current


def strip_prefixes(argv):
    while argv:
        head = os.path.basename(argv[0])
        if argv[0] in KEYWORDS or ("=" in argv[0] and argv[0].split("=", 1)[0].isidentifier()):
            argv = argv[1:]
        elif head in WRAPPERS:
            argv = argv[1:]
            while argv and (argv[0].startswith("-") or ("=" in argv[0] and argv[0].split("=", 1)[0].isidentifier())):
                argv = argv[2:] if argv[0] in WRAPPER_VALUE_FLAGS.get(head, set()) else argv[1:]
            if head == "timeout" and argv:
                argv = argv[1:]
        elif head in {"npx", "bunx", "pnpx"}:
            argv = [a for a in argv[1:] if not a.startswith("-")]
        else:
            return argv
    return argv


def short_flags(args):
    """Yields (letter, attached_value, next_arg) for each letter of each -abc cluster."""
    for j, a in enumerate(args):
        if a.startswith("-") and not a.startswith("--") and len(a) > 1:
            for k, letter in enumerate(a[1:], start=1):
                yield letter, a[k + 1:], args[j + 1] if j + 1 < len(args) else ""


def check_http(name, args):
    for letter, attached, nxt in short_flags(args):
        if name == "curl" and letter == "X" and (attached or nxt).upper() not in READ_METHODS:
            raise Denied(f"curl -X {(attached or nxt).upper()}")
        if name == "curl" and letter in "dFT":
            raise Denied(f"curl -{letter}, which sends a body")
    for j, a in enumerate(args):
        if a.startswith(("--data", "--json", "--form", "--upload-file", "--post-", "--body-", "--method=")) \
                and not a.upper().endswith(("=GET", "=HEAD")):
            raise Denied(f"{name} {a.split('=')[0]}")
        if a in {"--request", "--method"} and j + 1 < len(args) and args[j + 1].upper() not in READ_METHODS:
            raise Denied(f"{name} {a} {args[j + 1]}")


def check_gh(args):
    area, action = (args + ["", ""])[:2]
    if area in {"pr", "issue"} and action not in {"view", "list", "diff", "status", "checks", ""}:
        raise Denied(f"gh {area} {action}")
    if area in {"release", "repo", "secret", "variable", "workflow", "run", "label", "gist", "ruleset", "cache", "auth"} \
            and action not in {"view", "list", "ls", "status", "diff", "watch", ""}:
        raise Denied(f"gh {area} {action}")
    if area == "api":
        rest = args[1:]
        method = "GET"
        for letter, attached, nxt in short_flags(rest):
            if letter == "X":
                method = (attached or nxt).upper()
            elif letter in "fF" and method == "GET":
                method = "POST"
        for j, a in enumerate(rest):
            if a == "--method" and j + 1 < len(rest):
                method = rest[j + 1].upper()
            elif a.startswith("--method="):
                method = a.split("=", 1)[1].upper()
            elif a in {"--field", "--raw-field", "--input"} and method == "GET":
                method = "POST"
        if "graphql" in rest:
            if any("mutation" in a for a in rest):
                raise Denied("a GraphQL mutation")
        elif method not in READ_METHODS:
            raise Denied(f"gh api {method}")


def check_argv(argv):
    argv = strip_prefixes(argv)
    if not argv:
        return
    if "$" in argv[0] or "`" in argv[0]:
        raise Denied("a command name the guard cannot see")
    name, args = os.path.basename(argv[0]), argv[1:]
    if name in {"sh", "bash", "zsh", "dash"} and "-c" in args:
        idx = args.index("-c")
        if idx + 1 < len(args):
            check_command(args[idx + 1])
        return
    if name == "eval":
        check_command(" ".join(args))
        return
    if name in DENIED_TOOLS:
        raise Denied(name)
    if name in {"docker", "podman"} and args[:1] and args[0] not in {"ps", "images", "inspect", "logs", "version", "info"}:
        raise Denied(f"{name} {args[0]}, whose daemon runs outside the sandbox")
    if name == "tailscale" and args[:1] and args[0] in {"up", "down", "switch", "login", "logout", "set", "serve", "funnel", "cert"}:
        raise Denied(f"tailscale {args[0]}")
    if name == "scutil" and "--set" in args:
        raise Denied("scutil --set")
    if name == "launchctl" and args[:1] and args[0] not in {"list", "print", "print-disabled", "blame", "help"}:
        raise Denied(f"launchctl {args[0]}")
    if name in {"npm", "pnpm", "yarn", "cargo", "mix", "gem", "twine", "poetry", "hex"} and "publish" in args:
        raise Denied(f"{name} publish")
    if name == "docker" and args[:1] and args[0] in {"push", "login"}:
        raise Denied(f"docker {args[0]}")
    if name == "git":
        i = 0
        while i < len(args) and args[i].startswith("-"):
            i += 2 if args[i] in {"-C", "-c", "--git-dir", "--work-tree", "--namespace"} else 1
        if i < len(args) and args[i] in GIT_NETWORK_WRITES:
            raise Denied(f"git {args[i]}")
    elif name == "gh":
        check_gh(args)
    elif name in {"curl", "wget", "http", "https", "xh"}:
        check_http(name, args)


def check_command(command):
    command, heredoc_text = split_heredocs(command)
    for text in (command, heredoc_text):
        for match in SUBSTITUTIONS.finditer(text):
            check_command(next(g for g in match.groups() if g is not None))
    for argv in commands_in(SUBSTITUTIONS.sub("$SUB", command)):
        check_argv(argv)


def temp_path(path, cwd):
    full = os.path.realpath(os.path.join(cwd, os.path.expandvars(os.path.expanduser(path))))
    roots = ["/private/tmp", "/private/var/folders"]
    if os.environ.get("TMPDIR"):
        roots.append(os.path.realpath(os.environ["TMPDIR"]))
    return "$" not in full and (".roast" in full.split(os.sep) or any(full == r or full.startswith(r + "/") for r in roots))


def sandboxed(command):
    home = os.path.expanduser("~")
    return " ".join(shlex.quote(p) for p in [
        "sandbox-exec", "-D", f"CACHE={home}/Library/Caches", "-D", f"NPM={home}/.npm",
        "-p", SANDBOX_PROFILE, "/usr/bin/env", "ROAST_SANDBOXED=1", "UV_CACHE_DIR=/private/tmp/roast-uv-cache", "/bin/bash", "-c", command])


def decide(data):
    tool, tool_input = data.get("tool_name", ""), data.get("tool_input") or {}
    if tool in {"Write", "Edit", "MultiEdit", "NotebookEdit"}:
        path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
        if not temp_path(path, data.get("cwd") or os.getcwd()):
            raise Denied(f"writing {path}, outside a scratch folder")
        return None
    if tool != "Bash":
        return None
    command = tool_input.get("command", "")
    check_command(command)
    if shutil.which("sandbox-exec"):
        return {**tool_input, "command": sandboxed(command)}
    return None


def main():
    try:
        updated = decide(json.load(sys.stdin))
    except Denied as why:
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": f"Roast critics only read and observe: {why}. Report the claim as unverified instead.",
        }}))
        return
    # No permission decision: the host's own permission check still judges what the parser cannot see.
    if updated:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "updatedInput": updated}}))


if __name__ == "__main__":
    main()
