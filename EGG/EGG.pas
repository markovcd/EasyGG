{
    Komponent obs³uguj¹cy klienta sieci Gadu-Gadu. Pisany na podstawie
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

unit EGG;
  { Unit zawiera implementacjê komponentu TEasyGG (g³ówny modu³) }

interface

  { Wersja 0.02 - 22 stycznia 2010 }

uses
  SysUtils, Classes, ScktComp, XMLDoc, XMLIntf, EGGConsts, EGGFuncts, EGGBase, Dialogs;

const // komunikaty b³êdów
  E_USER_DUPLICATE = 'Podany u¿ytkownik ju¿ istnieje na liœcie.';
  E_GROUP_DUPLICATE = 'Podana grupa ju¿ istnieje na liœcie.';
  E_UNKNOWN_STATUS = 'Nieznany rodzaj statusu.';
  E_FORBIDDEN_STATUS = 'Nie mo¿na ustawiæ podanego statusu.';
  E_CONTACTS_CORRUPTED = 'Niew³aœciwy format listy kontaktów.';

type


  TEasyGG = class;
  TUser = class;
  //TGroup = class;

  //TGroupArray = array of TGroup;

  TUserStatus = (usGGWithMe, usAvailable, usNotAvailable, usBusy, usDND,
  usInvisible, usBlocked);

  TGender = (gUnknown, gFemale, gMale);

  TUserEvent = procedure(Sender: TObject; User: TUser) of object;
  TMsgSendEvent = procedure(Sender: TObject; UID: Cardinal) of object;
  TMsgRecvEvent = procedure(Sender: TObject; UID: Cardinal; HTMLMessage,
    PlainMessage, Attributes: String; Time: TDateTime;
    Conference: array of Cardinal) of object;

  {TGroups = class(TList)
  private
    FOwner: TEasyGG;
  protected
    function Get(Index: Integer): TGroup;
    function IndexOfGUID(AGUID: ShortString): Integer;
  public
    constructor Create(AOwner: TEasyGG); virtual;
    destructor Destroy; override;

    property Items[Index: Integer]: TGroup read Get;
    function Add(AName: ShortString): Integer;
    procedure Delete(Index: Integer);
    procedure Clear; override;

    function IndexOfName(AName: ShortString): Integer;
  end; }

  {TGroup = class(TObject)
  private
    FOwner: TEasyGG;
    FGUID: ShortString;
    FName: ShortString;
    FIsExpanded: Boolean;
    FUsers: TList;
  protected
    function GetUser(Index: Integer): TUser;
    procedure SetName(Value: ShortString);
  public
    constructor Create(AOwner: TEasyGG; AName: ShortString); virtual;
    destructor Destroy; override;

    property Name: ShortString read FName write SetName;
    property Users[Index: Integer]: TUser read GetUser; // tablica u¿ytkowników
    function AddUser(AUser: TUser): Integer;
    procedure DeleteUser(Index: Integer);
    function IndexOfUser(AUser: TUser): Integer;
  end; }

  TUsers = class(TList)
  private
    FOwner: TEasyGG;
  protected
    function Get(Index: Integer): TUser;
    function GetCount: Integer;
    function IndexOfGUID(AGUID: ShortString): Integer;
  public
    constructor Create(AOwner: TEasyGG); virtual;
    destructor Destroy; override;

    property Items[Index: Integer]: TUser read Get; default;
    function Add(AUID: LongWord): Integer;
    procedure Delete(Index: Integer);
    procedure Clear; override;
    property Count: Integer read GetCount;

    function IndexOfUID(AUID: LongWord): Integer;
    function IndexOfName(AName: ShortString): Integer;
  end;

  TUser = class(TObject)
  private
    FUID: LongWord;

    FFriendsOnly: Boolean;
    FImageStatus: Boolean;
    FStatus: TUserStatus;
    FDescription: ShortString;
    FImageSize: Byte;
    FTyp: Byte;

    FOwner: TEasyGG;

    FName: ShortString;
    FGUID: ShortString;
    FMobilePhone: ShortString;
    FHomePhone: ShortString;
    FEmail: ShortString;
    FWWWAddress: ShortString;
    FFirstName: ShortString;
    FLastName: ShortString;
    FGender: TGender;
    FBirth: ShortString;
    FCity: ShortString;
    FProvince: ShortString;
  protected
    function GetBlocked: Boolean;
    procedure SetBlocked(Value: Boolean);
    procedure SetUID(Value: LongWord);
    //function GetGroups: TGroupArray;
  public
    property UID: LongWord read FUID write SetUID; // numerek

    property Blocked: Boolean read GetBlocked write SetBlocked; // czy zablokowany?
    property FriendsOnly: Boolean read FFriendsOnly; // osoba ma w³¹czony tryb tylko dla przyjació³
    property ImageStatus: Boolean read FImageStatus; // osoba ma ustawiony status graficzny
    property Status: TUserStatus read FStatus; // status
    property Description: ShortString read FDescription; // opis
    property ImageSize: Byte read FImageSize; // maksymalny rozmiar obrazka

    constructor Create(AOwner: TEasyGG; AUID: Integer); virtual;
    procedure SendMsg(AHTMLMsg, APlainMsg, AAttributes: String);
    procedure SendMsgPlain(AMsg: String);

    property Name: ShortString read FName write FName; // nazwa
    property MobilePhone: ShortString read FMobilePhone write FMobilePhone; // tel kom
    property HomePhone: ShortString read FHomePhone write FHomePhone; // tel stacjonarny
    property Email: ShortString read FEmail write FEmail; // email
    property WWWAddress: ShortString read FWWWAddress write FWWWAddress; // strona www
    property FirstName: ShortString read FFirstName write FFirstName; // imie
    property LastName: ShortString read FLastName write FLastName; // nazwisko
    property Gender: TGender read FGender write FGender; // p³eæ
    property Birth: ShortString read FBirth write FBirth; // data urodzenia
    property City: ShortString read FCity write FCity; // miasto
    property Province: ShortString read FProvince write FProvince; // województwo

    //property Groups: TGroupArray read GetGroups;   TODO
  end;

  TEasyGG = class(TEasyGGBase)
  private
    FAutoHost: Boolean;
    FUsers: TUsers;
    //FGroups: TGroups;

    FOnUserStatus: TUserEvent;
    FOnAddUser: TUserEvent;
    FOnDeleteUser: TUserEvent;
    FOnReceiveMsg: TMsgRecvEvent;
    FOnSendMsg: TMsgSendEvent;
    FOnLoginFailed: TNotifyEvent;
    FOnLoginOK: TNotifyEvent;
    FOnDisconnecting: TNotifyEvent;
    FOnImportList: TNotifyEvent;
    FOnExportList: TNotifyEvent;

    FDescription: ShortString;
    FStatus: TUserStatus;
    FFriendsOnly: Boolean;
    FReceiveURLS: Boolean;
    FGetMsgFromBlocked: Boolean;
  protected
    procedure SocketDisconnect(Socket: TCustomWinSocket); override;

    procedure SocketGGNotifyReply(const UserArray: Tgg_notify_reply80Array); override;
    procedure SocketGGLoginOK(var UserArray: Tgg_notifyArray); override;
    procedure SocketGGLoginFailed; override;
    procedure SocketGGStatus(const User: Tgg_notify_reply80); override;
    procedure SocketGGWelcome(var AStatus, AFlags: LongWord;
      var ADescription: ShortString); override;
    procedure SocketGGRecvMsg(const Header: Tgg_recv_msg80); override;
    procedure SocketGGSendMsgAck(const Response: Tgg_send_msg_ack); override;
    procedure SocketGGDisconnecting; override;
    procedure SocketGGListReplyPut; override;
    procedure SocketGGListReplyGet(const XML: string); override;

    function ConvertStatus(AStatus: LongWord): TUserStatus; overload;
    function ConvertStatus(AStatus: TUserStatus): LongWord; overload;

    procedure SetReceiveURLS(Value: Boolean);

    procedure SetDescription(Value: ShortString);
    procedure SetStatus(Value: TUserStatus);
    procedure SetFriendsOnly(Value: Boolean);

    procedure NewStatus(AStatus: TUserStatus; ADescription: ShortString;
      AFriendsOnly, AReceiveURLS: Boolean);
    procedure Connect; override; // uzyskanie po³¹czenia z serwerem
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Users: TUsers read FUsers; // tablica u¿ytkowników
    //property Groups: TGroups read FGroups;

    property Status: TUserStatus read FStatus write SetStatus default usNotAvailable;

    procedure ContactsFromServer;
    procedure ContactsFromFile(FileName: String);
    procedure ContactsFromString(XML: String);

    function ContactsToString: String;
    procedure ContactsToFile(FileName: String);
    procedure ContactsToServer;
  published
    property AutoHost: Boolean read FAutoHost write FAutoHost default True; // automatyczne pobranie adresu serwera GG
    property Description: ShortString read FDescription write SetDescription;
    property FriendsOnly: Boolean read FFriendsOnly write SetFriendsOnly;
    property GetMsgFromBlocked: Boolean read FGetMsgFromBlocked write FGetMsgFromBlocked default False; {od wersji 0.2}
    property Host;
    property ImageSize;
    property Password;
    property Port;
    property ReceiveURLS: Boolean read FReceiveURLS write SetReceiveURLS; // czy otrzymywaæ linki od nieznajomych
    property UID;



    property OnUserStatus: TUserEvent read FOnUserStatus write FOnUserStatus;
    property OnReceiveMsg: TMsgRecvEvent read FOnReceiveMsg write FOnReceiveMsg;
    property OnSendMsg: TMsgSendEvent read FOnSendMsg write FOnSendMsg;
    property OnLoginFailed: TNotifyEvent read FOnLoginFailed write FOnLoginFailed;
    property OnLoginOK: TNotifyEvent read FOnLoginOK write FOnLoginOK;
    property OnDisconnecting: TNotifyEvent read FOnDisconnecting write FOnDisconnecting;
    property OnAddUser: TUserEvent read FOnAddUser write FOnAddUser;
    property OnDeleteUser: TUserEvent read FOnDeleteUser write FOnDeleteUser;
    property OnConnect;
    property OnConnecting;
    property OnDisconnect;
    property OnImportList: TNotifyEvent read FOnImportList write FOnImportList;
    property OnExportList: TNotifyEvent read FOnExportList write FOnExportList;
  end;

procedure Register;

implementation

{$R easygg_icon.dcr}

procedure Register;
begin
  RegisterComponents('mdev', [TEasyGG]);
end;

{ TGroups }
{
function TGroups.Add(AName: ShortString): Integer;
var
  Group: TGroup;
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if Get(i).FName = AName then
      EGGError.Create(E_GROUP_DUPLICATE);

  Group := TGroup.Create(FOwner, AName);
  Result := inherited Add(Group);
end;

procedure TGroups.Clear;
var
  i: Integer;
begin
  for i := Count - 1 to 0 do
    Delete(i);
end;

constructor TGroups.Create(AOwner: TEasyGG);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TGroups.Delete(Index: Integer);
begin
  Get(Index).Free;
  inherited Delete(Index);
end;

destructor TGroups.Destroy;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Get(i).Free;
  inherited Clear;
end;

function TGroups.Get(Index: Integer): TGroup;
begin
  Result := TGroup(inherited Get(Index));
end;

function TGroups.IndexOfGUID(AGUID: ShortString): Integer;
var
  i: Integer;
begin
  Result := -1;

  for i := 0 to Count - 1 do
    if Get(i).FGUID = AGUID then begin
      Result := i;
      Break;
    end;
end;

function TGroups.IndexOfName(AName: ShortString): Integer;
var
  i: Integer;
begin
  Result := -1;

  for i := 0 to Count - 1 do
    if Get(i).FName = AName then begin
      Result := i;
      Break;
    end;
end;
}
{ TGroup }
{
function TGroup.AddUser(AUser: TUser): Integer;
begin
  if FUsers.IndexOf(AUser) <> -1 then
    EGGError.Create(E_USER_DUPLICATE);

  Result := FUsers.Add(AUser);
end;

constructor TGroup.Create(AOwner: TEasyGG; AName: ShortString);
begin
  inherited Create;

  FOwner := AOwner;
  FName := AName;
  FGUID := NewGuid;
  FUsers := TList.Create;
end;

procedure TGroup.DeleteUser(Index: Integer);
begin
  FUsers.Delete(Index);
end;

destructor TGroup.Destroy;
begin
  FUsers.Free;
  inherited;
end;

function TGroup.GetUser(Index: Integer): TUser;
begin
  Result := TUser(FUsers[Index]);
end;

function TGroup.IndexOfUser(AUser: TUser): Integer;
begin
  Result := FUsers.IndexOf(AUser);
end;

procedure TGroup.SetName(Value: ShortString);
var
  i: Integer;
begin
  if Value = FName then Exit;

  for i := 0 to FOwner.FGroups.Count - 1 do
    if FOwner.FGroups.Get(i).FName = Value then
      EGGError.Create(E_GROUP_DUPLICATE);

  FName := Value;
end;
}
{ TUsers }

function TUsers.Add(AUID: LongWord): Integer;
var
  User: TUser;
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if Get(i).UID = AUID then
      EGGError.Create(E_USER_DUPLICATE);

  User := TUser.Create(FOwner, AUID);
  Result := inherited Add(User);
  if FOwner.Loggedin then
    FOwner.AddNotify(AUID, User.FTyp);

  if Assigned(FOwner.FOnAddUser) then
    FOwner.FOnAddUser(FOwner, User);
end;

procedure TUsers.Clear;
var
  i: Integer;
begin
  for i := Count - 1 to 0 do begin
    //Sleep(10);
    Delete(i);
  end;
end;

constructor TUsers.Create(AOwner: TEasyGG);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TUsers.Delete(Index: Integer);
var
  User: TUser;
begin
  User := Get(Index);
  if FOwner.Loggedin then
    FOwner.RemoveNotify(User.UID, User.FTyp);

  {for i := 0 to FOwner.FGroups.Count - 1 do begin            TODO!!!
    j := FOwner.FGroups.Items[i].FUsers.IndexOf(User);
    if j <> -1 then
      FOwner.FGroups.Items[i].FUsers.Delete(j); // usuniecie uzytkownika z grupy
  end;  }

  if Assigned(FOwner.FOnDeleteUser) then
    FOwner.FOnDeleteUser(FOwner, User);

  User.Free;
  inherited Delete(Index);
end;

destructor TUsers.Destroy;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Get(i).Free;
  inherited Clear;
end;

function TUsers.Get(Index: Integer): TUser;
begin
  Result := TUser(inherited Get(Index));
end;

function TUsers.GetCount: Integer;
begin
  Result := inherited Count;
end;

function TUsers.IndexOfGUID(AGUID: ShortString): Integer;
var
  i: Integer;
begin
  Result := -1;

  for i := 0 to Count - 1 do
    if Get(i).FGUID = AGUID then begin
      Result := i;
      Break;
    end;
end;

function TUsers.IndexOfName(AName: ShortString): Integer;
var
  i: Integer;
begin
  Result := -1;

  for i := 0 to Count - 1 do
    if Get(i).FName = AName then begin
      Result := i;
      Break;
    end;
end;

function TUsers.IndexOfUID(AUID: LongWord): Integer;
var
  i: Integer;
begin
  Result := -1;

  for i := 0 to Count - 1 do
    if Get(i).FUID = AUID then begin
      Result := i;
      Break;
    end;
end;

{ TUser }

constructor TUser.Create(AOwner: TEasyGG; AUID: Integer);
begin
  FOwner := AOwner;

  FGUID := NewGuid;
  FUID := AUID;
  FTyp := GG_USER_NORMAL;

  FStatus := usNotAvailable;
  FFriendsOnly := False;
  FImageStatus := False;
  FImageSize := 0;
  FDescription := '';

end;

function TUser.GetBlocked: Boolean;
begin
  Result := FTyp = GG_USER_BLOCKED;
end;

{function TUser.GetGroups: TGroupArray;
var
  i: Integer;
begin
  for i := 0 to FOwner.FGroups.Count - 1 do
    if FOwner.FGroups.Items[i].FUsers.IndexOf(Self) <> -1 then begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := FOwner.Groups.Items[i];
    end;
end;}

procedure TUser.SendMsg(AHTMLMsg, APlainMsg, AAttributes: String);
begin
  FOwner.SendMsg(FUID, AHTMLMsg, APlainMsg, AAttributes);
end;

procedure TUser.SendMsgPlain(AMsg: String);
begin
  FOwner.SendMsgPlain(FUID, AMsg);
end;

procedure TUser.SetBlocked(Value: Boolean);
begin
  
  if FOwner.Loggedin then
    FOwner.RemoveNotify(FUID, FTyp); // usuniêcie maski

  if Value then
    FTyp := GG_USER_BLOCKED
  else
    FTyp := GG_USER_NORMAL;

  if FOwner.Loggedin then
    FOwner.AddNotify(FUID, FTyp); // dodanie maski
end;

procedure TUser.SetUID(Value: LongWord);
var
  i: Integer;
begin
  if Value = FUID then Exit;

  for i := 0 to FOwner.Users.Count - 1 do
    if FOwner.Users.Get(i).FUID = Value then
      EGGError.Create(E_USER_DUPLICATE);

  if FOwner.Loggedin then
    FOwner.RemoveNotify(FUID, FTyp); // usuniêcie starego numeru

  FUID := Value;

  if FOwner.Loggedin then
    FOwner.AddNotify(FUID, FTyp); // dodanie dodanie nowego numeru
end;

{ TEasyGG }

constructor TEasyGG.Create(AOwner: TComponent);
begin
  inherited;
  FAutoHost := True;
  FGetMsgFromBlocked := False;
  FStatus := usNotAvailable;
  FUsers := TUsers.Create(Self);
  //FGroups := TGroups.Create(Self);
  SetStatus(usNotAvailable);
end;

destructor TEasyGG.Destroy;
begin
  SetStatus(usNotAvailable);

  FUsers.Free;
  //FGroups.Free;

  inherited;
end;

procedure TEasyGG.SetFriendsOnly(Value: Boolean);
begin
  if Value = FFriendsOnly then Exit;

  FFriendsOnly := Value;
  if Loggedin then
    NewStatus(FStatus, FDescription, FFriendsOnly, FReceiveURLS);
end;

procedure TEasyGG.SetStatus(Value: TUserStatus);
begin
  if Value = FStatus then Exit;
  if Value = usBlocked then
    EGGError.Create(E_FORBIDDEN_STATUS);
  FStatus := Value;
  if Loggedin then
    NewStatus(FStatus, FDescription, FFriendsOnly, FReceiveURLS)
  else
    Connect;
end;

procedure TEasyGG.SetReceiveURLS(Value: Boolean);
begin
  if Value = FReceiveURLS then Exit;

  FReceiveURLS := Value;
  if Loggedin then
    NewStatus(FStatus, FDescription, FFriendsOnly, FReceiveURLS);
end;

procedure TEasyGG.SetDescription(Value: ShortString);
begin
  if Value = FDescription then Exit;

  FDescription := Value;
  if Loggedin then
    NewStatus(FStatus, FDescription, FFriendsOnly, FReceiveURLS);
end;

procedure TEasyGG.NewStatus(AStatus: TUserStatus; ADescription: ShortString;
  AFriendsOnly, AReceiveURLS: Boolean);
var
  i, j: LongWord;
begin

  i := ConvertStatus(AStatus);
  i := EnableBit(i, 14, ADescription <> '');
  i := EnableBit(i, 15, AFriendsOnly);
  j := EnableBit(1, 23, AReceiveURLS);

  inherited NewStatus(i, j, ADescription);
end;

procedure TEasyGG.SocketDisconnect(Socket: TCustomWinSocket);
var
  i: Integer;
  User: TUser;
begin
  FStatus := usNotAvailable;

  for i := 0 to FUsers.Count - 1 do begin
    User := FUsers.Get(i);

    User.FStatus := usNotAvailable;
    User.FFriendsOnly := False;
    User.FImageStatus := False;
    User.FImageSize := 0;
    User.FDescription := '';

    if Assigned(FOnUserStatus) then
      FOnUserStatus(Self, User);
  end;

  inherited;
end;

procedure TEasyGG.SocketGGDisconnecting;
begin
  if Assigned(FOnDisconnecting) then
    FOnDisconnecting(Self);
end;

procedure TEasyGG.SocketGGListReplyGet(const XML: string);
var
  x: TXMLDocument;
  root, contact{, group}, val: IXMLNode;
  i, j: Integer;
  user: TUser;
begin
  x := TXMLDocument.Create(Self);
  x.LoadFromXML(XML);
  x.Active := True;

  {root := x.DocumentElement.ChildNodes.FindNode('Groups');           TODO!!!
  if root <> nil then  // dodawanie grup
    for i := 0 to root.ChildNodes.Count - 1 do begin
      group := root.ChildNodes[i];

      val := group.ChildNodes.FindNode('Id');
      if val = nil then
        EGGError.Create(E_CONTACTS_CORRUPTED);

      if (val.Text = '00000000-0000-0000-0000-000000000000') or
         (val.Text = '00000000-0000-0000-0000-000000000001') then
        Continue; // pomin grupy "Pozosta³e" i "Ignorowani"

      s := val.Text;

      val := group.ChildNodes.FindNode('Name');
      if val = nil then
        EGGError.Create(E_CONTACTS_CORRUPTED);

      j := FGroups.IndexOfGUID(s);
      if j = -1 then
        FGroups.Items[FGroups.Add(val.Text)].FGUID := s
      else
        FGroups.Items[i].FName := val.Text;

    end; }



  root := x.DocumentElement.ChildNodes.FindNode('Contacts');
  if root <> nil then  // dodawanie kontaktów
    for i := 0 to root.ChildNodes.Count - 1 do begin
      contact := root.ChildNodes[i];

      { Numer GG }
      val := contact.ChildNodes.FindNode('GGNumber');
      if val = nil then
        EGGError.Create(E_CONTACTS_CORRUPTED);
      j := FUsers.IndexOfUID(StrToInt(val.Text));
      if j = -1 then
        j := FUsers.Add(StrToInt(val.Text));
      user := FUsers.Get(j);

      { GUID }
      val := contact.ChildNodes.FindNode('Guid');
      if val = nil then
        user.FGUID := NewGuid
      else
        user.FGUID := val.Text;

      { Nazwa }
      val := contact.ChildNodes.FindNode('ShowName');
      if val <> nil then
        user.FName := val.Text;

      { Telefon komórkowy }
      val := contact.ChildNodes.FindNode('MobilePhone');
      if val <> nil then
        user.FMobilePhone := val.Text;

      { Telefon stacjonarny }
      val := contact.ChildNodes.FindNode('HomePhone');
      if val <> nil then
        user.FHomePhone := val.Text;

      { Email }
      val := contact.ChildNodes.FindNode('Email');
      if val <> nil then
        user.FEmail := val.Text;

      { Strona www }
      val := contact.ChildNodes.FindNode('WwwAddress');
      if val <> nil then
        user.FWWWAddress := val.Text;

      { Imiê }
      val := contact.ChildNodes.FindNode('FirstName');
      if val <> nil then
        user.FFirstName := val.Text;

      { Nazwisko }
      val := contact.ChildNodes.FindNode('LastName');
      if val <> nil then
        user.FLastName := val.Text;

      { P³eæ }
      val := contact.ChildNodes.FindNode('Gender');
      if val <> nil then begin
        if val.Text = '1' then
          user.FGender := gFemale
        else if val.Text = '2' then
          user.FGender := gMale
        else
          user.FGender := gUnknown;
      end;

      { Data urodzenia }
      val := contact.ChildNodes.FindNode('Birth');
      if val <> nil then
        user.FBirth := val.Text;

      { Miejscowoœæ }
      val := contact.ChildNodes.FindNode('City');
      if val <> nil then
        user.FCity := val.Text;

      { Województwo }
      val := contact.ChildNodes.FindNode('Province');
      if val <> nil then
        user.FProvince := val.Text;

      { Czy zablokowany }
      val := contact.ChildNodes.FindNode('FlagIgnored');
      if val <> nil then
        user.SetBlocked(LowerCase(val.Text) = 'true');

      { Grupy }
      {val := contact.ChildNodes.FindNode('Groups');        TODO!!!!
      if val <> nil then
        for j := 0 to val.ChildNodes.Count - 1 do begin
          if (val.ChildNodes[j].Text = '00000000-0000-0000-0000-000000000000') or
             (val.ChildNodes[j].Text = '00000000-0000-0000-0000-000000000001') then
            Continue; // pomin grupy "Pozosta³e" i "Ignorowani"

          k := FGroups.IndexOfGUID(val.ChildNodes[j].Text);
          if k = -1 then
            EGGError.Create(E_CONTACTS_CORRUPTED);

          if FGroups.Items[k].FUsers.IndexOf(user) = -1 then
            FGroups.Items[k].FUsers.Add(user);

        end; }

    end;

  x.Active := False;
  x.Free;

  if Assigned(FOnImportList) then
    FOnImportList(Self);
end;

procedure TEasyGG.SocketGGListReplyPut;
begin
  if Assigned(FOnExportList) then FOnExportList(Self);
end;

procedure TEasyGG.SocketGGLoginFailed;
begin
  if Assigned(FOnLoginFailed) then
    FOnLoginFailed(Self);
end;

procedure TEasyGG.SocketGGLoginOK(var UserArray: Tgg_notifyArray);
var
  Arrgg_notify: Tgg_notifyArray;
  i: Integer;
begin
  SetLength(Arrgg_notify, FUsers.Count);
  for i := 0 to High(Arrgg_notify) do begin
    Arrgg_notify[i].uin := FUsers.Get(i).FUID;
    Arrgg_notify[i].typ := Char(FUsers.Get(i).FTyp);
  end;
  UserArray := Arrgg_notify;

  if Assigned(FOnLoginOK) then
    FOnLoginOK(Self);

end;

procedure TEasyGG.SocketGGNotifyReply(const UserArray: Tgg_notify_reply80Array);
var
  i: Integer;
begin
  for i := 0 to High(UserArray) do
    SocketGGStatus(UserArray[i]);
end;

procedure TEasyGG.SocketGGStatus(const User: Tgg_notify_reply80);
var
  j: Integer;
  User2: TUser;
begin
  for j := 0 to FUsers.Count - 1 do begin
    User2 := FUsers.Get(j);
    if User.uin = User2.FUID then begin
      User2.FStatus := ConvertStatus(User.status);
      User2.FFriendsOnly := GetBit(User.status, 15);
      User2.FImageStatus := GetBit(User.status, 8);
      User2.FImageSize := Byte(User.image_size);
      User2.FDescription := UTF8ToAnsi(User.description);

      if Assigned(FOnUserStatus) then
        FOnUserStatus(Self, User2);

      Break;
    end;
  end;

end;

procedure TEasyGG.SocketGGRecvMsg(const Header: Tgg_recv_msg80);
var
  s: String;
  Count: LongWord;
  Conference: array of LongWord;
  i: Integer;
begin
  if Assigned(FOnReceiveMsg) then begin

    i := FUsers.IndexOfUID(Header.sender);
    if i <> -1 then
      if FUsers.Get(i).GetBlocked and (not FGetMsgFromBlocked) then
        Exit; // nie otrzymujemy wiadomoœci od zablokowanego u¿ytkownika

    if Length(Header.attributes) > 0 then
      if Header.attributes[0] = 1 then begin // je¿eli konferencja
        Move(Header.attributes[1], Count, SizeOf(LongWord)); // pobranie iloœci numerów
        SetLength(Conference, Count);
        for i := 0 to Count - 1 do
          Move(Header.attributes[i * SizeOf(LongWord) + 5], Conference[i], SizeOf(LongWord));

        SetLength(s, Length(Header.attributes) - Length(Conference) * SizeOf(LongWord) - 5);
        Move(Header.attributes[Length(Conference) * SizeOf(LongWord) + 5], s[1], Length(s));
      end
      else begin
        SetLength(s, Length(Header.attributes));
        Move(Header.attributes[0], s[1], Length(Header.attributes));
      end;

    FOnReceiveMsg(Self, Header.sender, Header.html_message, Header.plain_message, s, UnixToDateTime(Header.time), Conference);
  end;
end;

procedure TEasyGG.SocketGGSendMsgAck(const Response: Tgg_send_msg_ack);
begin
  if Assigned(FOnSendMsg) then
    FOnSendMsg(Self, Response.recipient);
end;

procedure TEasyGG.SocketGGWelcome(var AStatus, AFlags: LongWord;
  var ADescription: ShortString);
begin
  AStatus := ConvertStatus(FStatus); // status na starcie

  AStatus := EnableBit(AStatus, 14, FDescription <> '');
  AStatus := EnableBit(AStatus, 15, FFriendsOnly);

  AFlags := EnableBit(1, 23, FReceiveURLS);
  ADescription := FDescription;
end;


procedure TEasyGG.Connect;
var
  sHost: String;
  iPort: Integer;
begin
  if FAutoHost and (not Active) then begin
    GetHost(UID, sHost, iPort); // automatyczne pobranie adresu serwera
    Host := sHost;
    Port := iPort;
  end;
  
  inherited;
end;

procedure TEasyGG.ContactsFromFile(FileName: String);
var
  Strings: TStringList;
begin
  Strings := TStringList.Create;
  Strings.LoadFromFile(FileName);
  SocketGGListReplyGet(Strings.Text); 
  Strings.Free;
end;

procedure TEasyGG.ContactsFromServer;
begin
  UserlistGet;
end;

procedure TEasyGG.ContactsFromString(XML: String);
begin
  SocketGGListReplyGet(XML);
end;

procedure TEasyGG.ContactsToFile(FileName: String);
var
  Strings: TStringList;
begin
  Strings := TStringList.Create;
  Strings.Text := ContactsToString;
  Strings.SaveToFile(FileName);
  Strings.Free;
end;

procedure TEasyGG.ContactsToServer;
begin
  UserlistPut(ContactsToString);
end;

function TEasyGG.ContactsToString: String;
var
  x: TXMLDocument;
  i: Integer;
  root, group, contact, val: IXMLNode;
  //g: TGroupArray;
begin
  x := TXMLDocument.Create(Self);
  x.Active := True;
  x.AddChild('ContactBook'); // dodanie g³ównego elementu

  root := x.DocumentElement.AddChild('Groups'); // dodanie sekcji grup

  { Dodanie grupy "Pozosta³e" }
  group := root.AddChild('Group');
  group.AddChild('Id').Text := '00000000-0000-0000-0000-000000000000';
  group.AddChild('Name').Text := 'Pozosta³e';
  group.AddChild('IsExpanded').Text := 'true';
  group.AddChild('IsRemovable').Text := 'false';

  { Dodanie grupy "Ignorowani" }
  group := root.AddChild('Group');
  group.AddChild('Id').Text := '00000000-0000-0000-0000-000000000001';
  group.AddChild('Name').Text := 'Ignorowani';
  group.AddChild('IsExpanded').Text := 'false';
  group.AddChild('IsRemovable').Text := 'false';

  { Dodanie grup }
  {for i := 0 to FGroups.Count - 1 do begin                       TODO!!!!
    group := root.AddChild('Group');
    group.AddChild('Id').Text := FGroups.Items[i].FGUID;
    group.AddChild('Name').Text := FGroups.Items[i].FName;
    if FGroups.Items[i].FIsExpanded then
      group.AddChild('IsExpanded').Text := 'true'
    else
      group.AddChild('IsExpanded').Text := 'false';
    group.AddChild('IsRemovable').Text := 'true';
  end;}

  root := x.DocumentElement.AddChild('Contacts'); // dodanie sekcji u¿ytkowników

  { Dodanie u¿ytkowników }
  for i := 0 to FUsers.Count - 1 do begin
    contact := root.AddChild('Contact');
    contact.AddChild('Guid').Text := FUsers[i].FGUID;
    contact.AddChild('GGNumber').Text := IntToStr(FUsers[i].FUID);

    if FUsers[i].FName <> '' then
      contact.AddChild('ShowName').Text := FUsers[i].FName;
    if FUsers[i].FMobilePhone <> '' then
      contact.AddChild('MobilePhone').Text := FUsers[i].FMobilePhone;
    if FUsers[i].FHomePhone <> '' then
      contact.AddChild('HomePhone').Text := FUsers[i].FHomePhone;
    if FUsers[i].FEmail <> '' then
      contact.AddChild('Email').Text := FUsers[i].FEmail;
    if FUsers[i].FWWWAddress <> '' then
      contact.AddChild('WwwAddress').Text := FUsers[i].FWWWAddress;
    if FUsers[i].FFirstName <> '' then
      contact.AddChild('FirstName').Text := FUsers[i].FFirstName;
    if FUsers[i].FLastName <> '' then
      contact.AddChild('LastName').Text := FUsers[i].FLastName;

    if FUsers[i].FGender <> gUnknown then begin
      val := contact.AddChild('Gender');
      if FUsers[i].FGender = gMale then
        val.Text := '2'
      else if FUsers[i].FGender = gFemale then
        val.Text := '1';
    end;

    if FUsers[i].FBirth <> '' then
    contact.AddChild('Birth').Text := FUsers[i].FBirth;
    if FUsers[i].FCity <> '' then
    contact.AddChild('City').Text := FUsers[i].FCity;
    if FUsers[i].FProvince <> '' then
    contact.AddChild('Province').Text := FUsers[i].FProvince;

    val := contact.AddChild('Groups');
    val.AddChild('GroupId').Text := '00000000-0000-0000-0000-000000000000';
    if FUsers[i].GetBlocked then
      val.AddChild('GroupId').Text := '00000000-0000-0000-0000-000000000001';

    {for j := 0 to FGroups.Count - 1 do                         TODO!!!!
      if FGroups.Items[j].IndexOfUser(FUsers.Items[i]) <> -1 then
        val.AddChild('GroupId').Text := FGroups.Items[i].FGUID; }

    contact.AddChild('Avatars').AddChild('URL').Text := 'avatar-empty.gif'; // TODO!!!!
    contact.AddChild('FlagNormal').Text := 'true';
    if FUsers[i].GetBlocked then
      contact.AddChild('FlagIgnored').Text := 'true';
  end;


  x.SaveToXML(Result);
  x.Active := False;
  x.Free;
end;

function TEasyGG.ConvertStatus(AStatus: LongWord): TUserStatus;
begin
  AStatus := ClearBit(AStatus, 8); // usuniêcie maski opisu graficznego (komponent ich nie obs³uguje)
  AStatus := ClearBit(Astatus, 14); // usuniêcie maski opisu
  AStatus := ClearBit(Astatus, 15); // usuniêcie maski przyjació³

  Result := usNotAvailable;
  case AStatus of
    GG_STATUS_NOT_AVAIL, GG_STATUS_NOT_AVAIL_DESCR:
      Result := usNotAvailable;
    GG_STATUS_FFC, GG_STATUS_FFC_DESCR:
      Result := usGGWithMe;
    GG_STATUS_AVAIL, GG_STATUS_AVAIL_DESCR:
      Result := usAvailable;
    GG_STATUS_BUSY, GG_STATUS_BUSY_DESCR:
      Result := usBusy;
    GG_STATUS_DND, GG_STATUS_DND_DESCR:
      Result := usDND;
    GG_STATUS_INVISIBLE, GG_STATUS_INVISIBLE_DESCR:
      Result := usInvisible;
    GG_STATUS_BLOCKED:
      Result := usBlocked;
    else
      EGGError.Create(E_UNKNOWN_STATUS);
  end;
end;

function TEasyGG.ConvertStatus(AStatus: TUserStatus): LongWord;
begin
  Result := 0;
  case AStatus of
    usGGWithMe:
      Result := GG_STATUS_FFC;
    usAvailable:
      Result := GG_STATUS_AVAIL;
    usNotAvailable:
      Result := GG_STATUS_NOT_AVAIL;
    usBusy:
      Result := GG_STATUS_BUSY;
    usDND:
      Result := GG_STATUS_DND;
    usInvisible:
      Result := GG_STATUS_INVISIBLE;
    usBlocked:
      Result := GG_STATUS_BLOCKED;
    else
      EGGError.Create(E_UNKNOWN_STATUS);
  end;
end;

end.
