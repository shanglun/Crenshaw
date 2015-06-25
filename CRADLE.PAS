program Cradle;
const
TAB = ^I;
CR = ^M;
LF = ^J;
var
Look: char; {global lookahead char}

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

function GetName: string;{Get an identifier}
var x: string[8];
begin
     x:= '';
     if not IsAlpha(Look) then Expected('Name');
     while IsAlNum(Look) do begin
           x:= x + UpCase(Look);
           GetChar;
     end;
     GetName:=x;
end;

function GetNum: string;
var x: string[16];
begin
     x:='';
     if not IsDigit(Look) then expected('Integer');
     while IsDigit(Look) do begin
           x:=x + Look;
           GetChar;
     end;
     GetNum := x;
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

function Scan: string;
begin
     if IsAlpha(Look) then
        Scan := GetName
     else if isDigit(Look) then
        Scan := GetNum
     else begin
          Scan := Look;
          Getchar;
     end;
     SkipWhite;
end;

procedure Init;
begin
     GetChar;
end;

procedure Expression;
begin
     EmitLn('Move #' + GetNum + ',D0')
end;

{--------Main program-------}
begin
     Init;
     Expression
end.