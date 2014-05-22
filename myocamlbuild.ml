open Ocamlbuild_plugin

let try_exec cmd =
  Sys.command (cmd ^ " >/dev/null 2>&1") = 0

let has_ocamlopt = try_exec "which ocamlopt"

let native_compilation =
  try Sys.getenv "OCAMLBEST" = "native"
  with Not_found -> has_ocamlopt

let exe_suffix = if native_compilation then ".native" else ".byte"

let atdgen_action opts env build =
  let x = env "%.atd" in
  let d = Pathname.dirname x and f = Pathname.basename x in
  Cmd (S [A"cd"; P d; Sh"&&"; A"atdgen"; S opts; P f])

let js_of_ocaml env build =
  Cmd (S [A"js_of_ocaml"; P (env "%.byte")])

let ( / ) = Filename.concat

let platform_rules kind =
  let lib = "src" / "lib" in
  let platform_dir = "src" / "platform" in
  let platform_mod = platform_dir / kind / "platform" in
  let platform_lib = platform_dir / "platform-" ^ kind in
  let ml = platform_mod ^ ".ml" in
  let mli = platform_mod ^ ".mli" in
  let mllib = platform_lib ^ ".mllib" in
  rule mllib ~deps:[ml] ~prods:[mllib] (fun _ _ ->
    (* technically, there is no dependency, but we need the directory to
       exist for the following *)
    Echo ([platform_dir / kind / "Platform"; "\n"], mllib)
  );
  dep ["file:" ^ ml] [mli];
  copy_rule mli (lib / "platform.mli") mli;
  ocaml_lib platform_lib

let () = dispatch & function

  | Before_options ->

    Options.use_ocamlfind := true;
    Options.make_links := false;

  | After_rules ->

    Pathname.define_context "src/web" ["src/lib"];
    Pathname.define_context "src/tool" ["src/lib"];
    Pathname.define_context "demo" ["src/lib"];
    Pathname.define_context "stuff" ["src/lib"];
    Pathname.define_context "." ["src/lib"];

    (* the following avoids an ocamlfind warning, it should be built-in *)
    flag ["doc"; "thread"] (A"-thread");

    rule "%.atd -> %_t.ml & %_t.mli" ~deps:["%.atd"] ~prods:["%_t.ml"; "%_t.mli"]
      (atdgen_action [A"-t"]);
    rule "%.atd -> %_j.ml & %_j.mli" ~deps:["%.atd"] ~prods:["%_j.ml"; "%_j.mli"]
      (atdgen_action [A"-j"; A"-j-std"]);

    rule "%.byte -> %.js" ~deps:["%.byte"] ~prods:["%.js"] js_of_ocaml;

    rule "%.md -> %.html" ~deps:["%.md"] ~prods:["%.html"]
      (fun env build ->
        Cmd (S [A"markdown"; P (env "%.md"); Sh">"; P (env "%.html")])
      );

    platform_rules "native";
    platform_rules "js";

    copy_rule "belenios-tool" ("src/tool/tool_cmdline" ^ exe_suffix) "belenios-tool";

  | _ -> ()
