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

function IsAddop(c: char): boolean;
begin
     IsAddop := c in ['+', '-'];
end;

procedure Expression; Forward;

procedure Factor;
begin
     if Look = '(' then begin
        Match('(');
        Expression;
        Match(')');
        end
     else
         EmitLn('MOVE #' + GetNum + ',D0');
end;



procedure Multiply;
begin
     Match('*');
     Factor;
     EmitLn('MULS (SP)+, D1');
end;

procedure Divide;
begin
     Match('/');
     Factor;
     EmitLn('MOVE (SP)+, D1');
     EmitLn('DIVS D1,D0');
end;

procedure Term;
begin
     Factor;
     while Look in ['*', '/'] do begin
          EmitLn('Move D0, -(SP)');
          case Look of
               '*' : Multiply;
               '/' : Divide;
          else
               Expected('Mulop');
          end;
     end;
end;

procedure Add;
begin
     Match('+');
     Term;
     emitLn('Add (SP)+, D0');
end;

procedure Subtract;
begin
     Match('-');
     Term;
     EmitLn('SUB (SP)+, D0');
     EmitLn('NEG D0');
end;

procedure Expression;
begin
     if IsAddop(Look) then
        EmitLn('CLR D0')
     else
         Term;
     while IsAddop(Look) do begin
          EmitLn('Move D0, -(SP)');
          case Look of
               '+' : Add;
               '-' : Subtract;
          else
               Expected('Addop');
          end;
     end;
end;

{--------Main program-------}
begin
     Init;
     Expression
end.