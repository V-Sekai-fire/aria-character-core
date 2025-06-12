#!/bin/bash
# Search for Digest definition in desync codebase
echo "Searching for Digest definition in desync codebase..."
find /Users/setup/Developer/aria-character-core/thirdparty/desync -name "*.go" -exec grep -l "var Digest" {} \;
find /Users/setup/Developer/aria-character-core/thirdparty/desync -name "*.go" -exec grep -l "Digest.*=" {} \;
echo "---"
echo "Searching for Digest usage patterns..."
find /Users/setup/Developer/aria-character-core/thirdparty/desync -name "*.go" -exec grep -n "Digest\." {} \;