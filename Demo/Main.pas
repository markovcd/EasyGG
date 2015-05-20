unit Main;

interface

uses
  SysUtils, Forms, StdCtrls, ScktComp, EGG, IdleTimer, EGGBase,
  Classes, Controls, EGGFuncts, dialogs, Menus, Sockets;

type
  TfrmMain = class(TForm)
    GroupBox1: TGroupBox;
    btnSend: TButton;
    txtMsgSend: TMemo;
    txtMsgRecv: TMemo;
    GroupBox2: TGroupBox;
    lstContacts: TListBox;
    GroupBox3: TGroupBox;
    txtDescription: TEdit;
    cmbStatus: TComboBox;
    btnStatus: TButton;
    btnAdd: TButton;
    btnRemove: TButton;
    txtName: TEdit;
    txtUID: TEdit;
    Label1: TLabel;
    it: TIdleTimer;
    GroupBox4: TGroupBox;
    chkBusy: TCheckBox;
    txtBusyTime: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    txtUserID: TEdit;
    txtPassword: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    btnImportServer: TButton;
    btnExportFile: TButton;
    egg: TEasyGG;
    btnImportFile: TButton;
    btnExportServer: TButton;
    dlgOpen: TOpenDialog;
    dlgSave: TSaveDialog;
  

    procedure eggReceiveMsg(Sender: TObject; UID: Cardinal; HTMLMessage,
      PlainMessage, Attributes: string; Time: TDateTime;
      Conference: array of Cardinal);
    procedure eggSendMsg(Sender: TObject; UID: Cardinal);
    procedure eggUserStatus(Sender: TObject; User: TUser);
    procedure cmbStatusChange(Sender: TObject);
    procedure btnStatusClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure eggLoginOK(Sender: TObject);
    procedure eggDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure itBack(Sender: TObject);
    procedure itIdle(Sender: TObject);
    procedure eggConnecting(Sender: TObject; Socket: TCustomWinSocket);
    procedure btnImportServerClick(Sender: TObject);
    procedure eggImportList(Sender: TObject);
    procedure btnExportFileClick(Sender: TObject);
    procedure btnImportFileClick(Sender: TObject);
    procedure btnExportServerClick(Sender: TObject);
    procedure eggExportList(Sender: TObject);
  end;

var
  frmMain: TfrmMain;
  PrevStatus: TUserStatus;

const
  FMT_CONTACTS = '[%s] %s - %s';

function Stan(Status: TUserStatus): String; overload;
function Stan(Status: String): TUserStatus; overload;

implementation

{$R *.dfm}

function Stan(Status: TUserStatus): String;
begin
  case Status of
    usGGWithMe: Result := 'PoGGadaj ze mną';
    usAvailable: Result := 'Dostępny';
    usNotAvailable: Result := 'Niedostępny';
    usBusy: Result := 'Zaraz wracam';
    usDND: Result := 'Nie przeszkadzać';
    usInvisible: Result := 'Niewidoczny';
    usBlocked: Result := 'Zablokowany';
  end;
end;

function Stan(Status: String): TUserStatus;
begin
  Result := usNotAvailable;

  if Status = 'PoGGadaj ze mną' then
    Result := usGGWithMe
  else if Status = 'Dostępny' then
    Result := usAvailable
  else if Status = 'Niedostępny' then
    Result := usNotAvailable
  else if Status = 'Zaraz wracam' then
    Result := usBusy
  else if Status = 'Nie przeszkadzać' then
    Result := usDND
  else if Status = 'Niewidoczny' then
    Result := usInvisible
  else if Status = 'Zablokowany' then
    Result := usBlocked;
end;

procedure TfrmMain.btnSendClick(Sender: TObject);
var
  s, tim, r: String;
  Recipients: array of LongWord;
  i: Integer;
begin

  for i := 0 to lstContacts.Items.Count - 1 do
    if lstContacts.Selected[i] then begin
      SetLength(Recipients, Length(Recipients) + 1);
      Recipients[High(Recipients)] := TUser(lstContacts.Items.Objects[i]).UID;
    end;

  if Length(Recipients) = 0 then Exit;

  tim := FormatDateTime('c', Now);

  egg.ConferencePlain(Recipients, txtMsgSend.Text);

  for i := 0 to High(Recipients) do
    r := r + IntToStr(Recipients[i]) + ', ';
  r := Copy(r, 1, Length(r) - 2);

  s := Format('Do [%s] - %s'#13#10'%s', [r, tim, txtMsgSend.Text]);
  txtMsgRecv.Lines.Add(s);

  txtMsgSend.Clear;
end;

procedure TfrmMain.eggReceiveMsg(Sender: TObject; UID: Cardinal; HTMLMessage,
  PlainMessage, Attributes: string; Time: TDateTime;
  Conference: array of Cardinal);
var
  s, conf, tim: string;
  i: Integer;
begin
  tim := FormatDateTime('c', Time);
  if Length(Conference) = 0 then
    s := Format('Od [%d] - %s'#13#10'%s'#13#10, [UID, tim, PlainMessage])
  else begin
    conf := '';
    for i := 0 to High(Conference) do
      conf := conf + IntToStr(Conference[i]) + ', ';
    conf := Copy(conf, 1, Length(conf) - 2);
    s := Format('Od [%d] - %s'#13#10'Konferencja: (%s)'#13#10'%s'#13#10, [UID, tim, conf, PlainMessage]);
  end;
  txtMsgRecv.Lines.Add(s);
end;

procedure TfrmMain.eggSendMsg(Sender: TObject; UID: Cardinal);
begin
  txtMsgRecv.Lines.Add(Format('[Dostarczono do %d]', [UID]));
end;

procedure TfrmMain.eggConnecting(Sender: TObject; Socket: TCustomWinSocket);
begin
  egg.UID := StrToInt(txtUserID.Text);
  egg.Password := txtPassword.Text;
end;

procedure TfrmMain.eggDisconnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  it.Enabled := False;
  txtBusyTime.Enabled := True;
  txtUserID.Enabled := True;
  txtPassword.Enabled := True;

  cmbStatus.ItemIndex := cmbStatus.Items.IndexOf('Niedostępny');
end;

procedure TfrmMain.eggExportList(Sender: TObject);
begin
  ShowMessage('Listę poprawnie wyeksportowano na serwer.');
end;

procedure TfrmMain.eggImportList(Sender: TObject);
var
  i: Integer;
  User: TUser;
  s: String;
begin
  lstContacts.Clear;
  
  for i := 0 to egg.Users.Count - 1 do begin
    User := egg.Users[i];

    s := Format(FMT_CONTACTS, [Stan(User.Status), User.Name, User.Description]);
    lstContacts.AddItem(s, User);
  end;
end;

procedure TfrmMain.eggLoginOK(Sender: TObject);
begin
  it.IdleInterval := StrToInt(txtBusyTime.Text);
  it.Enabled := True;
  txtBusyTime.Enabled := False;
  txtUserID.Enabled := False;
  txtPassword.Enabled := False;
end;

procedure TfrmMain.eggUserStatus(Sender: TObject; User: TUser);
var
  i: Integer;
  s: String;
begin
  for i := 0 to lstContacts.Count - 1 do
    if lstContacts.Items.Objects[i] = User then begin
      s := Format(FMT_CONTACTS, [Stan(User.Status), User.Name, User.Description]);
      lstContacts.Items[i] := s;
      Break;
    end;

end;

procedure TfrmMain.btnStatusClick(Sender: TObject);
begin
  egg.Description := txtDescription.Text;
end;

procedure TfrmMain.btnExportFileClick(Sender: TObject);
begin
  if dlgSave.Execute then
    egg.ContactsToFile(dlgSave.FileName);
end;

procedure TfrmMain.btnImportFileClick(Sender: TObject);
begin
  if dlgOpen.Execute then
    egg.ContactsFromFile(dlgOpen.FileName);
end;

procedure TfrmMain.btnExportServerClick(Sender: TObject);
begin
  egg.ContactsToServer;
end;

procedure TfrmMain.btnImportServerClick(Sender: TObject);
begin
  egg.ContactsFromServer;
end;

procedure TfrmMain.btnAddClick(Sender: TObject);
var
  User: TUser;
  s: String;
begin
  User := egg.Users.Items[egg.Users.Add(StrToInt(txtUID.Text))];
  User.Name := txtName.Text;

  s := Format(FMT_CONTACTS, [Stan(User.Status), User.Name, User.Description]);
  lstContacts.AddItem(s, User);

  txtName.Clear;
  txtUID.Clear;
end;

procedure TfrmMain.btnRemoveClick(Sender: TObject);
var
  User: TUser;
  i: Integer;
begin
  for i := lstContacts.Items.Count - 1 downto 0 do
    if lstContacts.Selected[i] then begin
      User := TUser(lstContacts.Items.Objects[i]);
      lstContacts.Items.Delete(i);
      egg.Users.Delete(egg.Users.IndexOfUID(User.UID));
    end;
end;

procedure TfrmMain.cmbStatusChange(Sender: TObject);
begin
  egg.Status := Stan(cmbStatus.Items[cmbStatus.ItemIndex]);
end;

procedure TfrmMain.itIdle(Sender: TObject);
begin
  if (chkBusy.Checked) and (egg.Status = usAvailable) then begin
    egg.Status := usBusy;
    cmbStatus.ItemIndex := cmbStatus.Items.IndexOf('Zaraz wracam');
  end;


end;

procedure TfrmMain.itBack(Sender: TObject);
begin
  if chkBusy.Checked then begin
    egg.Status := usAvailable;
    cmbStatus.ItemIndex := cmbStatus.Items.IndexOf('Dostępny');
  end;
end;

end.
