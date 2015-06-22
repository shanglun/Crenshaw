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

function IsAlNum(c: char): boolean;
begin
     IsAlNum := IsAlpha(c) or IsDigit(c);
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


function IsBoolean(c: char): Boolean;
begin
	Isboolean := UpCase(c) in ['T','F'];
end;

function GetBoolean: boolean;
var
c: char;
begin
	if not IsBoolean(Look) then Expected('Boolean Literal');
	GetBoolean := UpCase(Look) = 'T';
	GetChar;
end;

{Expression stuff goes here.}

function IsAddop(c: char): boolean;
begin
     IsAddop := c in ['+', '-'];
end;

procedure Ident;
var Name: char;
begin
     Name := GetName;
     if Look = '(' then begin
        Match('(');
        Match(')');
        EmitLn('BSR ' + Name);
        end
     else
         EmitLn('Move ' + Name  + '(PC),D0')
end;

procedure Expression; Forward;

procedure Factor;
begin
     if Look = '(' then begin
        Match('(');
        Expression;
        Match(')');
     end
     else if IsAlpha(Look) then
          EmitLn('Move ' + GetName + '(PC),D0')
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
{Assignments}


{relops and boolean operators.}

procedure Equals;
begin
     Match('=');
     Expression;
     EmitLn('CMP (SP)+,D0');
     EmitLn('SEQ D0');
end;

procedure NotEquals;
begin
     Match('#');
     Expression;
     EmitLn('CMP (SP)+,D0');
     EmitLn('SNE D0');
end;

procedure Less;
begin
     Match('<');
     Expression;
     EmitLn('CMP (SP)+, D0');
     EmitLn('SGE D0');
end;

procedure Greater;
begin
     Match('>');
     Expression;
     EmitLn('CMP (SP)+,D0');
     EmitLn('SLE D0');
end;

function IsRelop(c:char):Boolean;
begin
     IsRelop:=c in ['=','#','<','>'];
end;

procedure Relation;
begin
     Expression;
     if IsRelop(Look) then begin
        EmitLn('MOVE D0, -(SP)');
        case Look of
        '=': Equals;
        '#': NotEquals;
        '<': Less;
        '>': Greater;
        end;
     EmitLn('TST D0');
     end;
end;

procedure BoolFactor;
begin
	if IsBoolean(Look) then
	   if GetBoolean then EmitLn('Move #-1,D0')
	   else EmitLn('CLR D0')
        else
            Relation;

end;

procedure NotFactor;
begin
     if Look = '!' then begin
        Match('!');
        BoolFactor;
        EmitLn('EOR #-1,D0');
        end
     else
         BoolFactor;
end;

procedure BoolTerm;
begin
     NotFactor;
     while Look = '&' do begin
           EmitLn('Move D0,-(SP)');
           Match('&');
           NotFactor;
           EmitLn('AND (SP)+, D0');
     end;
end;

procedure BoolOr;
begin
	Match('|');
	BoolTerm;
	EmitLn('OR (SP)+,D0');
end;

procedure BoolXOr;
begin
	Match('~');
	BoolTerm;
	EmitLn('EOR (SP)+,D0');
end;

function IsOrOp(c: char): Boolean;
begin
     IsOrop := c in ['|','~'];
end;

procedure BoolExpression;
begin
     BoolTerm;
     while IsOrOp(Look) do begin
           EmitLn('Move D0, -(SP)');
           case Look of
                '|': BoolOr;
                '~': BoolXOr;
           end;
     end;
end;



{--------Main program-------}
begin
     Init;
     BoolExpression;
end.