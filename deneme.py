import csv
import json

with open('hadiths_example.csv', newline='', encoding='utf-8') as infile, \
     open('duzgun.csv', 'w', newline='', encoding='utf-8') as outfile:
    reader = csv.DictReader(infile)
    fieldnames = reader.fieldnames
    writer = csv.DictWriter(outfile, fieldnames=fieldnames)
    writer.writeheader()
    for row in reader:
        for key in ['tags', 'narrator_chain', 'related_ayah']:
            val = row.get(key, "")
            if val.strip() == "" or val.strip() == "[]":
                row[key] = ""
            else:
                try:
                    # Python listesi gibi ise düzelt
                    parsed = eval(val) if val.startswith("[") else [val]
                    row[key] = json.dumps(parsed, ensure_ascii=False)
                except:
                    row[key] = json.dumps([val], ensure_ascii=False)
        writer.writerow(row)