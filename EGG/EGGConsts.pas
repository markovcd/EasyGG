{
    Komponent obs≥ugujπcy klienta sieci Gadu-Gadu. Pisany na podstawie
    specyfikacji na toxygen.net/libgadu/protocol.
    Copyright (C) 2009 markovcd
    markovcd@gmail.com    |    www.mdev.eu.tt

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
}


unit EGGConsts;
  { Unit zawiera podstawowe sta≥e i struktury protoko≥u }

interface

  const GG_VERSION = '8.0.0.7669'; // Wersja klienta GG
  const GG_VERSION_DESCR = 'Gadu-Gadu Client build 8.0.0.7669';
  const GG_LANG = 'pl';

          (* $Id: protocol.html 866 2009-10-13 22:42:35Z wojtekka $ *)
          (*          http://toxygen.net/libgadu/protocol           *)

// ====================== 1.1. Format pakietÛw i konwencje =====================

  { Notka o kompatybilnoúci:
  Nazwy typÛw rekordÛw bÍdπ zaczynaÊ siÍ literπ T.
  Nazwy zmiennych "type" i "class" zosta≥y zmienione odpowiednio na "typ" i
  "clas" ze wzglÍdu na kluczowe s≥owa jÍzyka Delphi. }

  { Wszystkie zmienne liczbowe sπ zgodne z kolejnoúciπ bajtÛw maszyn Intela,
  czyli Little-Endian. Wszystkie teksty sπ kodowane przy uøyciu zestawu znakÛw
  UTF-8, chyba øe zaznaczono inaczej. Linie koÒczπ siÍ znakami \r\n: }
  const rn = #13#10;

  {Przy opisie struktur, za≥oøono, øe char ma rozmiar 1 bajtu,
  short 2 bajtÛw, int 4 bajtÛw, long long 8 bajtÛw, wszystkie bez znaku: }
  //type int = LongWord;    // 4 bajty, bez znaku
  //type Word = Word;      // 2 bajty, bez znaku
  //type long_long = Int64; // W DELPHI NIE MA 8 BAJTOW BEZ ZNAKU! To cos ma 8 bajtow i znak
  type CharArray = array of char; // tablica znakow

  { Podobnie jak coraz wiÍksza iloúÊ komunikatorÛw, Gadu-Gadu korzysta z
  protoko≥u TCP/IP. Kaødy pakiet zawiera na poczπtku dwa sta≥e pola: }
  type Pgg_header = ^Tgg_header;
  Tgg_header = packed record
    typ: LongWord;	  // typ pakietu
	  length: LongWord; // d≥ugoúÊ reszty pakietu
  end;

// ========================== 1.2. Zanim siÍ po≥πczymy =========================

  { Øeby wiedzieÊ, z jakim serwerem mamy siÍ po≥πczyÊ, naleøy za pomocπ HTTP
  po≥πczyÊ siÍ z appmsg.gadu-gadu.pl i wys≥aÊ:
    GET /appsvc/appmsg_ver8.asp?fmnumber=NUMER&fmt=FORMAT&lastmsg=WIADOMOå∆&version=WERSJA HTTP/1.1
    Connection: Keep-Alive
    Host: appmsg.gadu-gadu.pl }

  { Zajmuje siÍ tym procedura BeforeConnect w klasie TEasyGG. W razie
  braku portÛw skorzystamy z domyúlnych: }
  const
    GG_DEFAULT_PORT1 = 8074;
    GG_DEFAULT_PORT2 = 443;
  

// ============================ 1.3. Logowanie siÍ =============================

  { Po po≥πczeniu siÍ portem 8074 lub 443 serwera Gadu-Gadu, otrzymujemy
  pakiet typu 0x0001, ktÛry na potrzeby tego dokumentu nazwiemy: }
  const GG_WELCOME = $0001;

  { Reszta pakietu zawiera ziarno ó wartoúÊ, ktÛrπ razem z has≥em
  przekazuje siÍ do funkcji skrÛtu: }
  type Pgg_welcome = ^Tgg_welcome;
  Tgg_welcome = packed record // gg_welcome w dokuentacji
    seed: LongWord; // ziarno
  end;

  { Kiedy mamy juø tπ wartoúÊ moøemy odes≥aÊ pakiet logowania: }
  const GG_LOGIN80 = $0031;

  type Tgg_login80 = packed record
    uin: LongWord;                      // numer Gadu-Gadu */
    language: array[0..1] of char;      // jÍzyk: "pl"
    hash_type: char;                    // rodzaj funkcji skrÛtu has≥a
    hash: array[0..63] of char;         // skrÛt has≥a dope≥niony \0
    status: LongWord;                   // poczπtkowy status po≥πczenia
    flags: LongWord;                    // poczπtkowe flagi po≥πczenia
    features: LongWord;                 // opcje protoko≥u (0x00000007)
    local_ip: LongWord;                 // lokalny adres po≥πczeÒ bezpoúrednich (nieuøywany)
    local_port: Word;                   // lokalny port po≥πczeÒ bezpoúrednich (nieuøywany)
    external_ip: LongWord;              // zewnÍtrzny adres (nieuøywany)
    external_port: Word;                // zewnÍtrzny port (nieuøywany)
    image_size: char;                   // maksymalny rozmiar grafiki w KB
    unknown2: char;                     // 0x64
    version_len: LongWord;              // d≥ugoúÊ ciπgu z wersjπ (0x21)
    version: array[0..32] of char;      // "Gadu-Gadu Client build 8.0.0.7669" (bez \0)
    description_size: LongWord;         // rozmiar opisu
    description: array[0..254] of char; // opis (nie musi wystπpiÊ, bez \0)
  end;
  { Pola okreúlajπce adresy i port sπ pozosta≥oúciami po poprzednich wersjach
  protoko≥Ûw i w obecnej wersji zawierajπ zera.
  Pole opcji protoko≥u zawsze zawiera wartoúÊ 0x00000007 i jest mapπ bitowπ: }
  const
    GG_FEATURES80 = $00000007 or $00000001 or $00000002 or $00000004 or $00000010;


  { SkrÛt has≥a moøna liczyÊ na dwa sposoby: }
  const GG_LOGIN_HASH_GG32 = #$01;
  const GG_LOGIN_HASH_SHA1 = #$02;
  { Pierwszy, nieuøywany juø algorytm (GG_LOGIN_HASH_GG32) zosta≥ wymyúlony na
  potrzeby Gadu-Gadu i zwraca 32-bitowπ wartoúÊ dla danego ziarna i has≥a. }

  {Ze wzglÍdu na niewielki zakres wartoúci wyjúciowych, istnieje
  prawdopodobieÒstwo, øe inne has≥o przy odpowiednim ziarnie da taki sam wynik.
  Z tego powodu zalecane jest uøywane algorytmu SHA-1, ktÛrego implementacje sπ
  dostÍpne dla wiÍkszoúci wspÛ≥czesnych systemÛw operacyjnych. SkrÛt SHA-1
  naleøy obliczyÊ z po≥πczenia has≥a (bez \0) i binarnej reprezentacji ziarna. }

  { Jeúli autoryzacja siÍ powiedzie, dostaniemy w odpowiedzi pakiet: }
  const GG_LOGIN80_OK = $0035;

  type Tgg_login80_ok = packed record
	  unknown1: LongWord;	// 01 00 00 00
  end;

  { W przypadku b≥Ídu autoryzacji otrzymamy pusty pakiet: }
  const GG_LOGIN_FAILED = $0009;


// ============================= 1.4. Zmiana stanu =============================

  { Gadu-Gadu przewiduje kilka stanÛw klienta, ktÛre zmieniamy pakietem typu: }
  const GG_NEW_STATUS80 = $0038;

  type Tgg_new_status80 = packed record
	  status: LongWord;		                // nowy status
	  flags: LongWord;                    // nowe flagi
	  description_size: LongWord;         // rozmiar opisu
	  description: array[0..254] of char;	// opis (nie musi wystπpiÊ, bez \0)
  end;

  { Moøliwe stany to: }
  const
    GG_STATUS_NOT_AVAIL = $0001;       // NiedostÍpny
    GG_STATUS_NOT_AVAIL_DESCR = $0015; // NiedostÍpny (z opisem)
    GG_STATUS_FFC = $0017;             // PoGGadaj ze mnπ
    GG_STATUS_FFC_DESCR = $0018;       // PoGGadaj ze mnπ (z opisem)
    GG_STATUS_AVAIL = $0002;           // DostÍpny
    GG_STATUS_AVAIL_DESCR = $0004;     // DostÍpny (z opisem)
    GG_STATUS_BUSY = $0003;            // ZajÍty
    GG_STATUS_BUSY_DESCR = $0005;      // ZajÍty (z opisem)
    GG_STATUS_DND = $0021;             // Nie przeszkadzaÊ
    GG_STATUS_DND_DESCR = $0022;       // Nie przeszkadzaÊ (z opisem)
    GG_STATUS_INVISIBLE = $0014 ;      // Niewidoczny
    GG_STATUS_INVISIBLE_DESCR = $0016; // Niewidoczny (z opisem)
    GG_STATUS_BLOCKED = $0006;         // Zablokowany
    GG_STATUS_IMAGE_MASK = $0100;      // Maska bitowa oznaczajπca ustawiony opis graficzny (tylko
    GG_STATUS_DESCR_MASK = $4000;      // Maska bitowa oznaczajπca ustawiony opis
    GG_STATUS_FRIENDS_MASK = $8000;    // Maska bitowa oznaczajπca tryb tylko dla przyjaciÛ≥

  { Flagi: }
  const
    GG_FLAGS80 = $00000001;
    GG_FLAGS80_URL = $00800000;

  { Jeúli klient obs≥uguje statusy graficzne, to statusy opisowe bÍdπ dodatkowo
  okreúlane przez dodanie flagi GG_STATUS_DESCR_MASK. Dotyczy to zarÛwno
  statusÛw wysy≥anych, jak i odbieranych z serwera.

  Naleøy pamiÍtaÊ, øeby przed roz≥πczeniem siÍ z serwerem naleøy zmieniÊ stan
  na GG_STATUS_NOT_AVAIL lub GG_STATUS_NOT_AVAIL_DESCR. Jeúli ma byÊ widoczny
  tylko dla przyjaciÛ≥, naleøy dodaÊ GG_STATUS_FRIENDS_MASK do normalnej
  wartoúci stanu.

  Maksymalna d≥ugoúÊ opisu wynosi 255 bajtÛw, jednak naleøy pamiÍtaÊ øe znak w
  UTF-8 czasami zajmuje wiÍcej niø 1 bajt. }


// ================== 1.5. Ludzie przychodzπ, ludzie odchodzπ ==================

  { Zaraz po zalogowaniu moøemy wys≥aÊ serwerowi naszπ listÍ kontaktÛw, øeby
  dowiedzieÊ siÍ, czy sπ w danej chwili dostÍpni. Lista kontaktÛw jest dzielona
  na pakiety po 400 wpisÛw. Pierwsze wpisy sπ typu GG_NOTIFY_FIRST, a ostatni
  typu GG_NOTIFY_LAST, øeby serwer wiedzia≥, kiedy koÒczymy. Jeúli lista
  kontaktÛw jest mniejsza niø 400 wpisÛw, wysy≥amy oczywiúcie tylko
  GG_NOTIFY_LAST. Pakiety te zawierajπ struktury gg_notify: }
  const GG_NOTIFY_FIRST = $000f;
  const GG_NOTIFY_LAST = $0010;

  type Tgg_notify = packed record
	  uin: LongWord; // numer Gadu-Gadu kontaktu
	  typ: Char;     // rodzaj uøytkownika
  end;

  { Gdzie pole type jest mapπ bitowπ nastÍpujπcych wartoúci: }
  const
    GG_USER_OFFLINE = $01;   // Kaødy uøytkownik dodany do listy kontaktÛw
    GG_USER_NORMAL  = $03;  // Uøytkownik, dla ktÛrego jesteúmy widoczni w trybie Ñtylko dla przyjaciÛ≥î
    GG_USER_BLOCKED = $04; // Uøytkownik, ktÛrego wiadomoúci nie chcemy otrzymywaÊ

  { Jeúli nie mamy nikogo na liúcie wysy≥amy nastÍpujπcy pakiet o zerowej
  d≥ugoúci: }
  const GG_LIST_EMPTY = $0012;

  { Jeúli ktoú jest, serwer odpowie pakietem GG_NOTIFY_REPLY80 zawierajπcym
  jednπ lub wiÍcej struktur gg_notify_reply80: }
  const GG_NOTIFY_REPLY80 = $37;
	
  type Pgg_notify_reply80 = ^Tgg_notify_reply80;
  Tgg_notify_reply80 = packed record
	  uin: LongWord;		                  // numer Gadu-Gadu kontaktu
	  status: LongWord;		                // status
	  flags: LongWord;		                // flagi (nieznane przeznaczenie)
	  remote_ip: LongWord;		            // adres IP bezpoúrednich po≥πczeÒ (nieuøywane)
	  remote_port: Word;	                // port bezpoúrednich po≥πczeÒ (nieuøywane)
	  image_size: char;	                  // maksymalny rozmiar obrazkÛw w KB
	  unknown2: char;		                  // 0x00
	  unknown3: LongWord;		              // 0x00000000
	  description_size: LongWord;	        // rozmiar opisu
	  description: array[0..254] of char; // opis (nie musi wystπpiÊ, bez \0)
  end;
  { Zdarzajπ siÍ teø inne Ñnietypoweî wartoúci, ale ich znaczenie nie jest
  jeszcze do koÒca znane. }

  { Aby dodaÊ do listy kontaktÛw numer w trakcie po≥πczenia, naleøy wys≥aÊ niøej
  opisany pakiet. Jego format jest identyczny jak GG_NOTIFY_*, z tπ rÛønicπ, øe
  zawiera jeden numer. }
  const GG_ADD_NOTIFY = $000d;
	
  type Tgg_add_notify = packed record
	  uin: LongWord; // numerek
	  typ: char;     // rodzaj uøytkownika
  end;

  { Poniøszy pakiet usuwa z listy kontaktÛw: }
  const GG_REMOVE_NOTIFY = $000e;
	
  type Tgg_remove_notify = packed record
	  uin: LongWord; // numerek
	  typ: char;     // rodzaj uøytkownika
  end;
  { Naleøy zwrÛciÊ uwagÍ, øe pakiety GG_ADD_NOTIFY i GG_REMOVE_NOTIFY dodajπ i
  usuwajπ flagi bÍdπce mapπ bitowπ. Aby zmieniÊ status uøytkownika z normalnego
  na blokowanego, naleøy najpierw usunπÊ rodzaj GG_USER_NORMAL, a nastÍpnie
  dodaÊ rodzaj GG_USER_BLOCKED. }

  { Jeúli ktoú opuúci Gadu-Gadu lub zmieni stan, otrzymamy poniøszy pakiet,
  ktÛrego struktura jest identyczna z GG_NOTIFY_REPLY80. }
  const GG_STATUS80 = $0036;


// ======================== 1.6. Wysy≥anie wiadomoúci ==========================

  { Wiadomoúci wysy≥a siÍ nastÍpujπcym typem pakietu: }
  const GG_SEND_MSG80 = $002d;

  type Tgg_send_msg80 = packed record
	  recipient: LongWord;		     // numer odbiorcy
	  seq: LongWord;		           // numer sekwencyjny
	  clas: LongWord;		           // klasa wiadomoúci
	  offset_plain: LongWord;	     // po≥oøenie treúci czystym tekstem
	  offset_attributes: LongWord; // po≥oøenie atrybutÛw
	  //html_message: PChar;	       // treúÊ w formacie HTML (zakoÒczona \0)
	  //plain_message: PChar;        // treúÊ czystym tekstem (zakoÒczona \0)
	  //attributes: PChar;	         // atrybuty wiadomoúci
  end;
  { Numer sekwencyjny w poprzednich wersjach protoko≥u by≥ losowπ liczbπ
  pozwalajπcπ przypisaÊ potwierdzenie do wiadomoúci. Obecnie jest znacznikiem
  czasu w postaci uniksowej (liczba sekund od 1 stycznia 1970r. UTC). }

  { Klasa wiadomoúci jest mapπ bitowπ (domyúlna wartoúÊ to 0x08): }
  const
    GG_CLASS_QUEUED = $0001; // Bit ustawiany wy≥πcznie przy odbiorze wiadomoúci, gdy wiadomoúÊ zosta≥a wczeúniej zakolejkowania z powodu nieobecnoúci
    GG_CLASS_MSG = $0004;    // WiadomoúÊ ma siÍ pojawiÊ w osobnym okienku (nieuøywane)
    GG_CLASS_CHAT = $0008;   // WiadomoúÊ jest czÍúciπ toczπcej siÍ rozmowy i zostanie wyúwietlona w istniejπcym okienku
    GG_CLASS_CTCP = $0010;   // WiadomoúÊ jest przeznaczona dla klienta Gadu-Gadu i nie powinna byÊ wyúwietlona uøytkownikowi (nieuøywane)
    GG_CLASS_ACK = $0020;    // Klient nie øyczy sobie potwierdzenia wiadomoúci

  { D≥ugoúÊ treúci wiadomoúci nie powinna przekraczaÊ 2000 znakÛw. Oryginalny
  klient zezwala na wys≥anie do 1989 znakÛw. TreúÊ w formacie HTML jest kodowana
  UTF-8. TreúÊ zapisana czystym tekstem jest kodowana zestawem znakÛw CP1250.
  W obu przypadkach, mimo domyúlnych atrybutÛw tekstu, oryginalny klient dodaje
  blok atrybutÛw tekstu. Dla HTML wyglπda to nastÍpujπco:
    <span style="color:#000000; font-family:'MS Shell Dlg 2'; font-size:9pt; ">Test</span> }

// ============================ 1.6.1. Konferencje =============================

  { Podczas konferencji ta sama wiadomoúÊ jest wysy≥ana do wszystkich odbiorcÛw,
  a do sekcji atrybutÛw do≥πczana jest lista pozosta≥ych uczestnikÛw
  konferencji. Dla przyk≥adu, jeúli w konferencji biorπ udzia≥ Ala, Bartek,
  Celina i Darek, to osoba Ala wysy≥a wysy≥a do Bartka wiadomoúÊ z listπ
  zawierajπcπ numery Celiny i Darka, do Celiny z numerami Bartka i Darka, a do
  Darka z numerami Bartka i Celiny. Lista pozosta≥ych uczestnikÛw konferencji
  jest przekazywana za pomocπ struktury: }
  type Tgg_msg_recipients = packed record
	  flag: char;		                           // 0x01
	  count: LongWord;		                     // liczba odbiorcÛw
	  //recipients: array[0..254] of LongWord;   // lista odbiorcÛw
  end;


// ========================= 1.6.2. Formatowanie tekstu ========================

  { Dla protoko≥u Nowego Gadu-Gadu natywnym formatem jest HTML, ale blok
  atrybutÛw rÛwnieø jest przesy≥any dla zachowania kompatybilnoúci ze starszymi
  klientami. }


// ============================ 1.6.2.1. Format HTML ===========================

  { Kaødy fragment tekstu o spÛjnych atrybutach jest zawarty w jednym znaczniku
  <span>, nawet jeúli sπ to atrybuty domyúlne. Dla przyk≥adu, wiadomoúÊ o
  treúci ÑTestî wys≥ana bez zmiany atrybutÛw tekstu przedstawia siÍ nastÍpujπco:
    <span style="color:#000000; font-family:'MS Shell Dlg 2'; font-size:9pt; ">Test</span> }

  { Oryginalny klient korzysta z nastÍpujπcych znacznikÛw HTML: 
      pogrubienie ó <b>
      kursywa ó <i>
      podkreúlenie ó <u>
      kolor t≥a ó <span style="background-color:#... ">
      kolor tekstu ó <span style="color:#... ">
      czcionka ó <span style="font-family:'...' ">
      rozmiar czcionki ó <span style="font-size:...pt ">
      nowa linia ó <br>
      obrazek ó <img src="..."> }

  { èrÛd≥o obrazka obrazka jest po≥πczeniem heksadecymalnego zapisu (ma≥ymi
  literami) sumy kontrolnej CRC32 oraz rozmiaru dope≥nionego do czterech bajtÛw.
  Dla obrazka o sumie kontrolnej 0x45fb2e46 i rozmiarze 16568 bajtÛw ürÛd≥em
  bÍdzie 45fb2e46000040b8. }

// ==================== 1.6.2.2. Czysty tekst z atrybutami =====================

  { Moøliwe jest rÛwnieø dodawanie do wiadomoúci rÛønych atrybutÛw tekstu, jak
  pogrubienie czy kolory. NiezbÍdne jest do≥πczenie do wiadomoúci nastÍpujπcej
  struktury: }
  type Tgg_msg_richtext = packed record
	  flag: char;	  // 0x02
	  length: Word; // d≥ugoúÊ dalszej czÍúci
  end;

  { Opis tej struktury niøej }
  type Tgg_msg_richtext_image = packed record
	  length: char;    // d≥ugoúÊ opisu obrazka (0x09)
	  typ: char;	     // rodzaj opisu obrazka (0x01)
	  size: LongWord;	 // rozmiar obrazka
	  crc32: LongWord; // suma kontrolna obrazka
  end;

  { Dalsza czÍúÊ pakietu zawiera odpowiedniπ iloúÊ struktur o ≥πcznej d≥ugoúci
  okreúlonej polem length: }
  type Tgg_msg_richtext_format = packed record
	  position: Word;	               // pozycja atrybutu w tekúcie
	  font: char;	                   // atrybuty czcionki
	  rgb: array[0..2] of char;	     // kolor czcionki (nie musi wystπpiÊ)
	  image: Tgg_msg_richtext_image; // obrazek (nie musi wystπpiÊ)
  end;

  { Kaøda z tych struktur okreúla kawa≥ek tekstu poczπwszy od znaku okreúlonego
  przez pole position (liczone od zera) aø do nastÍpnego wpisu lub koÒca tekstu.
  Pole font jest mapπ bitowπ i kolejne bity majπ nastÍpujπce znaczenie: }
  const
    GG_FONT_BOLD = $01;	     // Pogrubiony tekst
    GG_FONT_ITALIC = $02;	   // Kursywa
    GG_FONT_UNDERLINE =	$04; // Podkreúlenie
    GG_FONT_COLOR = $08;	   // Kolorowy tekst. Tylko w tym wypadku struktura gg_msg_richtext_format zawiera pole rgb[] bÍdπce opisem trzech sk≥adowych koloru, kolejno czerwonej, zielonej i niebieskiej.
    GG_FONT_IMAGE = $80;	   // Obrazek. Tylko w tym wypadku struktura gg_msg_richtext_format zawiera pole image.

  { Jeúli wiadomoúÊ zawiera obrazek, przesy≥ana jest jego suma kontrolna CRC32
  i rozmiar. DziÍki temu nie trzeba za kaødym razem wysy≥aÊ kaødego obrazka ó
  klienty je zachowujπ. Struktura gg_msg_richtext_image opisujπca obrazek
  umieszczony w wiadomoúci wyglπda nastÍpujπco: }
  {type Tgg_msg_richtext_image = packed record
	  length: char;    // d≥ugoúÊ opisu obrazka (0x09)
	  typ: char;	     // rodzaj opisu obrazka (0x01)
	  size: LongWord;	 // rozmiar obrazka
	  crc32: LongWord; // suma kontrolna obrazka
  end;} // STRUKTURE TE ZADEKLAROWANO PRZED JEJ UZYCIEM W gg_msg_richtext_format


// ======================== 1.6.3. Przesy≥anie obrazkÛw ========================

  { Gdy klient nie posiada w pamiÍci podrÍcznej obrazka o podanych parametrach,
  wysy≥a pustπ wiadomoúÊ o klasie GG_CLASS_MSG z do≥πczonπ strukturπ
  gg_msg_image_request: }
  type Tgg_msg_image_request = packed record
	  flag: char;	     // 0x04
	  size: LongWord;	 // rozmiar
	  crc32: LongWord; // suma kontrolna
  end;

  { W odpowiedzi, drugi klient wysy≥a obrazek za pomocπ wiadomoúci o zerowej
  d≥ugoúci (naleøy pamiÍtaÊ o koÒczπcym bajcie o wartoúci 0x00) z do≥πczonπ
  strukturπ gg_msg_image_reply: }
  type Tgg_msg_image_reply = packed record
	  flag: char;      	   // 0x05 lub 0x06
	  size: LongWord;      // rozmiar
	  crc32: LongWord;     // suma kontrolna
	  filename: CharArray; // nazwa pliku (nie musi wystπpiÊ)
	  image: CharArray;		 // zawartoúÊ obrazka (nie musi wystπpiÊ)
  end;
  { Jeúli d≥ugoúÊ struktury gg_msg_image_reply jest d≥uøsza niø 1909 bajtÛw,
  treúÊ obrazka jest dzielona na kilka pakietÛw nie przekraczajπcych 1909
  bajtÛw. Pierwszy pakiet ma pole flag rÛwne 0x05 i ma wype≥nione pole filename,
  a w kolejnych pole flag jest rÛwne 0x06 i pole filename w ogÛle nie wystÍpuje
  (nawet bajt zakoÒczenia ciπgu znakÛw).

  Jeúli otrzymamy pakiet bez pola filename oraz image, oznacza to, øe klient nie
  posiada øπdanego obrazka. }


// ============================ 1.6.4. Potwierdzenie ===========================

  { Serwer po otrzymaniu wiadomoúci odsy≥a potwierdzenie, ktÛre przy okazji mÛwi
  nam, czy wiadomoúÊ dotar≥a do odbiorcy czy zosta≥a zakolejkowana z powodu
  nieobecnoúci. Otrzymujemy je w postaci pakietu: }
  const GG_SEND_MSG_ACK = $0005;

  type Pgg_send_msg_ack = ^Tgg_send_msg_ack;
  Tgg_send_msg_ack = packed record
	  status: LongWord;	   // stan wiadomoúci
	  recipient: LongWord; // numer odbiorcy
	  seq: LongWord;	     // numer sekwencyjny
  end;

  { Numer sekwencyjny i numer adresata sπ takie same jak podczas wysy≥ania, a
  stan wiadomoúci moøe byÊ jednym z nastÍpujπcych: }
  const
    GG_ACK_BLOCKED = $0001;	      // Wiadomoúci nie przes≥ano (zdarza siÍ przy wiadomoúciach zawierajπcych adresy internetowe blokowanych przez serwer GG gdy odbiorca nie ma nas na liúcie)
    GG_ACK_DELIVERED = $0002;	    // WiadomoúÊ dostarczono
    GG_ACK_QUEUED = $0003;	      // WiadomoúÊ zakolejkowano
    GG_ACK_MBOXFULL = $0004;	    // Wiadomoúci nie dostarczono. Skrzynka odbiorcza na serwerze jest pe≥na (20 wiadomoúci maks). WystÍpuje tylko w trybie offline
    GG_ACK_NOT_DELIVERED = $0006;	// Wiadomoúci nie dostarczono. Odpowiedü ta wystÍpuje tylko w przypadku wiadomoúci klasy GG_CLASS_CTCP


// ======================== 1.7. Otrzymywanie wiadomoúci =======================

  { Wiadomoúci serwer przysy≥a za pomocπ pakietu: }
  const GG_RECV_MSG80 = $002e;

  type Tgg_recv_msg80 = packed record
	  sender: LongWord;		         // numer nadawcy
	  seq: LongWord;		           // numer sekwencyjny
	  time: LongWord;		           // czas nadania
	  clas: LongWord;		           // klasa wiadomoúci
	  offset_plain: LongWord;	     // po≥oøenie treúci czystym tekstem
	  offset_attributes: LongWord; // po≥oøenie atrybutÛw
	  html_message: PChar;	       // treúÊ w formacie HTML (zakoÒczona \0)
	  plain_message: PChar;        // treúÊ czystym tekstem (zakoÒczona \0)
	  attributes: array of Byte;	 // atrybuty wiadomoúci
  end;
  { Czas nadania jest zapisany w postaci UTC, jako iloúci sekund od 1 stycznia
  1970r. W przypadku pakietÛw Ñkonferencyjnychî na koÒcu pakietu doklejona jest
  struktura identyczna z gg_msg_recipients zawierajπca pozosta≥ych rozmÛwcÛw. }


// ============================== 1.8. Ping, pong ==============================

  { Od czasu do czasu klient wysy≥a pakiet do serwera, by oznajmiÊ, øe
  po≥πczenie jeszcze jest utrzymywane. Jeúli serwer nie dostanie takiego pakietu
  w przeciπgu 5 minut, zrywa po≥πczenie. To, czy klient dostaje odpowiedü
  zmienia siÍ z wersji na wersjÍ, wiÍc najlepiej nie polegaÊ na tym. }
  const
    GG_PING = $0008;
    GG_PONG = $0007;


// ============================== 1.9. Roz≥πczenie =============================

  { Jeúli serwer zechce nas roz≥πczyÊ, wyúle wczeúniej pusty pakiet: }
  const GG_DISCONNECTING = $000b;
  { Ma to miejsce, gdy prÛbowano zbyt wiele razy po≥πczyÊ siÍ z nieprawid≥owym
  has≥em (wtedy pakiet zostanie wys≥any w odpowiedzi na GG_LOGIN70), lub gdy
  rÛwnoczeúnie po≥πczy siÍ drugi klient z tym samym numerem (nowe po≥πczenie ma
  wyøszy priorytet). }

  { W nowych wersjach protoko≥u (prawdopodobnie od 0x29), po wys≥aniu pakietu
  zmieniajπcego status na niedostÍpny, serwer przysy≥a pakiet: }
  const GG_DISCONNECT_ACK = $000d;
  { Jest to potwierdzenie, øe serwer odebra≥ pakiet zmiany stanu i klient moøe
  zakoÒczyÊ po≥πczenie majπc pewnoúÊ, øe zostanie ustawiony øπdany opis. }


// ======================== 1.10. Wiadomoúci systemowe =========================

  { Od wersji 7.7 serwer moøe wysy≥aÊ nam wiadomoúci systemowe przy pomocy
  pakietu: }
  const GG_XML_EVENT = $0027;


// ======================= 1.11. Wiadomoúci GG_XML_ACTION ======================

  { Narazie nie przewidujÍ ich obs≥ugi. }


// ========================== 1.12. Katalog publiczny ==========================

  { Nowe Gadu-Gadu korzysta z OAutha do odczytu oraz zmian danych w katalogu,
  API opisane jest na: http://dev.gadu-gadu.pl/api/pages/gaduapi.html

  Nowe Gadu-Gadu korzysta z wyszukiwarki dostÍpnej na:
  http://ipubdir.gadu-gadu.pl/ngg/ }


// =========================== 1.13. Lista kontaktÛw ===========================

  { Od wersji 6.0 lista kontaktÛw na serwerze sta≥a czÍúciπ sesji, zamiast
  osobnej sesji HTTP. Aby wys≥aÊ lub pobraÊ listÍ kontaktÛw z serwera naleøy
  uøyÊ pakietu: }

  const GG_USERLIST_REQUEST80 = $002f;

  type Tgg_userlist_request = packed record
	  typ: char;		                   // rodzaj zapytania
	  request: array[0..2047] of char; // treúÊ (nie musi wystπpiÊ)
  end;

  { Pole type oznacza rodzaj zapytania: }
  const
    GG_USERLIST_PUT = $00;      // poczπtek eksportu listy
    GG_USERLIST_PUT_MORE = $01; // dalsza czÍúÊ eksportu listy
    GG_USERLIST_GET = $02;      // import listy

  { W przypadku eksportu listy kontaktÛw, pole request zawiera dokument XML
  opisany na stronie http://dev.gadu-gadu.pl/api/pages/formaty_plikow.html
  skompresowany algorytmem Deflate. WolnodostÍpna implementacja algorytmu,
  uøywana rÛwnieø przez oryginalnego klienta, znajduje siÍ w biblotece zlib.

  Podczas przesy≥ania lista kontaktÛw jest dzielona na pakiety po 2048 bajtÛw.
  Pierwszy jest wysy≥any pakietem typu GG_USERLIST_PUT, øeby uaktualniÊ plik
  na serwerze, pozosta≥e typu GG_USERLIST_PUT_MORE, øeby dopisaÊ do pliku. }

  { Na zapytania dotyczπce listy kontaktÛw serwer odpowiada pakietem: }
  const GG_USERLIST_REPLY80 = $0030;

  type Pgg_userlist_reply = ^Tgg_userlist_reply;
  Tgg_userlist_reply = packed record
	  typ: char;		                 // rodzaj zapytania
	  reply: array[0..2047] of char; // treúÊ (nie musi wystπpiÊ)
  end;

  { Pole type oznacza rodzaj odpowiedzi: }
  const
    GG_USERLIST_PUT_REPLY = $00;      // poczπtek eksportu listy
    GG_USERLIST_PUT_MORE_REPLY = $02; // kontynuacja
    GG_USERLIST_GET_MORE_REPLY = $04; // poczπtek importu listy
    GG_USERLIST_GET_REPLY = $06;      // ostatnia czÍúÊ importu

  { W przypadku importu w polu request znajdzie siÍ lista kontaktÛw w takiej
  samej postaci, w jakiej jπ umieszczono. Serwer nie ingeruje w jej treúÊ.
  Podobnie jak przy wysy≥aniu, przychodzi podzielona na mniejsze pakiety.
  Pobieranie krÛtkiej listy kontaktÛw zwykle powoduje wys≥anie pojedynczego
  pakietu GG_USERLIST_GET_REPLY, a gdy lista jest d≥uga, serwer moøe przys≥aÊ
  dowolnπ iloúÊ pakietÛw GG_USERLIST_GET_MORE_REPLY przed pakietem
  GG_USERLIST_GET_REPLY. }

  { Aby usunπÊ listÍ kontaktÛw z serwera oryginalny klient wysy≥a spacjÍ jako
  listÍ kontaktÛw czego wynikiem jest pole request o zawartoúci: 
    78 da 53 00 00 00 21 00 21}

implementation

end.
