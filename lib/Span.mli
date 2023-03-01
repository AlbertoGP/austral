(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

open Lexing

type position = Position of {
      (* Lines range from 1 to infinity. *)
      line: int;
      (* Columns range from 0 to infinity. *)
      column: int;
    }
[@@deriving (show, sexp)]

type span = Span of {
      filename: string;
      startp: position;
      endp: position;
    }
[@@deriving (show, sexp)]

val from_lexbuf : lexbuf -> span

(* Menhir has a special token, $loc, that evaluates to a (pos, pos) token. This
   function takes that pair and returns a span. *)
val from_loc : (Lexing.position * Lexing.position) -> span

val position_to_string : position -> string

val span_to_string : span -> string

val empty_span : span
