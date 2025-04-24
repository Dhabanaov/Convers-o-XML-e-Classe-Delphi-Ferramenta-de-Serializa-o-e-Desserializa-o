unit urClassXML;

interface

uses
  System.SysUtils, System.RTTI, System.TypInfo, System.Generics.Collections,
  Xml.XMLDoc, Xml.XMLIntf;

type
  TXMLToClass = class
  private
    class function IsSimpleType(PropType: TRttiType): Boolean;
    class procedure XMLToObject(Node: IXMLNode; Instance: TObject;
      Context: TRttiContext);
    class function StringToTValue(const S: string; PropType: TRttiType): TValue;
    class function RemoverDeclaracaoXML(const AXML: string): string;
    class procedure SerializeObject(Instance: TObject; Node: IXMLNode;
      Context: TRttiContext);
    class function IsGenericListOfObjects(PropType: TRttiType): Boolean;
  public
    class function XMLToClass<T: class, constructor>(const XMLContent
      : string): T;
    class function ObjectToXML<T>(const Instance: TObject): string;
  end;

implementation

class function TXMLToClass.IsGenericListOfObjects(PropType: TRttiType): Boolean;
begin
  Result := (PropType.TypeKind = tkClass) and
    (PropType.Name.StartsWith('TList<') or
    PropType.Name.StartsWith('TObjectList<'));
end;

class function TXMLToClass.IsSimpleType(PropType: TRttiType): Boolean;
begin
  Result := PropType.TypeKind in [tkInteger, tkInt64, tkFloat, tkChar, tkString,
    tkUString, tkWString, tkLString, tkEnumeration];
end;

class function TXMLToClass.ObjectToXML<T>(const Instance: TObject): string;
var
  Doc: IXMLDocument;
  Root: IXMLNode;
  Context: TRttiContext;
  RootName: string;
begin
  Doc := NewXMLDocument;
  Doc.Encoding := 'UTF-8';
  Doc.Options := [doNodeAutoIndent];

  RootName := Instance.ClassName;
  if RootName.StartsWith('T') then
    RootName := RootName.Substring(1); // remove o 'T'

  Root := Doc.AddChild(RootName);

  Context := TRttiContext.Create;
  SerializeObject(Instance, Root, Context);

  Result := Doc.Xml.Text.Trim;

  Result := StringReplace(Result, sLineBreak, '', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
end;

class function TXMLToClass.RemoverDeclaracaoXML(const AXML: string): string;
const
  XMLDeclStart = '<?xml';
  XMLDeclEnd = '?>';
var
  StartPos, EndPos: Integer;
begin
  Result := AXML.Trim;
  if Result.StartsWith(XMLDeclStart) then
  begin
    StartPos := 1;
    EndPos := Pos(XMLDeclEnd, Result);
    if EndPos > 0 then
      Delete(Result, StartPos, EndPos + Length(XMLDeclEnd) - 1);
  end;
end;

class procedure TXMLToClass.SerializeObject(Instance: TObject; Node: IXMLNode;
  Context: TRttiContext);

var
  RttiType, PropType: TRttiType;
  RttiProp: TRttiProperty;
  Value: TValue;
  ChildNode: IXMLNode;
  Item: TObject;
  X, DynArrayLength: Integer;
  StrValue: string;
begin
  if Instance = nil then
    Exit;
  RttiType := Context.GetType(Instance.ClassType);

  for RttiProp in RttiType.GetProperties do
  begin
    if not RttiProp.IsReadable then
      Continue;

    PropType := RttiProp.PropertyType;
    Value := RttiProp.GetValue(Instance);

    case IsSimpleType(PropType) of
      true:
        begin
          StrValue := Value.ToString;
          case StrValue.StartsWith('atr') of
            (true): Node.Attributes[RttiProp.Name] := StrValue.Substring(3);
            (False): Node.AddChild(RttiProp.Name).Text := StrValue;
          end;
        end;
      False:
        case (PropType.TypeKind = tkClass) and Value.IsObject of
          true:
            begin
              case IsGenericListOfObjects(PropType) of
                true:
                  begin
                    for X := 0 to TList<TObject>(Value.AsObject).Count - 1 do
                    begin
                      Item := TList<TObject>(Value.AsObject)[X];
                      ChildNode := Node.AddChild(RttiProp.Name);
                      SerializeObject(Item, ChildNode, Context);
                    end;
                  end;
                False:
                  begin
                    ChildNode := Node.AddChild(RttiProp.Name);
                    SerializeObject(Value.AsObject, ChildNode, Context);
                  end;
              end;
            end;
          False:
            if PropType.TypeKind = tkDynArray then
            begin
              DynArrayLength := Value.GetArrayLength;
              for X := 0 to DynArrayLength - 1 do
              begin
                if Value.GetArrayElement(X).Kind = tkClass then
                begin
                  Item := Value.GetArrayElement(X).AsObject;
                  if Assigned(Item) then
                  begin
                    ChildNode := Node.AddChild(RttiProp.Name);
                    SerializeObject(Item, ChildNode, Context);
                  end;
                end;
              end;
            end;
        end;
    end;
  end;
end;

class function TXMLToClass.StringToTValue(const S: string;
  PropType: TRttiType): TValue;
begin
  case PropType.TypeKind of
    tkInteger:
      Result := StrToIntDef(S, 0);
    tkInt64:
      Result := StrToInt64Def(S, 0);
    tkFloat:
      if PropType.Handle = TypeInfo(TDateTime) then
        Result := StrToDateTimeDef(S, 0)
      else
        Result := StrToFloatDef(S, 0);
    tkEnumeration:
      if PropType.Handle = TypeInfo(Boolean) then
        Result := SameText(S, 'true')
      else
        Result := TValue.FromOrdinal(PropType.Handle,
          GetEnumValue(PropType.Handle, S));
    tkString, tkLString, tkUString, tkWString:
      Result := S;
  else
    Result := TValue.Empty;
  end;
end;

class function TXMLToClass.XMLToClass<T>(const XMLContent: string): T;

var
  XMLDoc: IXMLDocument;
  xnoNo: IXMLNode;
  Context: TRttiContext;
begin
  Result := T.Create;

  XMLDoc := TXMLDocument.Create(nil);
  try
    XMLDoc.Options := [doNodeAutoCreate, doNodeAutoIndent];
    XMLDoc.LoadFromXML(RemoverDeclaracaoXML(XMLContent.Trim));
    XMLDoc.Active := true;
    xnoNo := XMLDoc.DocumentElement;

    Context := TRttiContext.Create;
    try
      XMLToObject(xnoNo, Result, Context);
    finally
      (Context).Free;
    end;
  except
    on E: Exception do
    begin
      FreeAndNil(Result);
    end;
  end;
end;

class procedure TXMLToClass.XMLToObject(Node: IXMLNode; Instance: TObject;
  Context: TRttiContext);

var

  I: Integer;
  Item: TObject;
  SubObj: TObject;
  DynArray: TValue;
  PropNode: IXMLNode;
  RttiType: TRttiType;
  PropType: TRttiType;
  ElementType: TRttiType;
  RttiProp: TRttiProperty;
  DynArrayData: TArray<TObject>;
  AttrName, AttrValue: string;
begin
  RttiType := Context.GetType(Instance.ClassType);

  for RttiProp in RttiType.GetProperties do
  begin
    if not RttiProp.IsWritable then
      Continue;

    PropType := RttiProp.PropertyType;

    for I := 0 to Node.AttributeNodes.Count - 1 do
    begin
      AttrName := Node.AttributeNodes[I].NodeName;
      AttrValue := Node.AttributeNodes[I].Text;
      if SameText(AttrName, RttiProp.Name) and IsSimpleType(PropType) then
      begin
        RttiProp.SetValue(Instance, TValue.From<string>('atr' + AttrValue));
        Continue;
      end;
    end;

    PropNode := nil;
    for I := 0 to Node.ChildNodes.Count - 1 do
    begin
      if SameText(Node.ChildNodes[I].LocalName, RttiProp.Name) then
      begin
        PropNode := Node.ChildNodes[I];
        Break;
      end;
    end;

    if not Assigned(PropNode) then
      Continue;

    case IsSimpleType(PropType) of
      true:
        RttiProp.SetValue(Instance, StringToTValue(PropNode.Text, PropType));
      False:
        case PropType.TypeKind of
          tkClass:
            begin


              SubObj := PropType.AsInstance.MetaclassType.Create;
              XMLToObject(PropNode, SubObj, Context);
              RttiProp.SetValue(Instance, SubObj);

            end;
          tkDynArray:
            begin
              if not(PropType is TRttiDynamicArrayType) then
                Continue;

              ElementType := TRttiDynamicArrayType(PropType).ElementType;
              if not Assigned(ElementType) or (ElementType.TypeKind <> tkClass)
              then
                Continue;

              for I := 0 to Node.ChildNodes.Count - 1 do
              begin
                if (Node.ChildNodes[I].NodeType = ntElement) and
                  SameText(Node.ChildNodes[I].NodeName, RttiProp.Name) then
                begin
                  Item := ElementType.AsInstance.MetaclassType.Create;
                  XMLToObject(Node.ChildNodes[I], Item, Context);
                  SetLength(DynArrayData, Length(DynArrayData) + 1);
                  DynArrayData[High(DynArrayData)] := Item;
                end;
              end;

              TValue.Make(@DynArrayData, PropType.Handle, DynArray);
              RttiProp.SetValue(Instance, DynArray);
            end;
        end;
    end;
  end;
end;

end.
