unit UToolSelect;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, BGRABitmapTypes, BGRABitmap,
  UTool, UToolBasic, UToolVectorial, UToolPolygon,
  ULayerAction, LCVectorOriginal;

type
  { TVectorialSelectTool }

  TVectorialSelectTool = class(TVectorialTool)
  protected
    function GetIsSelectingTool: boolean; override;
    procedure AssignShapeStyle({%H-}AMatrix: TAffineMatrix); override;
    function RoundCoordinate(ptF: TPointF): TPointF; override;
    function UpdateShape(toolDest: TBGRABitmap): TRect; override;
    procedure QuickDefineEnd; override;
    function BigImage: boolean;
  public
    function GetContextualToolbars: TContextualToolbars; override;
  end;

  { TToolSelectRect }

  TToolSelectRect = class(TVectorialSelectTool)
  protected
    function CreateShape: TVectorShape; override;
  public
    function Render(VirtualScreen: TBGRABitmap; {%H-}VirtualScreenWidth, {%H-}VirtualScreenHeight: integer; BitmapToVirtualScreen: TBitmapToVirtualScreenFunction):TRect; override;
    function GetContextualToolbars: TContextualToolbars; override;
  end;

  { TToolSelectEllipse }

  TToolSelectEllipse = class(TVectorialSelectTool)
  protected
    function CreateShape: TVectorShape; override;
  public
    function Render(VirtualScreen: TBGRABitmap; {%H-}VirtualScreenWidth, {%H-}VirtualScreenHeight: integer; BitmapToVirtualScreen: TBitmapToVirtualScreenFunction):TRect; override;
    function GetContextualToolbars: TContextualToolbars; override;
  end;

  { TToolSelectPoly }

  TToolSelectPoly = class(TToolPolygon)
  protected
    procedure AssignShapeStyle(AMatrix: TAffineMatrix); override;
    function GetIsSelectingTool: boolean; override;
  public
    function GetContextualToolbars: TContextualToolbars; override;
  end;

  { TToolSelectSpline }

  TToolSelectSpline = class(TToolSpline)
  protected
    procedure AssignShapeStyle(AMatrix: TAffineMatrix); override;
    function GetIsSelectingTool: boolean; override;
  public
    function GetContextualToolbars: TContextualToolbars; override;
  end;

  { TToolMagicWand }

  TToolMagicWand = class(TGenericTool)
  protected
    function GetIsSelectingTool: boolean; override;
    function DoToolDown(toolDest: TBGRABitmap; pt: TPoint; {%H-}ptF: TPointF;
      rightBtn: boolean): TRect; override;
  public
    function GetContextualToolbars: TContextualToolbars; override;
  end;

  { TToolSelectionPen }

  TToolSelectionPen = class(TToolPen)
  protected
    function GetIsSelectingTool: boolean; override;
    function StartDrawing(toolDest: TBGRABitmap; ptF: TPointF; rightBtn: boolean): TRect; override;
    function ContinueDrawing(toolDest: TBGRABitmap; originF, destF: TPointF): TRect; override;
  public
    function GetContextualToolbars: TContextualToolbars; override;
  end;

  { TTransformSelectionTool }

  TTransformSelectionTool = class(TGenericTool)
  protected
    function GetIsSelectingTool: boolean; override;
    function GetAction: TLayerAction; override;
    function FixSelectionTransform: boolean; override;
    function DoGetToolDrawingLayer: TBGRABitmap; override;
  end;

  { TToolMoveSelection }

  TToolMoveSelection = class(TTransformSelectionTool)
  protected
    handMoving, snapToPixel: boolean;
    handOriginF: TPointF;
    selectionTransformBefore: TAffineMatrix;
    function DoToolDown({%H-}toolDest: TBGRABitmap; {%H-}pt: TPoint; ptF: TPointF;
      {%H-}rightBtn: boolean): TRect; override;
    function DoToolMove({%H-}toolDest: TBGRABitmap; {%H-}pt: TPoint; ptF: TPointF): TRect; override;
  public
    constructor Create(AManager: TToolManager); override;
    function ToolUp: TRect; override;
    function ToolKeyDown(var key: Word): TRect; override;
    function ToolKeyUp(var key: Word): TRect; override;
    destructor Destroy; override;
  end;

  { TToolRotateSelection }

  TToolRotateSelection = class(TTransformSelectionTool)
  protected
    class var HintShowed: boolean;
    handMoving: boolean;
    handOrigin: TPointF;
    snapRotate: boolean;
    snapAngle: single;
    FOriginalTransform: TAffineMatrix;
    FCurrentAngle: single;
    FCurrentCenter: TPointF;
    function DoToolDown({%H-}toolDest: TBGRABitmap; {%H-}pt: TPoint; ptF: TPointF;
      rightBtn: boolean): TRect; override;
    function DoToolMove({%H-}toolDest: TBGRABitmap; {%H-}pt: TPoint; ptF: TPointF): TRect; override;
    function GetStatusText: string; override;
    procedure UpdateTransform;
  public
    constructor Create(AManager: TToolManager); override;
    function ToolKeyDown(var key: Word): TRect; override;
    function ToolKeyUp(var key: Word): TRect; override;
    function ToolUp: TRect; override;
    function Render(VirtualScreen: TBGRABitmap; {%H-}VirtualScreenWidth, {%H-}VirtualScreenHeight: integer; BitmapToVirtualScreen: TBitmapToVirtualScreenFunction):TRect; override;
    destructor Destroy; override;
  end;

implementation

uses types, ugraph, LCLType, LazPaintType, Math, BGRATransform, BGRAPath,
  BGRAPen, LCVectorRectShapes;

procedure AssignSelectShapeStyle(AShape: TVectorShape; ASwapColor: boolean);
var
  f: TVectorShapeFields;
begin
  f:= AShape.Fields;
  if vsfPenFill in f then AShape.PenFill.Clear;
  if vsfPenStyle in f Then AShape.PenStyle := ClearPenStyle;
  if vsfBackFill in f then
  begin
    if ASwapColor then
      AShape.BackFill.SetSolid(BGRABlack)
    else
      AShape.BackFill.SetSolid(BGRAWhite);
  end;
end;

{ TToolSelectSpline }

procedure TToolSelectSpline.AssignShapeStyle(AMatrix: TAffineMatrix);
begin
  FShape.BeginUpdate;
  inherited AssignShapeStyle(AMatrix);
  AssignSelectShapeStyle(FShape, FSwapColor);
  FShape.EndUpdate;
end;

function TToolSelectSpline.GetIsSelectingTool: boolean;
begin
  Result:= true;
end;

function TToolSelectSpline.GetContextualToolbars: TContextualToolbars;
begin
  Result:= [ctSplineStyle, ctCloseShape];
end;

{ TToolSelectPoly }

procedure TToolSelectPoly.AssignShapeStyle(AMatrix: TAffineMatrix);
begin
  FShape.BeginUpdate;
  inherited AssignShapeStyle(AMatrix);
  AssignSelectShapeStyle(FShape, FSwapColor);
  FShape.EndUpdate;
end;

function TToolSelectPoly.GetIsSelectingTool: boolean;
begin
  Result:= true;
end;

function TToolSelectPoly.GetContextualToolbars: TContextualToolbars;
begin
  Result:= [];
end;

{ TVectorialSelectTool }

function TVectorialSelectTool.GetIsSelectingTool: boolean;
begin
  Result:= true;
end;

procedure TVectorialSelectTool.AssignShapeStyle(AMatrix: TAffineMatrix);
begin
  AssignSelectShapeStyle(FShape, FSwapColor);
  if FShape is TCustomRectShape then
  begin
    if Manager.ShapeRatio = 0 then
      TCustomRectShape(FShape).FixedRatio:= EmptySingle
    else
      TCustomRectShape(FShape).FixedRatio:= Manager.ShapeRatio;
  end;
end;

function TVectorialSelectTool.RoundCoordinate(ptF: TPointF): TPointF;
begin
  Result:= PointF(floor(ptF.x)+0.5,floor(ptF.y)+0.5);
end;

function TVectorialSelectTool.UpdateShape(toolDest: TBGRABitmap): TRect;
begin
  if BigImage and FQuickDefine then
    result := OnlyRenderChange
  else
    Result:= inherited UpdateShape(toolDest);
end;

procedure TVectorialSelectTool.QuickDefineEnd;
var
  toolDest: TBGRABitmap;
  r: TRect;
begin
  toolDest := GetToolDrawingLayer;
  r := UpdateShape(toolDest);
  Action.NotifyChange(toolDest, r);
end;

function TVectorialSelectTool.BigImage: boolean;
begin
  result := Manager.Image.Width*Manager.Image.Height > 480000;
end;

function TVectorialSelectTool.GetContextualToolbars: TContextualToolbars;
begin
  Result:= [];
end;

{ TToolSelectRect }

function TToolSelectRect.CreateShape: TVectorShape;
begin
  result := TRectShape.Create(nil);
end;

function TToolSelectRect.Render(VirtualScreen: TBGRABitmap; VirtualScreenWidth,
  VirtualScreenHeight: integer;
  BitmapToVirtualScreen: TBitmapToVirtualScreenFunction): TRect;
var
  ab: TAffineBox;
  ptsF: ArrayOfTPointF;
  pts: array of TPoint;
  i: Integer;
  abBounds: TRect;
begin
  Result:= inherited Render(VirtualScreen, VirtualScreenWidth,
      VirtualScreenHeight, BitmapToVirtualScreen);

  if BigImage and FQuickDefine then
  begin
    ab := TCustomRectShape(FShape).GetAffineBox(
      AffineMatrixTranslation(0.5,0.5)*FEditor.Matrix*AffineMatrixTranslation(-0.5,-0.5), false);
    abBounds := ab.RectBounds;
    abBounds.Inflate(1,1);
    result := RectUnion(result, abBounds);
    if Assigned(VirtualScreen) then
    begin
      ptsF := ab.AsPolygon;
      setlength(pts, length(ptsF));
      for i := 0 to high(ptsF) do
        pts[i] := (ptsF[i]+PointF(0.5,0.5)).Round;
      VirtualScreen.DrawPolygonAntialias(pts,BGRAWhite,BGRABlack,FrameDashLength);
    end;
  end;
end;

function TToolSelectRect.GetContextualToolbars: TContextualToolbars;
begin
  Result:= [ctRatio];
end;

{ TToolSelectEllipse }

function TToolSelectEllipse.CreateShape: TVectorShape;
begin
  result := TEllipseShape.Create(nil);
end;

function TToolSelectEllipse.Render(VirtualScreen: TBGRABitmap;
  VirtualScreenWidth, VirtualScreenHeight: integer;
  BitmapToVirtualScreen: TBitmapToVirtualScreenFunction): TRect;
var
  ab: TAffineBox;
  ptsF: ArrayOfTPointF;
  pts: array of TPoint;
  i: Integer;
  abBounds: TRect;
begin
  Result:= inherited Render(VirtualScreen, VirtualScreenWidth,
      VirtualScreenHeight, BitmapToVirtualScreen);

  if BigImage and FQuickDefine then
  begin
    ab := TCustomRectShape(FShape).GetAffineBox(
      AffineMatrixTranslation(0.5,0.5)*FEditor.Matrix*AffineMatrixTranslation(-0.5,-0.5), false);
    abBounds := ab.RectBounds;
    abBounds.Inflate(1,1);
    result := RectUnion(result, abBounds);
    if Assigned(VirtualScreen) then
    begin
      with TCustomRectShape(FShape) do
        ptsF := BGRAPath.ComputeEllipse(FEditor.Matrix*Origin,
                    FEditor.Matrix*XAxis,FEditor.Matrix*YAxis);
      setlength(pts, length(ptsF));
      for i := 0 to high(ptsF) do
        pts[i] := ptsF[i].Round;
      VirtualScreen.DrawPolygonAntialias(pts,BGRAWhite,BGRABlack,FrameDashLength);
    end;
  end;
end;

function TToolSelectEllipse.GetContextualToolbars: TContextualToolbars;
begin
  Result:= [ctRatio];
end;

{ TTransformSelectionTool }

function TTransformSelectionTool.GetIsSelectingTool: boolean;
begin
  result := true;
end;

function TTransformSelectionTool.GetAction: TLayerAction;
begin
  Result:= nil;
end;

function TTransformSelectionTool.FixSelectionTransform: boolean;
begin
  Result:= false;
end;

function TTransformSelectionTool.DoGetToolDrawingLayer: TBGRABitmap;
begin
  result := Manager.Image.SelectionMaskReadonly;
end;

{ TToolRotateSelection }

function TToolRotateSelection.DoToolDown(toolDest: TBGRABitmap; pt: TPoint;
  ptF: TPointF; rightBtn: boolean): TRect;
begin
  result := EmptyRect;
  if not handMoving and not Manager.Image.SelectionMaskEmpty then
  begin
    if rightBtn then
    begin
      if FCurrentAngle <> 0 then
      begin
        FCurrentAngle := 0;
        FCurrentCenter := ptF;
        UpdateTransform;
      end else
      begin
        FCurrentCenter := ptF;
        UpdateTransform;
      end;
      result := OnlyRenderChange;
    end else
    begin
      handMoving := true;
      handOrigin := ptF;
    end;
  end;
end;

function TToolRotateSelection.DoToolMove(toolDest: TBGRABitmap; pt: TPoint;
  ptF: TPointF): TRect;
var angleDiff: single;
begin
  if not HintShowed then
  begin
    Manager.ToolPopup(tpmHoldKeyRestrictRotation, VK_SNAP);
    HintShowed:= true;
  end;
  if handMoving and ((handOrigin.X <> ptF.X) or (handOrigin.Y <> ptF.Y)) then
  begin
    angleDiff := ComputeAngle(ptF.X-FCurrentCenter.X,ptF.Y-FCurrentCenter.Y)-
                 ComputeAngle(handOrigin.X-FCurrentCenter.X,handOrigin.Y-FCurrentCenter.Y);
    if snapRotate then
    begin
      snapAngle += angleDiff;
      FCurrentAngle := round(snapAngle/15)*15;
    end
     else
       FCurrentAngle := FCurrentAngle + angleDiff;
    UpdateTransform;
    handOrigin := ptF;
    result := OnlyRenderChange;
  end else
    result := EmptyRect;
end;

function TToolRotateSelection.GetStatusText: string;
begin
  Result:= 'α = '+FloatToStrF(FCurrentAngle,ffFixed,5,1);
end;

procedure TToolRotateSelection.UpdateTransform;
begin
  Manager.Image.SelectionTransform := AffineMatrixTranslation(FCurrentCenter.X,FCurrentCenter.Y)*
                                   AffineMatrixRotationDeg(FCurrentAngle)*
                                   AffineMatrixTranslation(-FCurrentCenter.X,-FCurrentCenter.Y)*FOriginalTransform;
end;

constructor TToolRotateSelection.Create(AManager: TToolManager);
begin
  inherited Create(AManager);
  FCurrentCenter := Manager.Image.SelectionTransform * Manager.Image.GetSelectionMaskCenter;
  FOriginalTransform := Manager.Image.SelectionTransform;
  FCurrentAngle := 0;
end;

function TToolRotateSelection.ToolKeyDown(var key: Word): TRect;
begin
  result := EmptyRect;
  if key = VK_SNAP then
  begin
    if not snapRotate then
    begin
      snapRotate := true;
      snapAngle := FCurrentAngle;

      if handMoving then
      begin
        FCurrentAngle := round(snapAngle/15)*15;
        UpdateTransform;
        result := OnlyRenderChange;
      end;
    end;
    Key := 0;
  end else
  if key = VK_ESCAPE then
  begin
    if FCurrentAngle <> 0 then
    begin
      FCurrentAngle := 0;
      UpdateTransform;
      result := OnlyRenderChange;
    end;
    Key := 0;
  end;
end;

function TToolRotateSelection.ToolKeyUp(var key: Word): TRect;
begin
  if key = VK_SNAP then
  begin
    snapRotate := false;
    Key := 0;
  end;
  result := EmptyRect;
end;

function TToolRotateSelection.ToolUp: TRect;
begin
  handMoving:= false;
  Result:= EmptyRect;
end;

function TToolRotateSelection.Render(VirtualScreen: TBGRABitmap;
  VirtualScreenWidth, VirtualScreenHeight: integer; BitmapToVirtualScreen: TBitmapToVirtualScreenFunction): TRect;
var pictureRotateCenter: TPointF;
begin
  pictureRotateCenter := BitmapToVirtualScreen(FCurrentCenter);
  result := NicePoint(VirtualScreen, pictureRotateCenter.X,pictureRotateCenter.Y);
end;

destructor TToolRotateSelection.Destroy;
begin
  if handMoving then handMoving := false;
  inherited Destroy;
end;

{ TToolMoveSelection }

function TToolMoveSelection.DoToolDown(toolDest: TBGRABitmap; pt: TPoint;
  ptF: TPointF; rightBtn: boolean): TRect;
begin
  if not handMoving and not Manager.Image.SelectionMaskEmpty then
  begin
    handMoving := true;
    handOriginF := ptF;
    selectionTransformBefore := Manager.Image.SelectionTransform;
  end;
  result := EmptyRect;
end;

function TToolMoveSelection.DoToolMove(toolDest: TBGRABitmap; pt: TPoint;
  ptF: TPointF): TRect;
var dx,dy: single;
  newSelTransform: TAffineMatrix;
begin
  result := EmptyRect;
  if handMoving then
  begin
    dx := ptF.X-HandOriginF.X;
    dy := ptF.Y-HandOriginF.Y;
    if snapToPixel then
    begin
      dx := round(dx);
      dy := round(dy);
    end;
    newSelTransform := AffineMatrixTranslation(dx,dy) * selectionTransformBefore;
    if Manager.Image.SelectionTransform <> newSelTransform then
    begin
      Manager.Image.SelectionTransform := newSelTransform;
      result := OnlyRenderChange;
    end;
  end;
end;

constructor TToolMoveSelection.Create(AManager: TToolManager);
begin
  inherited Create(AManager);
  handMoving := false;
  snapToPixel:= false;
end;

function TToolMoveSelection.ToolUp: TRect;
begin
  handMoving := false;
  result := EmptyRect;
end;

function TToolMoveSelection.ToolKeyDown(var key: Word): TRect;
begin
  if (Key = VK_SNAP) or (Key = VK_SNAP2) then
  begin
    result := EmptyRect;
    snapToPixel:= true;
    key := 0;
  end else
    Result:=inherited ToolKeyDown(key);
end;

function TToolMoveSelection.ToolKeyUp(var key: Word): TRect;
begin
  if (Key = VK_SNAP) or (Key = VK_SNAP2) then
  begin
    result := EmptyRect;
    snapToPixel:= false;
    key := 0;
  end else
    Result:=inherited ToolKeyUp(key);
end;

destructor TToolMoveSelection.Destroy;
begin
  if handMoving then handMoving := false;
  inherited Destroy;
end;

{ TToolSelectionPen }

function TToolSelectionPen.GetIsSelectingTool: boolean;
begin
  Result:= true;
end;

function TToolSelectionPen.StartDrawing(toolDest: TBGRABitmap; ptF: TPointF;
  rightBtn: boolean): TRect;
begin
  if rightBtn then penColor := BGRABlack else penColor := BGRAWhite;
  toolDest.DrawLineAntialias(ptF.X,ptF.Y,ptF.X,ptF.Y,penColor,Manager.PenWidth,True);
  result := GetShapeBounds([ptF],Manager.PenWidth+1);
end;

function TToolSelectionPen.ContinueDrawing(toolDest: TBGRABitmap; originF,
  destF: TPointF): TRect;
begin
  toolDest.DrawLineAntialias(destF.X,destF.Y,originF.X,originF.Y,penColor,Manager.PenWidth,False);
  result := GetShapeBounds([destF,originF],Manager.PenWidth+1);
end;

function TToolSelectionPen.GetContextualToolbars: TContextualToolbars;
begin
  Result:= [ctPenWidth];
end;

{ TToolMagicWand }

function TToolMagicWand.GetIsSelectingTool: boolean;
begin
  Result:= true;
end;

function TToolMagicWand.DoToolDown(toolDest: TBGRABitmap; pt: TPoint;
  ptF: TPointF; rightBtn: boolean): TRect;
var penColor: TBGRAPixel;
  ofs: TPoint;
begin
  if not Manager.Image.CurrentLayerVisible then
  begin
    result := EmptyRect;
    exit;
  end;
  if rightBtn then penColor := BGRABlack else penColor := BGRAWhite;
  ofs := Manager.Image.LayerOffset[Manager.Image.CurrentLayerIndex];
  Manager.Image.CurrentLayerReadOnly.ParallelFloodFill(pt.X-ofs.X, pt.Y-ofs.Y,
    toolDest, penColor, fmDrawWithTransparency, Manager.Tolerance, ofs.X, ofs.Y);
  result := rect(0,0,toolDest.Width,toolDest.Height);
  Action.NotifyChange(toolDest, result);
  ValidateAction;
end;

function TToolMagicWand.GetContextualToolbars: TContextualToolbars;
begin
  Result:= [ctTolerance];
end;

initialization

  RegisterTool(ptMagicWand,TToolMagicWand);
  RegisterTool(ptSelectPen,TToolSelectionPen);
  RegisterTool(ptSelectRect,TToolSelectRect);
  RegisterTool(ptSelectEllipse,TToolSelectEllipse);
  RegisterTool(ptSelectPoly,TToolSelectPoly);
  RegisterTool(ptSelectSpline,TToolSelectSpline);
  RegisterTool(ptMoveSelection,TToolMoveSelection);
  RegisterTool(ptRotateSelection,TToolRotateSelection);

end.

