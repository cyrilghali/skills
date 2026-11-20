from leaderboard import top_player


def test_single_leader():
    assert top_player({"ana": 3, "bob": 9, "cy": 1}) == "bob"


def test_tie_goes_to_first_name():
    assert top_player({"dana": 4, "bob": 7, "carol": 7}) == "bob"


if __name__ == "__main__":
    for name, fn in list(globals().items()):
        if name.startswith("test_"):
            fn()
            print("ok", name)
