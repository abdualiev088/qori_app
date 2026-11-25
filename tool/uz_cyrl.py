#!/usr/bin/env python3
"""Rebuild lib/l10n/app_uz_Cyrl.arb from app_uz.arb (Uzbek Latin -> Cyrillic).

Run after editing app_uz.arb:  python3 tool/uz_cyrl.py && flutter gen-l10n
Placeholders, ICU plural syntax and brand names are left as they are; a few
words that don't transliterate letter by letter are fixed in convert().
"""
import re
O='ʻ'; A='ʼ'
UNITS=[('yo'+O,'йў'),('o'+O,'ў'),('g'+O,'ғ'),('sh','ш'),('ch','ч'),('yo','ё'),('yu','ю'),('ya','я'),('ye','е'),
       ('a','а'),('b','б'),('d','д'),('f','ф'),('g','г'),('h','ҳ'),('i','и'),('j','ж'),('k','к'),('l','л'),('m','м'),
       ('n','н'),('o','о'),('p','п'),('q','қ'),('r','р'),('s','с'),('t','т'),('u','у'),('v','в'),('x','х'),('y','й'),('z','з'),('c','ч')]
PROTECT=re.compile(r'\{\w+, plural, |=1\{|other\{|\{[a-zA-Z_]\w*\}|Hifdth|Apple|Google|you@example\.com|cave')
def word(seg):
    out=[]; i=0; low=seg.lower()
    while i<len(seg):
        ch=seg[i]
        if ch==A: out.append('ъ'); i+=1; continue
        for lat,cy in UNITS:
            if low.startswith(lat,i):
                prev=seg[i-1] if i>0 else ' '
                if lat=='e': pass
                c=cy
                if seg[i].isupper():
                    nxt=seg[i+len(lat):i+len(lat)+1]
                    c=cy.upper() if (len(cy)==1 or nxt.isupper() or len(lat)==1) else cy[0].upper()+cy[1:]
                    if len(cy)==2: c=cy[0].upper()+cy[1:] if not (nxt and nxt.isupper()) else cy.upper()
                out.append(c); i+=len(lat); break
        else:
            if low[i]=='e':
                prev=seg[i-1] if i>0 else ' '
                c='э' if not prev.isalpha() and prev not in (O,A) else 'е'
                out.append(c.upper() if ch.isupper() else c); i+=1
            else:
                out.append(ch); i+=1
    return ''.join(out)
def conv(s):
    parts=[]; last=0
    for m in PROTECT.finditer(s):
        parts.append(word(s[last:m.start()])); parts.append(m.group(0)); last=m.end()
    parts.append(word(s[last:]))
    return ''.join(parts)
FIX={'oktabr':'октябр','sentabr':'сентябр'}
def convert(T):
    out={k:conv(v) for k,v in T.items()}
    out['monthsLong']=out['monthsLong'].replace('октабр','октябр').replace('сентабр','сентябр')
    out.update(
      weekdaysShort='Ду,Се,Чо,Па,Жу,Ша,Як', weekdayLetters='Д,С,Ч,П,Ж,Ш,Я',
      enterEmail='Электрон почтангизни киритинг', emailIncomplete='Электрон почта тўлиқ киритилмаганга ўхшайди',
      authEmailBody='Электрон почтангизни киритинг, қолганини Hifdth ўзи бажаради.', email='Электрон почта',
      madeWithCare='Hifz · Қуръонни ёд оладиганлар учун',
      monthsShort='янв,фев,мар,апр,май,июн,июл,авг,сен,окт,ноя,дек')
    up='А-ЯЁЎҚҒҲ'
    out={k:re.sub(f'(?<=[{up}])ъ(?=[{up}])','Ъ',v) for k,v in out.items()}
    return out


if __name__ == '__main__':
    import json, pathlib
    root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
    src = json.loads((root / 'app_uz.arb').read_text())
    out = convert({k: v for k, v in src.items() if not k.startswith('@')})
    (root / 'app_uz_Cyrl.arb').write_text(json.dumps({'@@locale': 'uz_Cyrl', **out}, ensure_ascii=False, indent=2))
    print(f'wrote {len(out)} strings')
