# slugify

Turns each line of stdin into a URL slug: accents stripped, lowercase, runs of other characters collapsed to one hyphen.

```
$ printf 'Crème Brûlée!\nHello,   World\n' | python3 slugify.py
creme-brulee
hello-world
```

Characters with no ASCII equivalent (`日本`, `€`) are dropped, so a line made only of them becomes an empty slug.

## How do I run it?

Python 3.8+, no dependencies: `python3 slugify.py < titles.txt`.

## License

MIT.
