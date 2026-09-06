import re

path = r'C:\Users\f.migone\Desktop\projects\actif\anstat-microsim\00_documentation\working_paper\DT_CEQ_CIV2021.tex'

with open(path, 'rb') as f:
    raw = f.read()

# Fix double utf-8 encoding byte by byte
try:
    # Decode as UTF-8, then re-encode any latin1 mojibake sequences
    s = raw.decode('utf-8')
    # Replace common double-encoded utf-8 byte sequences
    fixed = s.encode('raw_unicode_escape').decode('utf-8', errors='ignore')
except Exception as e:
    print("Error:", e)

# Safer string replacement map for French accented characters
replacements = [
    ('Ã©', 'é'), ('Ã¨', 'è'), ('Ã\xa0', 'à'), ('Ã´', 'ô'), ('Ãª', 'ê'), ('Ã¢', 'â'),
    ('Ã®', 'î'), ('Ã¯', 'ï'), ('Ã¹', 'ù'), ('Ã»', 'û'), ('Ã§', 'ç'), ('Ã‰', 'É'),
    ('Ã€', 'À'), ('Ãˆ', 'È'), ('ÃŠ', 'Ê'), ('Ã”', 'Ô'), ('Ã‡', 'Ç'), ('â€™', '’'),
    ('â€“', '–'), ('â€”', '—'), ('Â\xa0', ' '), ('Â', '')
]

with open(path, 'r', encoding='utf-8', errors='ignore') as f:
    text = f.read()

for orig, sub in replacements:
    text = text.replace(orig, sub)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Encoding successfully repaired!")
