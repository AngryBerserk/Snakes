unit Main;

interface

uses
  System.UIConsts, System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Generics.Collections,
  GameObject, SnakeUnit, FMX.Colors, FMX.Gestures, FMX.Controls.Presentation,
  FMX.StdCtrls;

const
  kUp=['w','W'];
  kDown=['s','S'];
  kLeft=['a','A'];
  kRight=['d','D'];
  kRest=[' '];

  maxX=50;
  maxY=50;
  EnemySnakes=3;
  Speed=150;
  PlayerEnabled=true;

type
  TMainForm = class(TForm)
    Timer: TTimer;
    GestureManager1: TGestureManager;
    procedure TimerTimer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormGesture(Sender: TObject; const EventInfo: TGestureEventInfo;
      var Handled: Boolean);
    procedure Button1Gesture(Sender: TObject;
      const EventInfo: TGestureEventInfo; var Handled: Boolean);
  private
    Dir:TPoint;
    TurnPassed:Boolean;
    KeyPressed:Word;
    procedure Redraw;
    procedure CalculateCollisions;
    procedure FillWave;
    procedure MoveSnakes;
    procedure GetWinner;
    { Private declarations }
  public
    Snake:TSnake;
    WeveGotAwinner:Boolean;
    Apple:TApple;
    Objects:TObjectList<TGameObject>;
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  Painter;

{$R *.fmx}

procedure TMainForm.FormCreate(Sender: TObject);
  var z:byte;
begin
  RandSeed:=2;
  Dir:=Point(1,0);
  //Randomize;
  Objects:=TObjectList<TGameObject>.Create;
  Objects.OwnsObjects:=false;
  if PlayerEnabled then
    Begin
      Snake:=TSnake.Create;
      Snake.Body[0]:=Point(maxX div 2,maxY div 2);
      Objects.add(Snake);
    End;
  for z := 1 to EnemySnakes do
    Begin
      Objects.Add(TSnakeAI.Create);
      (Objects.Last as TSnakeAI).Body[0]:=Point(Random(maxX)+1,Random(maxY)+1);
    End;
  Apple:=TApple.Create;
  Apple.P.X:=Random(maxX)+1;
  Apple.P.Y:=Random(maxY)+1;
  Objects.Add(Apple);
  TPainter.Init(MainForm,maxX,maxY);
  keyPressed:=vkRight;
  Timer.Interval:=Speed;
end;

procedure TMainForm.FormGesture(Sender: TObject;
  const EventInfo: TGestureEventInfo; var Handled: Boolean);
  var Key:Word;
      KeyChar:Char;
      S:String;
begin
  if EventInfo.GestureID=igiDoubleTap then Timer.Enabled:=not Timer.Enabled;
  if EventInfo.GestureID=sgiLeft then Key:=vkLeft;
  if EventInfo.GestureID=sgiRight then Key:=vkRight;
  if EventInfo.GestureID=sgiUp then Key:=vkUp;
  if EventInfo.GestureID=sgiDown then Key:=vkDown;
  FormKeyDown(MainForm,Key,KeyChar,[]);
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
    var dx,dy:ShortInt;
begin
  if Key=vkEscape then
        Timer.Enabled:=not Timer.Enabled;
  if TurnPassed then
    Begin
      if (Key=vkUp)or(CharInSet(keyChar,kUp)) then
        Begin
          if KeyPressed<>vkDown then
          KeyPressed:=vkUp
        End;
      if (Key=vkDown)or(CharInSet(keyChar,kDown)) then
        Begin
          if KeyPressed<>vkUp then
          KeyPressed:=vkDown
        End;
      if (Key=vkLeft)or(CharInSet(keyChar,kLeft)) then
        Begin
          if KeyPressed<>vkRight then
          KeyPressed:=vkLeft
        End;
      if (Key=vkRight)or(CharInSet(keyChar,kRight)) then
        Begin
          if KeyPressed<>vkLeft then
          KeyPressed:=vkRight
        End;
      dx:=0;
      dy:=0;
      case keyPressed of
        vkLeft:   dx:=-1;
        vkRight:  dx:=1;
        vkUp:     dy:=-1;
        vkDown:   dy:=1;
      end;
      Dir:=Point(dx,dy);
      TurnPassed:=false;
    End;
end;

procedure TMainForm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
  var dx,dy:Single;
      SnakeHeadX,SnakeHeadY:Single;
      LftRt,UpDn:Single;
begin
  {$IFNDEF ANDROID}
  if PlayerEnabled then
    Begin
      dx:=ClientWidth/maxX;
      dy:=ClientHeight/maxY;
      SnakeHeadX:=Snake.Body.Last.X*dx;
      SnakeHeadY:=Snake.Body.Last.Y*dy;
      LftRt:=ABS(x-SnakeHeadX);
      UpDn:=ABS(y-SnakeHeadY);
      if LftRt>UpDn then
        Begin
          if x>SnakeHeadX then
            Begin
              if Dir<>Point(-1,0) then
                Dir:=Point(1,0)
            End
              else
                Begin
                  if Dir<>Point(1,0) then
                    Dir:=Point(-1,0)
                End;
        End
          else
            Begin
              if y>SnakeHeadY then
                Begin
                  if Dir<>Point(0,-1) then
                    Dir:=Point(0,1)
                End
                  else
                    Begin
                      if Dir<>Point(0,1) then
                        Dir:=Point(0,-1)
                    End;
            End
    End;
  {$ENDIF}
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  TPainter.ReInit;
end;

procedure TMainForm.Button1Gesture(Sender: TObject;
  const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  if EventInfo.GestureID=igiLongTap then Timer.Enabled:=not Timer.Enabled;
end;

procedure TMainForm.CalculateCollisions;
  var
    O,O2:TGameObject;
begin
  for O in Objects do
    for O2 in Objects do
      if (O is TSnake)and(not(O as TSnake).collided) then
          if O is TSnakeAI then (O as TSnake).AppleCollision
            else
              (O as TSnake).Collision(O2);
  if (PlayerEnabled)and(not Snake.Disabled) and (Snake.Collided) then
    Begin
      Snake.Disabled:=true;
      Timer.interval:=10;
      //ShowMessage('GameOver!');
    //  Halt;
    End;
end;

procedure TMainForm.FillWave;
  var S:TGameObject;
begin
  TSnakeAI.FillWave;
  for S in Objects do
    if S is TSnakeAI then
      (S as TSnakeAI).FillWave_
end;

procedure TMainForm.MoveSnakes;
  var S,O:TGameObject;
      AllFinished:Boolean;
begin
  for S in Objects do
    if (S is TSnake){and(not (S as TSnake).Collided)} then
      Begin
        if not ((S as TSnake).Collided) then
          Begin
            FillWave;
            (S as TSnake).Move(Dir);
          End;
        //CalculateCollisions;
      End;
  AllFinished:=true;
  repeat
    for S in Objects do
      if S is TSnakeAI then
        if not (S as TSnakeAI).WaveThread.Finished then AllFinished:=false
  until AllFinished;
end;

procedure TMainForm.TimerTimer(Sender: TObject);
begin
  MoveSnakes;
  Redraw;
  GetWinner;
  TurnPassed:=true;
  //if not Apple.AppleIsReal then
    //Apple.Spawn;
end;

procedure TMainForm.Redraw;
  var O:TGameObject;
Begin
  TPainter.StartPaint;
  for O in Objects do
    O.Paint;
  TPainter.Surface.Bitmap.Canvas.EndScene;
End;

procedure TMainForm.GetWinner;
  var S:String;O:TGameObject;
begin
  if Not WeveGotAwinner then
    Begin
      if ((PlayerEnabled)and(Not Snake.Disabled))and(TSnakeAI.Num=0) then
        Begin
          WeveGotAwinner:=true;
          S:='Красный';
        End
          Else
            if (
                ((PlayerEnabled)and(Snake.Disabled))
                or(not PlayerEnabled)
                )
                and (TSnakeAI.Num=1) then
              Begin
                WeveGotAwinner:=true;
                for O in Objects do
                  if O is TSnakeAI then
                    if not (O as TSnakeAI).Collided then
                      break;
                S:=SnakeColorStrings[(O as TSnakeAI).Ind]
              End;
      if WeveGotAwinner then
        Begin
          //Timer.Enabled:=false;
          ShowMessage('У нас есть победитель. Это '+S);
          {$IFNDEF ANDROID}
          //Halt;
          {$ENDIF}
        End;
    End;
end;

end.
