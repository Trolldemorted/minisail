(**************************************************************************)
(*     Sail                                                               *)
(*                                                                        *)
(*  Copyright (c) 2013-2017                                               *)
(*    Kathyrn Gray                                                        *)
(*    Shaked Flur                                                         *)
(*    Stephen Kell                                                        *)
(*    Gabriel Kerneis                                                     *)
(*    Robert Norton-Wright                                                *)
(*    Christopher Pulte                                                   *)
(*    Peter Sewell                                                        *)
(*    Alasdair Armstrong                                                  *)
(*    Brian Campbell                                                      *)
(*    Thomas Bauereiss                                                    *)
(*    Anthony Fox                                                         *)
(*    Jon French                                                          *)
(*    Dominic Mulligan                                                    *)
(*    Stephen Kell                                                        *)
(*    Mark Wassell                                                        *)
(*                                                                        *)
(*  All rights reserved.                                                  *)
(*                                                                        *)
(*  This software was developed by the University of Cambridge Computer   *)
(*  Laboratory as part of the Rigorous Engineering of Mainstream Systems  *)
(*  (REMS) project, funded by EPSRC grant EP/K008528/1.                   *)
(*                                                                        *)
(*  Redistribution and use in source and binary forms, with or without    *)
(*  modification, are permitted provided that the following conditions    *)
(*  are met:                                                              *)
(*  1. Redistributions of source code must retain the above copyright     *)
(*     notice, this list of conditions and the following disclaimer.      *)
(*  2. Redistributions in binary form must reproduce the above copyright  *)
(*     notice, this list of conditions and the following disclaimer in    *)
(*     the documentation and/or other materials provided with the         *)
(*     distribution.                                                      *)
(*                                                                        *)
(*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''    *)
(*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     *)
(*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A       *)
(*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR   *)
(*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,          *)
(*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT      *)
(*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF      *)
(*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND   *)
(*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,    *)
(*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT    *)
(*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF    *)
(*  SUCH DAMAGE.                                                          *)
(**************************************************************************)

open Ast
open Ast_util

let opt_output : string ref = ref "out.ir"
let opt_splice = ref ([]:string list)

let options =
  Arg.align [
      ( "-o",
        Arg.String (fun file -> opt_output := file ^ ".ir"),
        "<file> The name of the output file");
      ( "-v",
        Arg.Int (fun verbosity -> Util.opt_verbosity := verbosity),
        "<verbosity> produce verbose output");
      ( "-splice",
        Arg.String (fun s -> opt_splice := s :: !opt_splice),
        "<filename> add functions from file, replacing existing definitions where necessary");
      ( "-mono_rewrites",
        Arg.Set Rewrites.opt_mono_rewrites,
        " turn on rewrites for combining bitvector operations");
    ]

let usage_msg = "usage: isla-sail <options> <file1.sail> ... <fileN.sail>\n"


let main () =
  let open Process_file in
  let opt_file_arguments = ref [] in
  Arg.parse options (fun s ->
      opt_file_arguments := (!opt_file_arguments) @ [s])
    usage_msg;

  (* These options are either needed for ARM, or increase performance significantly (memo_z3) *)
  Nl_flow.opt_nl_flow := true;
  Type_check.opt_no_lexp_bounds_check := true;
  Process_file.opt_memo_z3 := true;
  Reporting.opt_warnings := false;
  Initial_check.opt_undefined_gen := true;
  Initial_check.opt_magic_hash := true;
  Type_check.opt_no_effects := true;

  let _, ast, env = load_files options Type_check.initial_env !opt_file_arguments in
  let ast, env = descatter env ast in
  let ast, env = Specialize.(specialize typ_ord_specialization env ast) in
  
  Minisail.minisail env ast
  
let () =
  try main () with
  | Reporting.Fatal_error e ->
     Reporting.print_error e;
     exit 1
