wget -O /tmp/UnionStream.tar.gz https://github.com/Said-Pro/Union/raw/refs/heads/main/UnionStream.tar.gz
cd /tmp/
tar -xzf UnionStream.tar.gz -C /usr/lib/enigma2/python/Plugins/Extensions
rm -f /tmp/UnionStream.tar.gz
killall -9 enigma2
