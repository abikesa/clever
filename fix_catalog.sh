#!/bin/bash

INPUT="index.html"
OUTPUT="cleaned_index.html"
TMP_LINKS="links.json"

# Extract all markdown-style links from messy HTML
grep -oP '\[[^\]]+\]\(https?://[^)]+\)' "$INPUT" | \
  sed -E 's/\[([^\]]+)\]\((https?:\/\/[^)]+)\)/{"name": "\1", "url": "\2"},/' > "$TMP_LINKS"

# Remove trailing comma from last object
sed -i '$ s/},$/}/' "$TMP_LINKS"

# Wrap in a valid JS const
echo "const links = [" > links_block.js
cat "$TMP_LINKS" >> links_block.js
echo "];" >> links_block.js

# Inject cleaned JS into HTML
awk '
  BEGIN { inside_script = 0 }
  /<script>/ { print; print_file = 1; next }
  /<\/script>/ {
    if (print_file) {
      while ((getline line < "links_block.js") > 0) print line;
      print_file = 0;
    }
    print;
    next;
  }
  {
    if (!print_file) print;
  }
' "$INPUT" > "$OUTPUT"

# Cleanup
rm "$TMP_LINKS" links_block.js

echo "✅ Cleaned HTML saved as $OUTPUT"
