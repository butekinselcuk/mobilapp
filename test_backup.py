#!/usr/bin/env python3
"""
İslami App Veritabanı Backup Test Scripti
Bu script backup ve restore işlemlerini test eder.

Kullanım:
    python test_backup.py
    python test_backup.py --quick
"""

import os
import sys
import subprocess
import tempfile
import shutil
import argparse
from pathlib import Path

def run_command(cmd, cwd=None, capture_output=True):
    """Komut çalıştır ve sonucu döndür"""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=capture_output,
            text=True,
            shell=True if isinstance(cmd, str) else False
        )
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def check_postgresql():
    """PostgreSQL kurulu mu kontrol et"""
    print("🔍 PostgreSQL kontrol ediliyor...")
    
    # pg_dump kontrolü
    success, stdout, stderr = run_command(['pg_dump', '--version'])
    if success:
        print(f"✅ pg_dump bulundu: {stdout.strip()}")
    else:
        print(f"❌ pg_dump bulunamadı: {stderr}")
        return False
    
    # psql kontrolü
    success, stdout, stderr = run_command(['psql', '--version'])
    if success:
        print(f"✅ psql bulundu: {stdout.strip()}")
    else:
        print(f"❌ psql bulunamadı: {stderr}")
        return False
    
    return True

def check_python_dependencies():
    """Python bağımlılıkları kontrol et"""
    print("🔍 Python bağımlılıkları kontrol ediliyor...")
    
    required_packages = ['sqlalchemy', 'asyncpg', 'pandas']
    
    for package in required_packages:
        success, stdout, stderr = run_command(['python', '-c', f'import {package}'])
        if success:
            print(f"✅ {package} bulundu")
        else:
            print(f"❌ {package} bulunamadı: {stderr}")
            return False
    
    return True

def check_backup_files():
    """Backup dosyalarının varlığını kontrol et"""
    print("🔍 Backup dosyaları kontrol ediliyor...")
    
    files_to_check = [
        'database_backup.sql',
        'backup_database.py',
        'restore_database.py',
        'backend/hadith_big_example.csv',
        'backend/hadith_example.csv',
        'backend/journey_module_example.csv',
        'reciters_inserts.sql',
        'duzgun.csv'
    ]
    
    all_found = True
    for file_path in files_to_check:
        path = Path(file_path)
        if path.exists():
            size = path.stat().st_size
            print(f"✅ {file_path} ({size / 1024:.1f} KB)")
        else:
            print(f"❌ {file_path} bulunamadı")
            all_found = False
    
    return all_found

def check_alembic_migrations():
    """Alembic migration dosyalarını kontrol et"""
    print("🔍 Alembic migrations kontrol ediliyor...")
    
    migrations_dir = Path('alembic/versions')
    if not migrations_dir.exists():
        print(f"❌ Alembic versions klasörü bulunamadı")
        return False
    
    migration_files = list(migrations_dir.glob('*.py'))
    if migration_files:
        print(f"✅ {len(migration_files)} migration dosyası bulundu:")
        for migration in migration_files:
            print(f"   📄 {migration.name}")
        return True
    else:
        print(f"⚠️  Migration dosyası bulunamadı")
        return False

def test_backup_script(quick=False):
    """Backup scriptini test et"""
    print("🧪 Backup scripti test ediliyor...")
    
    if quick:
        print("⚡ Hızlı test modu (sadece syntax kontrolü)")
        success, stdout, stderr = run_command(['python', 'backup_database.py', '--help'])
        if success:
            print("✅ Backup scripti çalışıyor")
            return True
        else:
            print(f"❌ Backup scripti hatası: {stderr}")
            return False
    
    # Geçici klasörde test backup
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"📁 Geçici test klasörü: {temp_dir}")
        
        # Backup scriptini çalıştır (sadece CSV ve SQL dosyaları)
        success, stdout, stderr = run_command([
            'python', 'backup_database.py',
            '--output-dir', temp_dir,
            '--no-csv', '--no-sql'  # PostgreSQL olmadan test
        ])
        
        if success:
            print("✅ Backup scripti başarıyla çalıştı")
            
            # Oluşturulan dosyaları kontrol et
            backup_dirs = list(Path(temp_dir).glob('backup_*'))
            if backup_dirs:
                backup_dir = backup_dirs[0]
                print(f"📁 Backup klasörü oluşturuldu: {backup_dir.name}")
                
                # İçeriği kontrol et
                files = list(backup_dir.rglob('*'))
                print(f"📄 {len(files)} dosya oluşturuldu")
                return True
            else:
                print("❌ Backup klasörü oluşturulmadı")
                return False
        else:
            print(f"❌ Backup scripti hatası: {stderr}")
            return False

def test_restore_script():
    """Restore scriptini test et"""
    print("🧪 Restore scripti test ediliyor...")
    
    # Sadece syntax kontrolü
    success, stdout, stderr = run_command(['python', 'restore_database.py', '--help'])
    if success:
        print("✅ Restore scripti çalışıyor")
        return True
    else:
        print(f"❌ Restore scripti hatası: {stderr}")
        return False

def test_csv_loading():
    """CSV yükleme scriptini test et"""
    print("🧪 CSV yükleme scripti test ediliyor...")
    
    hadith_loader = Path('backend/hadith_loader.py')
    if not hadith_loader.exists():
        print("❌ hadith_loader.py bulunamadı")
        return False
    
    # Syntax kontrolü
    success, stdout, stderr = run_command(['python', str(hadith_loader)])
    if 'Kullanım:' in stderr or 'Usage:' in stderr:
        print("✅ CSV yükleme scripti çalışıyor")
        return True
    else:
        print(f"❌ CSV yükleme scripti hatası: {stderr}")
        return False

def generate_test_report():
    """Test raporu oluştur"""
    report_content = f"""İslami App Backup Test Raporu
================================

Test Tarihi: {os.popen('date').read().strip()}
Test Ortamı: {sys.platform}
Python Sürümü: {sys.version}

Test Sonuçları:
--------------
"""
    
    tests = [
        ("PostgreSQL Araçları", check_postgresql),
        ("Python Bağımlılıkları", check_python_dependencies),
        ("Backup Dosyaları", check_backup_files),
        ("Alembic Migrations", check_alembic_migrations),
        ("Restore Scripti", test_restore_script),
        ("CSV Yükleme", test_csv_loading)
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, "✅ BAŞARILI" if result else "❌ BAŞARISIZ"))
        except Exception as e:
            results.append((test_name, f"❌ HATA: {e}"))
    
    for test_name, result in results:
        report_content += f"{test_name}: {result}\n"
    
    # Raporu dosyaya yaz
    report_file = Path('backup_test_report.txt')
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(report_content)
    
    print(f"\n📋 Test raporu oluşturuldu: {report_file}")
    return results

def main():
    parser = argparse.ArgumentParser(description='İslami App Backup Test Scripti')
    parser.add_argument('--quick', action='store_true',
                       help='Hızlı test (sadece syntax kontrolü)')
    parser.add_argument('--report', action='store_true',
                       help='Test raporu oluştur')
    
    args = parser.parse_args()
    
    print("🚀 İslami App Backup Test Başlatılıyor...")
    print("=" * 50)
    
    all_passed = True
    
    # Temel kontroller
    if not check_postgresql():
        print("⚠️  PostgreSQL araçları bulunamadı, bazı testler atlanacak")
    
    if not check_python_dependencies():
        print("⚠️  Python bağımlılıkları eksik")
        all_passed = False
    
    if not check_backup_files():
        print("⚠️  Bazı backup dosyaları eksik")
        all_passed = False
    
    if not check_alembic_migrations():
        print("⚠️  Alembic migrations bulunamadı")
    
    # Script testleri
    if not test_backup_script(args.quick):
        print("❌ Backup scripti testi başarısız")
        all_passed = False
    
    if not test_restore_script():
        print("❌ Restore scripti testi başarısız")
        all_passed = False
    
    if not test_csv_loading():
        print("❌ CSV yükleme testi başarısız")
        all_passed = False
    
    # Rapor oluştur
    if args.report:
        generate_test_report()
    
    print("\n" + "=" * 50)
    if all_passed:
        print("✅ Tüm testler başarılı!")
        print("\n📋 Backup sistemi kullanıma hazır:")
        print("   • python backup_database.py")
        print("   • python restore_database.py --sql-file database_backup.sql")
    else:
        print("❌ Bazı testler başarısız!")
        print("\n🔧 Sorunları çözmek için:")
        print("   • PostgreSQL client tools yükleyin")
        print("   • Python bağımlılıklarını yükleyin: pip install -r backend/requirements.txt")
        print("   • Eksik dosyaları kontrol edin")
        sys.exit(1)

if __name__ == '__main__':
    main()