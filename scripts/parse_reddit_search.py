import json
import re
from pathlib import Path

queries = [
    Path(r"C:\Users\hesam\Downloads\agent-tools\568e292a-e971-47fb-89c6-a29d0af5c717.txt"),
    Path(r"C:\Users\hesam\Downloads\agent-tools\41e67ec6-fd65-40cf-92a4-639e9989811f.txt"),
    Path(r"C:\Users\hesam\Downloads\agent-tools\f2c8e923-6912-4b22-b284-fd49c616a629.txt"),
    Path(r"C:\Users\hesam\Downloads\agent-tools\cc7e05c1-d22f-42f6-a279-e2980a175768.txt"),
]
keywords = re.compile(r"fa506iv|attestation|ftpm|tpm|bios|warzone|pa-420|3\.42", re.I)
seen = set()
for p in queries:
    if not p.exists():
        continue
    data = json.loads(p.read_text(encoding="utf-8")).get("data", [])
    for item in data:
        text = " ".join([item.get("title", ""), item.get("selftext", ""), item.get("subreddit", "")])
        if keywords.search(text):
            key = item.get("permalink", "")
            if key in seen:
                continue
            seen.add(key)
            print(
                f"{item.get('subreddit_name_prefixed')} | {item.get('title')} | "
                f"https://www.reddit.com{key} | comments:{item.get('num_comments')}"
            )