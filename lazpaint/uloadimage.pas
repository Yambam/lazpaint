unit ULoadImage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazPaintType, BGRABitmap;

function LoadFlatImageUTF8(AFilename: string; out AFinalFilename: string; AAppendFrame: string; ASkipDialog: boolean = false): TBGRABitmap;
procedure FreeMultiImage(var images: ArrayOfBGRABitmap);
function AbleToLoadUTF8(AFilename: string): boolean;

implementation

uses FileUtil, BGRAAnimatedGif, Graphics, UMultiImage,
  BGRAReadLzp, LCLProc, BGRABitmapTypes, BGRAReadPng,
  UFileSystem, BGRAReadIco;

function LoadIcoMultiImageFromStream(AStream: TStream; AClass: TCustomIconClass): ArrayOfBGRABitmap;
var ico: TCustomIcon; i,resIdx,maxIdx: integer;
    height,width: word; format:TPixelFormat;
    maxHeight,maxWidth: word; maxFormat: TPixelFormat;
begin
  ico := AClass.Create;
  ico.LoadFromStream(AStream);
  maxIdx := 0;
  maxHeight := 0;
  maxWidth := 0;
  maxFormat := pfDevice;
  for i := 0 to ico.Count-1 do
  begin
    ico.GetDescription(i,format,height,width);
    if (height > maxHeight) or (width > maxWidth) or
    ((height = maxHeight) and (width = maxWidth) and (format > maxFormat)) then
    begin
      maxIdx := i;
      maxHeight := height;
      maxWidth := width;
      maxFormat := format;
    end;
  end;
  if (maxWidth = 0) or (maxHeight = 0) then result := nil else
  begin
    setlength(result,ico.Count);
    ico.Current := maxIdx;
    result[0] := TBGRABitmap.Create;
    result[0].Assign(ico);
    result[0].Caption := IntTostr(maxWidth)+'x'+IntToStr(maxHeight)+'x'+IntToStr(PIXELFORMAT_BPP[maxFormat]);
    if Assigned(result[0].XorMask) then result[0].XorMask.Caption := result[0].Caption + ' (xor)';
    resIdx := 1;
    for i := 0 to ico.Count-1 do
    if i <> maxIdx then
    begin
      ico.Current := i;
      ico.GetDescription(i,format,height,width);
      result[resIdx] := TBGRABitmap.Create;
      result[resIdx].Assign(ico);
      result[resIdx].Caption := IntTostr(width)+'x'+IntToStr(height)+'x'+IntToStr(PIXELFORMAT_BPP[format]);
      if Assigned(result[resIdx].XorMask) then result[resIdx].XorMask.Caption := result[resIdx].Caption + ' (xor)';
      inc(resIdx);
    end;
  end;
  ico.Free;
end;

function LoadGifMultiImageFromStream(AStream: TStream): ArrayOfBGRABitmap;
var gif: TBGRAAnimatedGif; i: integer;
begin
  gif := TBGRAAnimatedGif.Create(AStream);
  try
    setlength(result,gif.Count);
    for i := 0 to gif.Count-1 do
    begin
      gif.CurrentImage:= i;
      result[i] := gif.MemBitmap.Duplicate as TBGRABitmap;
      result[i].Caption:= 'Frame'+IntToStr(i);
    end;
  finally
    gif.Free;
  end;
end;

function LoadFlatLzpFromStream(AStream: TStream): TBGRABitmap;
var
  reader: TBGRAReaderLazPaint;
begin
  reader := TBGRAReaderLazPaint.Create;
  result := TBGRABitmap.Create;
  try
    result.LoadFromStream(AStream, reader);
  finally
    reader.Free;
    if (result.Width = 0) or (result.Height = 0) then FreeAndNil(result);
  end;
end;

function LoadPngFromStream(AStream: TStream): TBGRABitmap;
var
  reader: TBGRAReaderPNG;
begin
  reader := TBGRAReaderPNG.Create;
  result := TBGRABitmap.Create;
  try
    result.LoadFromStream(AStream, reader);
  except
    FreeAndNil(result);
  end;
  if result <> nil then
  begin
    if (result.Width = 0) or (result.Height = 0) then FreeAndNil(result);
  end;
  reader.Free;
end;

procedure FreeMultiImage(var images: ArrayOfBGRABitmap);
var i: integer;
begin
  for i := 0 to high(images) do
    images[i].Free;
  images := nil;
end;

function AbleToLoadUTF8(AFilename: string): boolean;
var
  s: TStream;
begin
  s := FileManager.CreateFileStream(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    result := DefaultBGRAImageReader[DetectFileFormat(s, ExtractFileExt(AFilename))] <> nil;
  finally
    s.Free;
  end;
end;

function LoadFlatImageUTF8(AFilename: string; out AFinalFilename: string; AAppendFrame: string; ASkipDialog: boolean): TBGRABitmap;
var
  formMultiImage: TFMultiImage;
  multi: ArrayOfBGRABitmap;
  format : TBGRAImageFormat;
  s: TStream;

  procedure ChooseMulti(AStretch: boolean);
  begin
    if length(multi)=1 then
    begin
      result := multi[0];
      multi := nil;
    end else
    begin
      formMultiImage := TFMultiImage.Create(nil);
      try
        result := formMultiImage.ShowAndChoose(multi,AStretch);
      finally
        formMultiImage.Free;
      end;
      FreeMultiImage(multi);
      if result <> nil then
        AFinalFilename += '.'+result.Caption+AAppendFrame;
    end;
  end;

begin
  s := FileManager.CreateFileStream(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    format := DetectFileFormat(s, ExtractFileExt(AFilename));
    AFinalFilename:= AFilename;
    result := nil;
    if format = ifIco then
    begin
      multi := LoadIcoMultiImageFromStream(s, TIcon);
      if ASkipDialog then
      begin
        result := multi[0];
        multi[0] := nil;
        FreeMultiImage(multi);
      end
      else
        ChooseMulti(False);
    end else
    if format = ifCur then
    begin
      multi := LoadIcoMultiImageFromStream(s, TCursorImage);
      if ASkipDialog then
      begin
        result := multi[0];
        multi[0] := nil;
        FreeMultiImage(multi);
      end
      else
        ChooseMulti(False);
    end else
    if (format = ifGif) and not ASkipDialog then
    begin
      multi := LoadGifMultiImageFromStream(s);
      ChooseMulti(True);
    end else
    if format = ifLazPaint then
    begin
      result := LoadFlatLzpFromStream(s);
    end else
    if format = ifPng then
    begin
      result := LoadPngFromStream(s);
    end else
      result := TBGRABitmap.Create(s);
  finally
    s.Free;
  end;
end;

end.

