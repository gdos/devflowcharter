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



{ This unit contains routines used mainly by parsers }

unit ParserHelper;

interface

uses
   Base_Block, ApplicationCommon, DeclareList, UserFunction;

type

   TIdentInfo = record
   private
      FType,
      FTypeOriginal,
      FTypePointer: integer;
      FTypeAsString,
      FTypeOriginalAsString: string;
      FIsInteger,
      FIsReal,
      FIsNumeric,
      FIsRecord,
      FIsEnum,
      FIsPointer: boolean;
      procedure SetType(AType: integer);
   public
      Ident,
      SizeAsString,
      SizeExpArrayAsString,
      Value: string;
      IdentType,
      Size,
      DimensCount,
      Scope: integer;
      property TType: integer read FType write SetType;
      property TypeAsString: string read FTypeAsString;
      property TypeOriginal: integer read FTypeOriginal;
      property TypeOriginalAsString: string read FTypeOriginalAsString;
      property TypePointer: integer read FTypePointer;
      property IsInteger: boolean read FIsInteger;
      property IsReal: boolean read FIsReal;
      property IsNumeric: boolean read FIsNumeric;
      property IsRecord: boolean read FIsRecord;
      property IsEnum: boolean read FIsEnum;
      property IsPointer: boolean read FIsPointer;
      procedure New;
   end;

   TParserHelper = class(TObject)
   private
      //class function DecodeDimension(const AType: integer): integer;
      class function DecodeType(AType: integer): integer;
   public
      class function IsInLoop: boolean;
      class function ValidateUserFunctionParms(const AFunctionName: string; AParmList: array of integer): boolean;
      class function GetUserFunctionType(const AFunctionName: string): integer; overload;
      class function GetUserFunctionType: integer; overload;
      class function GetConstType(const AConstName: string): integer;
      class function GetEnumeratedType(const AValue: string): integer;
      class function GetTypeAsString(AType: integer):string;
      class function GetType(const ATypeName: string; const ALangName: string = ''): integer;
      class function GetFieldType(const AVarName, AField: string): integer; overload;
      class function GetFieldType(AType: integer; const AField: string): integer; overload;
      class function IsDeclared(const AIdentName: string): boolean;
      class function IsDuplicatedCase: boolean;
      class function GetConstValue(const AConstName: string): string;
      class function GetIdentInfo(const AIdentName: string): TIdentInfo;
      class function FindUserFunctionVarList(ABlock: TBlock): TVarDeclareList;
      class procedure GetParameterInfo(AHeader: TUserFunctionHeader; var AResult: TIdentInfo);
      class procedure GetVariableInfo(AVarList: TVarDeclareList; var AResult: TIdentInfo);
      class function IsRecordType(AType: integer): boolean;
      class function IsEnumType(AType: integer): boolean;
      class function IsIntegerType(AType: integer): boolean;
      class function IsRealType(AType: integer): boolean;
      class function IsNumericType(AType: integer): boolean;
      class function IsPointerType(AType: integer): boolean;
      class function IsBoolType(AType: integer): boolean;
      class function IsStringType(AType: integer): boolean;
      class function IsOtherType(AType: integer): boolean;
      class function GetPointerType(AType: integer): integer;
      class function GetOriginalType(AType: integer): integer;
      class function GetForVarType: integer;
      class function GetCaseVarType: integer;
      class function GetVarInfo(const AVarName: string): TIdentInfo;
      class function IsArrayType(AType: integer): boolean;
      class function AreTypesCompatible(AType1, AType2: integer): boolean;
      class function GetSizeExpArrayAsString(const ATypeAsString: string; const ASizeAsString: string): string;
   end;

const

   // generic datatype descriptors
   GENERIC_INT_TYPE  = 0;
   GENERIC_PTR_TYPE  = 99;

   DIMENSION_LEVEL_STEP = 100;

   INCORRECT_SIZE = 0;
   UNKNOWN_TYPE   = -2;
   NOT_DEFINED    = -3;

   VARIABLE     = 1;
   VARRAY       = 2;
   CONSTANT     = 3;
   ROUTINE_ID   = 4;
   ENUM_VALUE   = 5;
   UNKNOWN      = -1;

   GLOBAL    = -10;
   LOCAL     = -11;
   PARAMETER = -12;

implementation

uses
   Vcl.StdCtrls, System.SysUtils, UserDataType, Statement, CommonTypes, Case_Block,
   Main_Block, ForDo_Block, LangDefinition, CommonInterfaces;

procedure TIdentInfo.New;
begin
   FType := NOT_DEFINED;
   FTypeAsString := i18Manager.GetString('Unknown');
   FTypeOriginal := FType;
   FTypeOriginalAsString := FTypeAsString;
   FTypePointer := FType;
   IdentType := UNKNOWN;
   Size := INCORRECT_SIZE;
   SizeAsString := INCORRECT_SIZE.ToString;
   SizeExpArrayAsString := '';
   Value := '';
   Ident := '';
   Scope := GLOBAL;
   DimensCount := 0;
   FIsInteger := false;
   FIsReal := false;
   FIsNumeric := false;
   FIsRecord := false;
   FIsENum := false;
   FIsPointer := false;
end;

procedure TIdentInfo.SetType(AType: integer);
begin
   FType := AType;
   FTypeAsString := TParserHelper.GetTypeAsString(FType);
   FTypeOriginal := TParserHelper.GetOriginalType(FType);
   FTypeOriginalAsString := TParserHelper.GetTypeAsString(FTypeOriginal);
   FTypePointer := TParserHelper.GetPointerType(FType);
   FIsInteger := TParserHelper.IsIntegerType(FType);
   FIsReal := TParserHelper.IsRealType(FType);
   FIsNumeric := FIsInteger or FIsReal;
   FIsRecord := TParserHelper.IsRecordType(FType);
   FIsEnum := TParserHelper.IsEnumType(FType);
   FIsPointer := TParserHelper.IsPointerType(FType);
end;

class function TParserHelper.GetForVarType: integer;
var
   block: TBlock;
begin
   result := NOT_DEFINED;
   block := TInfra.GetParsedBlock;
   if block is TForDoBlock then
      result := GetVarInfo(TForDoBlock(block).edtVariable.Text).TType;
end;

class function TParserHelper.GetCaseVarType: integer;
var
   block: TBlock;
begin
   result := NOT_DEFINED;
   block := TInfra.GetParsedBlock;
   if block is TCaseBlock then
   begin
      result := GetVarInfo(TCaseBlock(block).GetTextControl.Text).TType;
      if result = NOT_DEFINED then
         result := GENERIC_INT_TYPE;
   end;
end;

// check if active statement is inside loop
class function TParserHelper.IsInLoop: boolean;
var
   block: TBlock;
begin
   result := false;
   block := TInfra.GetParsedBlock;
   while block <> nil do
   begin
      if block.BType in LOOP_BLOCKS then
      begin
         result := true;
         break;
      end;
      block := block.ParentBlock;
   end;
end;

class function TParserHelper.IsDuplicatedCase: boolean;
var
   edit: TCustomEdit;
begin
   result := false;
   edit := TInfra.GetParsedEdit;
   if (edit <> nil) and (edit.Parent is TCaseBlock) then
      result := TCaseBlock(edit.Parent).IsDuplicatedCase(edit);
end;

// get function type for active edit control
class function TParserHelper.GetUserFunctionType: integer;
var
   header: TUserFunctionHeader;
begin
   result := NOT_DEFINED;
   header := TInfra.GetFunctionHeader(TInfra.GetParsedBlock);
   if (header <> nil) and (header.Font.Color <> NOK_COLOR) then
      result := GetType(header.cbType.Text);
end;

class function TParserHelper.GetUserFunctionType(const AFunctionName: string): integer;
var
   func: TUserFunction;
begin
   result := NOT_DEFINED;
   if GProject <> nil then
   begin
      func := GProject.GetUserFunction(AFunctionName);
      if (func <> nil) and (func.Header <> nil) and (func.Header.Font.Color <> NOK_COLOR) then
         result := GetType(func.Header.cbType.Text);
   end;
end;

// get type descriptor for given type string
class function TParserHelper.GetType(const ATypeName: string; const ALangName: string = ''): integer;
var
   i: integer;
   lang: TLangDefinition;
begin
   result := UNKNOWN_TYPE;
   if ALangName.IsEmpty then
      lang := GInfra.CurrentLang
   else
      lang := GInfra.GetLangDefinition(ALangName);
   if lang <> nil then
   begin
      for i := 0 to High(lang.NativeDataTypes) do
      begin
         if TInfra.SameStrings(lang.NativeDataTypes[i].Name, ATypeName) then
         begin
            result := i;
            break;
         end;
      end;
   end;
   if (result = UNKNOWN_TYPE) and (GProject <> nil) and (GProject.GlobalVars <> nil) then
   begin
      result := GProject.GlobalVars.cbType.Items.IndexOf(ATypeName);
      if result = -1 then
         result := UNKNOWN_TYPE;
   end;
end;

class function TParserHelper.ValidateUserFunctionParms(const AFunctionName: string; AParmList: array of integer): boolean;
var
   i, paramType, currType: integer;
   func: TUserFunction;
   param: TParameter;
begin
   result := false;
   if GProject <> nil then
   begin
      func := GProject.GetUserFunction(AFunctionName);
      if (func <> nil) and (func.Header <> nil) and (Length(AParmList) = func.Header.ParameterCount) then
      begin
         i := 0;
         for param in func.Header.GetParameters do
         begin
            paramType := GetType(param.cbType.Text);
            currType := AParmList[i];
            if currType >= DIMENSION_LEVEL_STEP then
            begin
               currType := DecodeType(currType);
               if (currType <> paramType) or (not param.chkTable.Checked and not IsArrayType(paramType)) then
                  exit;
            end
            else if param.chkTable.Checked or not AreTypesCompatible(paramType, currType) then
               exit;
            i := i + 1;
         end;
         result := true;
      end;
   end;
end;

class function TParserHelper.GetEnumeratedType(const AValue: string): integer;
var
   dataType: TUserDataType;
   field: TField;
begin
   result := NOT_DEFINED;
   if GProject <> nil then
   begin
      for dataType in GProject.GetUserDataTypes do
      begin
         if dataType.Active and (dataType.Font.Color <> NOK_COLOR) and (dataType.Kind = dtEnum) then
         begin
            for field in dataType.GetFields do
            begin
               if (field.edtName.Font.Color <> NOK_COLOR) and TInfra.SameStrings(AValue, Trim(field.edtName.Text)) then
               begin
                  result := GetType(dataType.edtName.Text);
                  break;
               end;
            end;
         end;
         if result <> NOT_DEFINED then break;
      end;
   end;
end;

class function TParserHelper.FindUserFunctionVarList(ABlock: TBlock): TVarDeclareList;
var
   header: TUserFunctionHeader;
begin
   result := nil;
   header := TInfra.GetFunctionHeader(ABlock);
   if header <> nil then
      result := header.LocalVars;
end;

class function TParserHelper.GetSizeExpArrayAsString(const ATypeAsString: string; const ASizeAsString: string): string;
var
   dataType: TUserDataType;
   size: string;
begin
   result := ASizeAsString;
   if result.IsEmpty then
      exit;
   if GProject <> nil then
   begin
      dataType := GProject.GetUserDataType(ATypeAsString);
      if dataType <> nil then
      begin
         size := dataType.GetDimensions;
         if not size.IsEmpty then
         begin
            if result <> '1' then
               result := result + ',' + size
            else
               result := size;
         end;
      end;
   end;
end;

class procedure TParserHelper.GetParameterInfo(AHeader: TUserFunctionHeader; var AResult: TIdentInfo);
var
   param: TParameter;
   dataType: TUserDataType;
begin
   if AHeader <> nil then
   begin
      for param in AHeader.GetParameters do
      begin
         if (param.edtName.Font.Color <> NOK_COLOR) and TInfra.SameStrings(AResult.Ident, Trim(param.edtName.Text)) then
         begin
            AResult.TType := GetType(param.cbType.Text);
            with AResult do
            begin
               Scope := PARAMETER;
               if param.chkTable.Checked then
               begin
                  Size := 0;
                  SizeAsString := '';
                  DimensCount := 1;
               end
               else
               begin
                  Size := 1;
                  SizeAsString := '1';
                  DimensCount := 0;
               end;
               if GProject <> nil then
               begin
                  dataType := GProject.GetUserDataType(param.cbType.Text);
                  if dataType <> nil then
                     Inc(DimensCount, dataType.GetDimensionCount);
               end;
               if DimensCount > 0 then
               begin
                  IdentType := VARRAY;
                  SizeExpArrayAsString := GetSizeExpArrayAsString(TypeAsString, SizeAsString);
               end
               else
                  IdentType := VARIABLE;
            end;
            break;
         end;
      end;
   end;
end;

class procedure TParserHelper.GetVariableInfo(AVarList: TVarDeclareList; var AResult: TIdentInfo);
var
   i: integer;
begin
   if AVarList <> nil then
   begin
      i := AVarList.sgList.Cols[VAR_NAME_COL].IndexOf(AResult.Ident);
      if i > 0 then
      begin
         AResult.TType := GetType(AVarList.sgList.Cells[VAR_TYPE_COL, i]);
         with AResult do
         begin
            SizeAsString := AVarList.sgList.Cells[VAR_SIZE_COL, i];
            Size := StrToIntDef(SizeAsString, INCORRECT_SIZE);
            DimensCount := AVarList.GetDimensionCount(Ident, true);
            if DimensCount = 0 then
               IdentType := VARIABLE
            else
            begin
               IdentType := VARRAY;
               SizeExpArrayAsString := GetSizeExpArrayAsString(TypeAsString, SizeAsString);
            end;
            if (GProject <> nil) and (GProject.GlobalVars <> AVarList) then
               Scope := LOCAL;
         end;
      end;
   end;
end;

class function TParserHelper.GetVarInfo(const AVarName: string): TIdentInfo;
var
   block: TBlock;
begin
   result.New;
   result.Ident := AVarName;
   block := TInfra.GetParsedBlock;
   if block <> nil then
   begin
      GetParameterInfo(TInfra.GetFunctionHeader(block), result);
      if result.TType = NOT_DEFINED  then
         GetVariableInfo(FindUserFunctionVarList(block), result);
   end;
   if (result.TType = NOT_DEFINED) and (GProject <> nil) then
      GetVariableInfo(GProject.GlobalVars, result);
end;

// get field type for given structural variable
class function TParserHelper.GetFieldType(const AVarName, AField: string): integer;
begin
   result := GetFieldType(GetVarInfo(AVarName).TypeOriginal, AField);
end;

// get field type for given structural type
class function TParserHelper.GetFieldType(AType: integer; const AField: string): integer;
var
   typeString: string;
   dataType: TUserDataType;
   field: TField;
begin
   result := NOT_DEFINED;
   typeString := GetTypeAsString(AType);
   if (typeString <> i18Manager.GetString('Unknown')) and (GProject <> nil) then
   begin
      dataType := GProject.GetUserDataType(typeString);
      if (dataType <> nil) and (dataType.Kind = dtRecord) then
      begin
         for field in dataType.GetFields do
         begin
            if (field.edtName.Font.Color <> NOK_COLOR) and TInfra.SameStrings(Trim(field.edtName.Text), AField) then
            begin
               result := GetType(field.cbType.Text);
               break;
            end;
         end;
      end;
   end;
end;

// interface for _GetConstType template function
class function TParserHelper.GetConstType(const AConstName: string): integer;
var
   value: string;
begin
   result := NOT_DEFINED;
   value := GetConstValue(AConstName);
   if not value.IsEmpty then
   begin
      if Assigned(GInfra.CurrentLang.GetLiteralType) then
         result := GInfra.CurrentLang.GetLiteralType(value)
      else if Assigned(GInfra.DummyLang.GetLiteralType) then
         result := GInfra.DummyLang.GetLiteralType(value)
   end;
end;

class function TParserHelper.GetConstValue(const AConstName: string): string;
begin
   result := '';
   if (GProject <> nil) and (GProject.GlobalConsts <> nil) then
      result := GProject.GlobalConsts.GetValue(AConstName);
end;

class function TParserHelper.GetIdentInfo(const AIdentName: string): TIdentInfo;
begin
   result := GetVarInfo(AIdentName);
   if result.IdentType = UNKNOWN then
   begin
      result.TType := GetConstType(result.Ident);
      if result.TType <> NOT_DEFINED then
      begin
         result.IdentType := CONSTANT;
         result.Value := GetConstValue(result.Ident);
      end
      else
      begin
         result.TType := GetUserFunctionType(result.Ident);
         if result.TType <> NOT_DEFINED then
            result.IdentType := ROUTINE_ID
         else
         begin
            result.TType := GetEnumeratedType(result.Ident);
            if result.TType <> NOT_DEFINED then
               result.IdentType := ENUM_VALUE;
         end;
      end;
   end;
end;

class function TParserHelper.GetTypeAsString(AType: integer):string;
begin
   if (GProject <> nil) and (GProject.GlobalVars <> nil) and (AType >= 0) and (AType < GProject.GlobalVars.cbType.Items.Count) then
      result := GProject.GlobalVars.cbType.Items[AType]
   else if AType = GENERIC_PTR_TYPE then
      result := 'pointer'
   else if AType >= DIMENSION_LEVEL_STEP then
      result := 'array'
   else
      result := i18Manager.GetString('Unknown');
end;

class function TParserHelper.IsDeclared(const AIdentName: string): boolean;
var
   dataType: TUserDataType;
   field: TField;
begin
   result := true;
   if GProject <> nil then
   begin
      for dataType in GProject.GetUserDataTypes do
      begin
         if dataType.Active and (dataType.Font.Color <> NOK_COLOR) then
         begin
            for field in dataType.GetFields do
               if (field.edtName.Font.Color <> NOK_COLOR) and TInfra.SameStrings(AIdentName, Trim(field.edtName.Text)) then exit;
         end;
      end;
   end;
   if (GetVarInfo(AIdentName).TType = NOT_DEFINED) and (GetConstType(AIdentName) = NOT_DEFINED) and
      (GetUserFunctionType(AIdentName) = NOT_DEFINED) then result := false;
end;

class function TParserHelper.GetOriginalType(AType: integer): integer;
var
   userType: TUserDataType;
   pNativeType: PNativeDataType;
   typeName: string;
begin
   result := AType;
   if GProject <> nil then
   begin
      typeName := GetTypeAsString(AType);
      pNativeType := GInfra.GetNativeDataType(typeName);
      userType := GProject.GetUserDataType(typeName);
      if pNativeType <> nil then
         result := GetType(pNativeType.OrigType.Name)
      else if (userType <> nil) and (userType.GetDimensionCount > 0) then
         result := userType.GetOriginalType
      else if Assigned(GInfra.CurrentLang.GetOriginalType) then
         result := GetType(GInfra.CurrentLang.GetOriginalType(typeName));
   end;
end;

class function TParserHelper.GetPointerType(AType: integer): integer;
var
   lang: TLangDefinition;
begin
   result := UNKNOWN_TYPE;
   lang := nil;
   if Assigned(GInfra.CurrentLang.GetPointerTypeName) then
      lang := GInfra.CurrentLang
   else if Assigned(GInfra.DummyLang.GetPointerTypeName) then
      lang := GInfra.DummyLang;
   if lang <> nil then
      result := GetType(lang.GetPointerTypeName(GetTypeAsString(AType)))
end;

class function TParserHelper.IsIntegerType(AType: integer): boolean;
begin
   result := (GProject <> nil) and (AType in GProject.IntegerTypesSet);
end;

class function TParserHelper.IsRealType(AType: integer): boolean;
begin
   result := (GProject <> nil) and (AType in GProject.RealTypesSet);
end;

class function TParserHelper.IsNumericType(AType: integer): boolean;
begin
   result := IsIntegerType(AType) or IsRealType(AType);
end;

class function TParserHelper.IsPointerType(AType: integer): boolean;
begin
   result := (GProject <> nil) and (AType in GProject.PointerTypesSet);
end;

class function TParserHelper.IsRecordType(AType: integer): boolean;
begin
   result := (GProject <> nil) and (AType in GProject.RecordTypesSet);
end;

class function TParserHelper.IsEnumType(AType: integer): boolean;
begin
   result := (GProject <> nil) and (AType in GProject.EnumTypesSet);
end;

class function TParserHelper.IsArrayType(AType: integer): boolean;
begin
   result := (GProject <> nil) and (AType in GProject.ArrayTypesSet);
end;

class function TParserHelper.IsBoolType(AType: integer): boolean;
begin
   result := (GProject <> nil) and (AType in GProject.BoolTypesSet);
end;

class function TParserHelper.IsStringType(AType: integer): boolean;
begin
   result := (GProject <> nil) and (AType in GProject.StringTypesSet);
end;

class function TParserHelper.IsOtherType(AType: integer): boolean;
begin
   result := (GProject <> nil) and (AType in GProject.OtherTypesSet);
end;

class function TParserHelper.AreTypesCompatible(AType1, AType2: integer): boolean;
var
   isReal, isInt: boolean;
begin
   result := AType1 = AType2;
   if not result then
   begin
      isReal := IsRealType(AType1);
      result := isReal and IsRealType(AType2);
      if not result then
      begin
         isInt := IsIntegerType(AType2);
         result := isReal and isInt;
         if not result then
         begin
            result := IsIntegerType(AType1) and isInt;
            if not result then
            begin
               result := IsBoolType(AType1) and IsBoolType(AType2);
               if not result then
               begin
                  result := IsStringType(AType1) and IsStringType(AType2);
                  if not result then
                     result := (AType2 = GENERIC_PTR_TYPE) and IsPointerType(AType1);
               end;
            end;
         end;
      end;
      if not result and Assigned(GInfra.CurrentLang.AreTypesCompatible) then
         result := GInfra.CurrentLang.AreTypesCompatible(AType1, AType2);
   end;
end;

{class function TParserHelper.DecodeDimension(const AType: integer): integer;
begin
   result := AType div DIMENSION_LEVEL_STEP;
end;}

class function TParserHelper.DecodeType(AType: integer): integer;
begin
   result := AType mod DIMENSION_LEVEL_STEP;
end;

end.


