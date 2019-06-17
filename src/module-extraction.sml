(*
    Copyright 2018–2019 Fernando Borretti <fernando@borretti.me>

    This file is part of Austral.

    Austral is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Austral is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Austral.  If not, see <http://www.gnu.org/licenses/>.
*)

structure ModuleExtraction :> MODULE_EXTRACTION = struct
    fun extract (TypedDecl.Module (name, docstring, imports, decls)) =
        Module.Module (name, docstring, imports, extractDecls decls)

    and extractDecls decls =
        Map.fromList (map (fn (name, decl) =>
                              (name, extractDecl decl))
                          (Map.toList decls))

    and extractDecl (TypedDecl.RecordDefinition (ds, vis, name, slots)) =
        Module.RecordDefinition (ds, vis, name, map extractSlot slots)
      | extractDecl (TypedDecl.UnionDefinition (ds, vis, name, cases)) =
        Module.UnionDefinition (ds, vis, name, map extractCase cases)
      | extractDecl (TypedDecl.FunctionDefinition (ds, vis, name, params, rt, _)) =
        Module.FunctionDefinition (ds, vis, name, params, rt)

    and extractSlot (TypedDecl.SlotDefinition (name, ty, ds)) =
        Module.SlotDefinition (name, ty, ds)

    and extractCase (TypedDecl.CaseDefinition (name, tyOpt, ds)) =
        Module.CaseDefinition (name, tyOpt, ds)
end