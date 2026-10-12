"""Full translations in the same key order as en-us.lua; exports standalone Lua files."""
import json
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
folder = root / 'JokerReclaimed/localization'
pairs = re.findall(r"jrc_(\w+)\s*=\s*'([^']*)'", (folder / 'en-us.lua').read_text(encoding='utf-8'))
keys = [key for key, _ in pairs]
translations = {
    'ja': '''ジョーカー修復所
ジョーカーを修復
かけら
すべてのレア度
コモン
アンコモン
レア
レジェンダリー
ショップへ戻る
一覧へ戻る
ジョーカーを選択。かけらは次のランにも残ります。
このレア度には解放済みのジョーカーがありません。
ステッカー・ドル価格
レンタル
劣化
エターナル
適用不可
ドル価格のみ変更。エターナル＋レンタルは$2。
エディション・追加のかけら
通常
フォイル
ホログラム
ポリクローム
ネガティブ
レア度ごとの基本かけら数は変わりません。
カーソルを合わせて効果を確認。
修復できます
かけらが足りません
お金が足りません
ジョーカースロットがありません
ショップでのみ利用できます
未解放または禁止されたジョーカーです
このステッカーは併用できません
無効なエディションです
保存に失敗しました。消費はありません。
生成に失敗しました。消費はありません。
必要なModがありません。有効にして復旧してください。
かけらは受け取り済みです
このジョーカーは破壊できません
ジョーカーを破る
このジョーカーを破りますか？
ジョーカーを破壊します。売却金や売却効果はありません。
キャンセル
破る前に確認する
テスト用チートを有効化
左Ctrl＋左Shift＋F8：かけら1000個、$100
かけら#1#個 / このランの所持金$#2#
#1#個＋$#2#
修復・#1#個＋$#2#
#1# / #2#・#3#種類
かけら＋#1#個
破る・＋#1#
かけら#1#個が永久に加算されます。''',
    'zh_CN': '''小丑修复所
修复小丑牌
碎片
所有稀有度
普通
罕见
稀有
传奇
返回商店
返回列表
选择小丑牌。碎片可跨对局保留。
此稀有度没有已解锁的小丑牌。
贴纸 · 金币价格
租赁
易腐
永恒
不可用
仅替换金币价格。永恒＋租赁为$2。
版本 · 额外碎片
基础
闪箔
镭射
多彩
负片
仍需支付该稀有度的基础碎片费用。
悬停查看小丑牌效果。
可以修复
碎片不足
金币不足
没有空余的小丑牌槽位
仅可在商店使用
此小丑牌尚未解锁或被禁用
这些贴纸无法同时使用
无效版本
碎片保存失败，未消耗资源。
小丑牌生成失败，未消耗资源。
缺少所需模组，请重新启用以恢复。
已经领取过碎片
此小丑牌受到保护
撕碎小丑牌
撕碎这张小丑牌？
销毁小丑牌。不会获得卖出金钱或触发卖出效果。
取消
撕碎前确认
启用测试作弊
左Ctrl＋左Shift＋F8：1000碎片、$100
碎片#1#个 / 本局$#2#
#1#碎片＋$#2#
修复 · #1#碎片＋$#2#
#1# / #2# · #3#种小丑牌
＋#1#碎片
撕碎 · ＋#1#
永久获得#1#个碎片。''',
    'zh_TW': '''小丑修復所
修復小丑牌
碎片
所有稀有度
普通
罕見
稀有
傳奇
返回商店
返回列表
選擇小丑牌。碎片可跨對局保留。
此稀有度沒有已解鎖的小丑牌。
貼紙 · 金幣價格
租賃
易腐
永恆
無法套用
僅替換金幣價格。永恆＋租賃為$2。
版本 · 額外碎片
基礎
閃箔
全像
多彩
負片
仍需支付該稀有度的基礎碎片費用。
移至牌面以查看效果。
可以修復
碎片不足
金幣不足
沒有空餘的小丑牌欄位
僅可在商店使用
此小丑牌尚未解鎖或遭禁用
這些貼紙無法同時使用
無效版本
碎片儲存失敗，未消耗資源。
小丑牌生成失敗，未消耗資源。
缺少必要模組，請重新啟用以恢復。
已經領取過碎片
此小丑牌受到保護
撕碎小丑牌
撕碎這張小丑牌？
銷毀小丑牌。不會獲得賣出金錢或觸發賣出效果。
取消
撕碎前確認
啟用測試作弊
左Ctrl＋左Shift＋F8：1000碎片、$100
碎片#1#個 / 本局$#2#
#1#碎片＋$#2#
修復 · #1#碎片＋$#2#
#1# / #2# · #3#種小丑牌
＋#1#碎片
撕碎 · ＋#1#
永久獲得#1#個碎片。''',
    'de': '''Joker-Werkstatt
Joker wiederherstellen
Fragmente
Alle Seltenheiten
Gewöhnlich
Ungewöhnlich
Selten
Legendär
Zurück zum Shop
Zurück zu den Jokern
Joker wählen. Fragmente bleiben zwischen Runs erhalten.
Keine freigeschalteten Joker dieser Seltenheit.
Sticker · Dollarpreis
Gemietet
Vergänglich
Ewig
Nicht verfügbar
Ersetzt nur den Dollarpreis. Ewig + gemietet: $2.
Edition · zusätzliche Fragmente
Standard
Folie
Holografisch
Polychrom
Negativ
Die Grundkosten in Fragmenten bleiben bestehen.
Für Details mit der Maus über die Karte fahren.
Bereit zur Wiederherstellung
Nicht genug Fragmente
Nicht genug Geld
Kein freier Jokerplatz
Nur im Shop verfügbar
Dieser Joker ist gesperrt oder verboten
Diese Sticker lassen sich nicht kombinieren
Ungültige Edition
Speichern fehlgeschlagen. Nichts ausgegeben.
Joker konnte nicht erstellt werden. Nichts ausgegeben.
Benötigte Mod fehlt. Zur Wiederherstellung aktivieren.
Fragmente bereits erhalten
Dieser Joker ist geschützt
Joker zerreißen
Diesen Joker zerreißen?
Zerstört den Joker. Kein Verkaufserlös und keine Verkaufseffekte.
Abbrechen
Zerreißen vorher bestätigen
Test-Cheats aktivieren
Linke Strg + linke Umschalt + F8: 1000 Fragmente, $100
#1# Fragmente / $#2# in diesem Run
#1# Fragmente + $#2#
Wiederherstellen · #1# Fragmente + $#2#
#1# / #2# · #3# Joker
+#1# Fragmente
Zerreißen · +#1#
Du erhältst dauerhaft #1# Fragmente.''',
    'fr': '''Atelier des Jokers
Restaurer un Joker
Fragments
Toutes les raretés
Commun
Peu commun
Rare
Légendaire
Retour à la boutique
Retour aux Jokers
Choisissez un Joker. Les fragments restent entre les parties.
Aucun Joker débloqué de cette rareté.
Autocollants · prix en dollars
Location
Périssable
Éternel
Indisponible
Remplace uniquement le prix en dollars. Éternel + location : $2.
Édition · fragments supplémentaires
Standard
Brillante
Holographique
Polychrome
Négative
Le coût de base en fragments reste dû.
Survolez la carte pour consulter son effet.
Prêt à restaurer
Pas assez de fragments
Pas assez d’argent
Aucun emplacement de Joker libre
Disponible uniquement en boutique
Ce Joker est verrouillé ou interdit
Ces autocollants sont incompatibles
Édition invalide
Échec de sauvegarde. Rien n’a été dépensé.
Impossible de créer le Joker. Rien n’a été dépensé.
Un mod requis manque. Réactivez-le pour récupérer la carte.
Fragments déjà reçus
Ce Joker est protégé
Déchirer le Joker
Déchirer ce Joker ?
Détruit le Joker sans argent ni effets de vente.
Annuler
Confirmer avant de déchirer
Activer les codes de test
Ctrl gauche + Maj gauche + F8 : 1000 fragments, $100
#1# fragments / $#2# dans cette partie
#1# fragments + $#2#
Restaurer · #1# fragments + $#2#
#1# / #2# · #3# Jokers
+#1# fragments
Déchirer · +#1#
Recevez #1# fragments permanents.''',
    'es_ES': '''Taller de comodines
Restaurar comodín
Fragmentos
Todas las rarezas
Común
Inusual
Raro
Legendario
Volver a la tienda
Volver a los comodines
Elige un comodín. Los fragmentos se conservan entre partidas.
No hay comodines desbloqueados de esta rareza.
Pegatinas · precio en dólares
Alquiler
Perecedero
Eterno
No disponible
Solo sustituye el precio en dólares. Eterno + alquiler: $2.
Edición · fragmentos adicionales
Base
Laminada
Holográfica
Policromada
Negativa
El coste base en fragmentos sigue siendo obligatorio.
Pasa el cursor por la carta para ver su efecto.
Listo para restaurar
No hay suficientes fragmentos
No hay suficiente dinero
No hay espacio para otro comodín
Solo disponible en la tienda
Este comodín está bloqueado o prohibido
Estas pegatinas son incompatibles
Edición no válida
Error al guardar. No se ha gastado nada.
No se pudo crear el comodín. No se ha gastado nada.
Falta un mod necesario. Actívalo para recuperar la carta.
Fragmentos ya recibidos
Este comodín está protegido
Romper comodín
¿Romper este comodín?
Destruye el comodín sin dinero ni efectos de venta.
Cancelar
Confirmar antes de romper
Activar trucos de prueba
Ctrl izq. + Mayús izq. + F8: 1000 fragmentos, $100
#1# fragmentos / $#2# en esta partida
#1# fragmentos + $#2#
Restaurar · #1# fragmentos + $#2#
#1# / #2# · #3# comodines
+#1# fragmentos
Romper · +#1#
Recibes #1# fragmentos permanentes.''',
    'pt_BR': '''Oficina de Curingas
Restaurar curinga
Fragmentos
Todas as raridades
Comum
Incomum
Raro
Lendário
Voltar à loja
Voltar aos curingas
Escolha um curinga. Os fragmentos permanecem entre partidas.
Nenhum curinga desbloqueado desta raridade.
Adesivos · preço em dólares
Alugado
Perecível
Eterno
Indisponível
Substitui apenas o preço em dólares. Eterno + alugado: $2.
Edição · fragmentos extras
Base
Laminada
Holográfica
Policromática
Negativa
O custo base em fragmentos continua valendo.
Passe o cursor sobre a carta para ver o efeito.
Pronto para restaurar
Fragmentos insuficientes
Dinheiro insuficiente
Sem espaço para outro curinga
Disponível apenas na loja
Este curinga está bloqueado ou proibido
Estes adesivos são incompatíveis
Edição inválida
Falha ao salvar. Nada foi gasto.
Não foi possível criar o curinga. Nada foi gasto.
Falta um mod necessário. Ative-o para recuperar a carta.
Fragmentos já recebidos
Este curinga está protegido
Rasgar curinga
Rasgar este curinga?
Destrói o curinga sem dinheiro ou efeitos de venda.
Cancelar
Confirmar antes de rasgar
Ativar truques de teste
Ctrl esquerdo + Shift esquerdo + F8: 1000 fragmentos, $100
#1# fragmentos / $#2# nesta partida
#1# fragmentos + $#2#
Restaurar · #1# fragmentos + $#2#
#1# / #2# · #3# curingas
+#1# fragmentos
Rasgar · +#1#
Receba #1# fragmentos permanentes.''',
    'it': '''Officina dei Joker
Ripristina Joker
Frammenti
Tutte le rarità
Comune
Non comune
Raro
Leggendario
Torna al negozio
Torna ai Joker
Scegli un Joker. I frammenti restano tra una partita e l’altra.
Nessun Joker sbloccato di questa rarità.
Adesivi · prezzo in dollari
A noleggio
Deperibile
Eterno
Non disponibile
Sostituisce solo il prezzo in dollari. Eterno + noleggio: $2.
Edizione · frammenti aggiuntivi
Base
Laminata
Olografica
Policroma
Negativa
Il costo base in frammenti rimane invariato.
Passa il cursore sulla carta per vedere l’effetto.
Pronto per il ripristino
Frammenti insufficienti
Denaro insufficiente
Nessuno spazio Joker disponibile
Disponibile solo nel negozio
Questo Joker è bloccato o vietato
Questi adesivi sono incompatibili
Edizione non valida
Salvataggio fallito. Nessuna risorsa spesa.
Creazione fallita. Nessuna risorsa spesa.
Manca una mod necessaria. Riattivala per recuperare la carta.
Frammenti già ricevuti
Questo Joker è protetto
Strappa Joker
Strappare questo Joker?
Distrugge il Joker senza denaro né effetti di vendita.
Annulla
Conferma prima di strappare
Attiva trucchi di prova
Ctrl sinistro + Maiusc sinistro + F8: 1000 frammenti, $100
#1# frammenti / $#2# in questa partita
#1# frammenti + $#2#
Ripristina · #1# frammenti + $#2#
#1# / #2# · #3# Joker
+#1# frammenti
Strappa · +#1#
Ricevi #1# frammenti permanenti.''',
    'id': '''Bengkel Joker
Pulihkan Joker
Serpihan
Semua kelangkaan
Umum
Tidak umum
Langka
Legendaris
Kembali ke toko
Kembali ke Joker
Pilih Joker. Serpihan tetap tersimpan antarpermainan.
Belum ada Joker terbuka pada kelangkaan ini.
Stiker · harga dolar
Sewa
Mudah rusak
Abadi
Tidak tersedia
Hanya mengganti harga dolar. Abadi + sewa: $2.
Edisi · serpihan tambahan
Dasar
Foil
Holografis
Polikrom
Negatif
Biaya serpihan dasar tetap berlaku.
Arahkan kursor ke kartu untuk melihat efeknya.
Siap dipulihkan
Serpihan tidak cukup
Uang tidak cukup
Tidak ada slot Joker kosong
Hanya tersedia di toko
Joker ini terkunci atau dilarang
Stiker ini tidak bisa digabungkan
Edisi tidak valid
Gagal menyimpan. Tidak ada biaya yang dipotong.
Gagal membuat Joker. Tidak ada biaya yang dipotong.
Mod yang diperlukan tidak ada. Aktifkan kembali untuk memulihkan.
Serpihan sudah diterima
Joker ini dilindungi
Sobek Joker
Sobek Joker ini?
Menghancurkan Joker tanpa uang atau efek penjualan.
Batal
Konfirmasi sebelum menyobek
Aktifkan cheat pengujian
Ctrl kiri + Shift kiri + F8: 1000 serpihan, $100
#1# serpihan / $#2# dalam permainan ini
#1# serpihan + $#2#
Pulihkan · #1# serpihan + $#2#
#1# / #2# · #3# Joker
+#1# serpihan
Sobek · +#1#
Dapatkan #1# serpihan permanen.''',
    'ru': '''Мастерская джокеров
Восстановить джокера
Обрывки
Любая редкость
Обычный
Необычный
Редкий
Легендарный
Вернуться в магазин
К списку джокеров
Выберите джокера. Обрывки сохраняются между забегами.
Нет открытых джокеров этой редкости.
Наклейки · цена в долларах
Арендный
Портящийся
Вечный
Недоступно
Меняется только цена в долларах. Вечный + арендный: $2.
Издание · дополнительные обрывки
Обычное
Фольга
Голографическое
Полихромное
Негативное
Базовая стоимость в обрывках сохраняется.
Наведите курсор на карту, чтобы увидеть эффект.
Можно восстановить
Недостаточно обрывков
Недостаточно денег
Нет свободного места для джокера
Доступно только в магазине
Этот джокер закрыт или запрещён
Эти наклейки несовместимы
Недопустимое издание
Не удалось сохранить. Ресурсы не потрачены.
Не удалось создать джокера. Ресурсы не потрачены.
Нужный мод отсутствует. Включите его для восстановления.
Обрывки уже получены
Этот джокер защищён
Разорвать джокера
Разорвать этого джокера?
Уничтожает джокера без денег и эффектов продажи.
Отмена
Подтверждать разрыв джокера
Включить тестовые читы
Левые Ctrl + Shift + F8: 1000 обрывков, $100
#1# обрывков / $#2# в этом забеге
#1# обрывков + $#2#
Восстановить · #1# обрывков + $#2#
#1# / #2# · #3# джокеров
+#1# обрывков
Разорвать · +#1#
Вы получите #1# обрывков навсегда.''',
    'nl': '''Jokerwerkplaats
Joker herstellen
Snippers
Alle zeldzaamheden
Gewoon
Ongewoon
Zeldzaam
Legendarisch
Terug naar de winkel
Terug naar de Jokers
Kies een Joker. Snippers blijven bewaard tussen runs.
Geen vrijgespeelde Jokers van deze zeldzaamheid.
Stickers · dollarprijs
Gehuurd
Vergankelijk
Eeuwig
Niet beschikbaar
Vervangt alleen de dollarprijs. Eeuwig + gehuurd: $2.
Editie · extra snippers
Basis
Folie
Holografisch
Polychroom
Negatief
De basiskosten in snippers blijven gelden.
Beweeg de muis over de kaart voor het effect.
Klaar om te herstellen
Niet genoeg snippers
Niet genoeg geld
Geen vrije Jokerplek
Alleen beschikbaar in de winkel
Deze Joker is vergrendeld of verboden
Deze stickers zijn niet te combineren
Ongeldige editie
Opslaan mislukt. Er is niets uitgegeven.
Joker maken mislukt. Er is niets uitgegeven.
Een vereiste mod ontbreekt. Schakel deze weer in voor herstel.
Snippers al ontvangen
Deze Joker is beschermd
Joker verscheuren
Deze Joker verscheuren?
Vernietigt de Joker zonder verkoopgeld of verkoopeffecten.
Annuleren
Bevestigen vóór het verscheuren
Testcheats inschakelen
Linker Ctrl + linker Shift + F8: 1000 snippers, $100
#1# snippers / $#2# in deze run
#1# snippers + $#2#
Herstellen · #1# snippers + $#2#
#1# / #2# · #3# Jokers
+#1# snippers
Verscheuren · +#1#
Ontvang #1# blijvende snippers.''',
    'pl': '''Warsztat Jokerów
Odtwórz Jokera
Skrawki
Wszystkie rzadkości
Zwykły
Niezwykły
Rzadki
Legendarny
Powrót do sklepu
Powrót do Jokerów
Wybierz Jokera. Skrawki pozostają między rozgrywkami.
Brak odblokowanych Jokerów tej rzadkości.
Naklejki · cena w dolarach
Wynajęty
Nietrwały
Wieczny
Niedostępne
Zmienia tylko cenę w dolarach. Wieczny + wynajęty: $2.
Edycja · dodatkowe skrawki
Podstawowa
Folia
Holograficzna
Polichromia
Negatyw
Podstawowy koszt w skrawkach pozostaje bez zmian.
Najedź na kartę, aby zobaczyć efekt.
Można odtworzyć
Za mało skrawków
Za mało pieniędzy
Brak wolnego miejsca na Jokera
Dostępne tylko w sklepie
Ten Joker jest zablokowany lub zabroniony
Tych naklejek nie można łączyć
Nieprawidłowa edycja
Zapis nieudany. Niczego nie wydano.
Nie udało się utworzyć Jokera. Niczego nie wydano.
Brakuje wymaganej modyfikacji. Włącz ją ponownie, aby odzyskać kartę.
Skrawki już odebrano
Ten Joker jest chroniony
Podrzyj Jokera
Podrzeć tego Jokera?
Niszczy Jokera bez pieniędzy i efektów sprzedaży.
Anuluj
Potwierdzaj przed podarciem
Włącz kody testowe
Lewy Ctrl + lewy Shift + F8: 1000 skrawków, $100
#1# skrawków / $#2# w tej rozgrywce
#1# skrawków + $#2#
Odtwórz · #1# skrawków + $#2#
#1# / #2# · #3# Jokerów
+#1# skrawków
Podrzyj · +#1#
Otrzymasz na stałe #1# skrawków.''',
}
translations['es_419'] = translations['es_ES'].replace('coste', 'costo').replace('Mayús izq.', 'Shift izq.')

for language, text in translations.items():
    # The game's pixel font lacks middle dot and curly apostrophe glyphs.
    if language not in {'ja', 'zh_CN', 'zh_TW', 'ru'}:
        text = text.replace('\u00b7', '/').replace('\u2019', "'")
    values = text.splitlines()
    assert len(values) == len(keys), (language, len(values), len(keys))
    sections = {'dictionary': dict(zip(keys[:46], values[:46])), 'v_dictionary': dict(zip(keys[46:], values[46:]))}
    lines = ['return {misc = {']
    for section, entries in sections.items():
        lines.append(section + ' = {')
        for key, value in entries.items():
            lines.append('    jrc_' + key + ' = ' + json.dumps(value, ensure_ascii=False) + ',')
        lines.append('},')
    lines.append('}}')
    (folder / (language + '.lua')).write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f'Generated {len(translations)} complete locales; Korean and English retained.')
