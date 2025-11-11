from sqlalchemy import Column, Integer, String, Text, ForeignKey, Float, DateTime, func, Boolean, UniqueConstraint
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_admin = Column(Boolean, default=False)  # Admin kullanıcı mı?
    is_premium = Column(Boolean, default=False)  # Premium kullanıcı mı?
    premium_expiry = Column(DateTime, nullable=True)  # Premium bitiş tarihi (opsiyonel)
    # Profil özelleştirme alanları
    theme_preference = Column(String, nullable=True)  # 'light' | 'dark'
    avatar_url = Column(String, nullable=True)        # Yüklenen avatar dosyasının URL'si
    questions = relationship('Question', back_populates='user')
    question_history = relationship('UserQuestionHistory', back_populates='user', cascade='all, delete-orphan')
    favorite_hadiths = relationship('UserFavoriteHadith', back_populates='user', cascade='all, delete-orphan')

class Source(Base):
    __tablename__ = 'sources'
    id = Column(Integer, primary_key=True, index=True)
    type = Column(String, index=True)  # quran, hadis, kitap, vs.
    name = Column(String, index=True)
    reference = Column(String)
    questions = relationship('Question', back_populates='source')

class Question(Base):
    __tablename__ = 'questions'
    id = Column(Integer, primary_key=True, index=True)
    text = Column(Text, nullable=False)
    answer = Column(Text)
    user_id = Column(Integer, ForeignKey('users.id'))
    source_id = Column(Integer, ForeignKey('sources.id'))
    user = relationship('User', back_populates='questions')
    source = relationship('Source', back_populates='questions')

class JourneyModule(Base):
    __tablename__ = 'journey_modules'
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    icon = Column(String, nullable=True)  # Icon adı veya kodu (örn. 'menu_book')
    category = Column(String, nullable=True)  # Yeni eklendi
    tags = Column(String, nullable=True)      # Yeni eklendi
    steps = relationship('JourneyStep', back_populates='module', cascade='all, delete-orphan')

class JourneyStep(Base):
    __tablename__ = 'journey_steps'
    id = Column(Integer, primary_key=True, index=True)
    module_id = Column(Integer, ForeignKey('journey_modules.id'), nullable=False)
    title = Column(String, nullable=False)
    order = Column(Integer, nullable=False)
    content = Column(Text, nullable=True)
    media_url = Column(Text, nullable=True)
    media_type = Column(String, nullable=True)  # 'image', 'video', 'link'
    source = Column(String, nullable=True)
    module = relationship('JourneyModule', back_populates='steps')

class UserJourneyProgress(Base):
    __tablename__ = 'user_journey_progress'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    module_id = Column(Integer, ForeignKey('journey_modules.id'), nullable=False)
    completed_step = Column(Integer, default=0)  # Kaç adım tamamlandı
    completed_at = Column(DateTime, nullable=True)

class Hadith(Base):
    __tablename__ = 'hadiths'
    id = Column(Integer, primary_key=True, index=True)
    hadis_id = Column(String, nullable=True)           # Dış kaynak/ID
    kitap = Column(String, nullable=True)              # Kitap adı
    bab = Column(String, nullable=True)                # Bab adı
    hadis_no = Column(String, nullable=True)           # Hadis numarası
    arabic_text = Column(Text, nullable=True)          # Arapça metin
    turkish_text = Column(Text, nullable=True)         # Türkçe metin
    tags = Column(Text, nullable=True)                 # JSON string veya virgül ile ayrılmış
    topic = Column(String, nullable=True)              # Konu
    authenticity = Column(String, nullable=True)       # Sahih, zayıf vb.
    narrator_chain = Column(Text, nullable=True)       # Ravi zinciri
    related_ayah = Column(Text, nullable=True)         # JSON string veya virgül ile ayrılmış
    context = Column(Text, nullable=True)              # Açıklama/bağlam
    source = Column(String, nullable=False)            # Kaynak (örn. Buhari, Müslim)
    reference = Column(String, nullable=True)          # Kitap, bab, hadis no vs.
    category = Column(String, nullable=True)           # Konu/kategori (örn. Namaz, Oruç)
    language = Column(String, default='tr')            # Dil
    embedding = Column(Text, nullable=True)            # Vektör embedding (opsiyonel)
    created_at = Column(DateTime, server_default=func.now())

class ChatSession(Base):
    __tablename__ = 'chat_sessions'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=True)  # Anonim kullanıcılar için nullable
    session_token = Column(String, unique=True, nullable=False)  # Benzersiz session token
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    messages = relationship('ChatMessage', back_populates='session', cascade='all, delete-orphan')

class ChatMessage(Base):
    __tablename__ = 'chat_messages'
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey('chat_sessions.id'), nullable=False)
    message_type = Column(String, nullable=False)  # 'user' veya 'assistant'
    content = Column(Text, nullable=False)
    sources = Column(Text, nullable=True)  # JSON string olarak kaynaklar
    created_at = Column(DateTime, server_default=func.now())
    session = relationship('ChatSession', back_populates='messages')

class UserQuestionHistory(Base):
    __tablename__ = 'user_question_history'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    question = Column(String, nullable=False)
    answer = Column(Text, nullable=True)
    hadith_id = Column(Integer, ForeignKey('hadiths.id'), nullable=True)  # Eklendi
    created_at = Column(DateTime, server_default=func.now())
    user = relationship('User', back_populates='question_history')

class UserFavoriteHadith(Base):
    __tablename__ = 'user_favorite_hadiths'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    hadith_id = Column(Integer, ForeignKey('hadiths.id'), nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    user = relationship('User', back_populates='favorite_hadiths')
    hadith = relationship('Hadith') 

class Setting(Base):
    __tablename__ = 'settings'
    id = Column(Integer, primary_key=True, index=True)
    key = Column(String, unique=True, nullable=False)
    value = Column(String, nullable=False)
    __table_args__ = (UniqueConstraint('key', name='uq_settings_key'),) 

class QuranVerse(Base):
    __tablename__ = 'quran_verses'
    id = Column(Integer, primary_key=True, index=True)
    surah = Column(String, nullable=False)  # Sure adı veya numarası
    ayah = Column(Integer, nullable=False)  # Ayet numarası
    text = Column(Text, nullable=False)
    translation = Column(Text, nullable=True)
    source_id = Column(Integer, ForeignKey('sources.id'), nullable=True)
    source = relationship('Source')
    language = Column(String, default='tr')
    # Yeni eklenen alanlar:
    surah_id = Column(Integer, nullable=True)
    surah_name = Column(String, nullable=True)
    ayah_number = Column(Integer, nullable=True)
    text_ar = Column(Text, nullable=True)
    text_tr = Column(Text, nullable=True)
    audio_url = Column(Text, nullable=True)
    __table_args__ = (UniqueConstraint('surah', 'ayah', 'language', name='uq_quran_surah_ayah_lang'),)

class Dua(Base):
    __tablename__ = 'duas'
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    text = Column(Text, nullable=False)
    translation = Column(Text, nullable=True)
    category = Column(String, nullable=True)
    source_id = Column(Integer, ForeignKey('sources.id'), nullable=True)
    source = relationship('Source')
    language = Column(String, default='tr')

class Zikr(Base):
    __tablename__ = 'zikrs'
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    text = Column(Text, nullable=False)
    translation = Column(Text, nullable=True)
    count = Column(Integer, nullable=True)  # Tekrar sayısı
    category = Column(String, nullable=True)
    source_id = Column(Integer, ForeignKey('sources.id'), nullable=True)
    source = relationship('Source')
    language = Column(String, default='tr')

class ZikrSession(Base):
    __tablename__ = 'zikr_sessions'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=True)
    zikr_id = Column(Integer, ForeignKey('zikrs.id'), nullable=True)
    title = Column(String, nullable=True)
    target_count = Column(Integer, nullable=True)
    current_count = Column(Integer, default=0)
    status = Column(String, default='active')  # 'active' | 'finished'
    created_at = Column(DateTime, server_default=func.now())
    finished_at = Column(DateTime, nullable=True)
    # İlişkiler
    user = relationship('User')
    zikr = relationship('Zikr')

class Tafsir(Base):
    __tablename__ = 'tafsirs'
    id = Column(Integer, primary_key=True, index=True)
    surah = Column(String, nullable=False)
    ayah = Column(Integer, nullable=False)
    text = Column(Text, nullable=False)
    author = Column(String, nullable=True)
    source_id = Column(Integer, ForeignKey('sources.id'), nullable=True)
    source = relationship('Source')
    language = Column(String, default='tr')
    __table_args__ = (UniqueConstraint('surah', 'ayah', 'author', 'language', name='uq_tafsir_surah_ayah_author_lang'),) 

class QuranAudio(Base):
    __tablename__ = 'quran_audio'
    id = Column(Integer, primary_key=True, index=True)
    verse_id = Column(Integer, ForeignKey('quran_verses.id'), nullable=False)
    reciter = Column(String, nullable=False)  # Okuyucu adı veya kodu
    audio_url = Column(Text, nullable=False)
    # İlişki: Bir ayetin birden fazla okuyucusu olabilir
    verse = relationship('QuranVerse', backref='audio_files')
    __table_args__ = (UniqueConstraint('verse_id', 'reciter', name='uq_quran_audio_verse_reciter'),) 

class Reciter(Base):
    __tablename__ = 'reciters'
    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
