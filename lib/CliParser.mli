(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(** CLI parsing module. *)
open Identifier
open CliUtil

(** Represents a program entrypoint. *)
type entrypoint =
  | Entrypoint of module_name * identifier
[@@deriving eq]

(** Represents the path to a module. *)
type mod_source =
  | ModuleSource of { inter_path: string; body_path: string }
  (** Path to a module's interface and body files. *)
  | ModuleBodySource of { body_path: string }
  (** Path to a module's body file, for public body-only modules. *)
[@@deriving eq]

(** The compiler's target output. *)
type target =
  | TypeCheck
  (** Stop at the type checking stage. *)
  | Executable of { bin_path: string; entrypoint: entrypoint; }
  (** Compile to C, generate an executable. *)
  | CStandalone of { output_path: string; entrypoint: entrypoint option; }
  (** Compile to a standalone C file. *)
[@@deriving eq]

type error_reporting_mode =
  | ErrorReportPlain
  | ErrorReportJson

(** The type of compiler commands. The compiler's CLI arglist is parsed to an
    instance of this type. *)
type cmd =
  | HelpCommand
  (** Print usage. *)
  | VersionCommand
  (** Print the compiler's version. *)
  | CompileHelp
  (** Print usage of the compile command. *)
  | WholeProgramCompile of {
      modules: mod_source list;
      (** The list of modules to compile in order. *)
      target: target;
      (** The compiler's target. *)
      error_reporting_mode: error_reporting_mode;
      (** Whether to report errors in plain text or JSON. *)
    }
  (** Whole program compilation using the C backend. *)
[@@deriving eq]

(** Parse an argument list into a compiler command. *)
val parse : arglist -> cmd
