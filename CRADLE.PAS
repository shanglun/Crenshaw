program Cradle;
const
TAB = ^I;
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

function GetName: char;{Get an identifier}
begin
     if not IsAlpha(Look) then Expected('Name');
     GetName:=UpCase(Look);
     GetChar;
end;

function GetNum: char;
begin
     if not IsDigit(Look) then expected('Integer');
     GetNum := Look;
     GetChar;
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