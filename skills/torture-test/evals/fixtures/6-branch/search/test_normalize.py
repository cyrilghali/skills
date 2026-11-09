from normalize import normalize


def test_normalize():
    assert normalize("  Hello   World ") == "hello world"
