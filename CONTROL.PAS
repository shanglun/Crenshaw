program Cradle;
const
TAB = ^I;
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

procedure Condition;
begin
	EmitLn('<condition>');
end;

procedure Expression;
begin
     EmitLn('<expr>');
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
	Condition;
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
     Condition;
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
     Condition;
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

procedure Block(L: string);
begin
     while not (Look in ['e']) do begin
        case Look of
	   'i': DoIf(L);
           'w': DoWhile;
           'p': DoLoop;
           'r': DoRepeat;
           'f': DoFor;
		   'd': DoDo;
		   'b': DoBreak(L);
	else
           Other;
        end;
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