#!/usr/bin/env python3
"""Writes ios/fastlane/metadata/<locale>/*.txt for every App Store locale.

Run from the repo root:  python3 tool/store_texts/generate.py
Validates Apple's limits (name and subtitle 30 characters, keywords 100
bytes, promotional text 170 characters, description 4000 characters) and
the house rule: no dashes as punctuation.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from texts_a import GROUP_A  # noqa: E402
from texts_b import GROUP_B  # noqa: E402
from texts_c import GROUP_C  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "ios", "fastlane", "metadata")

SITE = "https://caspar-baumeister.github.io/pixi/"
URLS = {
    "support_url": SITE + "support.html",
    "marketing_url": SITE,
    "privacy_url": SITE + "privacy.html",
}
TERMS_URL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
MAIL = "caspar.baumeister.dev@gmail.com"

FORBIDDEN = ["–", "—", " - ", "‒", "―"]


def colon(locale):
    if locale.startswith(("ja", "zh")):
        return "："
    if locale.startswith("fr"):
        return " : "
    return ": "


def bullets(items):
    return "\n".join("• " + x for x in items)


def description(locale, d):
    c = colon(locale)
    parts = [
        d["intro"],
        d["about"],
        d["h_q"] + "\n" + bullets(d["q"]),
        d["h_t"] + "\n" + bullets(d["t"]),
        d["h_s"] + "\n" + bullets(d["s"]),
        d["h_p"] + "\n" + bullets(d["p"]),
        d["h_priv"] + "\n" + bullets(d["priv"]),
        d["h_prem"] + "\n" + d["prem1"] + "\n" + d["prem2"],
        d["terms"] + c + TERMS_URL + "\n" + d["privacy"] + c + URLS["privacy_url"],
    ]
    contact = d["contact"]
    sep = "" if contact.endswith("：") else " "
    parts.append(contact + sep + MAIL)
    return "\n\n".join(parts)


def fit_keywords(kw):
    terms = [t.strip() for t in kw.split(",") if t.strip()]
    dropped = []
    while len(",".join(terms).encode("utf-8")) > 100:
        dropped.append(terms.pop())
    return ",".join(terms), dropped


def main():
    locales = {}
    for g in (GROUP_A, GROUP_B, GROUP_C):
        for k, v in g.items():
            assert k not in locales, k
            locales[k] = v
    errors = []
    report = []
    for loc, d in sorted(locales.items()):
        name, sub = d["name"], d["subtitle"]
        kw, dropped = fit_keywords(d["keywords"])
        promo = d["promo"]
        desc = description(loc, d)
        if len(name) > 30:
            errors.append(f"{loc}: name {len(name)} > 30: {name}")
        if len(sub) > 30:
            errors.append(f"{loc}: subtitle {len(sub)} > 30: {sub}")
        if len(promo) > 170:
            errors.append(f"{loc}: promo {len(promo)} > 170")
        if len(desc) > 4000:
            errors.append(f"{loc}: description {len(desc)} > 4000")
        for field, text in (("name", name), ("subtitle", sub), ("keywords", kw),
                            ("promo", promo), ("description", desc)):
            for f in FORBIDDEN:
                if f in text:
                    errors.append(f"{loc}: {field} contains dash {f!r}")
        files = {
            "name.txt": name,
            "subtitle.txt": sub,
            "keywords.txt": kw,
            "promotional_text.txt": promo,
            "description.txt": desc,
            **{k + ".txt": v for k, v in URLS.items()},
        }
        folder = os.path.join(OUT, loc)
        os.makedirs(folder, exist_ok=True)
        for fn, text in files.items():
            with open(os.path.join(folder, fn), "w", encoding="utf-8") as fh:
                fh.write(text + "\n")
        report.append(
            f"{loc:8} name {len(name):2}  sub {len(sub):2}  kw {len(kw.encode()):3}B"
            f"  promo {len(promo):3}  desc {len(desc):4}"
            + (f"  dropped kw: {','.join(dropped)}" if dropped else "")
        )
    print("\n".join(report))
    print(f"\n{len(locales)} locales written to {OUT}")
    if errors:
        print("\nERRORS:")
        print("\n".join(errors))
        sys.exit(1)


if __name__ == "__main__":
    main()
