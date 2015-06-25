program Lexical;
type
Symbol = string[8];
SymTab = array[1..1000] of Symbol;
TabPtr = ^Symtab;

const
TAB = ^I;
CR = ^M;
LF = ^J;
KWList: array[1..4] of Symbol =
('IF','ELSE','ENDIF','END');
const KWcode: string[5] = 'xilee';
var
Look: char; {global lookahead char}
Token: char;
Value: string[16];

function Lookup(T: TabPtr; s:string; n:integer):integer;
var
i: integer;
found: boolean;
begin
     found := false;
     i:=n;
     while(i>0) and not found do
        if s=T^[i] then
           found := true
        else
            dec(i);
     Lookup := i;
end;

procedure GetChar; {scan next character}
begin
     Read(Look);
end;

procedure Error(s:string); {error reporting}
begin
     WriteLn;
     WriteLn(^G, 'Error: ', s, '.');
end;

procedure Abort(s:string); {exit the program on error.}
begin
     Error(s);
     Halt;
end;

procedure Expected(s: string);
begin
     Abort(s+' Expected');
end;

procedure Match(x:char);
begin
     if Look = x then GetChar
     else Expected('"' + x + '"');
end;

function IsAlpha(c: char): boolean;
begin
     IsAlpha := upcase(c) in ['A'..'Z'];
end;

function IsDigit(c: char): boolean;
begin
     IsDigit := c in ['0'..'9'];
end;

function IsAlNum(c: char): boolean;
begin
     IsAlNum := IsAlpha(c) or IsDigit(c);
end;

procedure GetName;{Get an identifier}
begin
     Value:= '';
     if not IsAlpha(Look) then Expected('Name');
     while IsAlNum(Look) do begin
           Value:= Value + UpCase(Look);
           GetChar;
     end;
     Token := KWCode[Lookup(Addr(KWList),Value,4)+1];
end;

procedure GetNum;
begin
     Value:='';
     Token := '#';
     if not IsDigit(Look) then expected('Integer');
     while IsDigit(Look) do begin
           Value:=Value + Look;
           GetChar;
     end;
end;

function IsOp(c:char): boolean;
begin
     IsOp := c in ['+','-','*','/','<','>',':','='];
end;

function GetOp: string;
begin
     Value := '';
     if not IsOp(Look) then Expected('Operator');
     while IsOp(Look) do
     begin
           Value := Value + Look;
           GetChar;
     end;

     if Length(Value) = 1 then
        Token := Value[1]
     else
         Token := '?';

end;

function IsWhite(c: char): boolean;
begin
   IsWhite := c in [' ', TAB];
end;

procedure SkipWhite;
begin
   while IsWhite(Look) do
      GetChar;
end;

procedure SkipComma;
begin
     SkipWhite;
     if Look = ',' then begin
        GetChar;
        SkipWhite;
     end;
end;

procedure Fin;
begin
   if Look = CR then GetChar;
   if Look = LF then GetChar;
end;

procedure Emit(s:string);
begin
     Write(TAB,s);
end;

procedure EmitLn(s:string);
begin
     Emit(s);
     WriteLn;
end;

procedure Scan;
var k: integer;
begin
     while Look = CR do
           Fin;
     if IsAlpha(Look) then
          GetName
     else if IsDigit(Look) then
          GetNum
     else if IsOp(Look) then
          GetOp
     else begin
          Value:= Look;
          Token := '?';
          GetChar;
     end;
     SkipWhite;
end;

procedure Init;
begin
     GetChar;
end;


{--------Main program-------}
begin
     Init;
     repeat
           Scan;
           case Token of
                'x': Write('Ident ');
                '#': Write('Number ');
                'i','l','e': Write('Keyword ');
                else Write ('Operator ');
           end;
           Writeln(Value);
     until VALUE = 'END';
end.