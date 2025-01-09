{
  concatStringsSep,
  mapAttrsToList,
  fixedWidthString,
  isAttrs,
  toINIWithGlobalSection,
  mkKeyValueDefault,
  isString,
}:

{
  toXML =
    {
      spacing ? 2,
      rootName ? "Root",
      xmlns ? {
        xsi = "http://www.w3.org/2001/XMLSchema-instance";
        xsd = "http://www.w3.org/2001/XMLSchema";
      },
    }:
    let
      indent = level: fixedWidthString (level * spacing) " " "";

      makeXmlns =
        if xmlns != { } then
          concatStringsSep " " (mapAttrsToList (name: value: ''xmlns:${name}="${value}"'') xmlns)
        else
          "";

      escapeValue =
        value:
        if (builtins.match ".*<SOPS:.*:PLACEHOLDER>.*" value) != null then
          value
        else
          builtins.replaceStrings [ "&" "<" ">" "'" "\"" ] [ "&amp;" "&lt;" "&gt;" "&apos;" "&quot;" ] value;

      makeValue =
        level: value:
        if builtins.isBool value then
          (if value then "true" else "false")
        else if builtins.isInt value then
          toString value
        else if builtins.isFloat value then
          value
        else if builtins.isString value then
          escapeValue value
        else if builtins.isNull value then
          ""
        else if builtins.isPath value then
          toString value
        else if builtins.isList value then
          if value == [ ] then
            ""
          else
            ''

              ${concatStringsSep "\n" (
                map (
                  value:
                  if builtins.isAttrs value then
                    attrsToXML (level + 1) "" value
                  else
                    throw "List elements must be attribute sets"
                ) value
              )}
              ${indent level}''
        else
          throw "Unsupported type for value: ${builtins.typeOf value}";

      makeTag =
        level: tagName: value:
        let
          val = makeValue level value;
          ind = indent level;
        in
        if val == "" then "${ind}<${tagName} />" else "${ind}<${tagName}>${val}</${tagName}>";

      makeElements =
        level: attrs:
        concatStringsSep "\n" (
          mapAttrsToList (
            tagName: value:
            if builtins.isAttrs value then attrsToXML level tagName value else makeTag level tagName value
          ) attrs
        );

      attrsToXML =
        level: tagName: value:
        let
          ind = indent level;
        in
        if tagName == "" then
          makeElements level value
        else if builtins.isAttrs value then
          ''
            ${ind}<${tagName}>
            ${makeElements (level + 1) value}
            ${ind}</${tagName}>''
        else
          makeTag level tagName value;
    in
    attrs: ''
      <?xml version="1.0" encoding="utf-8"?>
      <${rootName} ${makeXmlns}>
      ${attrsToXML 1 "" attrs}
      </${rootName}>'';

  toINI =
    { globalSection, sections }:
    toINIWithGlobalSection
      {
        mkKeyValue =
          k: v:
          if isAttrs v then
            "[[${k}]]\n" + toINIWithGlobalSection { } { globalSection = v; }
          else
            mkKeyValueDefault {
              mkValueString = v: if isString v then "${v}" else toString v;
            } "=" k v;
      }
      {
        inherit globalSection sections;
      };
}
