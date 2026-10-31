"""Conservative labels, independent of recipe eligibility and Gemini transport."""
import re
import unicodedata


def folded(text: str) -> str:
    text = text.lower().replace('ı', 'i')
    return ''.join(c for c in unicodedata.normalize('NFKD', text) if not unicodedata.combining(c))


def is_electronic(name: str) -> bool:
    text = folded(name)
    if re.search(r'\bkarton\b.*\bkutu\w*\s*$|\b(?:telefon|bilgisayar) kutusu\s*$', text):
        return False
    return bool(re.search(r'\b(kulaklik\w*|telefon\w*|bilgisayar\w*|laptop\w*|tablet\w*|headphones?\w*|earbuds?\w*|smartphones?\w*|computers?\w*|sarj aleti|powerbank|televizyon\w*|kumanda\w*|klavye\w*|mouse)\b', text))


def is_paper_cup(name: str) -> bool:
    text = folded(name)
    if is_nonpaper_cup(name) or re.search(r'\b(kilif\w*|rulo\w*)\b', text):
        return False
    return bool(re.search(r'\b(kagit|karton)\s+(?:kahve\s+|icecek\s+)?barda[kg]\w*\b|\bpaper\s+(?:coffee\s+)?cups?\b', text))


def is_nonpaper_cup(name: str) -> bool:
    return bool(re.search(r'\b(plastik|cam)\s+(?:kahve\s+|icecek\s+)?barda[kg]\w*\b|\b(plastic|glass)\s+(?:coffee\s+)?cups?\b', folded(name)))


def normalize_material_id(name: str, material_id: str | None) -> str | None:
    if is_electronic(name):
        return None
    if is_nonpaper_cup(name):
        return None
    if is_paper_cup(name):
        return 'paper_cup'
    if material_id == 'paper_cup' and re.search(r'\b(rulo\w*|kilif\w*)\b', folded(name)):
        return None
    return material_id
