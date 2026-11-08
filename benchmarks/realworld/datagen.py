"""Deterministic input documents for the jq and libxml2 workloads.

  datagen.py json <records> > data.json   (array of person-like records)
  datagen.py xml <items> > data.xml       (catalog with attributes, text, CDATA)

The output depends only on the arguments (fixed random seed).
"""
import json
import random
import sys


def main():
    kind, n = sys.argv[1], int(sys.argv[2])
    rnd = random.Random(1)
    syll = ["ka", "lo", "mi", "ne", "ru", "sa", "to", "vi", "ze", "po", "an", "el"]
    words = ["".join(rnd.choice(syll) for _ in range(rnd.randint(1, 4)))
             for _ in range(5000)]
    cities = ["Aberdeen", "Bergen", "Cork", "Delft", "Esbjerg", "Faro", "Genoa", "Hull"]
    out = sys.stdout
    if kind == "json":
        data = [{"id": i, "name": f"{rnd.choice(words)} {rnd.choice(words)}",
                 "age": rnd.randint(18, 90), "city": rnd.choice(cities),
                 "score": round(rnd.random() * 100, 3),
                 "tags": [rnd.choice(words) for _ in range(rnd.randint(0, 5))],
                 "active": rnd.random() < 0.7} for i in range(n)]
        json.dump(data, out)
    elif kind == "xml":
        out.write('<?xml version="1.0" encoding="UTF-8"?>\n<catalog>\n')
        for i in range(n):
            out.write(f'  <item id="{i}" kind="{rnd.choice("abc")}" '
                      f'city="{rnd.choice(cities)}">\n')
            out.write(f"    <name>{rnd.choice(words)} {rnd.choice(words)}</name>\n")
            out.write(f'    <price currency="EUR">{rnd.random() * 500:.2f}</price>\n')
            out.write(f"    <tags>{' '.join(rnd.choice(words) for _ in range(4))}</tags>\n")
            out.write("    <note><![CDATA[" +
                      " ".join(rnd.choice(words) for _ in range(8)) + "]]></note>\n")
            out.write("  </item>\n")
        out.write("</catalog>\n")
    else:
        sys.exit(f"unknown kind {kind}")


if __name__ == "__main__":
    main()
