module {name: "op"};

def flat_tree:
  . as $tree |
  reduce paths(scalars) as $path ({}; setpath([$path | map(tostring) | join(".")]; $tree | getpath($path)));

def flat_fields:
  reduce .[] as $field ({}; setpath($field.id; $field.value));

def autocomplete($query):
  reduce paths(scalars) as $p ([]; . + [$p | map(tostring) | join(".")]) |
  map(
    select(. | startswith($query)) |
    gsub("^(?<m>\($query)[^.]+.?).*"; "\(.m)")
  ) |
  unique[];

def tree_to_fields($file_hash):
  flat_tree |
  to_entries |
  map(
    (.key | contains(".")) as $hasSection |
    {
      id: .key,
      label: (if $hasSection then (.key | split(".") | del(.[0]) | join(".") ) else .key end),
      value: .value,
      section: (if $hasSection then {id: (.key | split(".") | first)} else null end),
      type: "STRING",
      purpose: ""
    }
  ) + [
    {
      id: "password",
      type: "CONCEALED",
      purpose: "PASSWORD",
      label: "password",
      value: $file_hash,
    },{
      id: "notesPlain",
      type: "STRING",
      purpose: "NOTES",
      label: "notesPlain",
      value: "flushed by milpa",
    }
  ];

def field_keys:
  map(.id // .label);

def fields_to_cli($delete_field_names; $separator):
 # section.field\.name[type|delete](=value)
  map(
    (.section.id // "") + (if .section then "." else "" end) + (.label | gsub("\\."; "\\."))+
    "["+(if .purpose == "PASSWORD" then "password" else "text" end)+"]="+.value
  ) +
  ($delete_field_names | map((.| gsub("\\."; "\\."))+"[delete]=")) |
  sort |
  join($separator);

def fields_to_item($title):
  {
    title: $title,
    category: "PASSWORD",
    sections: ( . | map(.section.id | select(.)) | unique | map({ id: ., label: .})),
    fields: .
  };

def fields_to_item($title; $original):
  ($original | del(.fields) | del(.sections)) * {
    title: $title,
    category: "PASSWORD",
    sections: ( . | map(.section.id | select(.)) | unique | map({ id: ., label: .})),
    fields: .
  };

def fields_to_tree:
  . as $fields |
  (reduce (. | map(select(.section.id == "~annotations"))[]) as $a ({};
    setpath([$a.label]; $a.value)
  )) as $annotations |
  reduce (. | map(select(.section.id != "~annotations" and .id != "notesPlain" and .id != "password")))[] as $field ({};
    setpath(
      $field.id | split(".") | map(if test("^\\d+$") then tonumber else . end);
      if ($annotations | has($field.id) | not) then
        $field.value
      else
        $annotations[$field.id] as $kind |
        if $kind == "secret" then $field.value else ($field.value | fromjson) end
      end
    )
  );
