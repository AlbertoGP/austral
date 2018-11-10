(*
    Copyright 2018 Fernando Borretti <fernando@borretti.me>

    This file is part of Boreal.

    Boreal is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Boreal is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Boreal.  If not, see <http://www.gnu.org/licenses/>.
*)

structure HirPass :> HIR_PASS = struct
    open HIR
    structure MT = MonoType

    val count = ref 0
    fun freshVar () =
        let
        in
            count := !count + 1;
            let val newid = !count
            in
                let val name = Symbol.mkSymbol (Ident.mkIdentEx "#",
                                                Ident.mkIdentEx ("g" ^ (Int.toString newid)))
                in
                    Symbol.Var (name, newid)
                end
            end
        end

    fun transformType MT.Unit =
        Unit
      | transformType MT.Bool =
        Bool
      | transformType (MT.Integer (s, w)) =
        Integer (s, w)
      | transformType (MT.Float f) =
        Float f
      | transformType (MT.Tuple tys) =
        Tuple (map transformType tys)
      | transformType (MT.Pointer ty) =
        Pointer (transformType ty)
      | transformType (MT.ForeignPointer ty) =
        Pointer (transformType ty)
      | transformType (MT.StaticArray ty) =
        StaticArray (transformType ty)
      | transformType (MT.Disjunction (name, id, _)) =
        Disjunction (name, id)

    fun caseNameIdx ty name =
        let fun nameVariantsIdx variants name =
                Option.valOf (Util.position name (map (fn (MonoType.Variant (name, _)) => name) variants))
        in
            case ty of
                (MonoType.Disjunction (_, _, variants)) => nameVariantsIdx variants name
              | _ => raise Fail "Internal error: not a disjunction"
        end

    structure M = MTAST

    fun transform M.UnitConstant =
        UnitConstant
      | transform (M.BoolConstant b) =
        BoolConstant b
      | transform (M.IntConstant (i, ty)) =
        IntConstant (i, transformType ty)
      | transform (M.FloatConstant (f, ty)) =
        FloatConstant (f, transformType ty)
      | transform (M.StringConstant s) =
        StringConstant s
      | transform (M.Variable (var, ty)) =
        Variable (var, transformType ty)
      | transform (M.Let (var, value, body)) =
        Let (var, transform value, transform body)
      | transform (M.Bind (vars, tup, body)) =
        (* Since we drop linearity in HIR, we can turn bind expressions into a
           Let that simply projects each tuple element. *)
        let val tupvar = freshVar ()
            and tys = case M.typeOf tup of
                          (MT.Tuple tys) => tys
                        | _ => raise Fail "Not a tuple [internal compiler error]"
        in
            Let (tupvar,
                 transform tup,
                 transformBind tys vars tupvar body)
        end
      | transform (M.Cond (t, c, a)) =
        Cond (transform t, transform c, transform a)
      | transform (M.ArithOp (kind, oper, lhs, rhs)) =
        ArithOp (kind, oper, transform lhs, transform rhs)
      | transform (M.TupleCreate elems) =
        TupleCreate (map transform elems)
      | transform (M.TupleProj (tup, idx)) =
        TupleProj (transform tup, idx)
      | transform (M.ArrayLength arr) =
        ArrayLength (transform arr)
      | transform (M.ArrayPointer arr) =
        ArrayPointer (transform arr)
      | transform (M.Allocate exp) =
        Allocate (transform exp)
      | transform (M.Load exp) =
        Load (transform exp)
      | transform (M.Store (ptr, value)) =
        Store (transform ptr, transform value)
      | transform (M.Construct (ty, name, value)) =
        Construct (transformType ty,
                   caseNameIdx ty name,
                   Option.map transform value)
      | transform (M.Case (exp, cases, ty)) =
        let val expvar = freshVar ()
        in
            (* TODO: better name for this *)
            let val expvarVar = Variable (expvar, transformType ty)
            in
                let fun transformCase (M.VariantCase (M.NameOnly name, body)) =
                        VariantCase (name, transform body)
                      | transformCase (M.VariantCase (M.NameBinding { casename, var, ty }, body)) =
                        VariantCase (casename,
                                     Let (var,
                                          UnsafeExtractCase (expvarVar,
                                                             casename,
                                                             transformType ty),
                                          transform body))
                in
                    Let (expvar,
                         transform exp,
                         Case (expvarVar,
                               map transformCase cases,
                               transformType ty))
                end
            end
        end
      | transform (M.ForeignFuncall (name, args, ty)) =
        ForeignFuncall (name, map transform args, transformType ty)
      | transform (M.ForeignNull ty) =
        ForeignNull (transformType ty)
      | transform (M.SizeOf ty) =
        SizeOf (transformType ty)
      | transform (M.AddressOf (var, ty)) =
        AddressOf (var, transformType ty)
      | transform (M.Cast (ty, exp)) =
        Cast (transformType ty, transform exp)
      | transform (M.Seq (a, b)) =
        Seq (transform a, transform b)
      | transform (M.ConcreteFuncall (name, args, ty)) =
        ConcreteFuncall (name, map transform args, transformType ty)
      | transform (M.GenericFuncall (name, id, _, args, ty)) =
        GenericFuncall (name,
                        id,
                        map transform args,
                        transformType ty)

    and transformBind tys (vars: Symbol.variable list) (tupvar: Symbol.variable) (body: MTAST.ast) =
        let fun transformInner (head::tail) tupvar body i =
                let val elemTy = transformType (List.nth (tys, i))
                in
                    Let (head,
                         TupleProj (Variable (tupvar, elemTy), i),
                         transformInner tail tupvar body (i + 1))
                end
              | transformInner nil _ body _ =
                transform body
        in
            transformInner vars tupvar body 0
        end

    fun transformTop (M.Defun (name, params, ty, body)) =
        Defun (name,
               mapParams params,
               transformType ty,
               transform body)
      | transformTop (M.DefunMonomorph (name, params, ty, body, id)) =
        DefunMonomorph (name,
                        mapParams params,
                        transformType ty,
                        transform body,
                        id)
      | transformTop (M.DeftypeMonomorph (name, ty, id)) =
        DeftypeMonomorph (name,
                          transformType ty,
                          id)
      | transformTop (M.ToplevelProgn l) =
        ToplevelProgn (map transformTop l)

    and mapParams l =
        map mapParam l

    and mapParam (MTAST.Param (var, ty)) =
        Param (var, transformType ty)
end
