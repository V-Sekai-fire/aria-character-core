#!/bin/bash
# Search for digest/hash related files and functions
echo "=== Files containing 'digest' or 'hash' ==="
find /Users/setup/Developer/aria-character-core/thirdparty/desync -name "*.go" | xargs grep -l -i "digest\|hash" | head -10

echo "=== Looking for Digest variable definition ==="
find /Users/setup/Developer/aria-character-core/thirdparty/desync -name "*.go" -exec grep -n "var.*Digest" {} \; 2>/dev/null

echo "=== Looking for chunk ID calculation ==="
find /Users/setup/Developer/aria-character-core/thirdparty/desync -name "*.go" -exec grep -n -A5 -B5 "func.*ID()" {} \; 2>/dev/null

echo "=== Looking for NewChunk function ==="
find /Users/setup/Developer/aria-character-core/thirdparty/desync -name "*.go" -exec grep -n -A10 "func NewChunk" {} \; 2>/dev/null