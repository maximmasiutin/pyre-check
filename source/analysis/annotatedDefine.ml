(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

(* This module provides handlers for dealing with function definitions and decorators. *)

open Core
open Ast
open Pyre
open Statement
module Callable = AnnotatedCallable

type t = Define.t Node.t [@@deriving compare, sexp, show, hash]

let create definition = definition

let define annotated = annotated

let parameter_annotations
    { Node.value = { Define.signature = { parameters; _ }; _ }; _ }
    ~resolution
  =
  let element index { Node.value = { Expression.Parameter.annotation; _ }; _ } =
    let annotation =
      annotation
      >>| (fun annotation -> GlobalResolution.parse_annotation resolution annotation)
      |> Option.value ~default:Type.Top
    in
    index, annotation
  in
  List.mapi ~f:element parameters |> Int.Map.of_alist_exn


let parent_definition { Node.value = { Define.signature = { legacy_parent; _ }; _ }; _ } ~resolution
  =
  match legacy_parent with
  | Some parent -> GlobalResolution.get_class_summary resolution (Reference.show parent)
  | _ -> None


let decorate
    ({
       Node.value =
         {
           Define.signature =
             { Define.Signature.decorators; parameters = original_parameters; _ } as signature;
           _;
         } as define;
       location;
     } as define_node)
    ~resolution
  =
  match decorators with
  | [] -> define_node
  | _ -> (
      match
        GlobalResolution.resolve_define
          resolution
          ~callable_name:None
          ~implementation:(Some signature)
          ~overloads:[]
          ~scoped_type_variables:None
      with
      | Ok (Type.Callable { implementation = { Type.Callable.parameters; annotation; _ }; _ }) ->
          let parameters =
            match parameters with
            | Defined parameters ->
                let convert (placed_single_star, sofar) parameter =
                  let location = Location.any in
                  let placed_single_star, sofar =
                    match placed_single_star, parameter with
                    | false, Type.Callable.CallableParamType.KeywordOnly _ ->
                        true, Expression.Parameter.create ~location ~name:"*" () :: sofar
                    | _ -> placed_single_star, sofar
                  in
                  let new_parameter =
                    match parameter with
                    | Type.Callable.CallableParamType.PositionalOnly { annotation; _ } ->
                        (* This means it will be read back in as an anonymous *)
                        Expression.Parameter.create
                          ~location
                          ~annotation:(Type.expression annotation)
                          ~name:"__"
                          ()
                    | Type.Callable.CallableParamType.KeywordOnly { name; annotation; _ }
                    | Type.Callable.CallableParamType.Named { name; annotation; _ } ->
                        Expression.Parameter.create
                          ~location
                          ~annotation:(Type.expression annotation)
                          ~name
                          ()
                    | Type.Callable.CallableParamType.Variable (Concrete annotation) ->
                        Expression.Parameter.create
                          ~location
                          ~annotation:(Type.expression annotation)
                          ~name:"*args"
                          ()
                    | Type.Callable.CallableParamType.Variable (Concatenation concatenation) ->
                        Expression.Parameter.create
                          ~location
                          ~annotation:
                            (Type.OrderedTypes.to_starred_annotation_expression
                               ~expression:Type.expression
                               concatenation)
                          ~name:"*args"
                          ()
                    | Type.Callable.CallableParamType.Keywords annotation ->
                        Expression.Parameter.create
                          ~location
                          ~annotation:(Type.expression annotation)
                          ~name:"**kwargs"
                          ()
                  in
                  placed_single_star, new_parameter :: sofar
                in
                List.fold parameters ~f:convert ~init:(false, []) |> snd |> List.rev
            | FromParamSpec _
            | Undefined ->
                original_parameters
          in
          let return_annotation = Some (Type.expression annotation) in
          {
            define with
            Define.signature = { signature with Define.Signature.parameters; return_annotation };
          }
          |> Node.create ~location
      | _ ->
          (* We should really signal this somehow *)
          define_node)


let is_constructor
    ({ Node.value = { Define.signature = { legacy_parent; _ }; _ }; _ } as definition)
    ~resolution
  =
  match legacy_parent >>| Reference.show with
  | Some parent_class ->
      let in_test =
        let superclasses = GlobalResolution.successors resolution parent_class in
        List.exists ~f:Type.Primitive.is_unit_test (parent_class :: superclasses)
      in
      Define.is_constructor ~in_test (Node.value definition)
  | None -> false
