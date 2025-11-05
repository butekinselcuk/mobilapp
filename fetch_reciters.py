import json

with open('cdn_surah_audio.json', encoding='utf-8') as f:
    data = json.load(f)

sql_lines = []
for reciter in data:
    reciter_id = reciter['identifier'].replace("'", "''")
    name = reciter.get('englishName', '').replace("'", "''")
    description = reciter.get('name', '').replace("'", "''")
    sql = f"INSERT INTO reciters (id, name, description) VALUES ('{reciter_id}', '{name}', '{description}');"
    sql_lines.append(sql)

with open('reciters_full_inserts.sql', 'w', encoding='utf-8') as f:
    f.write('\n'.join(sql_lines))

print('Full reciter SQL insert statements written to reciters_full_inserts.sql') 