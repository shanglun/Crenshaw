program Cradle;
const
TAB = ^I;
CR = ^M;
LF = ^J;
var
Look: char; {global lookahead char}
Lcount: integer;

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




{Expression stuff goes here.}

function IsAddop(c: char): boolean;
begin
     IsAddop := c in ['+', '-'];
end;

function IsMulop(c:char): boolean;
begin
	IsMulop := c in ['*','/'];
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


function NewLabel: string;
var S: string;
begin
     Str(LCount, S);
     NewLabel:= 'L' + S;
     Inc(LCount);
end;

procedure PostLabel(L:string);
begin
     WriteLn(L, ':');
end;

procedure DoBreak(L:string);
begin
	Match('b');
	if L <> '' then
		EmitLn('BRA ' + L)
	else
		Abort('No loop to break from');
end;

procedure Block(L:string); Forward;

procedure DoIf(L: string);
var L1, L2: string;
begin
	Match('i');
	BoolExpression;
	L1:=NewLabel;
	L2:=L1;
	EmitLn('BEG ' + L1);
	Block(L);
	if Look = 'l' then begin
		Match('l');
		L2 := NewLabel;
		EmitLn('BRA ' + L2);
		PostLabel(L1);
		Block(L);
	end;
	Match('e');
	PostLabel(L2);
end;

procedure DoWhile;
var L1, L2: string;
begin
     Match('w');
     L1:=NewLabel;
     L2:=NewLabel;
     PostLabel(L1);
     BoolExpression;
     EmitLn('BEQ ' + L2);
     Block(L2);
     Match('e');
     EmitLn('BRA '+L1);
     PostLabel(L2);
end;

procedure DoLoop;
var 
L1:string;
L2:string;
begin
     Match('p');
     L1:=NewLabel;
	 L2:=NewLabel;
     PostLabel(L1);
     Block(L2);
     Match('e');
     EmitLn('BRA ' + L1);
	 PostLabel(L2);
end;

procedure DoRepeat;
var L1, L2:string;
begin
     Match('r');
     L1:=NewLabel;
	 L2:=NewLabel;
     PostLabel(L1);
     Block(L2);
     Match('u');
     BoolExpression;
     Emit('BEQ ' + L1);
	 PostLabel(L2);
end;

procedure DoFor;
var
L1, L2: string;
Name: char;
begin
     Match('f');
     L1:=NewLabel;
     L2:=NewLabel;
     Name := GetName;
     Match('=');
     Expression;
     EmitLn('SUBQ #1, D0');
     EmitLn('LEA ' + Name + '(PC) A0');
     EmitLn('MOVE (A0), D0');
     Expression;
     EmitLn('MOVE D0, -(SP)');
     PostLabel(L1);
     EmitLn('LEA ' + Name + '(PC) A0');
     EmitLn('MOVE D0, (A0)');
     EmitLn('ADDQ #1, D0');
     EmitLn('MOVE D0, (A0)');
     EmitLn('CMP (SP), D0');
     EmitLn('BGT ' + L2);
     Block(L2);
     Match('e');
     EmitLn('BRA '+L1);
     PostLabel(L2);
     EmitLn('ADDQ #2, SP');
end;

procedure DoDo;
var
L1,L2:string;
begin
     Match('d');
     L1:=NewLabel;
	 L2:=NewLabel;
     Expression;
     EmitLn('SUBQ #1, D0');
     PostLabel(L1);
     EmitLn('MOVE D0, -(SP)');
     Block(L2);
     EmitLn('MOVE (SP)+,D0');
     EmitLn('DBRA D0,' + L1);
	 PostLabel(L2);
	 EmitLn('ADDQ #2, SP');
end;

procedure Other;
begin
     EmitLn(GetName);
end;

procedure Fin;
begin
	if Look = CR then GetChar;
	if Look = LF then GetChar;
end;

procedure Assignment;
var Name: char;
begin
     Name := GetName;
     Match('=');
     BoolExpression;
     EmitLn('LEA ' + Name + '(PC), A0');
     EmitLn('MOVE D0, (A0)')
end;

procedure Block(L: string);
begin
     while not (Look in ['e','l','u']) do begin
		Fin;
        case Look of
	   'i': DoIf(L);
       'w': DoWhile;
       'p': DoLoop;
       'r': DoRepeat;
       'f': DoFor;
	   'd': DoDo;
	   'b': DoBreak(L);
		else Assignment;
        end;
		Fin;
     end;
end;

procedure DoProgram;
begin
     Block('');
     if Look <> 'e' then Expected('End');
     EmitLn('END');
end;

procedure Init;
begin
     LCount:=0;
     GetChar;
end;

{--------Main program-------}
begin
     Init;
     DoProgram;
end.