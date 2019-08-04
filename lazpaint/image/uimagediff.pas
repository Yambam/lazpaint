unit UImageDiff;

{$mode objfpc}

interface

uses
  Classes, SysUtils, UStateType, BGRABitmap, BGRABitmapTypes, BGRALayers,
  BGRALayerOriginal, LCVectorOriginal;

function IsInverseImageDiff(ADiff1, ADiff2: TCustomImageDifference): boolean;
function TryCombineImageDiff(ANewDiff, APrevDiff: TCustomImageDifference): boolean;

type
  { TInversibleStateDifference }

  TInversibleStateDifference = class(TCustomImageDifference)
  private
    FAction: TInversibleAction;
    FLayerIndex: integer;
  public
    constructor Create(AState: TState; AAction: TInversibleAction; ALayerIndex : integer = -1);
    procedure ApplyTo(AState: TState); override;
    procedure UnApplyTo(AState: TState); override;
    procedure ApplyAction(AState: TState; AAction: TInversibleAction; AInverse: boolean);
    function ToString: ansistring; override;
    property Action: TInversibleAction read FAction write FAction;
    property LayerIndex: integer read FLayerIndex;
  end;

  { TSelectCurrentLayer }

  TSelectCurrentLayer = class(TCustomImageDifference)
  private
    FPrevLayerIndex, FNewLayerIndex: integer;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
  public
    constructor Create(AState: TState; ANewLayerIndex: integer);
    procedure ApplyTo(AState: TState); override;
    procedure UnApplyTo(AState: TState); override;
    function ToString: ansistring; override;
  end;

type
  { TImageLayerStateDifference }

  TImageLayerStateDifference = class(TCustomImageDifference)
  private
    function GetChangeImageLayer: boolean;
    function GetChangeSelectionLayer: boolean;
    function GetChangeSelectionMask: boolean;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetIsIdentity: boolean; override;
    function GetChangingBoundsDefined: boolean; override;
    function GetChangingBounds: TRect; override;
    procedure Init(AToState: TState; APreviousImage: TBGRABitmap; APreviousImageChangeRect: TRect;
        APreviousSelection: TBGRABitmap; APreviousSelectionChangeRect: TRect;
        APreviousSelectionLayer: TBGRABitmap; APreviousSelectionLayerChangeRect: TRect);
  public
    layerId: integer;
    imageOfs: TPoint;
    imageDiff, selectionLayerDiff: TImageDiff;
    selectionMaskDiff: TGrayscaleImageDiff;
    function TryCompress: boolean; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
    function UsedMemory: int64; override;
    constructor Create(AFromState, AToState: TState);
    constructor Create(AToState: TState; APreviousImage: TBGRABitmap; APreviousImageDefined: boolean;
        APreviousSelection: TBGRABitmap; APreviousSelectionDefined: boolean;
        APreviousSelectionLayer: TBGRABitmap; APreviousSelectionLayerDefined: boolean); overload;
    constructor Create(AToState: TState; APreviousImage: TBGRABitmap; APreviousImageChangeRect: TRect;
        APreviousSelection: TBGRABitmap; APreviousSelectionChangeRect: TRect;
        APreviousSelectionLayer: TBGRABitmap; APreviousSelectionLayerChangeRect: TRect); overload;
    function ToString: ansistring; override;
    destructor Destroy; override;
    property ChangeImageLayer: boolean read GetChangeImageLayer;
    property ChangeSelectionMask: boolean read GetChangeSelectionMask;
    property ChangeSelectionLayer: boolean read GetChangeSelectionLayer;
  end;

  { TSetLayerNameStateDifference }

  TSetLayerNameStateDifference = class(TCustomImageDifference)
  private
    previousName,nextName: ansistring;
    layerId: integer;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetIsIdentity: boolean; override;
  public
    constructor Create(ADestination: TState; ALayerId: integer; ANewName: ansistring);
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
    function ToString: ansistring; override;
  end;

  { TSetLayerOpacityStateDifference }

  TSetLayerOpacityStateDifference = class(TCustomImageDifference)
  private
    previousOpacity,nextOpacity: byte;
    layerId: integer;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetIsIdentity: boolean; override;
  public
    constructor Create(ADestination: TState; ALayerId: integer; ANewOpacity: byte);
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
  end;

  { TSetLayerOffsetStateDifference }

  TSetLayerOffsetStateDifference = class(TCustomImageDifference)
  private
    previousOffset,nextOffset: TPoint;
    layerId: integer;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetIsIdentity: boolean; override;
  public
    constructor Create(ADestination: TState; ALayerId: integer; ANewOffset: TPoint);
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
  end;

  { TSetLayerMatrixDifference }

  TSetLayerMatrixDifference = class(TCustomImageDifference)
  private
    previousMatrix,nextMatrix: TAffineMatrix;
    layerId: integer;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetIsIdentity: boolean; override;
  public
    constructor Create({%H-}ADestination: TState; ALayerId: integer; APreviousMatrix, ANextMatrix: TAffineMatrix);
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
  end;

  { TSetSelectionTransformDifference }

  TSetSelectionTransformDifference = class(TCustomImageDifference)
  private
    previousMatrix,nextMatrix: TAffineMatrix;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetIsIdentity: boolean; override;
  public
    constructor Create({%H-}ADestination: TState; ANextMatrix: TAffineMatrix);
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
  end;

  { TApplyLayerOffsetStateDifference }

  TApplyLayerOffsetStateDifference = class(TCustomImageDifference)
  private
    previousBounds,nextBounds,unchangedBounds: TRect;
    clippedData: TMemoryStream;
    useOriginal: boolean;
    previousOriginalRenderStatus: TOriginalRenderStatus;
    layerId: integer;
    FDestination: TState;
    previousLayerOffset: TPoint;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetIsIdentity: boolean; override;
    function GetChangingBoundsDefined: boolean; override;
    function GetChangingBounds: TRect; override;
  public
    constructor Create(ADestination: TState; ALayerId: integer; AOffsetX, AOffsetY: integer; AApplyNow: boolean);
    destructor Destroy; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
  end;

  { TSelectionTransformDifference }

  TSelectionTransformDifference = class(TCustomImageDifference)
    FPrevTransform: TAffineMatrix;
    FPrevSelectionMask, FPrevSelectionLayer: TStoredImage;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetIsIdentity: boolean; override;
  public
    constructor Create(ADestination: TState; AApplyNow: boolean);
    function TryCompress: boolean; override;
    destructor Destroy; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
  end;

  { TSetLayerVisibleStateDifference }

  TSetLayerVisibleStateDifference = class(TCustomImageDifference)
  private
    previousVisible,nextVisible: boolean;
    layerId: integer;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetIsIdentity: boolean; override;
  public
    constructor Create(ADestination: TState; ALayerId: integer; ANewVisible: boolean);
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
  end;

  { TSetLayerBlendOpStateDifference }

  TSetLayerBlendOpStateDifference = class(TCustomImageDifference)
  private
    previousBlendOp,nextBlendOp: TBlendOperation;
    layerId: integer;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetIsIdentity: boolean; override;
  public
    constructor Create(ADestination: TState; ALayerId: integer; ANewBlendOp: TBlendOperation);
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
  end;

  { TAddLayerStateDifference }

  TAddLayerStateDifference = class(TCustomImageDifference)
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
  public
    layerId: integer;
    content: TStoredImage;
    previousActiveLayerId: integer;
    name: ansistring;
    blendOp: TBlendOperation;
    function UsedMemory: int64; override;
    function TryCompress: boolean; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
    constructor Create(ADestination: TState; AContent: TBGRABitmap; AName: ansistring; ABlendOp: TBlendOperation);
    destructor Destroy; override;
  end;

  { TAddLayerFromOwnedOriginalStateDifference }

  TAddLayerFromOwnedOriginalStateDifference = class(TCustomImageDifference)
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    procedure Uncompress;
  public
    layerId: integer;
    originalData: TStream;
    compressedData: TStream;
    previousActiveLayerId: integer;
    name: ansistring;
    blendOp: TBlendOperation;
    matrix: TAffineMatrix;
    function UsedMemory: int64; override;
    function TryCompress: boolean; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
    constructor Create(ADestination: TState; AOriginal: TBGRALayerCustomOriginal;
        AName: ansistring; ABlendOp: TBlendOperation; AMatrix: TAffineMatrix);
    destructor Destroy; override;
  end;

  { TRemoveLayerStateDifference }

  TRemoveLayerStateDifference = class(TCustomImageDifference)
  protected
    content: TStoredLayer;
    nextActiveLayerId: integer;
    function GetImageDifferenceKind: TImageDifferenceKind; override;
  public
    function UsedMemory: int64; override;
    function TryCompress: boolean; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
    constructor Create(AState: TState);
    destructor Destroy; override;
  end;

  { TReplaceLayerByOriginalDifference }

  TReplaceLayerByOriginalDifference = class(TCustomImageDifference)
  private
    function GetLayerId: integer;
  protected
    FPreviousLayerContent: TStoredLayer;
    FPrevMatrix,FNextMatrix: TAffineMatrix;
    FSourceBounds: TRect;
    FOriginalGuid: TGUID;
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function CreateOriginal(AState: TState; ALayerIndex: integer): TBGRALayerCustomOriginal; virtual; abstract;
  public
    constructor Create(AFromState: TState; AIndex: integer; AAlwaysStoreBitmap: boolean);
    function UsedMemory: int64; override;
    function TryCompress: boolean; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
    property LayerId: integer read GetLayerId;
    property prevMatrix: TAffineMatrix read FPrevMatrix;
    property nextMatrix: TAffineMatrix read FNextMatrix write FNextMatrix;
    destructor Destroy; override;
  end;

  { TDiscardOriginalDifference }

  TDiscardOriginalDifference = class(TCustomImageDifference)
  private
    function GetLayerId: integer;
  protected
    FPreviousOriginalData: TStream;
    FPreviousOriginalGuid: TGuid;
    FOriginalUsedInOtherLayer: boolean;
    FPreviousOriginalMatrix: TAffineMatrix;
    FPreviousOriginalRenderStatus: TOriginalRenderStatus;
    FLayerId: integer;
    function GetImageDifferenceKind: TImageDifferenceKind; override;
  public
    constructor Create(AFromState: TState; AIndex: integer; AApplyNow: boolean);
    function UsedMemory: int64; override;
    function TryCompress: boolean; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
    property LayerId: integer read GetLayerId;
    destructor Destroy; override;
  end;

  { TReplaceLayerByImageOriginalDifference }

  TReplaceLayerByImageOriginalDifference = class(TReplaceLayerByOriginalDifference)
  protected
    function CreateOriginal(AState: TState; ALayerIndex: integer): TBGRALayerCustomOriginal; override;
  end;

  { TReplaceLayerByVectorOriginalDifference }

  TReplaceLayerByVectorOriginalDifference = class(TReplaceLayerByOriginalDifference)
  protected
    function CreateOriginal(AState: TState; ALayerIndex: integer): TBGRALayerCustomOriginal; override;
  end;

  { TAddShapeToVectorOriginalDifference }

  TAddShapeToVectorOriginalDifference = class(TCustomImageDifference)
  private
    FShapeIndex, FShapeId: integer;
    FLayerId: integer;
    FShapeCopy: TVectorShape;
    FShapeBounds: TRect;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetChangingBounds: TRect; override;
    function GetChangingBoundsDefined: boolean; override;
  public
    constructor Create(ADestination: TState; ALayerId: integer; AShape: TVectorShape; AShapeIndex: integer = -1);
    destructor Destroy; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
  end;

  { TVectorOriginalEmbeddedDifference }

  TVectorOriginalEmbeddedDifference = class(TCustomImageDifference)
  private
    FDate: TDateTime;
    FOriginalGuid: TGuid;
    FDiff: TBGRAOriginalDiff;
    FBounds: TRect;
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
    function GetChangingBounds: TRect; override;
    function GetChangingBoundsDefined: boolean; override;
  public
    constructor Create({%H-}ADestination: TState; AOriginalGuid: TGuid; ADiff: TBGRAOriginalDiff; ABounds: TRect);
    destructor Destroy; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
  end;

  { TDiscardOriginalStateDifference }

  TDiscardOriginalStateDifference = class(TCustomImageDifference)
  protected
    origData: TStream;
    origMatrix: TAffineMatrix;
    origRenderStatus: TOriginalRenderStatus;
    layerId: integer;
    function GetImageDifferenceKind: TImageDifferenceKind; override;
  public
    function UsedMemory: int64; override;
    function TryCompress: boolean; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
    constructor Create(AState: TState; AIndex: integer);
    destructor Destroy; override;
  end;

  { TAssignStateDifference }

  TAssignStateDifference = class(TCustomImageDifference)
  protected
    FStreamBefore, FStreamAfter: TMemoryStream;
    FSelectionDiff,FSelectionLayerDiff: TImageDiff;
    procedure Init(AState: TState; AValue: TBGRALayeredBitmap; AOwned: boolean; ASelectedLayerIndex: integer);
  public
    constructor Create(AState: TState; AValue: TBGRALayeredBitmap; AOwned: boolean; ASelectedLayerIndex: integer);
    constructor Create(AState: TState; AValue: TBGRALayeredBitmap; AOwned: boolean; ASelectedLayerIndex: integer; ACurrentSelection: TBGRABitmap; ASelectionLayer: TBGRABitmap);
    function UsedMemory: int64; override;
    function TryCompress: boolean; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnApplyTo(AState: TState); override;
    destructor Destroy; override;
  end;

  { TAssignStateDifferenceAfter }

  TAssignStateDifferenceAfter = class(TAssignStateDifference)
  public
    constructor Create(AState: TState; ABackup: TState);
  end;

  { TDuplicateLayerStateDifference }

  TDuplicateLayerStateDifference = class(TCustomImageDifference)
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
  public
    sourceLayerId: integer;
    duplicateId: integer;
    useOriginal: boolean;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
    constructor Create(ADestination: TState; AUseOriginal: boolean);
  end;

  { TMoveLayerStateDifference }

  TMoveLayerStateDifference = class(TCustomImageDifference)
  protected
    function GetIsIdentity: boolean; override;
    function GetImageDifferenceKind: TImageDifferenceKind; override;
  public
    sourceIndex,destIndex: integer;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
    constructor Create(ADestination: TState; AFromIndex, AToIndex: integer);
  end;

  { TMergeLayerOverStateDifference }

  TMergeLayerOverStateDifference = class(TCustomImageDifference)
  protected
    function GetImageDifferenceKind: TImageDifferenceKind; override;
  public
    previousActiveLayerId: integer;
    layerOverIndex: integer;
    layerOverCompressedBackup: TStoredLayer;
    layerUnderCompressedBackup: TStoredLayer;
    constructor Create(ADestination: TState; ALayerOverIndex: integer);
    function UsedMemory: int64; override;
    function TryCompress: boolean; override;
    procedure ApplyTo(AState: TState); override;
    procedure UnapplyTo(AState: TState); override;
    destructor Destroy; override;
  end;

implementation

uses BGRAWriteLzp, BGRAReadLzp, UImageState, BGRAStreamLayers, BGRALzpCommon, ugraph, Types,
  BGRATransform, zstream, LCVectorRectShapes, BGRAPen;

function IsInverseImageDiff(ADiff1, ADiff2: TCustomImageDifference): boolean;
begin
  if (ADiff1 is TInversibleStateDifference) and (ADiff2 is TInversibleStateDifference) then
    result := ((ADiff1 as TInversibleStateDifference).Action = GetInverseAction( (ADiff2 as TInversibleStateDifference).Action ))
          and ((ADiff1 as TInversibleStateDifference).LayerIndex = (ADiff2 as TInversibleStateDifference).LayerIndex)
  else
  if (ADiff1 is TSetLayerNameStateDifference) and (ADiff2 is TSetLayerNameStateDifference) then
  begin
    result := ((ADiff1 as TSetLayerNameStateDifference).nextName = (ADiff2 as TSetLayerNameStateDifference).previousName) and
      ((ADiff1 as TSetLayerNameStateDifference).previousName = (ADiff2 as TSetLayerNameStateDifference).nextName);
  end
  else
  if (ADiff1 is TSetLayerVisibleStateDifference) and (ADiff2 is TSetLayerVisibleStateDifference) then
  begin
    result := ((ADiff1 as TSetLayerVisibleStateDifference).nextVisible = (ADiff2 as TSetLayerVisibleStateDifference).previousVisible) and
      ((ADiff1 as TSetLayerVisibleStateDifference).previousVisible = (ADiff2 as TSetLayerVisibleStateDifference).nextVisible);
  end
  else
  if (ADiff1 is TSetLayerOpacityStateDifference) and (ADiff2 is TSetLayerOpacityStateDifference) then
  begin
    result := ((ADiff1 as TSetLayerOpacityStateDifference).nextOpacity = (ADiff2 as TSetLayerOpacityStateDifference).previousOpacity) and
      ((ADiff1 as TSetLayerOpacityStateDifference).previousOpacity = (ADiff2 as TSetLayerOpacityStateDifference).nextOpacity);
  end
  else
  if (ADiff1 is TSetLayerBlendOpStateDifference) and (ADiff2 is TSetLayerBlendOpStateDifference) then
  begin
    result := ((ADiff1 as TSetLayerBlendOpStateDifference).nextBlendOp = (ADiff2 as TSetLayerBlendOpStateDifference).previousBlendOp) and
      ((ADiff1 as TSetLayerBlendOpStateDifference).previousBlendOp = (ADiff2 as TSetLayerBlendOpStateDifference).nextBlendOp);
  end
  else
    result := false;
end;

function TryCombineImageDiff(ANewDiff, APrevDiff: TCustomImageDifference): boolean;
const VectorDiffMinTime = 2000/(1000*60*60*24);
var
  combined: TInversibleAction;
begin
  if (APrevDiff is TInversibleStateDifference) and (ANewDiff is TInversibleStateDifference) then
  begin
    if CanCombineInversibleAction((APrevDiff as TInversibleStateDifference).Action, (ANewDiff as TInversibleStateDifference).Action, combined) then
    begin
      (APrevDiff as TInversibleStateDifference).Action := combined;
      result := true;
    end
    else result := false;
  end
  else
  if (APrevDiff is TSetLayerNameStateDifference) and (ANewDiff is TSetLayerNameStateDifference) then
  begin
    if (APrevDiff as TSetLayerNameStateDifference).nextName = (ANewDiff as TSetLayerNameStateDifference).previousName then
    begin
      (APrevDiff as TSetLayerNameStateDifference).nextName := (ANewDiff as TSetLayerNameStateDifference).nextName;
      result := true;
    end
    else result := false;
  end
  else
  if (APrevDiff is TSetLayerOpacityStateDifference) and (ANewDiff is TSetLayerOpacityStateDifference) then
  begin
    if (APrevDiff as TSetLayerOpacityStateDifference).nextOpacity = (ANewDiff as TSetLayerOpacityStateDifference).previousOpacity then
    begin
      (APrevDiff as TSetLayerOpacityStateDifference).nextOpacity := (ANewDiff as TSetLayerOpacityStateDifference).nextOpacity;
      result := true;
    end
    else result := false;
  end
  else
  if (APrevDiff is TSetLayerOffsetStateDifference) and (ANewDiff is TSetLayerOffsetStateDifference) then
  begin
    if ((APrevDiff as TSetLayerOffsetStateDifference).nextOffset.x = (ANewDiff as TSetLayerOffsetStateDifference).previousOffset.x)
    and ((APrevDiff as TSetLayerOffsetStateDifference).nextOffset.y = (ANewDiff as TSetLayerOffsetStateDifference).previousOffset.y) then
    begin
      (APrevDiff as TSetLayerOffsetStateDifference).nextOffset := (ANewDiff as TSetLayerOffsetStateDifference).nextOffset;
      result := true;
    end
    else result := false;
  end
  else
  if (APrevDiff is TSetLayerMatrixDifference) and (ANewDiff is TSetLayerMatrixDifference) then
  begin
    if (APrevDiff as TSetLayerMatrixDifference).nextMatrix = (ANewDiff as TSetLayerMatrixDifference).previousMatrix then
    begin
      (APrevDiff as TSetLayerMatrixDifference).nextMatrix := (ANewDiff as TSetLayerMatrixDifference).nextMatrix;
      result := true;
    end
    else result := false;
  end
  else
  if (APrevDiff is TReplaceLayerByOriginalDifference) and (ANewDiff is TSetLayerMatrixDifference) then
  begin
    if (APrevDiff as TReplaceLayerByOriginalDifference).nextMatrix = (ANewDiff as TSetLayerMatrixDifference).previousMatrix then
    begin
      (APrevDiff as TReplaceLayerByOriginalDifference).nextMatrix := (ANewDiff as TSetLayerMatrixDifference).nextMatrix;
      result := true;
    end
    else result := false;
  end
  else
  if (APrevDiff is TSetSelectionTransformDifference) and (ANewDiff is TSetSelectionTransformDifference) then
  begin
    if (APrevDiff as TSetSelectionTransformDifference).nextMatrix = (ANewDiff as TSetSelectionTransformDifference).previousMatrix then
    begin
      (APrevDiff as TSetSelectionTransformDifference).nextMatrix := (ANewDiff as TSetSelectionTransformDifference).nextMatrix;
      result := true;
    end
    else result := false;
  end
  else
  if (APrevDiff is TSetLayerBlendOpStateDifference) and (ANewDiff is TSetLayerBlendOpStateDifference) then
  begin
    if (APrevDiff as TSetLayerBlendOpStateDifference).nextBlendOp = (ANewDiff as TSetLayerBlendOpStateDifference).previousBlendOp then
    begin
      (APrevDiff as TSetLayerBlendOpStateDifference).nextBlendOp := (ANewDiff as TSetLayerBlendOpStateDifference).nextBlendOp;
      result := true;
    end
    else result := false;
  end
  else
  if (APrevDiff is TVectorOriginalEmbeddedDifference) and (ANewDiff is TVectorOriginalEmbeddedDifference) then
  begin
    if (TVectorOriginalEmbeddedDifference(ANewDiff).FDate <
       TVectorOriginalEmbeddedDifference(APrevDiff).FDate+VectorDiffMinTime) and
      TVectorOriginalEmbeddedDifference(APrevDiff).FDiff.CanAppend(
      TVectorOriginalEmbeddedDifference(ANewDiff).FDiff) then
    begin
      TVectorOriginalEmbeddedDifference(APrevDiff).FDiff.Append(
        TVectorOriginalEmbeddedDifference(ANewDiff).FDiff);
      result := true;
    end else
      result := false;
  end else
    result := false;
end;

{ TVectorOriginalEmbeddedDifference }

function TVectorOriginalEmbeddedDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeImage;
end;

function TVectorOriginalEmbeddedDifference.GetChangingBounds: TRect;
begin
  Result:= FBounds;
end;

function TVectorOriginalEmbeddedDifference.GetChangingBoundsDefined: boolean;
begin
  Result:= true;
end;

constructor TVectorOriginalEmbeddedDifference.Create(ADestination: TState;
  AOriginalGuid: TGuid; ADiff: TBGRAOriginalDiff; ABounds: TRect);
begin
  FDate := Now;
  FOriginalGuid:= AOriginalGuid;
  FDiff := ADiff;
  FBounds := ABounds;
end;

destructor TVectorOriginalEmbeddedDifference.Destroy;
begin
  FDiff.Free;
  inherited Destroy;
end;

procedure TVectorOriginalEmbeddedDifference.ApplyTo(AState: TState);
var
  img: TImageState;
  idxOrig: Integer;
begin
  inherited ApplyTo(AState);
  img := AState as TImageState;
  idxOrig := img.LayeredBitmap.IndexOfOriginal(FOriginalGuid);
  if idxOrig<>-1 then
    FDiff.Apply(img.LayeredBitmap.Original[idxOrig]);
end;

procedure TVectorOriginalEmbeddedDifference.UnapplyTo(AState: TState);
var
  img: TImageState;
  idxOrig: Integer;
begin
  inherited UnapplyTo(AState);
  img := AState as TImageState;
  idxOrig := img.LayeredBitmap.IndexOfOriginal(FOriginalGuid);
  if idxOrig<>-1 then
    FDiff.Unapply(img.LayeredBitmap.Original[idxOrig]);
end;

{ TDiscardOriginalDifference }

function TDiscardOriginalDifference.GetLayerId: integer;
begin
  result := FLayerId;
end;

function TDiscardOriginalDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeStack;
end;

constructor TDiscardOriginalDifference.Create(AFromState: TState;
  AIndex: integer; AApplyNow: boolean);
var
  imgState: TImageState;
  i: Integer;
begin
  imgState := AFromState as TImageState;
  FLayerId := imgState.LayerId[AIndex];
  if not imgState.LayerOriginalDefined[AIndex] then
    raise exception.Create('Layer original is not defined');
  FPreviousOriginalGuid := imgState.LayeredBitmap.LayerOriginalGuid[AIndex];
  FOriginalUsedInOtherLayer := false;
  for i := 0 to imgState.NbLayers-1 do
    if (i <> AIndex) and (imgState.LayeredBitmap.LayerOriginalGuid[i] = FPreviousOriginalGuid) then
    begin
      FOriginalUsedInOtherLayer:= true;
      break;
    end;
  if not FOriginalUsedInOtherLayer then
  begin
    FPreviousOriginalData := TMemoryStream.Create;
    imgState.LayeredBitmap.SaveOriginalToStream(
      imgState.LayeredBitmap.LayerOriginalGuid[AIndex],
      FPreviousOriginalData);
  end;
  FPreviousOriginalMatrix := imgState.LayerOriginalMatrix[AIndex];
  FPreviousOriginalRenderStatus:= imgState.layeredBitmap.LayerOriginalRenderStatus[AIndex];
  if AApplyNow then ApplyTo(AFromState)
end;

function TDiscardOriginalDifference.UsedMemory: int64;
begin
  if Assigned(FPreviousOriginalData) then
    Result:= FPreviousOriginalData.Size
  else
    result:= 0;
end;

function TDiscardOriginalDifference.TryCompress: boolean;
begin
  Result:= false;
end;

procedure TDiscardOriginalDifference.ApplyTo(AState: TState);
var
  imgState: TImageState;
  layerIdx: Integer;
begin
  imgState := AState as TImageState;
  layerIdx := imgState.LayeredBitmap.GetLayerIndexFromId(FLayerId);
  imgState.LayeredBitmap.LayerOriginalGuid[layerIdx] := GUID_NULL;
  imgState.LayeredBitmap.LayerOriginalMatrix[layerIdx] := AffineMatrixIdentity;
  if not FOriginalUsedInOtherLayer then
    imgState.LayeredBitmap.RemoveUnusedOriginals;
  inherited ApplyTo(AState);
end;

procedure TDiscardOriginalDifference.UnapplyTo(AState: TState);
var
  imgState: TImageState;
  layerIdx, origIdx: Integer;
begin
  imgState := AState as TImageState;
  layerIdx := imgState.LayeredBitmap.GetLayerIndexFromId(FLayerId);
  if FOriginalUsedInOtherLayer then
  begin
    imgState.LayeredBitmap.LayerOriginalGuid[layerIdx] := FPreviousOriginalGuid;
  end else
  begin
    FPreviousOriginalData.Position := 0;
    origIdx := imgState.LayeredBitmap.AddOriginalFromStream(FPreviousOriginalData, FPreviousOriginalGuid, true);
    imgState.LayeredBitmap.LayerOriginalGuid[layerIdx] := imgState.LayeredBitmap.OriginalGuid[origIdx];
  end;
  imgState.LayeredBitmap.LayerOriginalMatrix[layerIdx] := FPreviousOriginalMatrix;
  imgState.LayeredBitmap.LayerOriginalRenderStatus[layerIdx] := FPreviousOriginalRenderStatus;
  inherited UnapplyTo(AState);
end;

destructor TDiscardOriginalDifference.Destroy;
begin
  FPreviousOriginalData.Free;
  inherited Destroy;
end;

{ TAddShapeToVectorOriginalDifference }

function TAddShapeToVectorOriginalDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeImage;
end;

function TAddShapeToVectorOriginalDifference.GetChangingBounds: TRect;
begin
  Result:= FShapeBounds;
end;

function TAddShapeToVectorOriginalDifference.GetChangingBoundsDefined: boolean;
begin
  Result:= true;
end;

constructor TAddShapeToVectorOriginalDifference.Create(ADestination: TState;
  ALayerId: integer; AShape: TVectorShape; AShapeIndex: integer);
var
  imgState: TImageState;
  layerIdx: Integer;
  orig: TBGRALayerCustomOriginal;
begin
  FLayerId := ALayerId;
  imgState := ADestination as TImageState;
  layerIdx := imgState.LayeredBitmap.GetLayerIndexFromId(FLayerId);
  orig := imgState.LayerOriginal[layerIdx];
  if not (orig is TVectorOriginal) then
  begin
    AShape.Free;
    raise exception.Create('Vector original expected');
  end;
  if AShapeIndex = -1 then AShapeIndex := TVectorOriginal(orig).ShapeCount;
  FShapeIndex:= AShapeIndex;
  FShapeCopy := AShape.Duplicate;

  inherited ApplyTo(ADestination);
  TVectorOriginal(orig).InsertShape(AShape, FShapeIndex);
  FShapeId := TVectorOriginal(orig).Shape[FShapeIndex].Id;
  TVectorOriginal(orig).SelectShape(FShapeIndex);
  FShapeBounds := imgState.LayeredBitmap.RenderOriginalIfNecessary(orig.Guid);
end;

destructor TAddShapeToVectorOriginalDifference.Destroy;
begin
  FShapeCopy.Free;
  inherited Destroy;
end;

procedure TAddShapeToVectorOriginalDifference.ApplyTo(AState: TState);
var
  imgState: TImageState;
  layerIdx: Integer;
  orig: TBGRALayerCustomOriginal;
  shape: TVectorShape;
begin
  inherited ApplyTo(AState);
  imgState := AState as TImageState;
  layerIdx := imgState.LayeredBitmap.GetLayerIndexFromId(FLayerId);
  orig := imgState.LayerOriginal[layerIdx];
  if not (orig is TVectorOriginal) then
    raise exception.Create('Vector original expected');

  shape := FShapeCopy.Duplicate;
  TVectorOriginal(orig).InsertShape(shape, FShapeIndex);
  TVectorOriginal(orig).Shape[FShapeIndex].Id := FShapeId;
  TVectorOriginal(orig).SelectShape(FShapeIndex);
  imgState.LayeredBitmap.RenderLayerFromOriginal(layerIdx);
end;

procedure TAddShapeToVectorOriginalDifference.UnapplyTo(AState: TState);
var
  imgState: TImageState;
  layerIdx: Integer;
  orig: TBGRALayerCustomOriginal;
begin
  inherited UnapplyTo(AState);
  imgState := AState as TImageState;
  layerIdx := imgState.LayeredBitmap.GetLayerIndexFromId(FLayerId);
  orig := imgState.LayerOriginal[layerIdx];
  if not (orig is TVectorOriginal) then
    raise exception.Create('Vector original expected');
  TVectorOriginal(orig).RemoveShape(TVectorOriginal(orig).Shape[FShapeIndex]);
end;

{ TReplaceLayerByVectorOriginalDifference }

function TReplaceLayerByVectorOriginalDifference.CreateOriginal(AState: TState;
  ALayerIndex: integer): TBGRALayerCustomOriginal;
var
  source: TBGRABitmap;
  temp: TBGRABitmap;
  imgState: TImageState;
  orig: TVectorOriginal;
  shape: TRectShape;
begin
  imgState := TImageState(AState);
  orig := TVectorOriginal.Create;
  source := imgState.LayeredBitmap.LayerBitmap[ALayerIndex];
  if not source.Empty then
  begin
    shape := TRectShape.Create(orig);
    shape.QuickDefine(PointF(0,0),PointF(FSourceBounds.Width,FSourceBounds.Height));
    shape.PenStyle := ClearPenStyle;
    temp := source.GetPart(FSourceBounds) as TBGRABitmap;
    shape.BackFill.SetTexture(temp,AffineMatrixIdentity);
    temp.FreeReference;
    orig.AddShape(shape);
  end;
  result := orig;
end;

{ TReplaceLayerByImageOriginalDifference }

function TReplaceLayerByImageOriginalDifference.CreateOriginal(AState: TState; ALayerIndex: integer): TBGRALayerCustomOriginal;
var
  source: TBGRABitmap;
  temp: TBGRACustomBitmap;
  imgState: TImageState;
  orig: TBGRALayerImageOriginal;
begin
  imgState := TImageState(AState);
  orig := TBGRALayerImageOriginal.Create;
  source := imgState.LayeredBitmap.LayerBitmap[ALayerIndex];
  if (FSourceBounds.Width <> source.Width) or (FSourceBounds.Height <> source.Height) then
  begin
    temp := source.GetPart(FSourceBounds);
    orig.AssignImage(temp);
    temp.Free;
  end else
    orig.AssignImage(source);
  result := orig;
end;

{ TSelectionTransformDifference }

function TSelectionTransformDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  if Assigned(FPrevSelectionMask) then
  begin
    if Assigned(FPrevSelectionLayer) then
      Result:= idkChangeImageAndSelection
    else
      Result:= idkChangeSelection;
  end else
    if Assigned(FPrevSelectionLayer) then
      Result:= idkChangeImage;
end;

function TSelectionTransformDifference.GetIsIdentity: boolean;
begin
  Result:= IsAffineMatrixIdentity(FPrevTransform);
end;

function TSelectionTransformDifference.TryCompress: boolean;
begin
  Result:= (Assigned(FPrevSelectionMask) and FPrevSelectionMask.Compress) or
           (Assigned(FPrevSelectionLayer) and FPrevSelectionLayer.Compress);
end;

constructor TSelectionTransformDifference.Create(ADestination: TState;
  AApplyNow: boolean);
var
  ImgState: TImageState;
begin
  inherited Create(ADestination);
  ImgState := ADestination as TImageState;
  FPrevTransform := ImgState.SelectionTransform;
  if not ImgState.SelectionMaskEmpty then
    FPrevSelectionMask := TStoredImage.Create(ImgState.SelectionMask)
  else
    FPrevSelectionMask := nil;
  if not ImgState.SelectionLayerEmpty then
    FPrevSelectionLayer := TStoredImage.Create(ImgState.SelectionLayer)
  else
    FPrevSelectionLayer := nil;
  if AApplyNow then ApplyTo(ADestination);
end;

destructor TSelectionTransformDifference.Destroy;
begin
  FPrevSelectionMask.Free;
  FPrevSelectionLayer.Free;
  inherited Destroy;
end;

procedure TSelectionTransformDifference.ApplyTo(AState: TState);
var
  ImgState: TImageState;
  newBmp: TBGRABitmap;
  newLeft, newTop: integer;
  r: TRect;
begin
  inherited ApplyTo(AState);
  if not IsIdentity then
  begin
    ImgState := AState as TImageState;
    if not ImgState.SelectionMaskEmpty then
    begin
      ImgState.ComputeTransformedSelectionMask(newBmp,newLeft,newTop);
      r := ImgState.GetSelectionMaskBounds;
      ImgState.SelectionMask.FillRect(r, BGRABlack, dmSet);
      ImgState.SelectionMask.PutImage(newLeft,newTop,newBmp,dmSet);
      newBmp.Free;
    end;
    if not ImgState.SelectionLayerEmpty then
    begin
      ImgState.ComputeTransformedSelectionLayer(newBmp,newLeft,newTop);
      r := ImgState.GetSelectionLayerBounds;
      ImgState.SelectionLayer.FillRect(r, BGRAPixelTransparent, dmSet);
      ImgState.SelectionLayer.PutImage(newLeft,newTop,newBmp,dmSet);
      newBmp.Free;
    end;
    ImgState.SelectionTransform := AffineMatrixIdentity;
    ImgState.DiscardSelectionMaskBounds;
    ImgState.DiscardSelectionLayerBounds;
  end;
end;

procedure TSelectionTransformDifference.UnapplyTo(AState: TState);
var
  ImgState: TImageState;
  prevMask, prevSelectionLayer: TBGRABitmap;
begin
  if not IsIdentity then
  begin
    ImgState := AState as TImageState;
    if Assigned(FPrevSelectionMask) then prevMask := FPrevSelectionMask.GetBitmap else prevMask := nil;
    if Assigned(FPrevSelectionLayer) then prevSelectionLayer := FPrevSelectionLayer.GetBitmap else prevSelectionLayer := nil;
    ImgState.ReplaceSelection(prevMask, prevSelectionLayer);
    ImgState.DiscardSelectionMaskBounds;
    ImgState.DiscardSelectionLayerBounds;
    ImgState.SelectionTransform := FPrevTransform;
  end;
  inherited UnapplyTo(AState);
end;

{ TReplaceLayerByOriginalDifference }

function TReplaceLayerByOriginalDifference.GetLayerId: integer;
begin
  result := FPreviousLayerContent.LayerId;
end;

function TReplaceLayerByOriginalDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeImage;
end;

constructor TReplaceLayerByOriginalDifference.Create(
  AFromState: TState; AIndex: integer; AAlwaysStoreBitmap: boolean);
var
  imgState: TImageState;
begin
  inherited Create(AFromState);
  imgState := AFromState as TImageState;
  FPreviousLayerContent := TStoredLayer.Create(imgState.LayeredBitmap, AIndex, AAlwaysStoreBitmap);
  FSourceBounds := imgState.LayeredBitmap.LayerBitmap[AIndex].GetImageBounds;
  with FPreviousLayerContent.Offset do FPrevMatrix := AffineMatrixTranslation(x+FSourceBounds.Left,y+FSourceBounds.Top);
  FNextMatrix := FPrevMatrix;
  ApplyTo(imgState);
end;

function TReplaceLayerByOriginalDifference.UsedMemory: int64;
begin
  Result:= FPreviousLayerContent.UsedMemory;
end;

function TReplaceLayerByOriginalDifference.TryCompress: boolean;
begin
  Result:= FPreviousLayerContent.Compress;
end;

procedure TReplaceLayerByOriginalDifference.ApplyTo(AState: TState);
var
  imgState: TImageState;
  orig: TBGRALayerCustomOriginal;
  origIndex,layerIdx: Integer;
begin
  inherited ApplyTo(AState);
  imgState := AState as TImageState;
  layerIdx := imgState.LayeredBitmap.GetLayerIndexFromId(FPreviousLayerContent.LayerId);
  orig := CreateOriginal(imgState, layerIdx);
  if FOriginalGuid <> GUID_NULL then orig.Guid := FOriginalGuid;
  origIndex := imgState.LayeredBitmap.AddOriginal(orig, true);
  if FOriginalGuid = GUID_NULL then FOriginalGuid := orig.Guid;
  imgState.LayeredBitmap.LayerOriginalGuid[layerIdx] := imgState.LayeredBitmap.OriginalGuid[origIndex];
  imgState.LayeredBitmap.LayerOriginalMatrix[layerIdx] := FNextMatrix;
  if FNextMatrix = FPrevMatrix then
    imgState.LayeredBitmap.LayerOriginalRenderStatus[layerIdx] := orsProof
  else
  begin
    imgState.LayeredBitmap.LayerOriginalRenderStatus[layerIdx] := orsNone;
    imgState.LayeredBitmap.RenderLayerFromOriginal(layerIdx);
  end;
end;

procedure TReplaceLayerByOriginalDifference.UnapplyTo(AState: TState);
var
  imgState: TImageState;
begin
  inherited UnapplyTo(AState);
  imgState := AState as TImageState;
  FPreviousLayerContent.Replace(imgState.LayeredBitmap);
end;

destructor TReplaceLayerByOriginalDifference.Destroy;
begin
  FPreviousLayerContent.Free;
  inherited Destroy;
end;

{ TSetSelectionTransformDifference }

function TSetSelectionTransformDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeImageAndSelection;
end;

function TSetSelectionTransformDifference.GetIsIdentity: boolean;
begin
  Result:= previousMatrix = nextMatrix;
end;

constructor TSetSelectionTransformDifference.Create(ADestination: TState;
  ANextMatrix: TAffineMatrix);
var
  imgState: TImageState;
begin
  imgState := ADestination as TImageState;
  previousMatrix := imgState.SelectionTransform;
  nextMatrix := ANextMatrix;
end;

procedure TSetSelectionTransformDifference.ApplyTo(AState: TState);
var
  imgState: TImageState;
begin
  inherited ApplyTo(AState);
  imgState := AState as TImageState;
  imgState.SelectionTransform := nextMatrix;
end;

procedure TSetSelectionTransformDifference.UnapplyTo(AState: TState);
var
  imgState: TImageState;
begin
  inherited UnapplyTo(AState);
  imgState := AState as TImageState;
  imgState.SelectionTransform := previousMatrix;
end;

{ TDiscardOriginalStateDifference }

function TDiscardOriginalStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeStack;
end;

function TDiscardOriginalStateDifference.UsedMemory: int64;
begin
  if Assigned(origData) then
    result := origData.Size
  else
    result := 0;
end;

function TDiscardOriginalStateDifference.TryCompress: boolean;
begin
  Result:= false;
end;

procedure TDiscardOriginalStateDifference.ApplyTo(AState: TState);
var
  imgState: TImageState;
  idx: Integer;
begin
  imgState := AState as TImageState;
  idx := imgState.LayeredBitmap.GetLayerIndexFromId(layerId);
  imgState.LayeredBitmap.LayerOriginalGuid[idx] := GUID_NULL;
  imgState.LayeredBitmap.LayerOriginalMatrix[idx] := AffineMatrixIdentity;
  imgState.LayeredBitmap.RemoveUnusedOriginals;
end;

procedure TDiscardOriginalStateDifference.UnapplyTo(AState: TState);
var
  imgState: TImageState;
  idx, idxOrig: Integer;
begin
  imgState := AState as TImageState;
  idx := imgState.LayeredBitmap.GetLayerIndexFromId(layerId);
  if Assigned(origData) then
  begin
    origData.Position:= 0;
    idxOrig := imgState.LayeredBitmap.AddOriginalFromStream(origData, true);
    imgState.LayeredBitmap.LayerOriginalGuid[idx] := imgState.LayeredBitmap.OriginalGuid[idxOrig];
    imgState.LayeredBitmap.LayerOriginalMatrix[idx] := origMatrix;
    imgState.LayeredBitmap.LayerOriginalRenderStatus[idx] := origRenderStatus;
  end;
end;

constructor TDiscardOriginalStateDifference.Create(AState: TState; AIndex: integer);
var
  imgState: TImageState;
begin
  inherited Create(AState);
  imgState := AState as TImageState;
  if imgState.LayeredBitmap = nil then
    raise exception.Create('Layered bitmap not created');
  AIndex := AIndex;
  if AIndex = -1 then raise exception.Create('No layer selected');
  layerId:= imgState.LayerId[AIndex];
  if imgState.LayerOriginalDefined[AIndex] then
  begin
    origData := TMemoryStream.Create;
    imgState.LayeredBitmap.SaveOriginalToStream(imgState.LayeredBitmap.LayerOriginalGuid[AIndex], origData);
    origMatrix := imgState.LayeredBitmap.LayerOriginalMatrix[AIndex];
    origRenderStatus:= imgState.LayeredBitmap.LayerOriginalRenderStatus[AIndex];
  end else
  begin
    origData := nil;
    origMatrix := AffineMatrixIdentity;
    origRenderStatus:= orsNone;
  end;
end;

destructor TDiscardOriginalStateDifference.Destroy;
begin
  origData.Free;
  inherited Destroy;
end;

{ TSetLayerMatrixDifference }

function TSetLayerMatrixDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeImage;
end;

function TSetLayerMatrixDifference.GetIsIdentity: boolean;
begin
  Result:= nextMatrix = previousMatrix;
end;

constructor TSetLayerMatrixDifference.Create(ADestination: TState;
  ALayerId: integer; APreviousMatrix, ANextMatrix: TAffineMatrix);
begin
  layerId:= ALayerId;
  previousMatrix := APreviousMatrix;
  nextMatrix := ANextMatrix;
end;

procedure TSetLayerMatrixDifference.ApplyTo(AState: TState);
var
  idx: Integer;
begin
  inherited ApplyTo(AState);
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.LayerOriginalMatrix[idx] := nextMatrix;
  TImageState(AState).LayeredBitmap.RenderLayerFromOriginal(idx);
end;

procedure TSetLayerMatrixDifference.UnapplyTo(AState: TState);
var
  idx: Integer;
begin
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.LayerOriginalMatrix[idx] := previousMatrix;
  TImageState(AState).LayeredBitmap.RenderLayerFromOriginal(idx);
end;

{ TSelectCurrentLayer }

function TSelectCurrentLayer.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeImage; //selection layer can affect image
end;

constructor TSelectCurrentLayer.Create(AState: TState; ANewLayerIndex: integer);
begin
  inherited Create(AState.saved, AState.saved);
  FPrevLayerIndex:= (AState as TImageState).SelectedImageLayerIndex;
  FNewLayerIndex:= ANewLayerIndex;
end;

procedure TSelectCurrentLayer.ApplyTo(AState: TState);
begin
  (AState as TImageState).SelectedImageLayerIndex:= FNewLayerIndex;
end;

procedure TSelectCurrentLayer.UnApplyTo(AState: TState);
begin
  (AState as TImageState).SelectedImageLayerIndex:= FPrevLayerIndex;
end;

function TSelectCurrentLayer.ToString: ansistring;
begin
  Result:= ClassName+'('+IntToStr(FPrevLayerIndex)+' to '+IntToStr(FNewLayerIndex)+')';
end;

{ TAddLayerFromOwnedOriginalStateDifference }

function TAddLayerFromOwnedOriginalStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeImage;
end;

procedure TAddLayerFromOwnedOriginalStateDifference.Uncompress;
var
  decompression: Tdecompressionstream;
  uncompressedSize: Int64;
begin
  if Assigned(compressedData) and not Assigned(originalData) then
  begin
    originalData:= TMemoryStream.Create;
    compressedData.Position := 0;
    uncompressedSize:= 0;
    compressedData.ReadBuffer(uncompressedSize, sizeof(uncompressedSize));
    decompression := Tdecompressionstream.Create(compressedData, true);
    originalData.CopyFrom(decompression, uncompressedSize);
    decompression.Free;
    FreeAndNil(compressedData);
  end
end;

function TAddLayerFromOwnedOriginalStateDifference.UsedMemory: int64;
begin
  if Assigned(originalData) then
    result := originalData.Size
  else
  if Assigned(compressedData) then
    result := compressedData.Size
  else
    result := 0;
end;

function TAddLayerFromOwnedOriginalStateDifference.TryCompress: boolean;
var
  compression: Tcompressionstream;
  uncompressedSize: Int64;
begin
  if Assigned(originalData) and not Assigned(compressedData) then
  begin
    compressedData:= TMemoryStream.Create;
    uncompressedSize := originalData.Size;
    compressedData.WriteBuffer(uncompressedSize, sizeof(uncompressedSize));
    compression := Tcompressionstream.Create(cldefault, compressedData, true);
    originalData.Position:= 0;
    compression.CopyFrom(originalData, originalData.Size);
    compression.Free;
    FreeAndNil(originalData);
    result := true;
  end
  else
    result := false;
end;

procedure TAddLayerFromOwnedOriginalStateDifference.ApplyTo(AState: TState);
var idx, origIdx: integer;
begin
  inherited ApplyTo(AState);
  Uncompress;
  if not Assigned(originalData) then
    raise exception.Create('Original data missing');

  with AState as TImageState do
  begin
    originalData.Position:= 0;
    origIdx:= LayeredBitmap.AddOriginalFromStream(originalData);
    idx := LayeredBitmap.AddLayerFromOriginal(LayeredBitmap.Original[origIdx].Guid, self.blendOp);
    LayeredBitmap.LayerUniqueId[idx] := self.layerId;
    LayeredBitmap.LayerName[idx] := name;
    LayeredBitmap.LayerOriginalMatrix[idx] := matrix;
    LayeredBitmap.RenderLayerFromOriginal(idx);
    SelectedImageLayerIndex := idx;
  end;
end;

procedure TAddLayerFromOwnedOriginalStateDifference.UnapplyTo(AState: TState);
var idx: integer;
begin
  inherited UnapplyTo(AState);
  with AState as TImageState do
  begin
    idx := LayeredBitmap.GetLayerIndexFromId(self.layerId);
    LayeredBitmap.RemoveLayer(idx);
    SelectedImageLayerIndex := LayeredBitmap.GetLayerIndexFromId(self.previousActiveLayerId);
  end;
end;

constructor TAddLayerFromOwnedOriginalStateDifference.Create(ADestination: TState;
  AOriginal: TBGRALayerCustomOriginal; AName: ansistring;
  ABlendOp: TBlendOperation; AMatrix: TAffineMatrix);
var idx: integer;
  imgDest: TImageState;
begin
  inherited Create(ADestination);
  imgDest := ADestination as TImageState;
  if imgDest.LayeredBitmap = nil then
    raise exception.Create('Layered bitmap not created');

  self.originalData := TMemoryStream.Create;
  AOriginal.SaveToStream(originalData);

  self.name := AName;
  self.blendOp:= AblendOp;
  self.matrix := AMatrix;
  self.previousActiveLayerId := imgDest.LayeredBitmap.LayerUniqueId[imgDest.SelectedImageLayerIndex];
  idx := imgDest.LayeredBitmap.AddLayerFromOwnedOriginal(AOriginal, ABlendOp);
  imgDest.LayeredBitmap.LayerName[idx] := name;
  imgDest.LayeredBitmap.LayerOriginalMatrix[idx] := matrix;
  self.layerId := imgDest.LayeredBitmap.LayerUniqueId[idx];
  imgDest.LayeredBitmap.RenderLayerFromOriginal(idx);
  imgDest.SelectedImageLayerIndex := idx;
end;

destructor TAddLayerFromOwnedOriginalStateDifference.Destroy;
begin
  originalData.Free;
  compressedData.Free;
  inherited Destroy;
end;

{ TApplyLayerOffsetStateDifference }

function TApplyLayerOffsetStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeImage;
end;

function TApplyLayerOffsetStateDifference.GetIsIdentity: boolean;
begin
  Result:= (previousBounds.Left = nextBounds.Left) and (previousBounds.Top = nextBounds.Top) and
     (previousBounds.right = nextBounds.Right) and (previousBounds.bottom = nextBounds.Bottom);
end;

function TApplyLayerOffsetStateDifference.GetChangingBoundsDefined: boolean;
begin
  Result:= true;
end;

function TApplyLayerOffsetStateDifference.GetChangingBounds: TRect;
begin
  Result:= EmptyRect;
end;

constructor TApplyLayerOffsetStateDifference.Create(ADestination: TState;
  ALayerId: integer; AOffsetX, AOffsetY: integer; AApplyNow: boolean);
var idx: integer;
  layers: TBGRALayeredBitmap;
  clippedImage: TBGRABitmap;
begin
  inherited Create(ADestination);
  FDestination := ADestination;
  layerId:= ALayerId;
  layers := (FDestination as TImageState).LayeredBitmap;
  idx := layers.GetLayerIndexFromId(ALayerId);
  if idx = -1 then raise exception.Create('Invalid layer Id');
  nextBounds := rect(0,0,layers.Width,layers.Height);
  previousBounds.Left := AOffsetX;
  previousBounds.Top := AOffsetY;
  previousBounds.Right := previousBounds.Left+layers.LayerBitmap[idx].Width;
  previousBounds.Bottom := previousBounds.Top+layers.LayerBitmap[idx].Height;
  previousLayerOffset := layers.LayerOffset[idx];
  if IsIdentity then
  begin
    clippedData := nil;
    useOriginal := false;
    unchangedBounds := previousBounds;
  end else
  begin
    unchangedBounds := previousBounds;
    IntersectRect(unchangedBounds, unchangedBounds, nextBounds);
    OffsetRect(unchangedBounds, -AOffsetX, -AOffsetY);
    useOriginal:= layers.LayerOriginalGuid[idx]<>GUID_NULL;
    previousOriginalRenderStatus:= layers.LayerOriginalRenderStatus[idx];

    clippedImage := layers.LayerBitmap[idx].Duplicate as TBGRABitmap;
    clippedImage.FillRect(unchangedBounds,BGRAPixelTransparent,dmSet);
    clippedData := TMemoryStream.Create;
    TBGRAWriterLazPaint.WriteRLEImage(clippedData, clippedImage);
    clippedImage.Free;
  end;
  if AApplyNow then ApplyTo(ADestination);
end;

destructor TApplyLayerOffsetStateDifference.Destroy;
begin
  FreeAndNil(clippedData);
  inherited Destroy;
end;

procedure TApplyLayerOffsetStateDifference.ApplyTo(AState: TState);
var idx: integer;
begin
  inherited ApplyTo(AState);
  if IsIdentity then exit;
  idx := (AState as TImageState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then raise exception.Create('Layer not found');
  (AState as TImageState).LayeredBitmap.ApplyLayerOffset(idx, true);
end;

procedure TApplyLayerOffsetStateDifference.UnapplyTo(AState: TState);
var idx: integer;
  newContent: TBGRABitmap;
  layers: TBGRALayeredBitmap;
  shifted: TRect;
  dummyCaption: ansistring;
  guid: TGuid;
  m: TAffineMatrix;
begin
  inherited ApplyTo(AState);
  if IsIdentity then exit;
  layers := (AState as TImageState).LayeredBitmap;
  idx := layers.GetLayerIndexFromId(layerId);
  if idx =-1 then
    raise exception.Create('Layer not found');

  newContent := TBGRABitmap.Create;
  clippedData.Position:= 0;
  TBGRAReaderLazPaint.LoadRLEImage(clippedData,newContent,dummyCaption);
  shifted := unchangedBounds;
  OffsetRect(shifted, previousBounds.left-nextBounds.left,previousBounds.top-nextBounds.top);
  newContent.PutImagePart(unchangedBounds.Left,unchangedBounds.Top, layers.LayerBitmap[idx],shifted, dmSet);
  guid := layers.LayerOriginalGuid[idx];
  m := layers.LayerOriginalMatrix[idx];
  layers.SetLayerBitmap(idx,newContent,True);
  layers.LayerOffset[idx] := previousLayerOffset;
  if useOriginal then
  begin
    layers.LayerOriginalGuid[idx] := guid;
    layers.LayerOriginalMatrix[idx] := m;
    layers.LayerOriginalRenderStatus[idx] := previousOriginalRenderStatus;
  end;
end;

{ TSetLayerOffsetStateDifference }

function TSetLayerOffsetStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeImage;
end;

function TSetLayerOffsetStateDifference.GetIsIdentity: boolean;
begin
  Result:=(previousOffset.x = nextOffset.x) and (previousOffset.y = nextOffset.y);
end;

constructor TSetLayerOffsetStateDifference.Create(ADestination: TState;
  ALayerId: integer; ANewOffset: TPoint);
var idx: integer;
  imgDest: TImageState;
begin
  inherited Create(Adestination);
  imgDest := ADestination as TImageState;
  layerId:= ALayerId;
  nextOffset:= ANewOffset;
  idx := imgDest.LayeredBitmap.GetLayerIndexFromId(ALayerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  previousOffset:= imgDest.LayerOffset[idx];
  ApplyTo(imgDest);
end;

procedure TSetLayerOffsetStateDifference.ApplyTo(AState: TState);
var idx: integer;
begin
  inherited ApplyTo(AState);
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.LayerOffset[idx] := nextOffset;
end;

procedure TSetLayerOffsetStateDifference.UnapplyTo(AState: TState);
var idx: integer;
begin
  inherited UnapplyTo(AState);
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.LayerOffset[idx] := previousOffset;
end;

{ TSetLayerBlendOpStateDifference }

function TSetLayerBlendOpStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeLayer;
end;

function TSetLayerBlendOpStateDifference.GetIsIdentity: boolean;
begin
  Result:=previousBlendOp = nextBlendOp;
end;

constructor TSetLayerBlendOpStateDifference.Create(ADestination: TState;
  ALayerId: integer; ANewBlendOp: TBlendOperation);
var idx: integer;
  imgDest: TImageState;
begin
  inherited Create(Adestination);
  imgDest := ADestination as TImageState;
  layerId:= ALayerId;
  nextBlendOp:= ANewBlendOp;
  idx := imgDest.LayeredBitmap.GetLayerIndexFromId(ALayerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  previousBlendOp:= imgDest.BlendOperation[idx];
  ApplyTo(imgDest);
end;

procedure TSetLayerBlendOpStateDifference.ApplyTo(AState: TState);
var idx: integer;
begin
  inherited ApplyTo(AState);
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.BlendOperation[idx] := nextBlendOp;
end;

procedure TSetLayerBlendOpStateDifference.UnapplyTo(AState: TState);
var idx: integer;
begin
  inherited UnapplyTo(AState);
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.BlendOperation[idx] := previousBlendOp;
end;

{ TSetLayerVisibleStateDifference }

function TSetLayerVisibleStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeLayer;
end;

function TSetLayerVisibleStateDifference.GetIsIdentity: boolean;
begin
  Result:= previousVisible=nextVisible;
end;

constructor TSetLayerVisibleStateDifference.Create(ADestination: TState;
  ALayerId: integer; ANewVisible: boolean);
var idx: integer;
  imgDest: TImageState;
begin
  inherited Create(Adestination);
  imgDest := ADestination as TImageState;
  layerId:= ALayerId;
  nextVisible:= ANewVisible;
  idx := imgDest.LayeredBitmap.GetLayerIndexFromId(ALayerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  previousVisible:= imgDest.LayerVisible[idx];
  ApplyTo(imgDest);
end;

procedure TSetLayerVisibleStateDifference.ApplyTo(AState: TState);
var idx: integer;
begin
  inherited ApplyTo(AState);
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.LayerVisible[idx] := nextVisible;
end;

procedure TSetLayerVisibleStateDifference.UnapplyTo(AState: TState);
var idx: integer;
begin
  inherited UnapplyTo(AState);
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.LayerVisible[idx] := previousVisible;
end;

{ TSetLayerOpacityStateDifference }

function TSetLayerOpacityStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeLayer;
end;

function TSetLayerOpacityStateDifference.GetIsIdentity: boolean;
begin
  Result:= (previousOpacity=nextOpacity);
end;

constructor TSetLayerOpacityStateDifference.Create(ADestination: TState;
  ALayerId: integer; ANewOpacity: byte);
var idx: integer;
  imgDest: TImageState;
begin
  inherited Create(Adestination);
  imgDest := ADestination as TImageState;
  layerId:= ALayerId;
  nextOpacity:= ANewOpacity;
  idx := imgDest.LayeredBitmap.GetLayerIndexFromId(ALayerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  previousOpacity:= imgDest.LayerOpacity[idx];
  ApplyTo(imgDest);
end;

procedure TSetLayerOpacityStateDifference.ApplyTo(AState: TState);
var idx: integer;
begin
  inherited ApplyTo(AState);
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.LayerOpacity[idx] := nextOpacity;
end;

procedure TSetLayerOpacityStateDifference.UnapplyTo(AState: TState);
var idx: integer;
begin
  inherited UnapplyTo(AState);
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.LayerOpacity[idx] := previousOpacity;
end;

{ TSetLayerNameStateDifference }

function TSetLayerNameStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeStack;
end;

function TSetLayerNameStateDifference.GetIsIdentity: boolean;
begin
  Result:= (previousName=nextName);
end;

constructor TSetLayerNameStateDifference.Create(ADestination: TState;
  ALayerId: integer; ANewName: ansistring);
var idx: integer;
  imgDest: TImageState;
begin
  inherited Create(Adestination);
  imgDest := ADestination as TImageState;
  layerId:= ALayerId;
  nextName:= ANewName;
  idx := imgDest.LayeredBitmap.GetLayerIndexFromId(ALayerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  previousName:= imgDest.LayerName[idx];
  ApplyTo(imgDest);
end;

procedure TSetLayerNameStateDifference.ApplyTo(AState: TState);
var idx: integer;
begin
  inherited ApplyTo(AState);
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.LayerName[idx] := nextName;
end;

procedure TSetLayerNameStateDifference.UnapplyTo(AState: TState);
var idx: integer;
begin
  inherited ApplyTo(AState);
  idx := TImageState(AState).LayeredBitmap.GetLayerIndexFromId(layerId);
  if idx =-1 then
    raise exception.Create('Layer not found');
  TImageState(AState).LayeredBitmap.LayerName[idx] := previousName;
end;

function TSetLayerNameStateDifference.ToString: ansistring;
begin
  Result:=ClassName+'('+QuotedStr(previousName)+' to '+QuotedStr(nextName)+')';
end;

{ TAssignStateDifferenceAfter }

constructor TAssignStateDifferenceAfter.Create(AState: TState; ABackup: TState);
var imgState,imgBackup: TImageState;
begin
  imgState := AState as TImageState;
  imgBackup := ABackup as TImageState;
  FSavedBefore := imgState.saved;
  FSavedAfter := False;
  FStreamBefore := TMemoryStream.Create;
  SaveLayersToStream(FStreamBefore,imgBackup.LayeredBitmap,imgBackup.SelectedImageLayerIndex,lzpRLE);
  FStreamAfter := TMemoryStream.Create;
  SaveLayersToStream(FStreamAfter,imgState.LayeredBitmap,imgState.SelectedImageLayerIndex,lzpRLE);
  FSelectionDiff := TImageDiff.Create(imgBackup.SelectionMask, imgState.SelectionMask);
  FSelectionLayerDiff := TImageDiff.Create(imgBackup.SelectionLayer, imgState.SelectionLayer);
end;

{ TAssignStateDifference }

procedure TAssignStateDifference.Init(AState: TState; AValue: TBGRALayeredBitmap; AOwned: boolean; ASelectedLayerIndex: integer);
begin
  with AState as TImageState do
  begin
    FStreamBefore := TMemoryStream.Create;
    SaveLayersToStream(FStreamBefore,LayeredBitmap,SelectedImageLayerIndex,lzpRLE);
    FStreamAfter := TMemoryStream.Create;
    SaveLayersToStream(FStreamAfter,AValue,ASelectedLayerIndex,lzpRLE);
    Assign(AValue, AOwned);
    SelectedImageLayerIndex := ASelectedLayerIndex;
  end;
  FSelectionDiff := nil;
  FSelectionLayerDiff := nil;
end;

constructor TAssignStateDifference.Create(AState: TState;
  AValue: TBGRALayeredBitmap; AOwned: boolean; ASelectedLayerIndex: integer);
begin
  inherited Create(AState);
  Init(AState,AValue,AOwned,ASelectedLayerIndex);
end;

constructor TAssignStateDifference.Create(AState: TState;
  AValue: TBGRALayeredBitmap; AOwned: boolean; ASelectedLayerIndex: integer;
  ACurrentSelection: TBGRABitmap; ASelectionLayer: TBGRABitmap);
begin
  inherited Create(AState);
  Init(AState,AValue,AOwned,ASelectedLayerIndex);
  FSelectionDiff := TImageDiff.Create((AState as TImageState).SelectionMask, ACurrentSelection);
  FSelectionLayerDiff := TImageDiff.Create((AState as TImageState).SelectionLayer, ASelectionLayer);
  (AState as TImageState).ReplaceSelection(ACurrentSelection, ASelectionLayer);
end;

function TAssignStateDifference.UsedMemory: int64;
begin
  Result:= 0;
  if Assigned(FStreamBefore) then result += FStreamBefore.Size;
  if Assigned(FStreamAfter) then result += FStreamAfter.Size;
  if Assigned(FSelectionDiff) then result += FSelectionDiff.UsedMemory;
  if Assigned(FSelectionLayerDiff) then result += FSelectionLayerDiff.UsedMemory;
end;

function TAssignStateDifference.TryCompress: boolean;
begin
  result := false;
  if Assigned(FSelectionDiff) then result := result or FSelectionDiff.Compress;
  if not result and Assigned(FSelectionLayerDiff) then result := result or FSelectionLayerDiff.Compress;
end;

procedure TAssignStateDifference.ApplyTo(AState: TState);
var temp: TBGRALayeredBitmap;
  index: integer;
begin
  inherited ApplyTo(AState);
  FStreamAfter.Position:= 0;
  temp := LoadLayersFromStream(FStreamAfter, index, True);
  (AState as TImageState).Assign(temp, True);
  (AState as TImageState).SelectedImageLayerIndex := index;
  (AState as TImageState).ReplaceSelection( FSelectionDiff.ApplyCanCreateNew((AState as TImageState).SelectionMask,False),
                                            FSelectionLayerDiff.ApplyCanCreateNew((AState as TImageState).SelectionLayer,False) );
end;

procedure TAssignStateDifference.UnApplyTo(AState: TState);
var temp: TBGRALayeredBitmap;
  index: integer;
begin
  inherited UnapplyTo(AState);
  FStreamBefore.Position:= 0;
  temp := LoadLayersFromStream(FStreamBefore, index, True);
  (AState as TImageState).Assign(temp, True);
  (AState as TImageState).SelectedImageLayerIndex := index;
  (AState as TImageState).ReplaceSelection( FSelectionDiff.ApplyCanCreateNew((AState as TImageState).SelectionMask,true),
                                            FSelectionLayerDiff.ApplyCanCreateNew((AState as TImageState).SelectionLayer,true) );
end;

destructor TAssignStateDifference.Destroy;
begin
  FStreamBefore.Free;
  FStreamAfter.Free;
  FSelectionDiff.Free;
  FSelectionLayerDiff.Free;
  inherited Destroy;
end;

{ TInversibleStateDifference }

constructor TInversibleStateDifference.Create(AState: TState;
  AAction: TInversibleAction; ALayerIndex : integer = -1);
begin
  inherited Create(AState);
  FAction := AAction;
  FLayerIndex:= ALayerIndex;
  ApplyTo(AState);
end;

procedure TInversibleStateDifference.ApplyTo(AState: TState);
begin
  inherited ApplyTo(AState);
  ApplyAction(AState as TImageState, FAction, False);
end;

procedure TInversibleStateDifference.UnApplyTo(AState: TState);
begin
  inherited UnapplyTo(AState);
  ApplyAction(AState as TImageState, FAction, True);
end;

procedure TInversibleStateDifference.ApplyAction(AState: TState;
  AAction: TInversibleAction; AInverse: boolean);
var i: integer;
  imgState: TImageState;
  newSelectionMask, newSelectionLayer: TBGRABitmap;
begin
  imgState := AState as TImageState;
  if AInverse then AAction := GetInverseAction(AAction);
  case AAction of
  iaSwapRedBlue,iaLinearNegative:
    begin
      for i := 0 to imgState.NbLayers-1 do
        if imgState.LayerOriginalDefined[i] then
          raise exception.Create('Cannot do an inversible raster action with layer originals');
      case AAction of
        iaSwapRedBlue: begin
                         imgState.LayeredBitmap.Unfreeze;
                         for i := 0 to imgState.NbLayers-1 do imgState.LayerBitmap[i].SwapRedBlue;
                       end;
        iaLinearNegative:
           begin
             imgState.LayeredBitmap.Unfreeze;
             for i := 0 to imgState.NbLayers-1 do imgState.LayerBitmap[i].LinearNegative;
           end
      else
        raise exception.Create('Unhandled case');
      end;
    end;
  iaHorizontalFlip: imgState.LayeredBitmap.HorizontalFlip;
  iaHorizontalFlipLayer: imgState.LayeredBitmap.HorizontalFlip(FLayerIndex);
  iaVerticalFlip: imgState.LayeredBitmap.VerticalFlip;
  iaVerticalFlipLayer: imgState.LayeredBitmap.VerticalFlip(FLayerIndex);
  iaRotate180: begin
      imgState.LayeredBitmap.HorizontalFlip;
      imgState.LayeredBitmap.VerticalFlip;
    end;
  iaRotateCW: begin
      imgState.LayeredBitmap.RotateCW;
      if imgState.SelectionMask <> nil then newSelectionMask := imgState.SelectionMask.RotateCW as TBGRABitmap else newSelectionMask := nil;
      if imgState.SelectionLayer <> nil then newSelectionLayer := imgState.SelectionLayer.RotateCW as TBGRABitmap else newSelectionLayer := nil;
      imgState.ReplaceSelection(newSelectionMask, newSelectionLayer);
    end;
  iaRotateCCW: begin
      imgState.LayeredBitmap.RotateCCW;
      if imgState.SelectionMask <> nil then newSelectionMask := imgState.SelectionMask.RotateCCW as TBGRABitmap else newSelectionMask := nil;
      if imgState.SelectionLayer <> nil then newSelectionLayer := imgState.SelectionLayer.RotateCCW as TBGRABitmap else newSelectionLayer := nil;
      imgState.ReplaceSelection(newSelectionMask, newSelectionLayer);
    end;
  end;
end;

function TInversibleStateDifference.ToString: ansistring;
begin
  Result:= ClassName+'('+InversibleActionStr[FAction];
  if FLayerIndex <> -1 then result += ', '+inttostr(FLayerIndex);
  result += ')';
end;

{ TRemoveLayerStateDifference }

function TRemoveLayerStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:=idkChangeImage;
end;

function TRemoveLayerStateDifference.UsedMemory: int64;
begin
  if Assigned(content) then
    result := content.UsedMemory
  else
    result := 0;
end;

function TRemoveLayerStateDifference.TryCompress: boolean;
begin
  Result:= content.Compress;
end;

procedure TRemoveLayerStateDifference.ApplyTo(AState: TState);
var idx: integer;
begin
  inherited ApplyTo(AState);
  with AState as TImageState do
  begin
    idx := LayeredBitmap.GetLayerIndexFromId(content.LayerId);
    LayeredBitmap.RemoveLayer(idx);
    LayeredBitmap.RemoveUnusedOriginals;
    SelectedImageLayerIndex := LayeredBitmap.GetLayerIndexFromId(self.nextActiveLayerId);
  end;
end;

procedure TRemoveLayerStateDifference.UnapplyTo(AState: TState);
begin
  inherited UnapplyTo(AState);
  with AState as TImageState do
  begin
    content.Restore(LayeredBitmap);
    SelectedImageLayerIndex := content.LayerIndex;
  end;
end;

constructor TRemoveLayerStateDifference.Create(AState: TState);
var idx,nextIdx: integer;
  imgState: TImageState;
begin
  inherited Create(AState);
  imgState := AState as TImageState;
  if imgState.LayeredBitmap = nil then
    raise exception.Create('Layered bitmap not created');
  if imgState.NbLayers = 1 then
    raise exception.Create('Impossible to remove last layer');
  idx := imgState.SelectedImageLayerIndex;
  if idx = -1 then
    raise exception.Create('No layer selected');
  self.content := TStoredLayer.Create(imgState.LayeredBitmap, idx);
  if idx+1 < imgState.NbLayers then
    nextIdx := idx+1 else nextIdx := idx-1;
  self.nextActiveLayerId := imgState.LayeredBitmap.LayerUniqueId[nextIdx];
end;

destructor TRemoveLayerStateDifference.Destroy;
begin
  self.content.Free;
  inherited Destroy;
end;

{ TMergeLayerOverStateDifference }

function TMergeLayerOverStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeImage; //includes stack
end;

constructor TMergeLayerOverStateDifference.Create(ADestination: TState;
  ALayerOverIndex: integer);
var
  imgDest: TImageState;
begin
  inherited Create(ADestination);
  imgDest := ADestination as TImageState;
  if (ALayerOverIndex < 0) or (ALayerOverIndex >= imgDest.NbLayers) then
    raise exception.Create('Index out of bounds');
  if ALayerOverIndex = 0 then
    raise exception.Create('First layer cannot be merged over');

  layerOverIndex := ALayerOverIndex;
  with imgDest.LayeredBitmap do
  begin
    previousActiveLayerId:= LayerUniqueId[imgDest.SelectedImageLayerIndex];
    layerOverCompressedBackup := TStoredLayer.Create(imgDest.LayeredBitmap, ALayerOverIndex, true);
    layerUnderCompressedBackup := TStoredLayer.Create(imgDest.LayeredBitmap, ALayerOverIndex-1, true);
  end;

  //select layer under and merge
  ApplyTo(imgDest);
end;

function TMergeLayerOverStateDifference.UsedMemory: int64;
begin
  Result:=0;
  if Assigned(layerOverCompressedBackup) then result += layerOverCompressedBackup.UsedMemory;
  if Assigned(layerUnderCompressedBackup) then result += layerUnderCompressedBackup.UsedMemory;
end;

function TMergeLayerOverStateDifference.TryCompress: boolean;
begin
  result := layerOverCompressedBackup.Compress or layerUnderCompressedBackup.Compress;
end;

procedure TMergeLayerOverStateDifference.ApplyTo(AState: TState);
var
  merged: TBGRABitmap;
begin
  inherited ApplyTo(AState);
  with AState as TImageState do
  begin
    if layerOverIndex >= NbLayers then exit;

     SelectedImageLayerIndex := layerOverIndex-1;
     if (LayerBitmap[layerOverIndex-1].Width <> Width) or
        (LayerBitmap[layerOverIndex-1].Height <> Height) or
        (LayerOffset[layerOverIndex-1].X <> 0) or
        (LayerOffset[layerOverIndex-1].Y <> 0) then
     begin
       merged := TBGRABitmap.Create(Width,Height);
       merged.PutImage(LayerOffset[layerOverIndex-1].X,LayerOffset[layerOverIndex-1].Y,LayerBitmap[layerOverIndex-1],dmSet);
       merged.BlendImageOver(LayerOffset[layerOverIndex].X,LayerOffset[layerOverIndex].Y,LayerBitmap[layerOverIndex],
                             BlendOperation[layerOverIndex],LayerOpacity[layerOverIndex],LinearBlend);
       LayeredBitmap.SetLayerBitmap(layerOverIndex-1, merged,true);
       LayeredBitmap.LayerOffset[layerOverIndex-1] := Point(0,0);
     end else
     begin
       LayeredBitmap.LayerOriginalGuid[layerOverIndex-1] := GUID_NULL;
       LayeredBitmap.LayerOriginalMatrix[layerOverIndex-1] := AffineMatrixIdentity;
       LayerBitmap[layerOverIndex-1].BlendImageOver(LayerOffset[layerOverIndex].X,LayerOffset[layerOverIndex].Y,LayerBitmap[layerOverIndex],
                             BlendOperation[layerOverIndex],LayerOpacity[layerOverIndex],LinearBlend);
     end;
     LayeredBitmap.RemoveLayer(layerOverIndex);
     LayeredBitmap.RemoveUnusedOriginals;
  end;
end;

procedure TMergeLayerOverStateDifference.UnapplyTo(AState: TState);
begin
  inherited UnapplyTo(AState);
  with AState as TImageState do
  begin
    layerOverCompressedBackup.Restore(LayeredBitmap);
    layerUnderCompressedBackup.Replace(LayeredBitmap);

    //select previous layer
    SelectedImageLayerIndex := LayeredBitmap.GetLayerIndexFromId(Self.previousActiveLayerId);
  end;
end;

destructor TMergeLayerOverStateDifference.Destroy;
begin
  layerOverCompressedBackup.Free;
  layerUnderCompressedBackup.Free;
  inherited Destroy;
end;

{ TMoveLayerStateDifference }

function TMoveLayerStateDifference.GetIsIdentity: boolean;
begin
  Result:= (sourceIndex = destIndex);
end;

function TMoveLayerStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:=idkChangeImage; //includes stack
end;

procedure TMoveLayerStateDifference.ApplyTo(AState: TState);
begin
  inherited ApplyTo(AState);
  with AState as TImageState do
    LayeredBitmap.InsertLayer(destIndex, sourceIndex);
end;

procedure TMoveLayerStateDifference.UnapplyTo(AState: TState);
begin
  inherited UnapplyTo(AState);
  with AState as TImageState do
    LayeredBitmap.InsertLayer(sourceIndex, destIndex);
end;

constructor TMoveLayerStateDifference.Create(ADestination: TState;
  AFromIndex, AToIndex: integer);
begin
  inherited Create(ADestination);
  self.sourceIndex := AFromIndex;
  self.destIndex := AToIndex;
  ApplyTo(ADestination);
end;

{ TDuplicateLayerStateDifference }

function TDuplicateLayerStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:=idkChangeImage;
end;

procedure TDuplicateLayerStateDifference.ApplyTo(AState: TState);
var sourceLayerIndex,duplicateIndex: integer;
  copy: integer;
begin
  inherited ApplyTo(AState);
  with AState as TImageState do
  begin
    sourceLayerIndex := LayeredBitmap.GetLayerIndexFromId(self.sourceLayerId);
    duplicateIndex := sourceLayerIndex+1;
    with LayeredBitmap do
    begin
      copy := AddLayer(LayerBitmap[sourceLayerIndex],BlendOperation[sourceLayerIndex],LayerOpacity[sourceLayerIndex]);
      LayerName[copy] := LayerName[sourceLayerIndex];
      LayerOffset[copy] := LayerOffset[sourceLayerIndex];
      LayerVisible[copy] := LayerVisible[sourceLayerIndex];
      if useOriginal then
      begin
        LayerOriginalGuid[copy] := LayerOriginalGuid[sourceLayerIndex];
        LayerOriginalMatrix[copy] := LayerOriginalMatrix[sourceLayerIndex];
        LayerOriginalRenderStatus[copy] := LayerOriginalRenderStatus[sourceLayerIndex];
      end;
      LayerUniqueId[copy] := duplicateId;
      InsertLayer(duplicateIndex, copy);
    end;
    SelectedImageLayerIndex := duplicateIndex;
  end;
end;

procedure TDuplicateLayerStateDifference.UnapplyTo(AState: TState);
var sourceLayerIndex,duplicateIndex: integer;
begin
  inherited UnapplyTo(AState);
  with AState as TImageState do
  begin
    sourceLayerIndex := LayeredBitmap.GetLayerIndexFromId(self.sourceLayerId);
    duplicateIndex := LayeredBitmap.GetLayerIndexFromId(self.duplicateId);
    LayeredBitmap.RemoveLayer(duplicateIndex);
    SelectedImageLayerIndex := sourceLayerIndex;
  end;
end;

constructor TDuplicateLayerStateDifference.Create(ADestination: TState;
  AUseOriginal: boolean);
var imgDest: TImageState;
begin
  inherited Create(ADestination);
  imgDest := ADestination as TImageState;
  useOriginal:= AUseOriginal;
  with imgDest do
  begin
    self.sourceLayerId := LayeredBitmap.LayerUniqueId[SelectedImageLayerIndex];
    self.duplicateId := LayeredBitmap.ProduceLayerUniqueId;
  end;
  ApplyTo(imgDest);
end;

{ TAddLayerStateDifference }

function TAddLayerStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  Result:= idkChangeImage;
end;

function TAddLayerStateDifference.UsedMemory: int64;
begin
  if Assigned(content) then
    result := content.UsedMemory
  else
    result := 0;
end;

function TAddLayerStateDifference.TryCompress: boolean;
begin
  if Assigned(content) then
    Result := content.Compress
  else
    result := false;
end;

procedure TAddLayerStateDifference.ApplyTo(AState: TState);
var idx: integer;
  bmp: TBGRABitmap;
begin
  inherited ApplyTo(AState);
  with AState as TImageState do
  begin
    bmp := content.GetBitmap;
    if bmp = nil then
      raise exception.Create('Bitmap not found');
    idx := LayeredBitmap.AddOwnedLayer(bmp);
    LayeredBitmap.LayerUniqueId[idx] := self.layerId;
    LayeredBitmap.LayerName[idx] := name;
    LayeredBitmap.BlendOperation[idx] := self.blendOp;
    SelectedImageLayerIndex := idx;
  end;
end;

procedure TAddLayerStateDifference.UnapplyTo(AState: TState);
var idx: integer;
begin
  inherited UnapplyTo(AState);
  with AState as TImageState do
  begin
    idx := LayeredBitmap.GetLayerIndexFromId(self.layerId);
    LayeredBitmap.RemoveLayer(idx);
    SelectedImageLayerIndex := LayeredBitmap.GetLayerIndexFromId(self.previousActiveLayerId);
  end;
end;

constructor TAddLayerStateDifference.Create(ADestination: TState;
  AContent: TBGRABitmap; AName: ansistring; ABlendOp: TBlendOperation);
var idx: integer;
  imgDest: TImageState;
begin
  inherited Create(ADestination);
  imgDest := ADestination as TImageState;
  if imgDest.LayeredBitmap = nil then
    raise exception.Create('Layered bitmap not created');
  self.content := TStoredImage.Create(AContent);
  self.name := AName;
  self.blendOp:= AblendOp;
  self.previousActiveLayerId := imgDest.LayeredBitmap.LayerUniqueId[imgDest.SelectedImageLayerIndex];
  idx := imgDest.LayeredBitmap.AddLayer(AContent, ABlendOp);
  imgDest.LayeredBitmap.LayerName[idx] := name;
  self.layerId := imgDest.LayeredBitmap.LayerUniqueId[idx];
  imgDest.SelectedImageLayerIndex := idx;
end;

destructor TAddLayerStateDifference.Destroy;
begin
  self.content.Free;
  inherited Destroy;
end;

{ TImageLayerStateDifference }

function TImageLayerStateDifference.GetChangeImageLayer: boolean;
begin
  result := (imageDiff <> nil) and not imageDiff.IsIdentity;
end;

function TImageLayerStateDifference.GetChangeSelectionLayer: boolean;
begin
  result := (selectionLayerDiff <> nil) and not selectionLayerDiff.IsIdentity;
end;

function TImageLayerStateDifference.GetChangeSelectionMask: boolean;
begin
  result := (selectionMaskDiff <> nil) and not selectionMaskDiff.IsIdentity;
end;

function TImageLayerStateDifference.GetImageDifferenceKind: TImageDifferenceKind;
begin
  if ChangeImageLayer or ChangeSelectionLayer then
  begin
    if ChangeSelectionMask then
      result := idkChangeImageAndSelection
    else if ChangeSelectionLayer then
      result := idkChangeImage
    else
      result := idkChangeImage;
  end
  else if ChangeSelectionMask then
    result := idkChangeSelection
  else
    result := idkChangeStack; //some default value
end;

function TImageLayerStateDifference.GetIsIdentity: boolean;
begin
  Result:= not ChangeImageLayer and
          not ChangeSelectionMask and
          not ChangeSelectionLayer;
end;

function TImageLayerStateDifference.GetChangingBoundsDefined: boolean;
begin
  Result:= true;
end;

function TImageLayerStateDifference.GetChangingBounds: TRect;
var
  r: TRect;
begin
  result := EmptyRect;
  if ChangeImageLayer then
  begin
    r := imageDiff.ChangeRect;
    OffsetRect(r, imageOfs.x, imageOfs.y);
    result := RectUnion(result, r);
  end;
  if ChangeSelectionLayer then result := RectUnion(result, selectionLayerDiff.ChangeRect);
  if ChangeSelectionMask then result := RectUnion(result, selectionMaskDiff.ChangeRect);
end;

procedure TImageLayerStateDifference.Init(AToState: TState; APreviousImage: TBGRABitmap; APreviousImageChangeRect: TRect;
        APreviousSelection: TBGRABitmap; APreviousSelectionChangeRect: TRect;
        APreviousSelectionLayer: TBGRABitmap; APreviousSelectionLayerChangeRect: TRect);
var
  next: TImageState;
  curIdx: integer;
begin
  inherited Create((AToState as TImageState).saved,false);
  layerId := -1;
  imageDiff := nil;
  imageOfs := Point(0,0);
  selectionMaskDiff := nil;
  selectionLayerDiff := nil;

  next := AToState as TImageState;
  layerId := next.selectedLayerId;
  curIdx := next.LayeredBitmap.GetLayerIndexFromId(LayerId);
  if curIdx = -1 then
    raise exception.Create('Layer not found')
  else
  begin
    if not IsRectEmpty(APreviousImageChangeRect) then
    begin
      imageDiff := TImageDiff.Create(APreviousImage,next.LayerBitmap[curIdx],APreviousImageChangeRect);
      imageOfs := next.LayerOffset[curIdx];
    end;
    if not IsRectEmpty(APreviousSelectionChangeRect) then
      selectionMaskDiff := TGrayscaleImageDiff.Create(APreviousSelection,next.SelectionMask,APreviousSelectionChangeRect);
    if not IsRectEmpty(APreviousSelectionLayerChangeRect) then
      selectionLayerDiff := TImageDiff.Create(APreviousSelectionLayer,next.SelectionLayer,APreviousSelectionLayerChangeRect);
  end;
end;

function TImageLayerStateDifference.TryCompress: boolean;
begin
  result := false;
  if Assigned(imageDiff) then result := result or imageDiff.Compress;
  if Assigned(selectionMaskDiff) then result := result or selectionMaskDiff.Compress;
  if Assigned(selectionLayerDiff) then result := result or selectionLayerDiff.Compress;
end;

procedure TImageLayerStateDifference.ApplyTo(AState: TState);
var
  idx: integer;
  lState: TImageState;
  newSelectionMask, newSelectionLayer: TBGRABitmap;
begin
  inherited ApplyTo(AState);
  lState := AState as TImageState;
  if layerId <> -1 then
  begin
    idx := lState.LayeredBitmap.GetLayerIndexFromId(layerId);
    if idx = -1 then raise exception.Create('Layer not found');
    if ChangeImageLayer and (lState.LayeredBitmap.LayerOriginalGuid[idx] <> GUID_NULL) then raise exception.Create('Does not apply to originals');
    if ChangeImageLayer then lState.LayeredBitmap.SetLayerBitmap(idx, imageDiff.ApplyCanCreateNew(lState.LayerBitmap[idx],False), True);
    if ChangeSelectionMask then newSelectionMask := selectionMaskDiff.ApplyCanCreateNew(lState.SelectionMask,False) else newSelectionMask := lState.SelectionMask;
    if ChangeSelectionLayer then newSelectionLayer := selectionLayerDiff.ApplyCanCreateNew(lState.SelectionLayer,False) else newSelectionLayer := lState.SelectionLayer;
    lState.ReplaceSelection(newSelectionMask, newSelectionLayer);
  end;
end;

procedure TImageLayerStateDifference.UnapplyTo(AState: TState);
var
  idx: integer;
  lState: TImageState;
  newSelectionMask, newSelectionLayer: TBGRABitmap;
begin
  inherited UnapplyTo(AState);
  lState := AState as TImageState;
  if layerId <> -1 then
  begin
    idx := lState.LayeredBitmap.GetLayerIndexFromId(layerId);
    if idx = -1 then raise exception.Create('Layer not found');
    if ChangeImageLayer and (lState.LayeredBitmap.LayerOriginalGuid[idx] <> GUID_NULL) then raise exception.Create('Does not apply to originals');
    if ChangeImageLayer then lState.LayeredBitmap.SetLayerBitmap(idx, imageDiff.ApplyCanCreateNew(lState.LayerBitmap[idx],True), True);
    if ChangeSelectionMask then newSelectionMask := selectionMaskDiff.ApplyCanCreateNew(lState.SelectionMask,True) else newSelectionMask := lState.SelectionMask;
    if ChangeSelectionLayer then newSelectionLayer := selectionLayerDiff.ApplyCanCreateNew(lState.SelectionLayer,True) else newSelectionLayer := lState.SelectionLayer;
    lState.ReplaceSelection(newSelectionMask, newSelectionLayer);
  end;
end;

function TImageLayerStateDifference.UsedMemory: int64;
begin
  Result:= 0;
  if Assigned(imageDiff) then result += imageDiff.UsedMemory;
  if Assigned(selectionMaskDiff) then result += selectionMaskDiff.UsedMemory;
  if Assigned(selectionLayerDiff) then result += selectionLayerDiff.UsedMemory;
end;

constructor TImageLayerStateDifference.Create(AFromState, AToState: TState);
var
  prev,next: TImageState;
  prevIdx,curIdx: integer;
begin
  inherited Create(AFromState,AToState);
  layerId := -1;
  imageDiff := nil;
  imageOfs := Point(0,0);
  selectionMaskDiff := nil;
  selectionLayerDiff := nil;

  prev := AFromState as TImageState;
  next := AToState as TImageState;
  layerId := next.selectedLayerId;
  if layerId <> prev.selectedLayerId then
    raise exception.Create('Inconsistent layer id');
  prevIdx := prev.LayeredBitmap.GetLayerIndexFromId(LayerId);
  curIdx := next.LayeredBitmap.GetLayerIndexFromId(LayerId);
  if (curIdx = -1) or (prevIdx = -1) then
    raise exception.Create('Layer not found')
  else
  begin
    imageDiff := TImageDiff.Create(prev.LayerBitmap[prevIdx],next.LayerBitmap[curIdx]);
    imageOfs := next.LayerOffset[curIdx];
    selectionMaskDiff := TGrayscaleImageDiff.Create(prev.SelectionMask,next.SelectionMask);
    selectionLayerDiff := TImageDiff.Create(prev.SelectionLayer,next.SelectionLayer);
  end;
end;

constructor TImageLayerStateDifference.Create(AToState: TState;
  APreviousImage: TBGRABitmap; APreviousImageDefined: boolean;
  APreviousSelection: TBGRABitmap; APreviousSelectionDefined: boolean;
  APreviousSelectionLayer: TBGRABitmap; APreviousSelectionLayerDefined: boolean);
var
  r1,r2,r3: TRect;
  w,h: integer;
begin
  w := (AToState as TImageState).Width;
  h := (AToState as TImageState).Height;
  if APreviousImageDefined then r1 := rect(0,0,w,h) else r1 := EmptyRect;
  if APreviousSelectionDefined then r2 := rect(0,0,w,h) else r2 := EmptyRect;
  if APreviousSelectionLayerDefined then r3 := rect(0,0,w,h) else r3 := EmptyRect;
  Init(AToState,APreviousImage,r1,APreviousSelection,r2,APreviousSelectionLayer,r3);
end;

constructor TImageLayerStateDifference.Create(AToState: TState;
  APreviousImage: TBGRABitmap; APreviousImageChangeRect: TRect;
  APreviousSelection: TBGRABitmap; APreviousSelectionChangeRect: TRect;
  APreviousSelectionLayer: TBGRABitmap; APreviousSelectionLayerChangeRect: TRect);
begin
  Init(AToState, APreviousImage, APreviousImageChangeRect, APreviousSelection,
    APreviousSelectionChangeRect, APreviousSelectionLayer, APreviousSelectionLayerChangeRect);
end;

function TImageLayerStateDifference.ToString: ansistring;
begin
  Result:= ClassName+'(';
  If ChangeImageLayer then
  begin
    if (imageDiff.SizeBefore.cx = 0) or (imageDiff.SizeBefore.cy = 0) then
      result += 'Create'
    else
    if (imageDiff.SizeAfter.cx = 0) or (imageDiff.SizeAfter.cy = 0) then
      result += 'Remove'
    else
      result += 'Change';

    result += 'ImageLayer ';
  end;
  If ChangeSelectionMask then
  begin
    if (selectionMaskDiff.SizeBefore.cx = 0) or (selectionMaskDiff.SizeBefore.cy = 0) then
      result += 'Create'
    else
    if (selectionMaskDiff.SizeAfter.cx = 0) or (selectionMaskDiff.SizeAfter.cy = 0) then
      result += 'Remove'
    else
      result += 'Change';

    result += 'SelectionMask ';
  end;
  If ChangeSelectionLayer then
  begin
    if (selectionLayerDiff.SizeBefore.cx = 0) or (selectionLayerDiff.SizeBefore.cy = 0) then
      result += 'Create'
    else
    if (selectionLayerDiff.SizeAfter.cx = 0) or (selectionLayerDiff.SizeAfter.cy = 0) then
      result += 'Remove'
    else
      result += 'Change';

    result += 'SelectionLayer ';
  end;
  result := trim(Result)+')';
end;

destructor TImageLayerStateDifference.Destroy;
begin
  imageDiff.Free;
  selectionMaskDiff.Free;
  selectionLayerDiff.Free;
  inherited Destroy;
end;

end.

