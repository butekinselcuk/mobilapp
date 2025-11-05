#!/usr/bin/env python3
"""
İslami App Veritabanı Restore Scripti
Bu script backup'lanmış veritabanını geri yükler.

Kullanım:
    python restore_database.py --backup-dir ./database_backups/backup_20250127_143000
    python restore_database.py --sql-file ./database_backup.sql
    python restore_database.py --backup-dir ./backups --create-db
"""

import os
import sys
import subprocess
import argparse
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

def run_psql(db_config, sql_file, database=None):
    """psql komutunu çalıştır"""
    target_db = database or db_config['database']
    
    cmd = [
        'psql',
        '-h', db_config['host'],
        '-p', db_config['port'],
        '-U', db_config['user'],
        '-d', target_db,
        '-f', str(sql_file)
    ]
    
    # Password'u environment variable olarak ayarla
    env = os.environ.copy()
    if db_config['password']:
        env['PGPASSWORD'] = db_config['password']
    
    try:
        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ SQL dosyası başarıyla çalıştırıldı: {sql_file}")
            return True
        else:
            print(f"❌ SQL çalıştırma hatası: {result.stderr}")
            return False
    except FileNotFoundError:
        print("❌ psql komutu bulunamadı. PostgreSQL client tools yüklü olduğundan emin olun.")
        return False
    except Exception as e:
        print(f"❌ SQL çalıştırma hatası: {e}")
        return False

def create_database(db_config):
    """Veritabanını oluştur"""
    cmd = [
        'createdb',
        '-h', db_config['host'],
        '-p', db_config['port'],
        '-U', db_config['user'],
        db_config['database']
    ]
    
    # Password'u environment variable olarak ayarla
    env = os.environ.copy()
    if db_config['password']:
        env['PGPASSWORD'] = db_config['password']
    
    try:
        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Veritabanı oluşturuldu: {db_config['database']}")
            return True
        else:
            if 'already exists' in result.stderr:
                print(f"⚠️  Veritabanı zaten mevcut: {db_config['database']}")
                return True
            else:
                print(f"❌ Veritabanı oluşturma hatası: {result.stderr}")
                return False
    except FileNotFoundError:
        print("❌ createdb komutu bulunamadı. PostgreSQL client tools yüklü olduğundan emin olun.")
        return False
    except Exception as e:
        print(f"❌ Veritabanı oluşturma hatası: {e}")
        return False

def run_alembic_upgrade():
    """Alembic migration'ları çalıştır"""
    backend_dir = Path('backend')
    if not backend_dir.exists():
        print("⚠️  Backend klasörü bulunamadı, alembic atlanıyor")
        return True
    
    try:
        result = subprocess.run(
            ['alembic', 'upgrade', 'head'],
            cwd=backend_dir,
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            print(f"✅ Alembic migrations başarıyla çalıştırıldı")
            return True
        else:
            print(f"❌ Alembic hatası: {result.stderr}")
            return False
    except FileNotFoundError:
        print("⚠️  Alembic bulunamadı, migration atlanıyor")
        return True
    except Exception as e:
        print(f"❌ Alembic hatası: {e}")
        return False

def load_csv_data(backup_dir):
    """CSV verilerini yükle"""
    csv_dir = backup_dir / 'csv_data'
    if not csv_dir.exists():
        print("⚠️  CSV veri klasörü bulunamadı")
        return True
    
    # Hadith CSV'sini yükle
    hadith_csv = csv_dir / 'hadith_big_example.csv'
    if hadith_csv.exists():
        try:
            result = subprocess.run(
                ['python', 'hadith_loader.py', str(hadith_csv)],
                cwd='backend',
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                print(f"✅ Hadith verileri yüklendi")
            else:
                print(f"❌ Hadith yükleme hatası: {result.stderr}")
                return False
        except Exception as e:
            print(f"❌ Hadith yükleme hatası: {e}")
            return False
    
    return True

def restore_from_backup_dir(backup_dir, db_config, create_db=False):
    """Backup klasöründen restore et"""
    backup_path = Path(backup_dir)
    if not backup_path.exists():
        print(f"❌ Backup klasörü bulunamadı: {backup_dir}")
        return False
    
    print(f"📁 Backup klasörü: {backup_path}")
    
    # Veritabanını oluştur (isteğe bağlı)
    if create_db:
        if not create_database(db_config):
            return False
    
    success = True
    
    # Full backup varsa onu kullan
    full_backup = backup_path / 'full_backup.sql'
    if full_backup.exists():
        print("🔄 Full backup restore ediliyor...")
        if not run_psql(db_config, full_backup):
            success = False
    else:
        # Schema + data ayrı ayrı restore et
        schema_backup = backup_path / 'schema_only.sql'
        data_backup = backup_path / 'data_only.sql'
        
        if schema_backup.exists():
            print("🔄 Schema restore ediliyor...")
            if not run_psql(db_config, schema_backup):
                success = False
        
        if data_backup.exists():
            print("🔄 Data restore ediliyor...")
            if not run_psql(db_config, data_backup):
                success = False
        
        # CSV verilerini yükle
        if success:
            print("🔄 CSV verileri yükleniyor...")
            if not load_csv_data(backup_path):
                success = False
    
    # SQL scriptleri çalıştır
    sql_scripts_dir = backup_path / 'sql_scripts'
    if sql_scripts_dir.exists():
        for sql_file in sql_scripts_dir.glob('*.sql'):
            if sql_file.name not in ['drop_all.sql']:  # Tehlikeli scriptleri atla
                print(f"🔄 SQL script çalıştırılıyor: {sql_file.name}")
                if not run_psql(db_config, sql_file):
                    print(f"⚠️  SQL script hatası (devam ediliyor): {sql_file.name}")
    
    # Alembic migrations
    if success:
        print("🔄 Alembic migrations çalıştırılıyor...")
        if not run_alembic_upgrade():
            print("⚠️  Alembic hatası (devam ediliyor)")
    
    return success

def restore_from_sql_file(sql_file, db_config, create_db=False):
    """Tek SQL dosyasından restore et"""
    sql_path = Path(sql_file)
    if not sql_path.exists():
        print(f"❌ SQL dosyası bulunamadı: {sql_file}")
        return False
    
    print(f"📄 SQL dosyası: {sql_path}")
    
    # Veritabanını oluştur (isteğe bağlı)
    if create_db:
        if not create_database(db_config):
            return False
    
    # SQL dosyasını çalıştır
    print("🔄 SQL dosyası restore ediliyor...")
    if not run_psql(db_config, sql_path):
        return False
    
    # Alembic migrations
    print("🔄 Alembic migrations çalıştırılıyor...")
    if not run_alembic_upgrade():
        print("⚠️  Alembic hatası (devam ediliyor)")
    
    return True

def main():
    parser = argparse.ArgumentParser(description='İslami App Veritabanı Restore Scripti')
    parser.add_argument('--backup-dir', '-d', type=str,
                       help='Backup klasörü yolu')
    parser.add_argument('--sql-file', '-f', type=str,
                       help='Tek SQL dosyası yolu')
    parser.add_argument('--create-db', action='store_true',
                       help='Veritabanını oluştur (yoksa)')
    parser.add_argument('--database', type=str,
                       help='Hedef veritabanı adı (varsayılan: .env\'den)')
    
    args = parser.parse_args()
    
    if not args.backup_dir and not args.sql_file:
        print("❌ --backup-dir veya --sql-file belirtmelisiniz")
        parser.print_help()
        sys.exit(1)
    
    # Veritabanı konfigürasyonu
    db_url = get_database_url()
    db_config = parse_database_url(db_url)
    
    if args.database:
        db_config['database'] = args.database
    
    print(f"🚀 Restore başlatılıyor...")
    print(f"🔗 Hedef veritabanı: {db_config['database']} @ {db_config['host']}:{db_config['port']}")
    
    success = False
    
    if args.backup_dir:
        success = restore_from_backup_dir(args.backup_dir, db_config, args.create_db)
    elif args.sql_file:
        success = restore_from_sql_file(args.sql_file, db_config, args.create_db)
    
    if success:
        print(f"\n✅ Restore başarıyla tamamlandı!")
        print(f"🔗 Veritabanı: {db_config['database']}")
        print(f"\n📋 Sonraki adımlar:")
        print(f"   1. Backend sunucusunu başlatın: cd backend && python main.py")
        print(f"   2. Frontend uygulamasını başlatın: cd islami_app_new && flutter run")
    else:
        print(f"\n❌ Restore sırasında hatalar oluştu!")
        sys.exit(1)

if __name__ == '__main__':
    main()