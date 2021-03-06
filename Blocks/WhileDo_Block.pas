{  
   Copyright (C) 2006 The devFlowcharter project.
   The initial author of this file is Michal Domagala.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
}



unit WhileDo_Block;

interface

uses
   Vcl.Graphics, System.Types, Base_Block, CommonInterfaces;

type

   TWhileDoBlock = class(TGroupBlock)
      public
         constructor Create(ABranch: TBranch); overload;
         constructor Create(ABranch: TBranch; ALeft, ATop, AWidth, AHeight, b_hook, p1X, p1Y: integer; AId: integer = ID_INVALID); overload;
         function Clone(ABranch: TBranch): TBlock; override;
      protected
         procedure Paint; override;
         procedure SetWidth(AMinX: integer); override;
         function GetDiamondTop: TPoint; override;
   end;

implementation

uses
   System.Classes, ApplicationCommon, CommonTypes, Return_Block;

constructor TWhileDoBlock.Create(ABranch: TBranch; ALeft, ATop, AWidth, AHeight, b_hook, p1X, p1Y: integer; AId: integer = ID_INVALID);
begin

   FType := blWhile;

   inherited Create(ABranch, ALeft, ATop, AWidth, AHeight, Point(p1X, p1Y), AId);

   FInitParms.Width := 200;
   FInitParms.Height := 131;
   FInitParms.BottomHook := 100;
   FInitParms.BranchPoint.X := 100;
   FInitParms.BottomPoint.X := 189;
   FInitParms.P2X := 0;
   FInitParms.HeightAffix := 22;

   TopHook.Y := 79;
   BottomPoint.X := Width-11;
   BottomPoint.Y := 50;
   BottomHook := b_hook;
   TopHook.X := p1X;
   IPoint.Y := 74;
   Constraints.MinWidth := FInitParms.Width;
   Constraints.MinHeight := FInitParms.Height;
   FStatement.Alignment := taCenter;
   PutTextControls;
end;

function TWhileDoBlock.Clone(ABranch: TBranch): TBlock;
begin
   result := TWhileDoBlock.Create(ABranch, Left, Top, Width, Height, BottomHook, Branch.Hook.X, Branch.Hook.Y);
   result.CloneFrom(Self);
end;

constructor TWhileDoBlock.Create(ABranch: TBranch);
begin
   Create(ABranch, 0, 0, 200, 131, 100, 100, 109);
end;

procedure TWhileDoBlock.Paint;
var
   dRight, dBottom, dTop, dLeft: PPoint;
begin
   inherited;
   if Expanded then
   begin
      IPoint.X := Branch.Hook.X + 40;
      dBottom := @FDiamond[D_BOTTOM];
      dRight := @FDiamond[D_RIGHT];
      dTop := @FDiamond[D_TOP];
      dLeft := @FDiamond[D_LEFT];
      BottomPoint.Y := dRight.Y;
      TopHook := dBottom^;

      DrawArrow(Branch.Hook.X, TopHook.Y, Branch.Hook);
      if Branch.FindInstanceOf(TReturnBlock) = -1 then
      begin
         Canvas.MoveTo(BottomHook, Height-21);
         Canvas.LineTo(5, Height-21);
         DrawArrowTo(5, 0, arrMiddle);
         Canvas.LineTo(TopHook.X, 0);
      end;
      DrawTextLabel(dBottom.X-10, dBottom.Y, FTrueLabel, true);
      DrawTextLabel(dRight.X, dRight.Y-5, FFalseLabel, false, true);
      DrawBlockLabel(dLeft.X+5, dLeft.Y-5, GInfra.CurrentLang.LabelWhile, true, true);
      Canvas.MoveTo(TopHook.X, 0);
      Canvas.LineTo(dTop.X, dTop.Y);
      Canvas.PenPos := dRight^;
      Canvas.LineTo(BottomPoint.X, BottomPoint.Y);
      DrawArrowTo(BottomPoint.X, Height-1);
   end;
   DrawI;
end;

function TWhileDoBlock.GetDiamondTop: TPoint;
begin
   result := Point(Branch.Hook.X, 19);
end;

procedure TWhileDoBlock.SetWidth(AMinX: integer);
begin
   if AMinX < FInitParms.Width - 30 then
      Width := FInitParms.Width
   else
      Width := AMinX + 30;
   BottomPoint.X := Width - 11;
end;

end.