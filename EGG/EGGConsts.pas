{
    Komponent obs�uguj�cy klienta sieci Gadu-Gadu. Pisany na podstawie
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
  { Unit zawiera podstawowe sta�e i struktury protoko�u }

interface

  const GG_VERSION = '8.0.0.7669'; // Wersja klienta GG
  const GG_VERSION_DESCR = 'Gadu-Gadu Client build 8.0.0.7669';
  const GG_LANG = 'pl';

          (* $Id: protocol.html 866 2009-10-13 22:42:35Z wojtekka $ *)
          (*          http://toxygen.net/libgadu/protocol           *)

// ====================== 1.1. Format pakiet�w i konwencje =====================

  { Notka o kompatybilno�ci:
  Nazwy typ�w rekord�w b�d� zaczyna� si� liter� T.
  Nazwy zmiennych "type" i "class" zosta�y zmienione odpowiednio na "typ" i
  "clas" ze wzgl�du na kluczowe s�owa j�zyka Delphi. }

  { Wszystkie zmienne liczbowe s� zgodne z kolejno�ci� bajt�w maszyn Intela,
  czyli Little-Endian. Wszystkie teksty s� kodowane przy u�yciu zestawu znak�w
  UTF-8, chyba �e zaznaczono inaczej. Linie ko�cz� si� znakami \r\n: }
  const rn = #13#10;

  {Przy opisie struktur, za�o�ono, �e char ma rozmiar 1 bajtu,
  short 2 bajt�w, int 4 bajt�w, long long 8 bajt�w, wszystkie bez znaku: }
  //type int = LongWord;    // 4 bajty, bez znaku
  //type Word = Word;      // 2 bajty, bez znaku
  //type long_long = Int64; // W DELPHI NIE MA 8 BAJTOW BEZ ZNAKU! To cos ma 8 bajtow i znak
  type CharArray = array of char; // tablica znakow

  { Podobnie jak coraz wi�ksza ilo�� komunikator�w, Gadu-Gadu korzysta z
  protoko�u TCP/IP. Ka�dy pakiet zawiera na pocz�tku dwa sta�e pola: }
  type Pgg_header = ^Tgg_header;
  Tgg_header = packed record
    typ: LongWord;	  // typ pakietu
	  length: LongWord; // d�ugo�� reszty pakietu
  end;

// ========================== 1.2. Zanim si� po��czymy =========================

  { �eby wiedzie�, z jakim serwerem mamy si� po��czy�, nale�y za pomoc� HTTP
  po��czy� si� z appmsg.gadu-gadu.pl i wys�a�:
    GET /appsvc/appmsg_ver8.asp?fmnumber=NUMER&fmt=FORMAT&lastmsg=WIADOMO��&version=WERSJA HTTP/1.1
    Connection: Keep-Alive
    Host: appmsg.gadu-gadu.pl }

  { Zajmuje si� tym procedura BeforeConnect w klasie TEasyGG. W razie
  braku port�w skorzystamy z domy�lnych: }
  const
    GG_DEFAULT_PORT1 = 8074;
    GG_DEFAULT_PORT2 = 443;
  

// ============================ 1.3. Logowanie si� =============================

  { Po po��czeniu si� portem 8074 lub 443 serwera Gadu-Gadu, otrzymujemy
  pakiet typu 0x0001, kt�ry na potrzeby tego dokumentu nazwiemy: }
  const GG_WELCOME = $0001;

  { Reszta pakietu zawiera ziarno � warto��, kt�r� razem z has�em
  przekazuje si� do funkcji skr�tu: }
  type Pgg_welcome = ^Tgg_welcome;
  Tgg_welcome = packed record // gg_welcome w dokuentacji
    seed: LongWord; // ziarno
  end;

  { Kiedy mamy ju� t� warto�� mo�emy odes�a� pakiet logowania: }
  const GG_LOGIN80 = $0031;

  type Tgg_login80 = packed record
    uin: LongWord;                      // numer Gadu-Gadu */
    language: array[0..1] of char;      // j�zyk: "pl"
    hash_type: char;                    // rodzaj funkcji skr�tu has�a
    hash: array[0..63] of char;         // skr�t has�a dope�niony \0
    status: LongWord;                   // pocz�tkowy status po��czenia
    flags: LongWord;                    // pocz�tkowe flagi po��czenia
    features: LongWord;                 // opcje protoko�u (0x00000007)
    local_ip: LongWord;                 // lokalny adres po��cze� bezpo�rednich (nieu�ywany)
    local_port: Word;                   // lokalny port po��cze� bezpo�rednich (nieu�ywany)
    external_ip: LongWord;              // zewn�trzny adres (nieu�ywany)
    external_port: Word;                // zewn�trzny port (nieu�ywany)
    image_size: char;                   // maksymalny rozmiar grafiki w KB
    unknown2: char;                     // 0x64
    version_len: LongWord;              // d�ugo�� ci�gu z wersj� (0x21)
    version: array[0..32] of char;      // "Gadu-Gadu Client build 8.0.0.7669" (bez \0)
    description_size: LongWord;         // rozmiar opisu
    description: array[0..254] of char; // opis (nie musi wyst�pi�, bez \0)
  end;
  { Pola okre�laj�ce adresy i port s� pozosta�o�ciami po poprzednich wersjach
  protoko��w i w obecnej wersji zawieraj� zera.
  Pole opcji protoko�u zawsze zawiera warto�� 0x00000007 i jest map� bitow�: }
  const
    GG_FEATURES80 = $00000007 or $00000001 or $00000002 or $00000004 or $00000010;


  { Skr�t has�a mo�na liczy� na dwa sposoby: }
  const GG_LOGIN_HASH_GG32 = #$01;
  const GG_LOGIN_HASH_SHA1 = #$02;
  { Pierwszy, nieu�ywany ju� algorytm (GG_LOGIN_HASH_GG32) zosta� wymy�lony na
  potrzeby Gadu-Gadu i zwraca 32-bitow� warto�� dla danego ziarna i has�a. }

  {Ze wzgl�du na niewielki zakres warto�ci wyj�ciowych, istnieje
  prawdopodobie�stwo, �e inne has�o przy odpowiednim ziarnie da taki sam wynik.
  Z tego powodu zalecane jest u�ywane algorytmu SHA-1, kt�rego implementacje s�
  dost�pne dla wi�kszo�ci wsp�czesnych system�w operacyjnych. Skr�t SHA-1
  nale�y obliczy� z po��czenia has�a (bez \0) i binarnej reprezentacji ziarna. }

  { Je�li autoryzacja si� powiedzie, dostaniemy w odpowiedzi pakiet: }
  const GG_LOGIN80_OK = $0035;

  type Tgg_login80_ok = packed record
	  unknown1: LongWord;	// 01 00 00 00
  end;

  { W przypadku b��du autoryzacji otrzymamy pusty pakiet: }
  const GG_LOGIN_FAILED = $0009;


// ============================= 1.4. Zmiana stanu =============================

  { Gadu-Gadu przewiduje kilka stan�w klienta, kt�re zmieniamy pakietem typu: }
  const GG_NEW_STATUS80 = $0038;

  type Tgg_new_status80 = packed record
	  status: LongWord;		                // nowy status
	  flags: LongWord;                    // nowe flagi
	  description_size: LongWord;         // rozmiar opisu
	  description: array[0..254] of char;	// opis (nie musi wyst�pi�, bez \0)
  end;

  { Mo�liwe stany to: }
  const
    GG_STATUS_NOT_AVAIL = $0001;       // Niedost�pny
    GG_STATUS_NOT_AVAIL_DESCR = $0015; // Niedost�pny (z opisem)
    GG_STATUS_FFC = $0017;             // PoGGadaj ze mn�
    GG_STATUS_FFC_DESCR = $0018;       // PoGGadaj ze mn� (z opisem)
    GG_STATUS_AVAIL = $0002;           // Dost�pny
    GG_STATUS_AVAIL_DESCR = $0004;     // Dost�pny (z opisem)
    GG_STATUS_BUSY = $0003;            // Zaj�ty
    GG_STATUS_BUSY_DESCR = $0005;      // Zaj�ty (z opisem)
    GG_STATUS_DND = $0021;             // Nie przeszkadza�
    GG_STATUS_DND_DESCR = $0022;       // Nie przeszkadza� (z opisem)
    GG_STATUS_INVISIBLE = $0014 ;      // Niewidoczny
    GG_STATUS_INVISIBLE_DESCR = $0016; // Niewidoczny (z opisem)
    GG_STATUS_BLOCKED = $0006;         // Zablokowany
    GG_STATUS_IMAGE_MASK = $0100;      // Maska bitowa oznaczaj�ca ustawiony opis graficzny (tylko
    GG_STATUS_DESCR_MASK = $4000;      // Maska bitowa oznaczaj�ca ustawiony opis
    GG_STATUS_FRIENDS_MASK = $8000;    // Maska bitowa oznaczaj�ca tryb tylko dla przyjaci�

  { Flagi: }
  const
    GG_FLAGS80 = $00000001;
    GG_FLAGS80_URL = $00800000;

  { Je�li klient obs�uguje statusy graficzne, to statusy opisowe b�d� dodatkowo
  okre�lane przez dodanie flagi GG_STATUS_DESCR_MASK. Dotyczy to zar�wno
  status�w wysy�anych, jak i odbieranych z serwera.

  Nale�y pami�ta�, �eby przed roz��czeniem si� z serwerem nale�y zmieni� stan
  na GG_STATUS_NOT_AVAIL lub GG_STATUS_NOT_AVAIL_DESCR. Je�li ma by� widoczny
  tylko dla przyjaci�, nale�y doda� GG_STATUS_FRIENDS_MASK do normalnej
  warto�ci stanu.

  Maksymalna d�ugo�� opisu wynosi 255 bajt�w, jednak nale�y pami�ta� �e znak w
  UTF-8 czasami zajmuje wi�cej ni� 1 bajt. }


// ================== 1.5. Ludzie przychodz�, ludzie odchodz� ==================

  { Zaraz po zalogowaniu mo�emy wys�a� serwerowi nasz� list� kontakt�w, �eby
  dowiedzie� si�, czy s� w danej chwili dost�pni. Lista kontakt�w jest dzielona
  na pakiety po 400 wpis�w. Pierwsze wpisy s� typu GG_NOTIFY_FIRST, a ostatni
  typu GG_NOTIFY_LAST, �eby serwer wiedzia�, kiedy ko�czymy. Je�li lista
  kontakt�w jest mniejsza ni� 400 wpis�w, wysy�amy oczywi�cie tylko
  GG_NOTIFY_LAST. Pakiety te zawieraj� struktury gg_notify: }
  const GG_NOTIFY_FIRST = $000f;
  const GG_NOTIFY_LAST = $0010;

  type Tgg_notify = packed record
	  uin: LongWord; // numer Gadu-Gadu kontaktu
	  typ: Char;     // rodzaj u�ytkownika
  end;

  { Gdzie pole type jest map� bitow� nast�puj�cych warto�ci: }
  const
    GG_USER_OFFLINE = $01;   // Ka�dy u�ytkownik dodany do listy kontakt�w
    GG_USER_NORMAL  = $03;  // U�ytkownik, dla kt�rego jeste�my widoczni w trybie �tylko dla przyjaci�
    GG_USER_BLOCKED = $04; // U�ytkownik, kt�rego wiadomo�ci nie chcemy otrzymywa�

  { Je�li nie mamy nikogo na li�cie wysy�amy nast�puj�cy pakiet o zerowej
  d�ugo�ci: }
  const GG_LIST_EMPTY = $0012;

  { Je�li kto� jest, serwer odpowie pakietem GG_NOTIFY_REPLY80 zawieraj�cym
  jedn� lub wi�cej struktur gg_notify_reply80: }
  const GG_NOTIFY_REPLY80 = $37;
	
  type Pgg_notify_reply80 = ^Tgg_notify_reply80;
  Tgg_notify_reply80 = packed record
	  uin: LongWord;		                  // numer Gadu-Gadu kontaktu
	  status: LongWord;		                // status
	  flags: LongWord;		                // flagi (nieznane przeznaczenie)
	  remote_ip: LongWord;		            // adres IP bezpo�rednich po��cze� (nieu�ywane)
	  remote_port: Word;	                // port bezpo�rednich po��cze� (nieu�ywane)
	  image_size: char;	                  // maksymalny rozmiar obrazk�w w KB
	  unknown2: char;		                  // 0x00
	  unknown3: LongWord;		              // 0x00000000
	  description_size: LongWord;	        // rozmiar opisu
	  description: array[0..254] of char; // opis (nie musi wyst�pi�, bez \0)
  end;
  { Zdarzaj� si� te� inne �nietypowe� warto�ci, ale ich znaczenie nie jest
  jeszcze do ko�ca znane. }

  { Aby doda� do listy kontakt�w numer w trakcie po��czenia, nale�y wys�a� ni�ej
  opisany pakiet. Jego format jest identyczny jak GG_NOTIFY_*, z t� r�nic�, �e
  zawiera jeden numer. }
  const GG_ADD_NOTIFY = $000d;
	
  type Tgg_add_notify = packed record
	  uin: LongWord; // numerek
	  typ: char;     // rodzaj u�ytkownika
  end;

  { Poni�szy pakiet usuwa z listy kontakt�w: }
  const GG_REMOVE_NOTIFY = $000e;
	
  type Tgg_remove_notify = packed record
	  uin: LongWord; // numerek
	  typ: char;     // rodzaj u�ytkownika
  end;
  { Nale�y zwr�ci� uwag�, �e pakiety GG_ADD_NOTIFY i GG_REMOVE_NOTIFY dodaj� i
  usuwaj� flagi b�d�ce map� bitow�. Aby zmieni� status u�ytkownika z normalnego
  na blokowanego, nale�y najpierw usun�� rodzaj GG_USER_NORMAL, a nast�pnie
  doda� rodzaj GG_USER_BLOCKED. }

  { Je�li kto� opu�ci Gadu-Gadu lub zmieni stan, otrzymamy poni�szy pakiet,
  kt�rego struktura jest identyczna z GG_NOTIFY_REPLY80. }
  const GG_STATUS80 = $0036;


// ======================== 1.6. Wysy�anie wiadomo�ci ==========================

  { Wiadomo�ci wysy�a si� nast�puj�cym typem pakietu: }
  const GG_SEND_MSG80 = $002d;

  type Tgg_send_msg80 = packed record
	  recipient: LongWord;		     // numer odbiorcy
	  seq: LongWord;		           // numer sekwencyjny
	  clas: LongWord;		           // klasa wiadomo�ci
	  offset_plain: LongWord;	     // po�o�enie tre�ci czystym tekstem
	  offset_attributes: LongWord; // po�o�enie atrybut�w
	  //html_message: PChar;	       // tre�� w formacie HTML (zako�czona \0)
	  //plain_message: PChar;        // tre�� czystym tekstem (zako�czona \0)
	  //attributes: PChar;	         // atrybuty wiadomo�ci
  end;
  { Numer sekwencyjny w poprzednich wersjach protoko�u by� losow� liczb�
  pozwalaj�c� przypisa� potwierdzenie do wiadomo�ci. Obecnie jest znacznikiem
  czasu w postaci uniksowej (liczba sekund od 1 stycznia 1970r. UTC). }

  { Klasa wiadomo�ci jest map� bitow� (domy�lna warto�� to 0x08): }
  const
    GG_CLASS_QUEUED = $0001; // Bit ustawiany wy��cznie przy odbiorze wiadomo�ci, gdy wiadomo�� zosta�a wcze�niej zakolejkowania z powodu nieobecno�ci
    GG_CLASS_MSG = $0004;    // Wiadomo�� ma si� pojawi� w osobnym okienku (nieu�ywane)
    GG_CLASS_CHAT = $0008;   // Wiadomo�� jest cz�ci� tocz�cej si� rozmowy i zostanie wy�wietlona w istniej�cym okienku
    GG_CLASS_CTCP = $0010;   // Wiadomo�� jest przeznaczona dla klienta Gadu-Gadu i nie powinna by� wy�wietlona u�ytkownikowi (nieu�ywane)
    GG_CLASS_ACK = $0020;    // Klient nie �yczy sobie potwierdzenia wiadomo�ci

  { D�ugo�� tre�ci wiadomo�ci nie powinna przekracza� 2000 znak�w. Oryginalny
  klient zezwala na wys�anie do 1989 znak�w. Tre�� w formacie HTML jest kodowana
  UTF-8. Tre�� zapisana czystym tekstem jest kodowana zestawem znak�w CP1250.
  W obu przypadkach, mimo domy�lnych atrybut�w tekstu, oryginalny klient dodaje
  blok atrybut�w tekstu. Dla HTML wygl�da to nast�puj�co:
    <span style="color:#000000; font-family:'MS Shell Dlg 2'; font-size:9pt; ">Test</span> }

// ============================ 1.6.1. Konferencje =============================

  { Podczas konferencji ta sama wiadomo�� jest wysy�ana do wszystkich odbiorc�w,
  a do sekcji atrybut�w do��czana jest lista pozosta�ych uczestnik�w
  konferencji. Dla przyk�adu, je�li w konferencji bior� udzia� Ala, Bartek,
  Celina i Darek, to osoba Ala wysy�a wysy�a do Bartka wiadomo�� z list�
  zawieraj�c� numery Celiny i Darka, do Celiny z numerami Bartka i Darka, a do
  Darka z numerami Bartka i Celiny. Lista pozosta�ych uczestnik�w konferencji
  jest przekazywana za pomoc� struktury: }
  type Tgg_msg_recipients = packed record
	  flag: char;		                           // 0x01
	  count: LongWord;		                     // liczba odbiorc�w
	  //recipients: array[0..254] of LongWord;   // lista odbiorc�w
  end;


// ========================= 1.6.2. Formatowanie tekstu ========================

  { Dla protoko�u Nowego Gadu-Gadu natywnym formatem jest HTML, ale blok
  atrybut�w r�wnie� jest przesy�any dla zachowania kompatybilno�ci ze starszymi
  klientami. }


// ============================ 1.6.2.1. Format HTML ===========================

  { Ka�dy fragment tekstu o sp�jnych atrybutach jest zawarty w jednym znaczniku
  <span>, nawet je�li s� to atrybuty domy�lne. Dla przyk�adu, wiadomo�� o
  tre�ci �Test� wys�ana bez zmiany atrybut�w tekstu przedstawia si� nast�puj�co:
    <span style="color:#000000; font-family:'MS Shell Dlg 2'; font-size:9pt; ">Test</span> }

  { Oryginalny klient korzysta z nast�puj�cych znacznik�w HTML: 
      pogrubienie � <b>
      kursywa � <i>
      podkre�lenie � <u>
      kolor t�a � <span style="background-color:#... ">
      kolor tekstu � <span style="color:#... ">
      czcionka � <span style="font-family:'...' ">
      rozmiar czcionki � <span style="font-size:...pt ">
      nowa linia � <br>
      obrazek � <img src="..."> }

  { �r�d�o obrazka obrazka jest po��czeniem heksadecymalnego zapisu (ma�ymi
  literami) sumy kontrolnej CRC32 oraz rozmiaru dope�nionego do czterech bajt�w.
  Dla obrazka o sumie kontrolnej 0x45fb2e46 i rozmiarze 16568 bajt�w �r�d�em
  b�dzie 45fb2e46000040b8. }

// ==================== 1.6.2.2. Czysty tekst z atrybutami =====================

  { Mo�liwe jest r�wnie� dodawanie do wiadomo�ci r�nych atrybut�w tekstu, jak
  pogrubienie czy kolory. Niezb�dne jest do��czenie do wiadomo�ci nast�puj�cej
  struktury: }
  type Tgg_msg_richtext = packed record
	  flag: char;	  // 0x02
	  length: Word; // d�ugo�� dalszej cz�ci
  end;

  { Opis tej struktury ni�ej }
  type Tgg_msg_richtext_image = packed record
	  length: char;    // d�ugo�� opisu obrazka (0x09)
	  typ: char;	     // rodzaj opisu obrazka (0x01)
	  size: LongWord;	 // rozmiar obrazka
	  crc32: LongWord; // suma kontrolna obrazka
  end;

  { Dalsza cz�� pakietu zawiera odpowiedni� ilo�� struktur o ��cznej d�ugo�ci
  okre�lonej polem length: }
  type Tgg_msg_richtext_format = packed record
	  position: Word;	               // pozycja atrybutu w tek�cie
	  font: char;	                   // atrybuty czcionki
	  rgb: array[0..2] of char;	     // kolor czcionki (nie musi wyst�pi�)
	  image: Tgg_msg_richtext_image; // obrazek (nie musi wyst�pi�)
  end;

  { Ka�da z tych struktur okre�la kawa�ek tekstu pocz�wszy od znaku okre�lonego
  przez pole position (liczone od zera) a� do nast�pnego wpisu lub ko�ca tekstu.
  Pole font jest map� bitow� i kolejne bity maj� nast�puj�ce znaczenie: }
  const
    GG_FONT_BOLD = $01;	     // Pogrubiony tekst
    GG_FONT_ITALIC = $02;	   // Kursywa
    GG_FONT_UNDERLINE =	$04; // Podkre�lenie
    GG_FONT_COLOR = $08;	   // Kolorowy tekst. Tylko w tym wypadku struktura gg_msg_richtext_format zawiera pole rgb[] b�d�ce opisem trzech sk�adowych koloru, kolejno czerwonej, zielonej i niebieskiej.
    GG_FONT_IMAGE = $80;	   // Obrazek. Tylko w tym wypadku struktura gg_msg_richtext_format zawiera pole image.

  { Je�li wiadomo�� zawiera obrazek, przesy�ana jest jego suma kontrolna CRC32
  i rozmiar. Dzi�ki temu nie trzeba za ka�dym razem wysy�a� ka�dego obrazka �
  klienty je zachowuj�. Struktura gg_msg_richtext_image opisuj�ca obrazek
  umieszczony w wiadomo�ci wygl�da nast�puj�co: }
  {type Tgg_msg_richtext_image = packed record
	  length: char;    // d�ugo�� opisu obrazka (0x09)
	  typ: char;	     // rodzaj opisu obrazka (0x01)
	  size: LongWord;	 // rozmiar obrazka
	  crc32: LongWord; // suma kontrolna obrazka
  end;} // STRUKTURE TE ZADEKLAROWANO PRZED JEJ UZYCIEM W gg_msg_richtext_format


// ======================== 1.6.3. Przesy�anie obrazk�w ========================

  { Gdy klient nie posiada w pami�ci podr�cznej obrazka o podanych parametrach,
  wysy�a pust� wiadomo�� o klasie GG_CLASS_MSG z do��czon� struktur�
  gg_msg_image_request: }
  type Tgg_msg_image_request = packed record
	  flag: char;	     // 0x04
	  size: LongWord;	 // rozmiar
	  crc32: LongWord; // suma kontrolna
  end;

  { W odpowiedzi, drugi klient wysy�a obrazek za pomoc� wiadomo�ci o zerowej
  d�ugo�ci (nale�y pami�ta� o ko�cz�cym bajcie o warto�ci 0x00) z do��czon�
  struktur� gg_msg_image_reply: }
  type Tgg_msg_image_reply = packed record
	  flag: char;      	   // 0x05 lub 0x06
	  size: LongWord;      // rozmiar
	  crc32: LongWord;     // suma kontrolna
	  filename: CharArray; // nazwa pliku (nie musi wyst�pi�)
	  image: CharArray;		 // zawarto�� obrazka (nie musi wyst�pi�)
  end;
  { Je�li d�ugo�� struktury gg_msg_image_reply jest d�u�sza ni� 1909 bajt�w,
  tre�� obrazka jest dzielona na kilka pakiet�w nie przekraczaj�cych 1909
  bajt�w. Pierwszy pakiet ma pole flag r�wne 0x05 i ma wype�nione pole filename,
  a w kolejnych pole flag jest r�wne 0x06 i pole filename w og�le nie wyst�puje
  (nawet bajt zako�czenia ci�gu znak�w).

  Je�li otrzymamy pakiet bez pola filename oraz image, oznacza to, �e klient nie
  posiada ��danego obrazka. }


// ============================ 1.6.4. Potwierdzenie ===========================

  { Serwer po otrzymaniu wiadomo�ci odsy�a potwierdzenie, kt�re przy okazji m�wi
  nam, czy wiadomo�� dotar�a do odbiorcy czy zosta�a zakolejkowana z powodu
  nieobecno�ci. Otrzymujemy je w postaci pakietu: }
  const GG_SEND_MSG_ACK = $0005;

  type Pgg_send_msg_ack = ^Tgg_send_msg_ack;
  Tgg_send_msg_ack = packed record
	  status: LongWord;	   // stan wiadomo�ci
	  recipient: LongWord; // numer odbiorcy
	  seq: LongWord;	     // numer sekwencyjny
  end;

  { Numer sekwencyjny i numer adresata s� takie same jak podczas wysy�ania, a
  stan wiadomo�ci mo�e by� jednym z nast�puj�cych: }
  const
    GG_ACK_BLOCKED = $0001;	      // Wiadomo�ci nie przes�ano (zdarza si� przy wiadomo�ciach zawieraj�cych adresy internetowe blokowanych przez serwer GG gdy odbiorca nie ma nas na li�cie)
    GG_ACK_DELIVERED = $0002;	    // Wiadomo�� dostarczono
    GG_ACK_QUEUED = $0003;	      // Wiadomo�� zakolejkowano
    GG_ACK_MBOXFULL = $0004;	    // Wiadomo�ci nie dostarczono. Skrzynka odbiorcza na serwerze jest pe�na (20 wiadomo�ci maks). Wyst�puje tylko w trybie offline
    GG_ACK_NOT_DELIVERED = $0006;	// Wiadomo�ci nie dostarczono. Odpowied� ta wyst�puje tylko w przypadku wiadomo�ci klasy GG_CLASS_CTCP


// ======================== 1.7. Otrzymywanie wiadomo�ci =======================

  { Wiadomo�ci serwer przysy�a za pomoc� pakietu: }
  const GG_RECV_MSG80 = $002e;

  type Tgg_recv_msg80 = packed record
	  sender: LongWord;		         // numer nadawcy
	  seq: LongWord;		           // numer sekwencyjny
	  time: LongWord;		           // czas nadania
	  clas: LongWord;		           // klasa wiadomo�ci
	  offset_plain: LongWord;	     // po�o�enie tre�ci czystym tekstem
	  offset_attributes: LongWord; // po�o�enie atrybut�w
	  html_message: PChar;	       // tre�� w formacie HTML (zako�czona \0)
	  plain_message: PChar;        // tre�� czystym tekstem (zako�czona \0)
	  attributes: array of Byte;	 // atrybuty wiadomo�ci
  end;
  { Czas nadania jest zapisany w postaci UTC, jako ilo�ci sekund od 1 stycznia
  1970r. W przypadku pakiet�w �konferencyjnych� na ko�cu pakietu doklejona jest
  struktura identyczna z gg_msg_recipients zawieraj�ca pozosta�ych rozm�wc�w. }


// ============================== 1.8. Ping, pong ==============================

  { Od czasu do czasu klient wysy�a pakiet do serwera, by oznajmi�, �e
  po��czenie jeszcze jest utrzymywane. Je�li serwer nie dostanie takiego pakietu
  w przeci�gu 5 minut, zrywa po��czenie. To, czy klient dostaje odpowied�
  zmienia si� z wersji na wersj�, wi�c najlepiej nie polega� na tym. }
  const
    GG_PING = $0008;
    GG_PONG = $0007;


// ============================== 1.9. Roz��czenie =============================

  { Je�li serwer zechce nas roz��czy�, wy�le wcze�niej pusty pakiet: }
  const GG_DISCONNECTING = $000b;
  { Ma to miejsce, gdy pr�bowano zbyt wiele razy po��czy� si� z nieprawid�owym
  has�em (wtedy pakiet zostanie wys�any w odpowiedzi na GG_LOGIN70), lub gdy
  r�wnocze�nie po��czy si� drugi klient z tym samym numerem (nowe po��czenie ma
  wy�szy priorytet). }

  { W nowych wersjach protoko�u (prawdopodobnie od 0x29), po wys�aniu pakietu
  zmieniaj�cego status na niedost�pny, serwer przysy�a pakiet: }
  const GG_DISCONNECT_ACK = $000d;
  { Jest to potwierdzenie, �e serwer odebra� pakiet zmiany stanu i klient mo�e
  zako�czy� po��czenie maj�c pewno��, �e zostanie ustawiony ��dany opis. }


// ======================== 1.10. Wiadomo�ci systemowe =========================

  { Od wersji 7.7 serwer mo�e wysy�a� nam wiadomo�ci systemowe przy pomocy
  pakietu: }
  const GG_XML_EVENT = $0027;


// ======================= 1.11. Wiadomo�ci GG_XML_ACTION ======================

  { Narazie nie przewiduj� ich obs�ugi. }


// ========================== 1.12. Katalog publiczny ==========================

  { Nowe Gadu-Gadu korzysta z OAutha do odczytu oraz zmian danych w katalogu,
  API opisane jest na: http://dev.gadu-gadu.pl/api/pages/gaduapi.html

  Nowe Gadu-Gadu korzysta z wyszukiwarki dost�pnej na:
  http://ipubdir.gadu-gadu.pl/ngg/ }


// =========================== 1.13. Lista kontakt�w ===========================

  { Od wersji 6.0 lista kontakt�w na serwerze sta�a cz�ci� sesji, zamiast
  osobnej sesji HTTP. Aby wys�a� lub pobra� list� kontakt�w z serwera nale�y
  u�y� pakietu: }

  const GG_USERLIST_REQUEST80 = $002f;

  type Tgg_userlist_request = packed record
	  typ: char;		                   // rodzaj zapytania
	  request: array[0..2047] of char; // tre�� (nie musi wyst�pi�)
  end;

  { Pole type oznacza rodzaj zapytania: }
  const
    GG_USERLIST_PUT = $00;      // pocz�tek eksportu listy
    GG_USERLIST_PUT_MORE = $01; // dalsza cz�� eksportu listy
    GG_USERLIST_GET = $02;      // import listy

  { W przypadku eksportu listy kontakt�w, pole request zawiera dokument XML
  opisany na stronie http://dev.gadu-gadu.pl/api/pages/formaty_plikow.html
  skompresowany algorytmem Deflate. Wolnodost�pna implementacja algorytmu,
  u�ywana r�wnie� przez oryginalnego klienta, znajduje si� w biblotece zlib.

  Podczas przesy�ania lista kontakt�w jest dzielona na pakiety po 2048 bajt�w.
  Pierwszy jest wysy�any pakietem typu GG_USERLIST_PUT, �eby uaktualni� plik
  na serwerze, pozosta�e typu GG_USERLIST_PUT_MORE, �eby dopisa� do pliku. }

  { Na zapytania dotycz�ce listy kontakt�w serwer odpowiada pakietem: }
  const GG_USERLIST_REPLY80 = $0030;

  type Pgg_userlist_reply = ^Tgg_userlist_reply;
  Tgg_userlist_reply = packed record
	  typ: char;		                 // rodzaj zapytania
	  reply: array[0..2047] of char; // tre�� (nie musi wyst�pi�)
  end;

  { Pole type oznacza rodzaj odpowiedzi: }
  const
    GG_USERLIST_PUT_REPLY = $00;      // pocz�tek eksportu listy
    GG_USERLIST_PUT_MORE_REPLY = $02; // kontynuacja
    GG_USERLIST_GET_MORE_REPLY = $04; // pocz�tek importu listy
    GG_USERLIST_GET_REPLY = $06;      // ostatnia cz�� importu

  { W przypadku importu w polu request znajdzie si� lista kontakt�w w takiej
  samej postaci, w jakiej j� umieszczono. Serwer nie ingeruje w jej tre��.
  Podobnie jak przy wysy�aniu, przychodzi podzielona na mniejsze pakiety.
  Pobieranie kr�tkiej listy kontakt�w zwykle powoduje wys�anie pojedynczego
  pakietu GG_USERLIST_GET_REPLY, a gdy lista jest d�uga, serwer mo�e przys�a�
  dowoln� ilo�� pakiet�w GG_USERLIST_GET_MORE_REPLY przed pakietem
  GG_USERLIST_GET_REPLY. }

  { Aby usun�� list� kontakt�w z serwera oryginalny klient wysy�a spacj� jako
  list� kontakt�w czego wynikiem jest pole request o zawarto�ci: 
    78 da 53 00 00 00 21 00 21}

implementation

end.
