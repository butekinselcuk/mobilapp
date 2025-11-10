import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Constants from 'expo-constants';
import { Platform } from 'react-native';
import { SURAH_LIST } from './surahs';

// Base URL öncelik sırası: .env(API_URL) -> app.config.js extra.apiUrl -> manifest.extra.apiUrl -> prod
let baseURL = (
  (typeof process !== 'undefined' && process.env && process.env.API_URL) ||
  (Constants?.expoConfig?.extra?.apiUrl) ||
  (Constants?.manifest?.extra?.apiUrl) ||
  'https://islami-app-backend.onrender.com'
);

// Android emülatörde localhost düzeltmesi
if (Platform.OS === 'android' && typeof baseURL === 'string' && baseURL.includes('127.0.0.1')) {
  baseURL = baseURL.replace('127.0.0.1', '10.0.2.2');
}

// Web/iOS ortamlarında yanlışlıkla localhost'a işaret ediyorsa Render backend'ine dön
if (typeof baseURL === 'string' && (/localhost|127\.0\.0\.1/i).test(baseURL)) {
  baseURL = 'https://islami-app-backend.onrender.com';
}

// Konsola kısa bilgi (yardımcı)
// console.log('API baseURL:', baseURL);

export const api = axios.create({ baseURL, timeout: 12000 });

api.interceptors.request.use(async (config) => {
  try {
    const token = await AsyncStorage.getItem('access_token');
    if (token) {
      config.headers = config.headers || {};
      config.headers.Authorization = `Bearer ${token}`;
    }
  } catch {}
  return config;
});

export async function login(username, password) {
  const res = await api.post('/auth/login', { username, password });
  const { access_token, user_id } = res.data || {};
  if (access_token) {
    await AsyncStorage.setItem('access_token', access_token);
  }
  if (user_id) {
    await AsyncStorage.setItem('user_id', String(user_id));
  }
  return res.data;
}

export async function register(username, email, password) {
  // Slashlı endpoint preflight’ta daha tutarlı çalıştığı için burada tercih ediyoruz
  const res = await api.post('/auth/register/', { username, email, password });
  return res.data;
}

export async function hadithSearch(query, top_k = 10) {
  const res = await api.get('/api/hadith_search', { params: { q: query, top_k } });
  return res.data;
}

export async function getFavorites() {
  const res = await api.get('/user/favorites');
  return res.data;
}

export async function addFavorite(hadith_id) {
  const res = await api.post('/user/favorites', null, { params: { hadith_id } });
  return res.data;
}

export async function removeFavorite(hadith_id) {
  const res = await api.delete('/user/favorites', { params: { hadith_id } });
  return res.data;
}

export async function getHistory({ search, category, source, date_from, date_to, sort_by = 'created_at', order = 'desc' } = {}) {
  const res = await api.get('/user/history', { params: { search, category, source, date_from, date_to, sort_by, order } });
  return res.data;
}

export async function deleteHistoryMany(history_ids) {
  const res = await api.post('/user/history/delete_many', { history_ids });
  return res.data;
}

export async function createOrGetSession(sessionToken) {
  const res = await api.post('/api/chat/session', { session_token: sessionToken || null });
  return res.data; // { session_token, messages }
}

export async function chat(question, sourceFilter, sessionToken) {
  // Auth gerektirmeyen sohbet akışı: /api/chat (get_current_user_optional)
  const res = await api.post('/api/chat', {
    question,
    // Backend varsayılanı "all"; null yerine açıkça all gönderelim
    source_filter: sourceFilter || 'all',
    session_token: sessionToken || null,
  });
  return res.data; // { answer, sources, session_token }
}

// Kimlik doğrulamalı akış: /api/ask (Bearer access_token gerekli)
export async function askAi(question, sourceFilter) {
  const res = await api.post('/api/ask', {
    question,
    source_filter: sourceFilter || 'all',
  });
  return res.data; // { answer, sources }
}

export async function getMe() {
  const res = await api.get('/auth/me');
  return res.data; // { username, email, is_admin, is_premium, premium_expiry }
}

export async function getProfile() {
  const res = await api.get('/user/profile');
  return res.data; // { username, email, is_admin, isPremium, premium_expiry, theme_preference, avatar_url }
}

export async function updateThemePreference(theme) {
  const res = await api.post('/user/theme', { theme });
  return res.data; // { status, theme_preference }
}

export async function changePassword(oldPassword, newPassword) {
  const res = await api.post('/user/change_password', { old_password: oldPassword, new_password: newPassword });
  return res.data; // { status: 'password_changed' }
}

export async function uploadAvatar(file, onProgress) {
  const form = new FormData();
  form.append('file', file);
  const res = await api.post('/user/avatar', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
    onUploadProgress: (evt) => {
      if (onProgress && evt.total) {
        onProgress(Math.round((evt.loaded / evt.total) * 100));
      }
    },
  });
  return res.data; // { status, avatar_url }
}

export async function activatePremium() {
  const res = await api.post('/user/activate_premium');
  return res.data; // { is_premium, premium_expiry }
}

// Sağlık kontrolü (Render backend /health)
export async function health() {
  const res = await api.get('/health');
  return res.data; // { status: 'ok', db: 'ok' | 'error' }
}

// Günün Ayeti ve Günün Hadisi (Render backend)
export async function getDailyAyah() {
  // Beklenen endpoint: /api/daily_ayah -> { text, reference }
  const res = await api.get('/api/daily_ayah');
  return res.data;
}

export async function getDailyHadith() {
  // Beklenen endpoint: /api/daily_hadith -> { text, reference }
  const res = await api.get('/api/daily_hadith');
  return res.data;
}

// Kur’an verileri (SQL backend)
// İsim -> ID eşleşmesi için yardımcı sözlük
const SURAH_NAME_TO_ID = Object.fromEntries(SURAH_LIST.map((s) => [String(s.name).toLowerCase(), s.id]));
// Backend Türkçe adları için ek sözlük (main/composite_app ile uyumlu)
const SURAH_TR_NAME_TO_ID = {
  'fatiha': 1, 'bakara': 2, "al-i imran": 3, 'nisa': 4, 'maide': 5,
  "en'am": 6, "a'raf": 7, 'enfal': 8, 'tevbe': 9, 'yunus': 10,
  'hud': 11, 'yusuf': 12, "ra'd": 13, 'ibrahim': 14, 'hicr': 15,
  'nahl': 16, 'isra': 17, 'kehf': 18, 'meryem': 19, 'taha': 20,
  'enbiya': 21, 'hac': 22, "mü'minun": 23, 'nur': 24, 'furkan': 25,
  "şuara": 26, 'neml': 27, 'kasas': 28, 'ankebut': 29, 'rum': 30,
  'lokman': 31, 'secde': 32, 'ahzab': 33, 'sebe': 34, 'fatır': 35,
  'yasin': 36, 'saffat': 37, 'sad': 38, 'zümer': 39, 'mümin': 40,
  'fussilet': 41, 'şura': 42, 'zuhruf': 43, 'duhan': 44, 'casiye': 45,
  'ahkaf': 46, 'muhammed': 47, 'fetih': 48, 'hucurat': 49, 'kaf': 50,
  'zariyat': 51, 'tur': 52, 'necm': 53, 'kamer': 54, 'rahman': 55,
  'vakia': 56, 'hadid': 57, 'mücadele': 58, 'haşr': 59, 'mümtehine': 60,
  'saff': 61, 'cuma': 62, 'münafikun': 63, 'tegabun': 64, 'talak': 65,
  'tahrim': 66, 'mülk': 67, 'kalem': 68, 'hakka': 69, 'mearic': 70,
  'nuh': 71, 'cin': 72, 'müzzemmil': 73, 'müddessir': 74, 'kıyamet': 75,
  'insan': 76, 'mürselat': 77, 'nebe': 78, 'naziat': 79, 'abese': 80,
  'tekvir': 81, 'infitar': 82, 'mutaffifin': 83, 'inşikak': 84, 'büruc': 85,
  'tarık': 86, 'ala': 87, 'gaşiye': 88, 'fecr': 89, 'beled': 90,
  'şems': 91, 'leyl': 92, 'duha': 93, 'inşirah': 94, 'tin': 95,
  'alak': 96, 'kadir': 97, 'beyyine': 98, 'zilzal': 99, 'adiyat': 100,
  'karia': 101, 'tekasur': 102, 'asr': 103, 'hümeze': 104, 'fil': 105,
  'kureyş': 106, 'maun': 107, 'kevser': 108, 'kafirun': 109, 'nasr': 110,
  'tebbet': 111, 'ihlas': 112, 'felak': 113, 'nas': 114,
};

function normalizeBackendVerses(list) {
  if (!Array.isArray(list)) return [];
  return list.map((it) => {
    const surahRaw = it?.surah;
    let surahId = undefined;
    if (surahRaw != null) {
      const num = Number(surahRaw);
      if (!Number.isNaN(num) && num > 0 && num <= 114) {
        surahId = num;
      } else if (typeof surahRaw === 'string') {
        const key = surahRaw.trim().toLowerCase();
        surahId = SURAH_NAME_TO_ID[key] || SURAH_TR_NAME_TO_ID[key];
      }
    }
    return {
      ...it,
      surah_id: surahId,
      ayah_id: it?.ayah,
    };
  });
}

export async function getQuranVerses({ surah, ayah, language = 'tr', q, reciter } = {}) {
  const params = {};
  if (surah) params.surah = surah;
  if (ayah) params.ayah = ayah;
  if (language) params.language = language;
  if (q) params.search = q;
  if (reciter) params.reciter = reciter;
  try {
    const res = await api.get('/api/quran', { params });
    // Backend şemasını UI’da beklenen anahtarlarla hizala
    return normalizeBackendVerses(res.data); // [{ surah, ayah, text, language, audio_url?, surah_id, ayah_id }]
  } catch (error) {
    // Backend 404/erişilemez ise AlQuran Cloud fallback
    try {
      // Backend şemasına uyumlu kapsamlı fallback: metin_ar, metin_tr/translation ve ses
      const s = String(surah || '1');

      // 1) Arapça metin (Uthmani)
      const arUrl = `https://api.alquran.cloud/v1/surah/${encodeURIComponent(s)}/quran-uthmani`;
      const arResp = await fetch(arUrl);
      if (!arResp.ok) throw new Error(`AlQuran ar error ${arResp.status}`);
      const arJson = await arResp.json();
      const arAyahs = arJson?.data?.ayahs || [];

      // 2) Çeviri: dil eşlemesi
      let trAyahs = [];
      if (language === 'tr') {
        const trUrl = `https://api.alquran.cloud/v1/surah/${encodeURIComponent(s)}/tr.diyanet`;
        const trResp = await fetch(trUrl);
        if (!trResp.ok) throw new Error(`AlQuran tr error ${trResp.status}`);
        const trJson = await trResp.json();
        trAyahs = trJson?.data?.ayahs || [];
      }

      // 3) Ses: Mishary Alafasy
      const audioUrl = `https://api.alquran.cloud/v1/surah/${encodeURIComponent(s)}/ar.alafasy`;
      const audioResp = await fetch(audioUrl);
      if (!audioResp.ok) throw new Error(`AlQuran audio error ${audioResp.status}`);
      const audioJson = await audioResp.json();
      const audioAyahs = audioJson?.data?.ayahs || [];

      // Arapça + çeviri + ses eşlemesi
      const combined = arAyahs.map((ar, idx) => {
        const trText = trAyahs[idx]?.text || undefined;
        const audio = audioAyahs[idx]?.audio || undefined;
        return {
          surah: ar?.surah?.number,
          ayah: ar?.numberInSurah,
          text: trText || ar?.text,
          language,
          audio_url: audio,
        };
      });

      return normalizeBackendVerses(combined);
    } catch (fallbackErr) {
      return [];
    }
  }
}

export async function getDailyAyah() {
  const res = await api.get('/api/daily_ayah');
  return res.data;
}

export async function getDailyHadith() {
  const res = await api.get('/api/daily_hadith');
  return res.data;
}

export async function getReciters() {
  const res = await api.get('/api/reciters');
  return res.data;
}

export async function getProfile() {
  const res = await api.get('/user/profile');
  return res.data;
}

export async function uploadAvatar(file, onProgress) {
  const form = new FormData();
  form.append('file', file);
  const res = await api.post('/user/avatar', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
    onUploadProgress: (evt) => {
      if (onProgress && evt.total) {
        onProgress(Math.round((evt.loaded / evt.total) * 100));
      }
    },
  });
  return res.data;
}
