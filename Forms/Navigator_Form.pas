unit Navigator_Form;

interface

uses
  System.Classes, Vcl.Controls, Vcl.StdCtrls, System.Types, Base_Form, OmniXML;

type
  TNavigatorForm = class(TBaseForm)
    chkAlphaVisible: TCheckBox;
    scbAlphaVal: TScrollBar;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure chkAlphaVisibleClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure scbAlphaValChange(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  private
    { Private declarations }
    procedure SetAlphaValVisible(AValue: boolean);
  public
    { Public declarations }
    InvalidateInd: boolean;
    procedure ResetForm; override;
    procedure ExportSettingsToXMLTag(ATag: IXMLElement); override;
    procedure ImportSettingsFromXMLTag(ATag: IXMLElement); override;
    procedure DoInvalidate;
  end;

var
  NavigatorForm: TNavigatorForm;

implementation

uses
   WinApi.Windows, System.SysUtils, Vcl.Graphics, Vcl.Forms, ApplicationCommon,
   BlockTabSheet, XMLProcessor;

{$R *.dfm}

procedure TNavigatorForm.FormCreate(Sender: TObject);
begin
   DoubleBuffered := true;
   InvalidateInd := true;
   SetBounds(50, 50, 426, 341);
   Constraints.MinWidth := 150;
   Constraints.MinHeight := 150;
   ControlStyle := ControlStyle + [csOpaque];
   Constraints.MaxWidth := (Screen.Width*9) div 10;
   Constraints.MaxHeight := (Screen.Height*9) div 10;
   scbAlphaVal.Position := GSettings.NavigatorAlphaValue;
   scbAlphaVal.OnKeyDown := TInfra.GetMainForm.OnKeyDown;
   chkAlphaVisible.Checked := GSettings.NavigatorAlphaVisible;
end;

procedure TNavigatorForm.FormPaint(Sender: TObject);
const
   EXTENT_X = 1024;
   EXTENT_Y = 1024;
var
   lhdc: HDC;
   edit: TCustomEdit;
   selStart, selLength, xExt, yExt: integer;
   box: TScrollBoxEx;
   r: TRect;
begin
   if GProject <> nil then
   begin
      edit := TInfra.GetActiveEdit;
      if edit <> nil then
      begin
         selStart := edit.SelStart;
         selLength := edit.SelLength;
      end;
      lhdc := SaveDC(Canvas.Handle);
      try
         box := GProject.GetActivePage.Box;
         xExt := MulDiv(EXTENT_X, box.HorzScrollBar.Range, ClientWidth);
         yExt := MulDiv(EXTENT_Y, box.VertScrollBar.Range, ClientHeight);
         SetMapMode(Canvas.Handle, MM_ANISOTROPIC);
         SetWindowExtEx(Canvas.Handle, xExt, yExt, nil);
         SetViewPortExtEx(Canvas.Handle, EXTENT_X, EXTENT_Y, nil);
         box.PaintToCanvas(Canvas);
         Canvas.Pen.Width := 2;
         Canvas.Pen.Color := clRed;
         r := box.GetDisplayRect;
         Canvas.Polyline([r.TopLeft,
                          Point(r.Right, r.Top),
                          r.BottomRight,
                          Point(r.Left, r.Bottom),
                          r.TopLeft]);
      finally
         RestoreDC(Canvas.Handle, lhdc);
         if edit <> nil then
         begin
            edit.SelStart := selStart;
            edit.SelLength := selLength;
         end;
      end;
   end;
end;

procedure TNavigatorForm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
   box: TScrollBox;
begin
   if (Button = mbLeft) and (GProject <> nil) then
   begin
      box := GProject.GetActivePage.Box;
      box.HorzScrollBar.Position := MulDiv(X, box.HorzScrollBar.Range, ClientWidth) - (box.ClientWidth div 2);
      box.VertScrollBar.Position := MulDiv(Y, box.VertScrollBar.Range, ClientHeight) - (box.ClientHeight div 2);
      Invalidate;
      box.Repaint;
   end;
end;


procedure TNavigatorForm.ResetForm;
begin
   inherited ResetForm;
   Position := poDesigned;
   InvalidateInd := true;
   SetBounds(50, 50, 426, 341);
end;

procedure TNavigatorForm.FormResize(Sender: TObject);
begin
   Invalidate;
end;

procedure TNavigatorForm.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
   if ssLeft in Shift then
      FormMouseDown(Sender, mbLeft, Shift, X, Y);
end;

procedure TNavigatorForm.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
   if GProject <> nil then
      GProject.GetActivePage.Box.BoxMouseWheel(Sender, Shift, WheelDelta, MousePos, Handled);
end;

procedure TNavigatorForm.ExportSettingsToXMLTag(ATag: IXMLElement);
begin
   if Visible then
   begin
      ATag.SetAttribute('nav_win_show', 'true');
      ATag.SetAttribute('nav_win_x', Left.ToString);
      ATag.SetAttribute('nav_win_y', Top.ToString);
      ATag.SetAttribute('nav_win_width', Width.ToString);
      ATag.SetAttribute('nav_win_height', Height.ToString);
      if WindowState = wsMinimized then
         ATag.SetAttribute('nav_win_min', 'true');
   end;
end;

procedure TNavigatorForm.ImportSettingsFromXMLTag(ATag: IXMLElement);
var
   x, y, w, h: integer;
begin
   if TXMLProcessor.GetBoolFromAttr(ATag, 'nav_win_show') then
   begin
      Position := poDesigned;
      if TXMLProcessor.GetBoolFromAttr(ATag, 'nav_win_min') then
         WindowState := wsMinimized;
      x := StrToIntDef(ATag.GetAttribute('nav_win_x'), 50);
      y := StrToIntDef(ATag.GetAttribute('nav_win_y'), 50);
      w := StrToIntDef(ATag.GetAttribute('nav_win_width'), 426);
      h := StrToIntDef(ATag.GetAttribute('nav_win_height'), 341);
      SetBounds(x, y, w, h);
      Show;
   end;
end;

procedure TNavigatorForm.chkAlphaVisibleClick(Sender: TObject);
begin
   SetAlphaValVisible(chkAlphaVisible.Checked);
   GSettings.NavigatorAlphaVisible := chkAlphaVisible.Checked;
end;

procedure TNavigatorForm.FormShow(Sender: TObject);
begin
   chkAlphaVisible.Checked := GSettings.NavigatorAlphaVisible;
   SetAlphaValVisible(chkAlphaVisible.Checked);
end;

procedure TNavigatorForm.SetAlphaValVisible(AValue: boolean);
begin
   if AValue then
   begin
      scbAlphaVal.Width := 33;
      scbAlphaVal.Height := 89;
   end
   else
   begin
      scbAlphaVal.Width := 1;
      scbAlphaVal.Height := 1;
   end;
end;

procedure TNavigatorForm.DoInvalidate;
begin
   if InvalidateInd then
      Invalidate;
end;

procedure TNavigatorForm.scbAlphaValChange(Sender: TObject);
begin
   AlphaBlendValue := scbAlphaVal.Position;
   GSettings.NavigatorAlphaValue := AlphaBlendValue;
end;

end.
