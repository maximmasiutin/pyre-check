(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open Core
open Data_structures
open Ast
open Expression

module T = struct
  type t =
    (* Identifier for a regular expression, as returned by the parser. *)
    | Regular of Location.t
    (* Identifier for all expressions generated from the different preprocessing steps. *)
    | ArtificialAttributeAccess of Origin.t
    | ArtificialCall of Origin.t
    | ArtificialComparisonOperator of Origin.t
    | ArtificialBinaryOperator of Origin.t
    | ArtificialUnaryOperator of Origin.t
    | ArtificialBooleanOperator of Origin.t
    | ArtificialSubscript of Origin.t
    | ArtificialWalrusOperator of Origin.t
    | ArtificialSlice of Origin.t
    | ArtificialAwait of Origin.t
    (* Qualification creates identifiers without an origin. *)
    | IdentifierExpression of {
        location: Location.t;
        identifier: string;
      }
    | FormatStringArtificial of Location.t
    | FormatStringStringify of Location.t
    (* Identifier for constant expression.
     *
     * This is necessary because we sometimes create constant expressions during preprocessing:
     * - `Expression.normalize` can create True/False constant nodes with the same location
     * - `Preprocessing.expand_named_tuples` can create string literals
     * - `Cfg.MatchTranslate` can create integer constants
     * - `Cfg.create` can create ellipsis for try handlers
     *)
    | Constant of {
        location: Location.t;
        constant: Constant.t;
      }
  [@@deriving compare, equal, sexp, hash, show { with_path = false }]

  let location = function
    | Regular location
    | ArtificialAttributeAccess { Origin.location; _ }
    | ArtificialCall { Origin.location; _ }
    | ArtificialComparisonOperator { Origin.location; _ }
    | ArtificialBinaryOperator { Origin.location; _ }
    | ArtificialUnaryOperator { Origin.location; _ }
    | ArtificialBooleanOperator { Origin.location; _ }
    | ArtificialSubscript { Origin.location; _ }
    | ArtificialWalrusOperator { Origin.location; _ }
    | ArtificialSlice { Origin.location; _ }
    | ArtificialAwait { Origin.location; _ }
    | IdentifierExpression { location; _ }
    | FormatStringArtificial location
    | FormatStringStringify location
    | Constant { location; _ } ->
        location


  let autogenerated_compare = compare

  let compare left right =
    match Location.compare (location left) (location right) with
    | 0 -> autogenerated_compare left right
    | result -> result


  let of_call ~location { Call.origin; _ } =
    match origin with
    | None -> Regular location
    | Some origin -> ArtificialCall origin


  let of_attribute_access ~location { Name.Attribute.origin; _ } =
    match origin with
    | None -> Regular location
    | Some origin -> ArtificialAttributeAccess origin


  let of_identifier ~location identifier = IdentifierExpression { location; identifier }

  let of_format_string_artificial ~location = FormatStringArtificial location

  let of_format_string_stringify ~location = FormatStringStringify location

  let of_define_statement define_location = Regular define_location

  let of_return_statement return_location = Regular return_location

  let of_expression { Node.value; location } =
    match value with
    | Expression.Call { Call.origin = Some origin; _ } -> ArtificialCall origin
    | Expression.Name (Name.Identifier identifier) -> IdentifierExpression { location; identifier }
    | Expression.Name (Name.Attribute { origin = Some origin; _ }) ->
        ArtificialAttributeAccess origin
    | Expression.ComparisonOperator { ComparisonOperator.origin = Some origin; _ } ->
        ArtificialComparisonOperator origin
    | Expression.BinaryOperator { BinaryOperator.origin = Some origin; _ } ->
        ArtificialBinaryOperator origin
    | Expression.UnaryOperator { UnaryOperator.origin = Some origin; _ } ->
        ArtificialUnaryOperator origin
    | Expression.BooleanOperator { BooleanOperator.origin = Some origin; _ } ->
        ArtificialBooleanOperator origin
    | Expression.Subscript { Subscript.origin = Some origin; _ } -> ArtificialSubscript origin
    | Expression.WalrusOperator { WalrusOperator.origin = Some origin; _ } ->
        ArtificialWalrusOperator origin
    | Expression.Slice { Slice.origin = Some origin; _ } -> ArtificialSlice origin
    | Expression.Await { Await.origin = Some origin; _ } -> ArtificialAwait origin
    | Expression.Constant
        (( Constant.True | Constant.False | Constant.Ellipsis | Constant.String _
         | Constant.Integer _ ) as constant) ->
        Constant { location; constant }
    | _ -> Regular location


  let pp_json_key formatter = function
    | Regular location -> Location.pp formatter location
    | ArtificialAttributeAccess { Origin.location; kind } ->
        Format.fprintf
          formatter
          "%a|artificial-attribute-access|%a"
          Location.pp
          location
          Origin.pp_kind_json
          kind
    | ArtificialCall { Origin.location; kind } ->
        Format.fprintf
          formatter
          "%a|artificial-call|%a"
          Location.pp
          location
          Origin.pp_kind_json
          kind
    | ArtificialComparisonOperator { Origin.location; kind } ->
        Format.fprintf
          formatter
          "%a|artificial-comparison-operator|%a"
          Location.pp
          location
          Origin.pp_kind_json
          kind
    | ArtificialBinaryOperator { Origin.location; kind } ->
        Format.fprintf
          formatter
          "%a|artificial-binary-operator|%a"
          Location.pp
          location
          Origin.pp_kind_json
          kind
    | ArtificialUnaryOperator { Origin.location; kind } ->
        Format.fprintf
          formatter
          "%a|artificial-unary-operator|%a"
          Location.pp
          location
          Origin.pp_kind_json
          kind
    | ArtificialBooleanOperator { Origin.location; kind } ->
        Format.fprintf
          formatter
          "%a|artificial-boolean-operator|%a"
          Location.pp
          location
          Origin.pp_kind_json
          kind
    | ArtificialSubscript { Origin.location; kind } ->
        Format.fprintf
          formatter
          "%a|artificial-subscript|%a"
          Location.pp
          location
          Origin.pp_kind_json
          kind
    | ArtificialWalrusOperator { Origin.location; kind } ->
        Format.fprintf
          formatter
          "%a|artificial-walrus|%a"
          Location.pp
          location
          Origin.pp_kind_json
          kind
    | ArtificialSlice { Origin.location; kind } ->
        Format.fprintf
          formatter
          "%a|artificial-slice|%a"
          Location.pp
          location
          Origin.pp_kind_json
          kind
    | ArtificialAwait { Origin.location; kind } ->
        Format.fprintf
          formatter
          "%a|artificial-await|%a"
          Location.pp
          location
          Origin.pp_kind_json
          kind
    | IdentifierExpression { location; identifier } ->
        Format.fprintf formatter "%a|identifier|%s" Location.pp location identifier
    | FormatStringArtificial location ->
        Format.fprintf formatter "%a|format-string-artificial" Location.pp location
    | FormatStringStringify location ->
        Format.fprintf formatter "%a|format-string-stringify" Location.pp location
    | Constant { location; constant } ->
        Format.fprintf
          formatter
          "%a|constant|%a"
          Location.pp
          location
          Expression.pp
          (Expression.Constant constant |> Node.create_with_default_location)


  let json_key = Format.asprintf "%a" pp_json_key
end

include T

module Map = struct
  include SerializableMap.Make (T)
end
