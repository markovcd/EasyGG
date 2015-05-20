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

unit EGGFuncts;
  { Unit zawiera podstawowe metody zwi¹zane z obs³ug¹ protoko³u }

interface

uses
  SysUtils, SHA1, ScktComp, Classes, ZLib, EGGConsts;

function GetBit(const Value: LongWord; const Bit: Byte): Boolean;
function ClearBit(const Value: LongWord; const Bit: Byte): LongWord;
function SetBit(const Value: LongWord; const Bit: Byte): LongWord;
function EnableBit(const Value: LongWord; const Bit: Byte; const TurnOn: Boolean): LongWord;
function gg_sha_hash(const password: string; const seed: LongWord): string;
function HttpGetText(URL: string): string;
procedure GetHost(const AUID: Integer; var AHost: String; var APort: Integer);
function DateTimeToUnix(ConvDate: TDateTime): Longint;
function UnixToDateTime(USec: Longint): TDateTime;
function Deflate(s: String): String;
function Inflate(s: String): String;
function NewGuid: String;

implementation

function NewGuid: String;
var
  GUID : TGUID;
begin
  CreateGUID(Guid);
  Result := GUIDToString(GUID);
  Result := LowerCase(Result); // ma³e litery
  Result := Copy(Result, 2, Length(Result) - 2); // usuniêcie "{" i "}"
end;

function GetBit(const Value: LongWord; const Bit: Byte): Boolean;
begin
  Result := (Value and (1 shl Bit)) <> 0;
end;

function ClearBit(const Value: LongWord; const Bit: Byte): LongWord;
begin
  Result := Value and not (1 shl Bit);
end;

function SetBit(const Value: LongWord; const Bit: Byte): LongWord;
begin
  Result := Value or (1 shl Bit);
end;

function EnableBit(const Value: LongWord; const Bit: Byte; const TurnOn: Boolean): LongWord;
begin
  Result := (Value or (1 shl Bit)) xor (LongWord(not TurnOn) shl Bit);
end;

function gg_sha_hash(const password: string; const seed: LongWord): string;
var
  SHA1: TDCP_sha1;
  digest:array [0..19] of byte;
begin
  SHA1 := TDCP_sha1.Create(nil);
  SHA1.Init;
  SHA1.UpdateStr(password);
  SHA1.Update(seed, SizeOf(seed));
  SHA1.Final(digest);
  SHA1.Free;

  SetLength(Result, 20);
  Move(digest[0], Result[1], 20);
end;

function HttpGetText(URL: string): string;
var
  FClientSocket: TClientSocket;
  SockStream: TWinSocketStream;
  Host, Request: String;
  Buffer: array[0..254] of Char;
const
  DATA = 'GET %s HTTP/1.1' + rn +
         'Connection: Keep-Alive' + rn +
         'Host: %s' + rn + rn;
begin
  FillChar(Buffer, SizeOf(Buffer), #0);

  if Copy(URL, 1, 7) = 'http://' then
    URL := Copy(URL, 8, Length(URL));
  Host := Copy(URL, 1, Pos('/', URL) - 1);
  Request := Copy(URL, Pos('/', URL), Length(URL));

  Request := Format(DATA, [Request, Host]);

  FClientSocket := TClientSocket.Create(nil);
  FClientSocket.Host := Host;
  FClientSocket.Port := 80;
  FClientSocket.ClientType := ctBlocking;

  FClientSocket.Active := True; // uzyskanie polaczenia
  SockStream := TWinSocketStream.Create(FClientSocket.Socket, 60000); // utworzenie streamu
  SockStream.Write(Request[1], Length(Request));
  SockStream.Read(Buffer, SizeOf(Buffer));
  Result := Buffer;
  Result := Trim(Copy(Result, Pos(rn + rn, Result), Length(Result)));
  FClientSocket.Active := False;
  SockStream.Free;
  FClientSocket.Free;
end;

procedure GetHost(const AUID: Integer; var AHost: string; var APort: Integer);
var
  s: String;
  i, j: Integer;
const
  URL = 'http://appmsg.gadu-gadu.pl/appsvc/appmsg_ver8.asp?fmnumber=%d&lastmsg=0&version=%s';
begin
  s := HttpGetText(Format(URL, [AUID, GG_VERSION]));

  i := LastDelimiter(' ', s);
  AHost := Trim(Copy(s, i + 1, Length(s)));
  j := LastDelimiter(':', s);
  if j <> 0 then
    APort := StrToInt(Copy(s, j + 1, i - j - 1));
end;

function DateTimeToUnix(ConvDate: TDateTime): Longint;
const
  UnixStartDate: TDateTime = 25569.0;
begin
  //example: DateTimeToUnix(now);
  Result := Round((ConvDate - UnixStartDate) * 86400);
end;

function UnixToDateTime(USec: Longint): TDateTime;
const
  UnixStartDate: TDateTime = 25569.0;
begin
  //Example: UnixToDateTime(1003187418);
  Result := (Usec / 86400) + UnixStartDate;
end;

{$IFDEF VER200}
function Deflate(s: String): String;
begin
  Result := ZCompressStr(s);
end;

function Inflate(s: String): String;
begin
  Result := ZDecompressStr(s);
end;
{$ELSE}
function Deflate(s: String): String;
var
  pIn, pOut: Pointer;
  i: Integer;
begin
  pIn := nil;
  pOut := nil;
  try
    GetMem(pIn, Length(s)); // zaalokowanie pamiêci o wielkoœci s
    Move(s[1], pIn^, Length(s)); // skopiowanie zmiennej s do pamiêci
    CompressBuf(pIn, Length(s), pOut, i); // kompresja
    SetLength(Result, i); // ustanowienie d³ugoœci zmiennej wynikowej
    Move(pOut^, Result[1], i); // skopiowanie danych do wyniku
  finally // zwolnienie pamiêci
    if pIn <> nil then FreeMem(pIn, Length(s));
    if pOut <> nil then FreeMem(pOut, i);
  end;
end;

function Inflate(s: String): String;
var
  pIn, pOut: Pointer;
  i: Integer;
begin
  pIn := nil;
  pOut := nil;
  try
    GetMem(pIn, Length(s)); // zaalokowanie pamiêci o wielkoœci s
    Move(s[1], pIn^, Length(s)); // skopiowanie zmiennej s do pamiêci
    DecompressBuf(pIn, Length(s), 0, pOut, i); // dekompresja
    SetLength(Result, i); // ustanowienie d³ugoœci zmiennej wynikowej
    Move(pOut^, Result[1], i); // skopiowanie danych do wyniku
  finally // zwolnienie pamiêci
    if pIn <> nil then FreeMem(pIn, Length(s));
    if pOut <> nil then FreeMem(pOut, i);
  end;
end;
{$ENDIF}

end.
