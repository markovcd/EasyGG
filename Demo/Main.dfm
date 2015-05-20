object frmMain: TfrmMain
  Left = 665
  Top = 195
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'EasyGG demo'
  ClientHeight = 412
  ClientWidth = 478
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 224
    Top = 8
    Width = 251
    Height = 314
    Caption = 'Wiadomo'#347'ci'
    TabOrder = 0
    object btnSend: TButton
      Left = 3
      Top = 280
      Width = 242
      Height = 21
      Caption = 'Wy'#347'lij'
      TabOrder = 0
      OnClick = btnSendClick
    end
    object txtMsgSend: TMemo
      Left = 4
      Top = 199
      Width = 242
      Height = 75
      ScrollBars = ssVertical
      TabOrder = 1
    end
    object txtMsgRecv: TMemo
      Left = 4
      Top = 22
      Width = 242
      Height = 171
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 2
    end
  end
  object GroupBox2: TGroupBox
    Left = 1
    Top = 8
    Width = 217
    Height = 225
    Caption = 'Lista'
    TabOrder = 1
    object Label1: TLabel
      Left = 4
      Top = 197
      Width = 18
      Height = 13
      Caption = 'UID'
    end
    object Label3: TLabel
      Left = 3
      Top = 170
      Width = 32
      Height = 13
      Caption = 'Nazwa'
    end
    object lstContacts: TListBox
      Left = 4
      Top = 22
      Width = 209
      Height = 139
      ItemHeight = 13
      MultiSelect = True
      TabOrder = 0
    end
    object btnAdd: TButton
      Left = 189
      Top = 167
      Width = 21
      Height = 21
      Caption = '+'
      TabOrder = 1
      OnClick = btnAddClick
    end
    object btnRemove: TButton
      Left = 189
      Top = 194
      Width = 21
      Height = 21
      Caption = '-'
      TabOrder = 2
      OnClick = btnRemoveClick
    end
    object txtName: TEdit
      Left = 40
      Top = 167
      Width = 143
      Height = 21
      TabOrder = 3
    end
    object txtUID: TEdit
      Left = 40
      Top = 194
      Width = 143
      Height = 21
      TabOrder = 4
      Text = '0'
    end
  end
  object GroupBox3: TGroupBox
    Left = 1
    Top = 239
    Width = 217
    Height = 84
    Caption = 'Status'
    TabOrder = 2
    object txtDescription: TEdit
      Left = 4
      Top = 22
      Width = 179
      Height = 21
      MaxLength = 255
      TabOrder = 0
    end
    object cmbStatus: TComboBox
      Left = 5
      Top = 49
      Width = 209
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      ItemIndex = 5
      TabOrder = 1
      Text = 'Niedost'#281'pny'
      OnChange = cmbStatusChange
      Items.Strings = (
        'Dost'#281'pny'
        'Zaraz wracam'
        'Nie przeszkadza'#263
        'PoGGadaj ze mn'#261
        'Niewidoczny'
        'Niedost'#281'pny')
    end
    object btnStatus: TButton
      Left = 189
      Top = 22
      Width = 21
      Height = 21
      Caption = 'OK'
      TabOrder = 2
      OnClick = btnStatusClick
    end
  end
  object GroupBox4: TGroupBox
    Left = 1
    Top = 328
    Width = 280
    Height = 81
    Caption = 'Ustawienia'
    TabOrder = 3
    object Label2: TLabel
      Left = 74
      Top = 51
      Width = 34
      Height = 13
      Caption = 'sekund'
    end
    object Label4: TLabel
      Left = 146
      Top = 29
      Width = 18
      Height = 13
      Caption = 'UID'
    end
    object Label5: TLabel
      Left = 137
      Top = 51
      Width = 27
      Height = 13
      Caption = 'Has'#322'o'
    end
    object chkBusy: TCheckBox
      Left = 3
      Top = 24
      Width = 121
      Height = 17
      Caption = 'Auto Zaraz wracam'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
    object txtBusyTime: TEdit
      Left = 3
      Top = 47
      Width = 65
      Height = 21
      TabOrder = 1
      Text = '300'
    end
    object txtUserID: TEdit
      Left = 170
      Top = 24
      Width = 105
      Height = 21
      TabOrder = 2
    end
    object txtPassword: TEdit
      Left = 170
      Top = 47
      Width = 105
      Height = 21
      PasswordChar = '*'
      TabOrder = 3
    end
  end
  object btnImportServer: TButton
    Left = 287
    Top = 328
    Width = 183
    Height = 17
    Caption = 'Import listy z serwera'
    TabOrder = 4
    OnClick = btnImportServerClick
  end
  object btnExportFile: TButton
    Left = 287
    Top = 391
    Width = 183
    Height = 18
    Caption = 'Eksport listy do pliku'
    TabOrder = 5
    OnClick = btnExportFileClick
  end
  object btnImportFile: TButton
    Left = 287
    Top = 345
    Width = 183
    Height = 17
    Caption = 'Import listy z pliku'
    TabOrder = 6
    OnClick = btnImportFileClick
  end
  object btnExportServer: TButton
    Left = 287
    Top = 374
    Width = 183
    Height = 17
    Caption = 'Eksport listy na serwer'
    TabOrder = 7
    OnClick = btnExportServerClick
  end
  object it: TIdleTimer
    OnIdle = itIdle
    OnBack = itBack
    Left = 176
    Top = 72
  end
  object egg: TEasyGG
    FriendsOnly = False
    Port = 0
    ReceiveURLS = False
    UID = 0
    OnUserStatus = eggUserStatus
    OnReceiveMsg = eggReceiveMsg
    OnSendMsg = eggSendMsg
    OnLoginOK = eggLoginOK
    OnConnecting = eggConnecting
    OnDisconnect = eggDisconnect
    OnImportList = eggImportList
    OnExportList = eggExportList
    Left = 144
    Top = 72
  end
  object dlgOpen: TOpenDialog
    Left = 176
    Top = 104
  end
  object dlgSave: TSaveDialog
    Left = 144
    Top = 104
  end
end
