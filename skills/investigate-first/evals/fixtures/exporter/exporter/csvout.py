def quote(value):
    text = str(value)
    if any(ch in text for ch in [",", '"', "\n"]):
        return '"' + text.replace('"', '""') + '"'
    return text


def row(fields):
    return ",".join(quote(f) for f in fields)
