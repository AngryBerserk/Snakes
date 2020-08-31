unit GameObject;

interface

uses
  Types, system.UITypes;

type
  TGameObject=class
    procedure Paint;virtual;abstract;
  end;
  TApple=class(TGameObject)
    P:TPoint;
    Hidden:Boolean;
    RespawnCounter:Word;
    procedure Spawn;
    procedure Paint;override;
    function AppleIsReal:Boolean;
  end;

implementation

uses
  Painter,Main,SnakeUnit;

procedure TApple.Paint;
begin
  if RespawnCounter>maxX+maxY then
    Begin
      Spawn;
      RespawnCounter:=0;
    End;
  TPainter.Paint(P.x,P.y,TAlphaColorRec.Create(TAlphaColorRec.Lime));
  inc(RespawnCounter);
end;

procedure TApple.Spawn;
begin
  if not MainForm.WeveGotAwinner then
    Begin
      P.X:=Random(maxX)+1;
      P.Y:=Random(maxY)+1;
      RespawnCounter:=0;
    End
      else
        Begin
          MainForm.Objects.Remove(MainForm.Apple);
          Hidden:=true
        End;
end;

function TApple.AppleIsReal:Boolean;
  var
    O:TGameObject;
begin
  result:=false;
  for O in MainForm.Objects do
    if O is TSnakeAI then
      if (not(O as TSnakeAI).Collided)and((O as TSnakeAI).AppleIsReal) then
        Result:=true;
end;

end.
