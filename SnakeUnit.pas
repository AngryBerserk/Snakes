unit SnakeUnit;

interface

uses
  Types, System.classes, System.Generics.Collections, GameObject, System.UITypes,
  Painter, System.SyncObjs;

const
  Dirs:Array [1..4] of TPoint =((X:1;Y:0),(X:-1;Y:0),(X:0;Y:1),(X:0;Y:-1));
  MaxSnakes=10;
  SnakeColors:Array[1..MaxSnakes] of TAlphaColor = (
    TAlphaColorRec.Blue,
    TAlphaColorRec.Green,
    TAlphaColorRec.White,
    TAlphaColorRec.Brown,
    TAlphaColorRec.Fuchsia,
    TAlphaColorRec.Aqua,
    TAlphaColorRec.Orange,
    TAlphaColorRec.Purple,
    TAlphaColorRec.Olivedrab,
    TAlphaColorRec.Gold
    );
  SnakeColorStrings:Array[1..MaxSnakes] of String = (
    'Синий',
    'Зелёный',
    'Белый',
    'Коричневый',
    'Розовый',
    'Голубой',
    'Оранжевый',
    'Сиреневый',
    'Оливковый',
    'Золотой');

type
  PSnakeAI=^TSnakeAI;
  TWaveThread = class (TThread)
    protected
      Snake:PSnakeAI;
      procedure Execute;override;
  end;
  TMapRow=TList<Integer>;
  TSnake=class(TGameObject)
      Body:TList<TPoint>;
    public
      length:Word;
      Disabled:Boolean;
      Color:TAlphaColorRec;
      Collided:Boolean;
      constructor Create;virtual;
      procedure Paint;override;
      function getBodyType(P:TPoint):TBodyKind;
      procedure Collision(O:TGameObject);
      procedure Move(pt:TPoint);virtual;
      procedure AppleCollision;
      procedure Collide;virtual;
  end;
  TSnakeAI=class(TSnake)
    private
      WaveBuffer:TList<TPoint>;
      TurnBuffer:TList<Word>;
      Map:TList<TMapRow>;
      function RunWave(StartPoint:TPoint):TPoint;
      procedure DumpWaveMap;
    public
      ind:Byte;
      AppleIsReal:Boolean;
      WaveThread:TWaveThread;
      class var Num:Byte;
      class var waveMap:TList<TMapRow>;
      class constructor Create;
      class procedure FillWave;
      constructor Create;override;
      procedure FillWave_;
      procedure Move(pt:TPoint);override;
      procedure DumpMapToFile(const FileName:String);
      function GetMove:Boolean;
      procedure Collide;override;
  end;

implementation

uses
  Main;

constructor TSnake.Create;
begin
  Body:=TList<TPoint>.Create;
  Body.Add(Point(10,10));
  Length:=5;
  Color:=TAlphaColorRec.Create(TAlphaColorRec.Red);
end;

procedure TSnake.AppleCollision;
  var P:TPoint;
begin
  if not MainForm.Apple.Hidden then
    Begin
      for P in Body do
        if P=MainForm.Apple.P then
          Begin
            MainForm.Apple.Spawn;
            length:=length+1;
          End;
    End;
end;

procedure TSnake.Move(pt: TPoint);
  var pp:TPoint;
begin
  Pp:=Body.Last;
  Body.Add(Point(Pp.X+pt.x,Pp.Y+pt.y));
  //delete extra parts
  if length=0 then
    Body.Remove(Body.First)
      else
        length:=length-1;
end;

function TSnake.getBodyType(P:TPoint):TBodyKind;
  var I:Word;
Begin
  I:=Body.IndexOf(P);
  if I=0 then
    Result:=kTail
      else
        if (I=1)and(Body.Count>3) then
          Result:=kpreTail
            else
              if I=Body.Count-1 then
                Result:=kHead
                  else
                    Result:=kBody
End;

procedure TSnake.Paint;
  var P:TPoint;
Begin
  for P in Body do
    Tpainter.Paint(getBodyType(P),P.X,P.Y,Color);
End;

procedure TSnake.Collision(O:TGameObject);
  var z,max:Word;
begin
  if O is TApple then
    AppleCollision
      else
        Begin
          if O=Self then
            Begin
              max:=Body.Count-2;
              if (Body.Last.X>MaxX)or(Body.Last.X<1)or(Body.Last.Y>MaxY)or(Body.Last.Y<1) then Collide
            End
              else
                max:=(O as TSnake).Body.Count-1;
          for z:=0 to max do
            if (O as TSnake).Body[z]=Body.Last then
              Collide
        End;
end;

procedure TSnake.Collide;
begin
  Collided:=true;
  Color:=TAlphaColorRec.Create(TAlphaColorRec.Gray);
end;

//TSnakeAI

procedure TSnakeAI.Collide;
begin
  Inherited;
  Num:=Num-1;
end;

constructor TSnakeAI.Create;
  var x,y:Word;
begin
  inherited;
  Num:=Num+1;
  Ind:=Num;
  AppleIsReal:=true;
  Color:=TAlphaColorRec.Create(SnakeColors[Ind]);
  WaveBuffer:=TList<TPoint>.Create;
  TurnBuffer:=TList<Word>.Create;
  Map:=TList<TMapRow>.Create;
  for x := 0 to MaxX+1 do
    Begin
      Map.add(TMapRow.Create);
      for y := 0 to MaxY+1 do
        Map.Last.Add(0)
    End;
end;

class constructor TSnakeAI.Create;
  var x,y:Word;
Begin
  WaveMap:=TList<TMapRow>.Create;
  for x := 0 to MaxX+1 do
    Begin
      WaveMap.add(TMapRow.Create);
      for y := 0 to MaxY+1 do
        WaveMap.Last.Add(0)
    End;
End;

class procedure TSnakeAI.FillWave;
  var
      P:TPoint;
      x,y:Word;
begin
  //initial fill
  for x := 0 to maxX+1 do
    for y := 0 to maxY+1 do
      WaveMap[x][y]:=0;
  for x := 0 to maxX+1 do
    WaveMap[x][0]:=-1;
  for x := 0 to maxX+1 do
    WaveMap[x][maxY+1]:=-1;
  for y := 0 to maxY+1 do
    WaveMap[0][y]:=-1;
  for y := 0 to maxY+1 do
    WaveMap[maxX+1][y]:=-1;
  if PlayerEnabled then
    for P in MainForm.Snake.Body do
      WaveMap[P.X][P.Y]:=-1;
end;

procedure TSnakeAI.FillWave_;
  var P:TPoint;
begin
  for P in Body do
    WaveMap[P.X][P.Y]:=-1;
end;

Function TSnakeAI.RunWave(StartPoint:TPoint):TPoint;
  var P:TPoint;
Begin
  WaveBuffer.Clear;
  WaveBuffer.Add(StartPoint);
  TurnBuffer.Clear;
  TurnBuffer.Add(1);
  repeat
    P:=WaveBuffer.First;
    Map[P.X][P.Y]:=TurnBuffer.First;
    WaveBuffer.Remove(WaveBuffer.First);
    if Map[P.X+1][P.y]=0 then Begin WaveBuffer.Add(Point(P.X+1,P.y)); TurnBuffer.Add(TurnBuffer.First+1);Map[P.X+1][P.y]:=TurnBuffer.First+1 end;
    if Map[P.X-1][P.y]=0 then Begin WaveBuffer.Add(Point(P.X-1,P.y)); TurnBuffer.Add(TurnBuffer.First+1);Map[P.X-1][P.y]:=TurnBuffer.First+1 end;
    if Map[P.X][P.y+1]=0 then Begin WaveBuffer.Add(Point(P.X,P.y+1)); TurnBuffer.Add(TurnBuffer.First+1);Map[P.X][P.y+1]:=TurnBuffer.First+1 end;
    if Map[P.X][P.y-1]=0 then Begin WaveBuffer.Add(Point(P.X,P.y-1)); TurnBuffer.Add(TurnBuffer.First+1);Map[P.X][P.y-1]:=TurnBuffer.First+1 end;
    TurnBuffer.Remove(TurnBuffer.First);
    WaveBuffer.TrimExcess;
  until TurnBuffer.Count=0;
  Result:=P;
End;

procedure TSnakeAI.DumpMapToFile(const FileName:String);
  var x,y:Word;
  F:TextFile;
begin
  AssignFile(F,'C:\'+Filename);
  Rewrite(F);
  for x := 0 to maxX+1 do
    Begin
      for y := 0 to maxY+1 do
        if (x=Body.Last.x) and (y=Body.Last.y) then Write(F,Map[x][y],'&') else
          if (x=MainForm.Apple.P.x) and (y=MainForm.Apple.P.y) then Write(F, ' A') else
          if (Map[x][y]=-1) then Write(F,' #') else
            if (Map[x][y]<10) then Write(F,' ',Map[x][y])
             else Write(F,Map[x][y]);
      Writeln(F,'');
    End;
  CloseFile(F);
end;

function TSnakeAI.GetMove:Boolean;
  var O:TPoint;
begin
  result:=true;
  for O in Dirs do
    if Map[Body.Last.x+O.x][Body.Last.y+O.y]>-1 then
      if Map[Body.Last.x+O.x][Body.Last.y+O.y]=Map[Body.Last.x][Body.Last.y]-1 then
        Begin
          inherited move(O);
          exit
        End;
  //unable to move
  result:=false
end;

procedure TSnakeAI.DumpWaveMap;
 var x,y:Word;
begin
  //copy wavemap to local map
  for x := 0 to maxX+1 do
    for y := 0 to maxY+1 do
      Map[x][y]:=WaveMap[x][y];
end;

procedure TSnakeAI.Move(pt:TPoint);
Begin
  WaveThread:=TWaveThread.Create(false);
  WaveThread.Snake:=@Self;
end;

procedure TWaveThread.Execute;
  var P:TPoint;
      CriticalSection:TCriticalSection;
begin
  CriticalSection:=TCriticalSection.Create;
  CriticalSection.Enter;
  Snake.DumpWaveMap;
  CriticalSection.Leave;
  Snake.Map[Snake.Body.Last.x][Snake.Body.Last.Y]:=0;
  if not MainForm.Apple.Hidden then
    Snake.runWave(MainForm.Apple.P);
  {$IFDEF DEBUG}
    //DumpMapToFile('Map.txt');
  {$ENDIF}
  if not Snake.GetMove then
    Begin
      //Do the wave from head
      Snake.AppleIsReal:=false;
      Snake.DumpWaveMap;
      P:=Snake.runWave(Snake.Body.Last);
      {$IFDEF DEBUG}
      //DumpMapToFile('1stPass.txt');
      {$ENDIF}
      Snake.DumpWaveMap;
      Snake.Map[Snake.Body.Last.x][Snake.Body.Last.Y]:=0;
      Snake.runWave(P);
      {$IFDEF DEBUG}
      //DumpMapToFile('2ndPass.txt');
      {$ENDIF}
      if not Snake.getMove then Snake.collide
    End
      else
        Snake.AppleIsReal:=true;
end;

end.
