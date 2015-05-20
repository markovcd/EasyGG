{
    Komponent wykrywaj¹cy czas nieaktywnoœci u¿ytkownika
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

unit IdleTimer;

interface

uses
  Windows, Classes, ExtCtrls;

const
  DEFAULT_IDLE = 300; // domyœlny czas wartoœci IdleInterval (w sekundach)

type
  TIdleTimer = class(TComponent)
  private
    FOnIdle: TNotifyEvent;
    FOnBack: TNotifyEvent;
    FIdleInterval: Cardinal;
    FTime: Cardinal;
    FTimer: TTimer;
  protected
    procedure SetIdleInterval(Value: Cardinal);
    procedure Timer(Sender: TObject);
    function GetEnabled: Boolean;
    procedure SetEnabled(Value: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetIdleTime: Cardinal;
  published
    property OnIdle: TNotifyEvent read FOnIdle write FOnIdle;
    property OnBack: TNotifyEvent read FOnBack write FOnBack;
    property IdleInterval: Cardinal read FIdleInterval write SetIdleInterval default DEFAULT_IDLE;
    property Enabled: Boolean read GetEnabled write SetEnabled default False;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('mdev', [TIdleTimer]);
end;

{ TIdleTimer }

procedure TIdleTimer.SetEnabled(Value: Boolean);
begin
  FTimer.Enabled := Value;
end;

function TIdleTimer.GetEnabled;
begin
  Result := FTimer.Enabled;
end;

function TIdleTimer.GetIdleTime: Cardinal;
var
   liInfo: TLastInputInfo;
begin
   liInfo.cbSize := SizeOf(TLastInputInfo) ;
   GetLastInputInfo(liInfo) ;
   Result := (GetTickCount - liInfo.dwTime) DIV 1000;
end;

constructor TIdleTimer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 1000;
  FTimer.OnTimer := Timer;

  FIdleInterval := DEFAULT_IDLE;
  FTime := 0;
end;

destructor TIdleTimer.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TIdleTimer.SetIdleInterval(Value: Cardinal);
begin
  FTime := 0;
  FIdleInterval := Value;
end;

procedure TIdleTimer.Timer(Sender: TObject);
var
  ATime: Cardinal;
begin
  ATime := GetIdleTime;
  if (ATime >= FIdleInterval) and (FTime = 0) then begin
    if Assigned(FOnIdle) then
      FOnIdle(Self);
    FTime := ATime;
  end
  else if FTime > ATime then begin
    if Assigned(FOnBack) then
      FOnBack(Self);
    FTime := 0;
  end;
end;

end.
