(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Stages

(** Desugar anonymous borrows. *)

val transform_expr : Ast.aexpr -> AstDB.aexpr

val transform_stmt : Ast.astmt -> AstDB.astmt
