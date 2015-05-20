{
    Komponent obs³uguj¹cy klienta sieci Gadu-Gadu. Pisany na podstawie
    specyfikacji na http://toxygen.net/libgadu/protocol/.
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

unit EGGBase;
  { Unit implementuje klasê bazow¹ dla TEasyGG. Obs³uguje ona protokó³ na niskim poziomie. }

interface

uses
  SysUtils, Classes, WinSock, ScktComp, ExtCtrls, EGGConsts, EGGFuncts, dialogs;

const PING_INTERVAL = 1000 * 120; // co ile wysy³aæ ping (w milisekundach)

type
  EGGError = class(Exception);

  Tgg_notifyArray = array of Tgg_notify;
  Tgg_notify_reply80Array = array of Tgg_notify_reply80;

  TPingTimer = class(TTimer)
  protected
    procedure Ping(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TGGSocket = class(TCustomSocket)
  private
    FClientSocket: TClientWinSocket;
  protected
    procedure DoActivate(Value: Boolean); override;
    function GetClientType: TClientType;
    property ClientType: TClientType read GetClientType;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Socket: TClientWinSocket read FClientSocket;
    property Host;
    property Port;
    property OnLookup;
    property OnConnecting;
    property OnConnect;
    property OnDisconnect;
    property OnRead;
    property OnWrite;
    property OnError;
  end;

  TEasyGGBase = class(TGGSocket)
  private
    FPingTimer: TPingTimer;
    FUID: LongWord;
    FPassword: string;
    FImageSize: Byte;

    FData: String;
  protected
    procedure Event(Socket: TCustomWinSocket; SocketEvent: TSocketEvent); override;

    procedure Login(const AUID: LongWord; const APassword: String;
      const Seed: LongWord; const AImageSize: Byte;
      const AStatus, AFlags, AFeatures: LongWord;
      const ADescription: ShortString = ''); // loguje siê na serwerze
    procedure NewStatus(const AStatus, AFlags: LongWord; const ADescription: ShortString = ''); // nowy status
    procedure Notify(var Users: array of Tgg_notify); // stan u¿ytkowników na starcie
    procedure AddNotify(const AUID: LongWord; const ATyp: Byte); // dodanie flag u¿ytkownika
    procedure RemoveNotify(const AUID: LongWord; const ATyp: Byte); // usuniêcie flag u¿ytkownika


    procedure PacketHandler(const PacketType, PacketLength: LongWord; const Packet: Pointer); // obs³uga pakietów

    procedure SocketRead(Socket: TCustomWinSocket); // odczyt danych z serwera
    procedure SocketDisconnect(Socket: TCustomWinSocket); virtual;

    procedure SocketGGWelcome(var AStatus, AFlags: LongWord;
      var ADescription: ShortString); virtual; abstract;
    procedure SocketGGLoginOK(var UserArray: Tgg_notifyArray); virtual; abstract;
    procedure SocketGGLoginFailed; virtual; abstract;
    procedure SocketGGDisconnecting; virtual; abstract;
    procedure SocketGGNotifyReply(const UserArray: Tgg_notify_reply80Array); virtual; abstract;
    procedure SocketGGStatus(const User: Tgg_notify_reply80); virtual; abstract;
    procedure SocketGGSendMsgAck(const Response: Tgg_send_msg_ack); virtual; abstract;
    procedure SocketGGRecvMsg(const Header: Tgg_recv_msg80); virtual; abstract;
    procedure SocketGGListReplyPut; virtual; abstract;
    procedure SocketGGListReplyGet(const XML: string); virtual; abstract;

    procedure SendPacket(var Agg_header: Tgg_header; var data); overload; // wys³anie pakietu

    procedure Connect; virtual;

    procedure SetLoggedin(Value: Boolean);
    function GetLoggedin: Boolean;

    procedure UserlistGet;
    procedure UserlistPut(AXML: String);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Loggedin: Boolean read GetLoggedin;
    property UID: LongWord read FUID write FUID;
    property Password: string read FPassword write FPassword;
    property ImageSize: Byte read FImageSize write FImageSize default 255;

    procedure SendMsg(AUID: LongWord; AHTMLMsg, APlainMsg, AAttributes: String);
    procedure SendMsgPlain(AUID: LongWord; AMsg: String);
    procedure Conference(ARecipients: array of LongWord; AHTMLMsg, APlainMsg,
      AAttributes: String);
    procedure ConferencePlain(ARecipients: array of LongWord; AMsg: String);
  end;

implementation

{ TEasyGGBase }

constructor TEasyGGBase.Create(AOwner: TComponent);
begin
  inherited;
  FData := '';
  FImageSize := 255;
  FPingTimer := TPingTimer.Create(Self);
end;

destructor TEasyGGBase.Destroy;
begin
  FPingTimer.Free;
  inherited;
end;

procedure TEasyGGBase.Connect;
begin
  Self.Active := True;
end;

procedure TEasyGGBase.AddNotify(const AUID: LongWord; const ATyp: Byte);
var
  Agg_add_notify: Tgg_add_notify;
  Agg_header: Tgg_header;
begin
  Agg_add_notify.uin := AUID;
  Agg_add_notify.typ := Char(ATyp);

  Agg_header.typ := GG_ADD_NOTIFY;
  Agg_header.length := SizeOf(Agg_add_notify);

  SendPacket(Agg_header, Agg_add_notify);
end;

procedure TEasyGGBase.RemoveNotify(const AUID: LongWord; const ATyp: Byte);
var
  Agg_remove_notify: Tgg_remove_notify;
  Agg_header: Tgg_header;
begin
  Agg_remove_notify.uin := AUID;
  Agg_remove_notify.typ := Char(ATyp);

  Agg_header.typ := GG_REMOVE_NOTIFY;
  Agg_header.length := SizeOf(Agg_remove_notify);

  SendPacket(Agg_header, Agg_remove_notify);
end;

procedure TEasyGGBase.SocketDisconnect(Socket: TCustomWinSocket);
begin
  SetLoggedin(False);
end;

procedure TEasyGGBase.SocketRead(Socket: TCustomWinSocket);
var
  gg_header: Tgg_header;
  p: Pointer;
begin
  FData := FData + Socket.ReceiveText; // pobranie wszystkiego co jest
  p := Addr(FData[1]); // ustawienie wskaŸnika na pocz¹tek danych
  gg_header := Tgg_header(p^); // pobranie nag³ówka
  p := Pointer(LongWord(p) + SizeOf(Tgg_header)); // zwiêkszenie wskaŸnika o rozmiar nag³ówka
  if (Length(FData) - SizeOf(Tgg_header)) >= Int64(gg_header.length) then begin // je¿eli pobrano tyle samo, lub wiêcej danych ni¿ potrzeba
    PacketHandler(gg_header.typ, gg_header.length, p); // zajmij siê obs³ug¹ pakietu
    Delete(FData, 1, gg_header.length + SizeOf(Tgg_header)); // usuniêcie obs³u¿onych danych
    if Length(FData) <> 0 then
      SocketRead(Socket); // obs³u¿ pozosta³e dane
  end;

end;

procedure TEasyGGBase.UserlistGet;
var
  Agg_header: Tgg_header;
  Agg_userlist_request: Tgg_userlist_request;
begin
  Agg_header.typ := GG_USERLIST_REQUEST80;
  Agg_header.length := 1;
  Agg_userlist_request.typ := Char(GG_USERLIST_GET);

  SendPacket(Agg_header, Agg_userlist_request);
end;

procedure TEasyGGBase.UserlistPut(AXML: String);
var
  Arrgg_header: array of Tgg_header;
  Arrgg_userlist_request: array of Tgg_userlist_request;
  Compressed, s: String;
  i: Integer;
begin

  Compressed := '';
  if AXML <> '' then
    Compressed := Deflate(AXML); // kompresja danych

  repeat
    s := Copy(Compressed, 1, 2048); // skopiowanie pierwszych 2048 bajtów
    Delete(Compressed, 1, 2048); // usuniêcie pierwszych 2048 bajtów

    { Zwiêkszenie rozmiarów tablic o 1 }
    SetLength(Arrgg_userlist_request, Length(Arrgg_userlist_request) + 1);
    SetLength(Arrgg_header, Length(Arrgg_userlist_request));

    { Nag³ówek }
    Arrgg_header[High(Arrgg_header)].typ := GG_USERLIST_REQUEST80;
    Arrgg_header[High(Arrgg_header)].length := Length(s) + 1;

    { Pakiet }
    Arrgg_userlist_request[High(Arrgg_userlist_request)].typ := Char(GG_USERLIST_PUT_MORE);
    Move(s[1], Arrgg_userlist_request[High(Arrgg_userlist_request)].request[0], Length(s));
  until Length(Compressed) = 0;
  Arrgg_userlist_request[0].typ := Char(GG_USERLIST_PUT);

  for i := 0 to High(Arrgg_header) do // wys³anie danych
    SendPacket(Arrgg_header[i], Arrgg_userlist_request[i]);
end;

procedure TEasyGGBase.SendMsg(AUID: LongWord; AHTMLMsg, APlainMsg, AAttributes: String);
var
  Agg_send_msg80: Tgg_send_msg80;
  Agg_header: Tgg_header;
  Msg, Data: String;
begin
  AHTMLMsg := AnsiToUTF8(AHTMLMsg); // zmiana kodowania na UTF8
  Msg := AHTMLMsg + #0 + APlainMsg + #0 + AAttributes; // posklejanie wiadomoœci

  Agg_send_msg80.recipient := AUID;
  Agg_send_msg80.seq := DateTimeToUnix(Now); // obecny czas w postaci uniksowej
  Agg_send_msg80.clas := GG_CLASS_CHAT;
  Agg_send_msg80.offset_plain := SizeOf(Agg_send_msg80) + Length(AHTMLMsg) + 1;
  Agg_send_msg80.offset_attributes := Agg_send_msg80.offset_plain + LongWord(Length(APlainMsg)) + 1;

  Agg_header.typ := GG_SEND_MSG80;
  Agg_header.length := SizeOf(Agg_send_msg80) + Length(Msg);

  SetLength(Data, SizeOf(Agg_send_msg80));
  Move(Agg_send_msg80, Data[1], SizeOf(Agg_send_msg80)); // przeniesienie struktury do danych
  Data := Data + Msg; // przeniesienie wiadomoœci do danych

  SendPacket(Agg_header, Data[1]); // wys³anie pakietu
end;

procedure TEasyGGBase.SendMsgPlain(AUID: LongWord; AMsg: String);
const
  ATTR = #2#6#0#0#0#8#0#0#0; // atrybuty czystego tekstu
begin
  SendMsg(AUID, AMsg, AMsg, ATTR);
end;

procedure TEasyGGBase.Conference(ARecipients: array of LongWord; AHTMLMsg,
  APlainMsg, AAttributes: String);
var
  Agg_msg_recipients: Tgg_msg_recipients;
  Data, s: String;
  i, j, k: Integer;
begin
  if Length(ARecipients) = 1 then
    SendMsg(ARecipients[0], AHTMLMsg,APlainMsg, AAttributes)
  else begin

    Agg_msg_recipients.flag := #1;
    Agg_msg_recipients.count := Length(ARecipients) - 1;
    SetLength(Data, SizeOf(Agg_msg_recipients));
    Move(Agg_msg_recipients, Data[1], SizeOf(Agg_msg_recipients));

    SetLength(s, Agg_msg_recipients.count * SizeOf(LongWord));
    for i := 0 to High(ARecipients) do begin
      k := 0;
      for j := 0 to High(ARecipients) do begin
        if j = i then Continue;
        Move(ARecipients[j], s[k * SizeOf(LongWord) + 1], SizeOf(LongWord));
        Inc(k);
      end;
      SendMsg(ARecipients[i], AHTMLMsg, APlainMsg, Data + s + AAttributes);
    end;

  end;
end;

procedure TEasyGGBase.ConferencePlain(ARecipients: array of LongWord; AMsg: String);
const
  ATTR = #2#6#0#0#0#8#0#0#0; // atrybuty czystego tekstu
begin
  Conference(ARecipients, AMsg, AMsg, ATTR);
end;

procedure TEasyGGBase.SendPacket(var Agg_header: Tgg_header; var data);
var
  buffer: String;
begin
  SetLength(buffer, SizeOf(Agg_header) + Agg_header.length); // ustawienie d³ bufora
  Move(Agg_header, buffer[1], SizeOf(Agg_header)); // dodanie nag³ówka do bufora
  Move(data, buffer[SizeOf(Agg_header) + 1], Agg_header.length); // dodanie danych do bufora
  Socket.SendText(buffer); // wys³anie pakietu
end;

procedure TEasyGGBase.PacketHandler(const PacketType, PacketLength: LongWord; const Packet: Pointer);
var
  gg_notify: Tgg_notifyArray;
  gg_notify_reply80: Tgg_notify_reply80Array;
  gg_recv_msg80: Tgg_recv_msg80;
  i, j: LongWord;
  AStatus, AFlags: LongWord;
  ADescription: ShortString;
  gg_userlist_reply: Tgg_userlist_reply;
  s: String;
begin
  if PacketType = EGGConsts.GG_WELCOME then begin // pakiet powitalny (rozdzia³ 1.3)
    SocketGGWelcome(AStatus, AFlags, ADescription); // pobranie wartoœci z klasy potomnej
    Login(FUID, FPassword, Tgg_welcome(Packet^).seed, FImageSize, AStatus, AFlags, GG_FEATURES80, ADescription); // zalogowanie
  end
  else if PacketType = EGGConsts.GG_LOGIN80_OK then begin // logowanie powiod³o siê (1.3)
    SocketGGLoginOK(gg_notify); // pobranie tablicy z procedury
    Notify(gg_notify); // wys³anie listy kontaktów

    SetLoggedin(True); // zalogowano
  end
  else if PacketType = EGGConsts.GG_LOGIN_FAILED then  // nieudane logowanie (1.3)
    SocketGGLoginFailed
  else if PacketType = EGGConsts.GG_DISCONNECTING then // serwer chce nas roz³¹czyæ (1.9)
    SocketGGDisconnecting
  else if PacketType = EGGConsts.GG_SEND_MSG_ACK then  // otrzymano potwierdzenie o dostarczonej wiadomoœci (1.6.4)
    SocketGGSendMsgAck(Tgg_send_msg_ack(Packet^))
  else if PacketType = EGGConsts.GG_NOTIFY_REPLY80 then begin // stan kontaktów na starcie (1.5)
    i := 0;
     
    { Rozdzia³ pakietu na struktury typu Tgg_notify_reply80 }
    if PacketLength > 0 then
      while i <= PacketLength - 1 do begin
        SetLength(gg_notify_reply80, Length(gg_notify_reply80) + 1); // zwiêkszenie rozmiaru tablicy o 1
        Move(Pointer(LongWord(Packet) + i)^, gg_notify_reply80[High(gg_notify_reply80)], SizeOf(Tgg_notify_reply80) - 255);
        Inc(i, SizeOf(Tgg_notify_reply80) - 255);
        Move(Pointer(LongWord(Packet) + i)^, gg_notify_reply80[High(gg_notify_reply80)].description, gg_notify_reply80[High(gg_notify_reply80)].description_size);
        Inc(i, gg_notify_reply80[High(gg_notify_reply80)].description_size);
      end;

    SocketGGNotifyReply(gg_notify_reply80);

  end
  else if PacketType = EGGConsts.GG_STATUS80 then // ktoœ na liœcie zmienia status (1.5)
    SocketGGStatus(Tgg_notify_reply80(Packet^))
  else if PacketType = EGGConsts.GG_RECV_MSG80 then begin // otrzymano wiadomoœæ (1.7)
    i := SizeOf(Tgg_recv_msg80) - SizeOf(PChar) * 3; // d³ugoœæ struktury oprócz treœci wiadomoœci
    Move(Packet^, gg_recv_msg80, i);
    gg_recv_msg80.html_message := Pointer(LongWord(Packet) + i);
    gg_recv_msg80.plain_message := Pointer(LongWord(Packet) + gg_recv_msg80.offset_plain);

    j := PacketLength - gg_recv_msg80.offset_attributes; // d³ugoœæ atrybutów
    SetLength(gg_recv_msg80.attributes, j);
    Move(Pointer(LongWord(Packet) + gg_recv_msg80.offset_plain)^, gg_recv_msg80.attributes[0], j);

    SocketGGRecvMsg(gg_recv_msg80);
  end
  else if PacketType = EGGConsts.GG_USERLIST_REPLY80 then begin // odbieranie/wysy³anie listy kontaktów (1.13)
    Move(Packet^, gg_userlist_reply.typ, SizeOf(Char));
    if gg_userlist_reply.typ = Char(GG_USERLIST_PUT_REPLY) then
      SocketGGListReplyPut
    else if gg_userlist_reply.typ = Char(GG_USERLIST_GET_REPLY) then begin
      SetLength(s, PacketLength);
      Move(Packet^, s[1], PacketLength);
      Delete(s, 1, 1); // usuniêcie pola typ
      s := Inflate(s);
      SocketGGListReplyGet(s);
    end;
  end;

end;

procedure TEasyGGBase.Login(const AUID: LongWord; const APassword: String;
  const Seed: LongWord; const AImageSize: Byte;
  const AStatus, AFlags, AFeatures: LongWord;
  const ADescription: ShortString = '');
var
  Agg_login80: Tgg_login80;
  Agg_header: Tgg_header;
  hash: string;
  ADescriptionUTF8: ShortString;
begin
  hash := gg_sha_hash(APassword, Seed); // hash has³a i seeda
  FillChar(Agg_login80.hash, SizeOf(Agg_login80.hash), #0);

  ADescriptionUTF8 := Copy(AnsiToUTF8(ADescription), 1, 255); // konwersja opisu na UTF8

  { Dane do logowania }
  Agg_login80.uin := AUID;
  Agg_login80.language := GG_LANG;
  Agg_login80.hash_type := GG_LOGIN_HASH_SHA1;
  Move(hash[1], Agg_login80.hash, Length(hash));
  Agg_login80.status := AStatus;
  Agg_login80.flags := AFlags;
  Agg_login80.features := AFeatures;
  Agg_login80.local_ip := 0;
  Agg_login80.local_port := 0;
  Agg_login80.external_ip := 0;
  Agg_login80.external_port := 0;
  Agg_login80.image_size := Char(AImageSize);
  Agg_login80.unknown2 := #$64;
  Agg_login80.version_len := $21;
  Agg_login80.version := GG_VERSION_DESCR;
  Agg_login80.description_size := Length(ADescriptionUTF8);
  Move(ADescriptionUTF8[1], Agg_login80.description[0], Agg_login80.description_size);

  { Nag³ówek }
  Agg_header.typ := GG_LOGIN80;
  Agg_header.length := SizeOf(Agg_login80) + Agg_login80.description_size - 255;

  SendPacket(Agg_header, Agg_login80); // Wys³anie nag³ówka i danych
end;

procedure TEasyGGBase.NewStatus(const AStatus, AFlags: LongWord; const ADescription: ShortString = '');
var
  Agg_header: Tgg_header;
  Agg_new_status80: Tgg_new_status80;
  ADescriptionUTF8: ShortString;
begin
  ADescriptionUTF8 := Copy(AnsiToUTF8(ADescription), 1, 255); // konwersja opisu na UTF8

  { Pakiet zmieniajacy status }
  Agg_new_status80.status := AStatus;
  Agg_new_status80.flags := AFlags;
  Agg_new_status80.description_size := Length(ADescriptionUTF8);
  Move(ADescriptionUTF8[1], Agg_new_status80.description[0], Agg_new_status80.description_size);

  { Nag³ówek }
  Agg_header.typ := GG_NEW_STATUS80;
  Agg_header.length := SizeOf(Agg_new_status80) + Agg_new_status80.description_size - 255;

  SendPacket(Agg_header, Agg_new_status80); // Wys³anie nag³ówka i danych
end;

procedure TEasyGGBase.Notify(var Users: array of Tgg_notify);
var
  Agg_header: Tgg_header;
  i, j: Integer;
  Users2: array of array of Tgg_notify;
begin
  if Length(Users) = 0 then begin // Lista nie zawiera kontaktow
    Agg_header.typ := GG_LIST_EMPTY;
    Agg_header.length := 0;
    Socket.SendBuf(Agg_header, SizeOf(Agg_header));
  end
  else if Length(Users) <= 400 then begin // Lista zawiera mniej niz 400 kontaktow
    Agg_header.typ := GG_NOTIFY_LAST;
    Agg_header.length := SizeOf(Tgg_notify) * Length(Users);
    SendPacket(Agg_header, Users);
  end
  else if Length(Users) > 400 then begin // POPRAWIC I DOKONCZYC!
    j := 0;
    for i := Low(Users) to High(Users) do begin
      if ((i + 1) mod 400) = 0 then begin
        SetLength(Users2, Length(Users2) + 1);
        SetLength(Users2[High(Users2)], i - j + 1);
        Move(Users[j], Users2[High(Users2)], i - j + 1);
        j := i + 1;
      end;

    end;
  end;
end;

procedure TEasyGGBase.Event(Socket: TCustomWinSocket;
  SocketEvent: TSocketEvent);
begin
  inherited;
  case SocketEvent of
    seRead: SocketRead(Socket);
    seDisconnect: SocketDisconnect(Socket);
  end;
end;

function TEasyGGBase.GetLoggedin: Boolean;
begin
  Result := FPingTimer.Enabled;
end;

procedure TEasyGGBase.SetLoggedin(Value: Boolean);
begin
  FPingTimer.Enabled := Value;
end;

{ TGGSocket }

constructor TGGSocket.Create(AOwner: TComponent);
begin
  inherited;
  FClientSocket := TClientWinSocket.Create(INVALID_SOCKET);
  InitSocket(FClientSocket);
end;

destructor TGGSocket.Destroy;
begin
  FClientSocket.Free;
  inherited;
end;

procedure TGGSocket.DoActivate(Value: Boolean);
begin
  if (Value <> FClientSocket.Connected) and not (csDesigning in ComponentState) then
  begin
    if FClientSocket.Connected then
      FClientSocket.Disconnect(FClientSocket.SocketHandle)
    else FClientSocket.Open(Host, Address, Service, Port, ClientType = ctBlocking);
  end;
end;

function TGGSocket.GetClientType: TClientType;
begin
  Result := FClientSocket.ClientType;
end;

{ TPingTimer }

constructor TPingTimer.Create(AOwner: TComponent);
begin
  inherited;
  Enabled := False;
  Interval := PING_INTERVAL;
  OnTimer := Ping;
end;

procedure TPingTimer.Ping(Sender: TObject);
var
  Agg_header: Tgg_header;
begin
  Agg_header.typ := GG_PING;
  Agg_header.length := 0;
  TEasyGGBase(Owner).Socket.SendBuf(Agg_header, SizeOf(Agg_header));
end;

end.
