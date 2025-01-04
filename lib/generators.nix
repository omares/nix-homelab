{
  concatStringsSep,
  mapAttrsToList,
  strings,
}:

{
  toXML =
    {
      indent ? 2,
      rootName ? "root",
      xmlns ? {
        xsi = "http://www.w3.org/2001/XMLSchema-instance";
        xsd = "http://www.w3.org/2001/XMLSchema";
      },
    }:
    let
      indentStr = level: strings.fixedWidthString (level * indent) " " "";

      xmlnsString =
        if xmlns != { } then
          concatStringsSep " " (mapAttrsToList (name: value: ''xmlns:${name}="${value}"'') xmlns)
        else
          "";

      valueToString =
        value:
        if builtins.isBool value then
          (if value then "true" else "false")
        else if builtins.isInt value then
          toString value
        else if builtins.isFloat value then
          toString value
        else if builtins.isString value then
          value
        else if builtins.isNull value then
          ""
        else if builtins.isPath value then
          toString value
        else if builtins.isList value then
          if value == [ ] then
            ""
          else
            "\n"
            + concatStringsSep "\n" (
              map (
                v: if builtins.isAttrs v then attrsToXML 2 "" v else throw "List elements must be attribute sets"
              ) value
            )
            + "\n"
            + indentStr 1
        else
          throw "Unsupported type for value: ${builtins.typeOf value}";

      attrsToXML =
        level: name: value:
        let
          ind = indentStr level;

          handleSet =
            attrs:
            concatStringsSep "\n" (
              mapAttrsToList (
                n: v:
                if builtins.isAttrs v then
                  attrsToXML (level + 1) n v
                else
                  "${ind}${indentStr 1}<${n}>${valueToString v}</${n}>"
              ) attrs
            );
        in
        if builtins.isAttrs value then
          ''
            ${ind}<${name}>
            ${handleSet value}
            ${ind}</${name}>''
        else
          "${ind}<${name}>${valueToString value}</${name}>";
    in
    attrs: ''
      <?xml version="1.0" encoding="utf-8"?>
      <${rootName} ${xmlnsString}>
      ${attrsToXML 1 "" attrs}
      </${rootName}>'';
}
