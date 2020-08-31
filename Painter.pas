unit Painter;

interface

uses
  sysutils, FMX.objects, FMX.Types, FMX.Graphics, System.Types, FMX.Forms, System.UITypes;

const
  spriteWidth=5;
  spriteHeight=5;

type
  TBodyKind=(kHead,kTail,kBody,kPreTail);
  TPainter=class
    public
      class var dx,
      dy:Single;
      class var screenPoint:Single;
      class var Surface:TImage;
      class constructor create;
      class destructor destroy;
      class procedure Init(Owner:TFMXObject;const w,h:Word);
      class procedure ReInit;
      class procedure StartPaint;
      //snake
      class procedure Paint(const kind:TBodyKind; const x,y:Single;const C:TAlphaColorRec);overload;
      //apple
      class procedure Paint(const x,y:Single;const C:TAlphaColorRec);overload;
  end;

implementation

uses
  main;

class constructor TPainter.create;
Begin
  inherited;
End;

class procedure TPainter.ReInit;
Begin
  dx:=(Surface.Parent as TForm).ClientWidth/maxX;
  dy:=(Surface.Parent as TForm).ClientHeight/maxY;
  Surface.width:=(Surface.Parent as TForm).ClientWidth;
  Surface.Height:=(Surface.Parent as TForm).ClientHeight;
  Surface.Bitmap.Width:=(Surface.Parent as TForm).ClientWidth;
  Surface.Bitmap.Height:=(Surface.Parent as TForm).ClientHeight;
End;

class procedure TPainter.Init(Owner: TFmxObject; const w: Word; const h: Word);
begin
  //ScreenPoint:=1;
  Surface:=TImage.Create(nil);
  Surface.Parent:=Owner;
  Surface.BringToFront;
  Surface.Position.X:=0;
  Surface.Position.Y:=0;
  Surface.WrapMode:=TImageWrapMode.Stretch;
  Surface.Bitmap:=TBitmap.Create;
  Surface.HitTest:=false;
  ReInit;
end;

class procedure TPainter.Paint(const kind:TBodyKind; const x: Single; const y: Single; const C:TAlphaColorRec);
  var tor2:TRectF;
      coef:Single;

  function getRect:Single;
  Begin
    case kind of
      kHead: result:=0;
      kTail: result:=0.65;
      kPreTail: result:=0.75;
      kBody: result:=0.85;
    end;
  End;

begin
  Surface.Bitmap.Canvas.Stroke.Color:=TAlphaColor(C);
  Surface.Bitmap.Canvas.Fill.Color:=TAlphaColor(C);
  Surface.Bitmap.Canvas.Fill.Kind:=TBrushKind.Solid;
  Surface.Bitmap.Canvas.Stroke.Thickness:=1;
  coef:=getRect;
  tor2:=TRectF.create(
                      (x-1)*dx+dx*coef,
                      (y-1)*dy+dy*coef,
                      (x-1)*dx+dx-dx*coef,
                      (y-1)*dy+dy-dy*coef
                      );
  Surface.Bitmap.Canvas.FillRect(tor2,0,0,[TCorner.TopLeft, TCorner.TopRight, TCorner.BottomLeft, TCorner.BottomRight],1);
end;

//apple
class procedure TPainter.Paint(const x: Single; const y: Single; const C:TAlphaColorRec);
  var tor2:TRectF;
      coef:Single;

begin
  Surface.Bitmap.Canvas.Stroke.Color:=TAlphaColor(C);
  Surface.Bitmap.Canvas.Fill.Color:=TAlphaColor(C);
  Surface.Bitmap.Canvas.Fill.Kind:=TBrushKind.Solid;
  Surface.Bitmap.Canvas.Stroke.Thickness:=1;
  coef:=0.9;
  tor2:=TRectF.create(
                      (x-1)*dx+dx*coef,
                      (y-1)*dy+dy*coef,
                      (x-1)*dx+dx-dx*coef,
                      (y-1)*dy+dy-dy*coef
                      );
  Surface.Bitmap.Canvas.FillEllipse(tor2,1);
  //Surface.Bitmap.Canvas.FillRect(tor2,0,0,[TCorner.TopLeft, TCorner.TopRight, TCorner.BottomLeft, TCorner.BottomRight],1);
end;

class procedure TPainter.StartPaint;
  var tor2:TRectF;
begin
  TPainter.Surface.Bitmap.Canvas.BeginScene;
  Surface.Bitmap.Canvas.Stroke.Color:=TAlphaColorRec.Black;
  Surface.Bitmap.Canvas.Fill.Color:=TAlphaColorRec.Black;
  Surface.Bitmap.Canvas.Fill.Kind:=TBrushKind.Solid;
  Surface.Bitmap.Canvas.Stroke.Thickness:=0;
  tor2:=TRectF.create(0,0,Surface.Width,Surface.Height);
  Surface.Bitmap.Canvas.FillRect(tor2,0,0,[TCorner.TopLeft, TCorner.TopRight, TCorner.BottomLeft, TCorner.BottomRight],1);
end;

class destructor TPainter.destroy;
begin
  //Surface.Parent:=nil;
  //Surface.Bitmap.Destroy;
  inherited
end;

end.
