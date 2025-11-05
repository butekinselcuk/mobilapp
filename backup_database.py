#!/usr/bin/env python3
"""
İslami App Veritabanı Backup Scripti
Bu script veritabanının tam backup'ını alır ve CSV dosyalarını da yedekler.

Kullanım:
    python backup_database.py
    python backup_database.py --output-dir ./backups
    python backup_database.py --tables-only
    python backup_database.py --data-only
"""

import os
import sys
import subprocess
import datetime
import argparse
import shutil
from pathlib import Path

def get_database_url():
    """Environment'tan veritabanı URL'ini al"""
    # Backend .env dosyasından DATABASE_URL'i oku
    env_path = Path('backend/.env')
    if env_path.exists():
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith('DATABASE_URL='):
                    return line.split('=', 1)[1].strip().strip('"\'')
    
    # Varsayılan değer
    return 'postgresql://postgres:postgres@localhost:5432/imanapp'

def parse_database_url(db_url):
    """Database URL'ini parse et"""
    # postgresql://user:password@host:port/database
    if '://' in db_url:
        db_url = db_url.split('://', 1)[1]
    
    if '@' in db_url:
        auth, host_db = db_url.split('@', 1)
        if ':' in auth:
            user, password = auth.split(':', 1)
        else:
            user, password = auth, ''
    else:
        user, password = 'postgres', 'postgres'
        host_db = db_url
    
    if '/' in host_db:
        host_port, database = host_db.split('/', 1)
    else:
        host_port, database = host_db, 'imanapp'
    
    if ':' in host_port:
        host, port = host_port.split(':', 1)
    else:
        host, port = host_port, '5432'
    
    return {
        'host': host,
        'port': port,
        'user': user,
        'password': password,
        'database': database
    }

def run_pg_dump(db_config, output_file, options=None):
    """pg_dump komutunu çalıştır"""
    cmd = [
        'pg_dump',
        '-h', db_config['host'],
        '-p', db_config['port'],
        '-U', db_config['user'],
        '-d', db_config['database'],
        '-f', str(output_file)
    ]
    
    if options:
        cmd.extend(options)
    
    # Password'u environment variable olarak ayarla
    env = os.environ.copy()
    if db_config['password']:
        env['PGPASSWORD'] = db_config['password']
    
    try:
        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Backup başarıyla oluşturuldu: {output_file}")
            return True
        else:
            print(f"❌ Backup hatası: {result.stderr}")
            return False
    except FileNotFoundError:
        print("❌ pg_dump komutu bulunamadı. PostgreSQL client tools yüklü olduğundan emin olun.")
        return False
    except Exception as e:
        print(f"❌ Backup hatası: {e}")
        return False

def backup_csv_files(output_dir):
    """CSV dosyalarını backup klasörüne kopyala"""
    csv_files = [
        'backend/hadith_big_example.csv',
        'backend/hadith_example.csv',
        'backend/journey_module_example.csv',
        'duzgun.csv',
        'hadiths_example.csv'
    ]
    
    csv_backup_dir = output_dir / 'csv_data'
    csv_backup_dir.mkdir(exist_ok=True)
    
    for csv_file in csv_files:
        csv_path = Path(csv_file)
        if csv_path.exists():
            shutil.copy2(csv_path, csv_backup_dir / csv_path.name)
            print(f"✅ CSV kopyalandı: {csv_file}")
        else:
            print(f"⚠️  CSV dosyası bulunamadı: {csv_file}")

def backup_sql_files(output_dir):
    """SQL dosyalarını backup klasörüne kopyala"""
    sql_files = [
        'database_backup.sql',
        'reciters_inserts.sql',
        'reciters_full_inserts.sql',
        'drop_all.sql'
    ]
    
    sql_backup_dir = output_dir / 'sql_scripts'
    sql_backup_dir.mkdir(exist_ok=True)
    
    for sql_file in sql_files:
        sql_path = Path(sql_file)
        if sql_path.exists():
            shutil.copy2(sql_path, sql_backup_dir / sql_path.name)
            print(f"✅ SQL kopyalandı: {sql_file}")
        else:
            print(f"⚠️  SQL dosyası bulunamadı: {sql_file}")

def backup_alembic_migrations(output_dir):
    """Alembic migration dosyalarını backup'la"""
    migrations_dir = Path('alembic/versions')
    if migrations_dir.exists():
        backup_migrations_dir = output_dir / 'alembic_migrations'
        shutil.copytree(migrations_dir, backup_migrations_dir, dirs_exist_ok=True)
        print(f"✅ Alembic migrations kopyalandı")
    else:
        print(f"⚠️  Alembic migrations bulunamadı")

def create_backup_info(output_dir, db_config):
    """Backup bilgi dosyası oluştur"""
    info_content = f"""İslami App Veritabanı Backup Bilgileri
=============================================

Backup Tarihi: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Veritabanı: {db_config['database']}
Host: {db_config['host']}:{db_config['port']}
Kullanıcı: {db_config['user']}

Dosyalar:
---------
- full_backup.sql: Tam veritabanı backup'ı (şema + veri)
- schema_only.sql: Sadece tablo yapıları
- data_only.sql: Sadece veriler
- csv_data/: CSV veri dosyaları
- sql_scripts/: SQL script dosyaları
- alembic_migrations/: Migration dosyaları

Restore Talimatları:
-------------------
1. Yeni veritabanı oluşturun:
   CREATE DATABASE imanapp;

2. Full backup'ı restore edin:
   psql -h {db_config['host']} -p {db_config['port']} -U {db_config['user']} -d {db_config['database']} -f full_backup.sql

3. Veya sadece şemayı restore edip CSV'lerden veri yükleyin:
   psql -h {db_config['host']} -p {db_config['port']} -U {db_config['user']} -d {db_config['database']} -f schema_only.sql
   python backend/hadith_loader.py csv_data/hadith_big_example.csv

4. Alembic migration'ları çalıştırın:
   cd backend
   alembic upgrade head
"""
    
    info_file = output_dir / 'backup_info.txt'
    with open(info_file, 'w', encoding='utf-8') as f:
        f.write(info_content)
    
    print(f"✅ Backup bilgileri oluşturuldu: {info_file}")

def main():
    parser = argparse.ArgumentParser(description='İslami App Veritabanı Backup Scripti')
    parser.add_argument('--output-dir', '-o', type=str, default='./database_backups',
                       help='Backup dosyalarının kaydedileceği klasör')
    parser.add_argument('--tables-only', action='store_true',
                       help='Sadece tablo yapılarını backup al')
    parser.add_argument('--data-only', action='store_true',
                       help='Sadece verileri backup al')
    parser.add_argument('--no-csv', action='store_true',
                       help='CSV dosyalarını backup alma')
    parser.add_argument('--no-sql', action='store_true',
                       help='SQL script dosyalarını backup alma')
    
    args = parser.parse_args()
    
    # Çıktı klasörünü oluştur
    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    output_dir = Path(args.output_dir) / f'backup_{timestamp}'
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"🚀 Backup başlatılıyor...")
    print(f"📁 Çıktı klasörü: {output_dir}")
    
    # Veritabanı konfigürasyonu
    db_url = get_database_url()
    db_config = parse_database_url(db_url)
    
    print(f"🔗 Veritabanı: {db_config['database']} @ {db_config['host']}:{db_config['port']}")
    
    success = True
    
    # PostgreSQL backup'ları
    if not args.data_only:
        # Tam backup
        full_backup_file = output_dir / 'full_backup.sql'
        if not run_pg_dump(db_config, full_backup_file):
            success = False
        
        # Sadece şema
        schema_backup_file = output_dir / 'schema_only.sql'
        if not run_pg_dump(db_config, schema_backup_file, ['--schema-only']):
            success = False
    
    if not args.tables_only:
        # Sadece veri
        data_backup_file = output_dir / 'data_only.sql'
        if not run_pg_dump(db_config, data_backup_file, ['--data-only']):
            success = False
    
    # CSV dosyalarını kopyala
    if not args.no_csv:
        backup_csv_files(output_dir)
    
    # SQL dosyalarını kopyala
    if not args.no_sql:
        backup_sql_files(output_dir)
    
    # Alembic migrations
    backup_alembic_migrations(output_dir)
    
    # Backup bilgi dosyası
    create_backup_info(output_dir, db_config)
    
    if success:
        print(f"\n✅ Backup başarıyla tamamlandı!")
        print(f"📁 Backup klasörü: {output_dir}")
        
        # Dosya boyutlarını göster
        total_size = 0
        for file_path in output_dir.rglob('*'):
            if file_path.is_file():
                size = file_path.stat().st_size
                total_size += size
                print(f"   📄 {file_path.name}: {size / 1024:.1f} KB")
        
        print(f"📊 Toplam boyut: {total_size / 1024 / 1024:.1f} MB")
    else:
        print(f"\n❌ Backup sırasında hatalar oluştu!")
        sys.exit(1)

if __name__ == '__main__':
    main()