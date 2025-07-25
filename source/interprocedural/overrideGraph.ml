(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

(* OverrideGraph: represents a mapping from a method to classes overriding it.
 *
 * This can be used as a traditional ocaml value using the `Heap` module, and
 * stored in shared memory using the `SharedMemory` module.
 *)

open Core
open Pyre
open Ast
open Statement
module PyrePysaLogic = Analysis.PyrePysaLogic

(** Override graph in the ocaml heap, storing a mapping from a method to classes overriding it. *)
module Heap = struct
  type t = Reference.t list Target.Map.Tree.t

  let empty = Target.Map.Tree.empty

  let of_alist_exn = Target.Map.Tree.of_alist_exn

  let fold graph ~init ~f =
    Target.Map.Tree.fold graph ~init ~f:(fun ~key:member ~data:subtypes -> f ~member ~subtypes)


  let equal left right = Target.Map.Tree.equal (List.equal Reference.equal) left right

  let pp formatter overrides =
    let pp_pair formatter (member, subtypes) =
      Format.fprintf
        formatter
        "@,%a -> %s"
        Target.pp_internal
        member
        (List.map ~f:Reference.show subtypes |> String.concat ~sep:", ")
    in
    let pp_pairs formatter = List.iter ~f:(pp_pair formatter) in
    Format.fprintf formatter "{@[<v 2>%a@]@,}" pp_pairs (Target.Map.Tree.to_alist overrides)


  let show = Format.asprintf "%a" pp

  let from_source ~pyre_api ~source =
    if PyrePysaApi.ReadOnly.source_is_unit_test pyre_api ~source then
      Target.Map.Tree.empty
    else
      let timer = Timer.start () in
      let class_method_overrides { Node.value = { Class.body; name = class_name; _ }; _ } =
        let get_method_overrides child_method =
          let method_name = Define.unqualified_name child_method in
          let ancestor =
            try
              PyrePysaApi.ReadOnly.overrides pyre_api (Reference.show class_name) ~name:method_name
            with
            | PyrePysaLogic.UntrackedClass untracked_type ->
                Log.warning
                  "Found untracked type `%s` when looking for a parent of `%a.%s`. The method will \
                   be considered has having no parent, which could lead to false negatives."
                  untracked_type
                  Reference.pp
                  class_name
                  method_name;
                None
          in
          ancestor
          >>= fun ancestor ->
          let parent_annotation = PyrePysaLogic.AnnotatedAttribute.parent ancestor in
          let ancestor_parent =
            Type.Primitive parent_annotation
            |> Type.expression
            |> Expression.show
            |> Reference.create
          in
          (* This special case exists only for `type`. Our override lookup for a class C first looks
             at the regular MRO. If that fails, it looks for Type[C]'s MRO. However, when C is type,
             this causes a cycle to get registered. *)
          if Reference.equal ancestor_parent class_name then
            None
          else
            let kind =
              if Define.is_property_setter child_method then
                Target.PropertySetter
              else
                Target.Normal
            in
            Some (Target.create_method ~kind ancestor_parent method_name, class_name)
        in
        let extract_define = function
          | { Node.value = Statement.Define define; _ } -> Some define
          | _ -> None
        in
        let overrides =
          body |> List.filter_map ~f:extract_define |> List.filter_map ~f:get_method_overrides
        in
        Statistics.performance
          ~randomly_log_every:1000
          ~always_log_time_threshold:1.0 (* Seconds *)
          ~name:"Overrides built"
          ~section:`DependencyGraph
          ~normals:["class", Reference.show class_name]
          ~timer
          ();
        overrides
      in
      let record_overrides map (ancestor_method, overriding_type) =
        let update_types = function
          | Some types -> overriding_type :: types
          | None -> [overriding_type]
        in
        Target.Map.Tree.update map ancestor_method ~f:update_types
      in
      let record_overrides_list map relations = List.fold relations ~init:map ~f:record_overrides in
      Preprocessing.classes source
      |> List.map ~f:class_method_overrides
      |> List.fold ~init:Target.Map.Tree.empty ~f:record_overrides_list
      |> Target.Map.Tree.map ~f:(List.dedup_and_sort ~compare:Reference.compare)


  let skip_overrides ~to_skip overrides =
    Target.Map.Tree.filter_keys
      ~f:(fun override ->
        to_skip
        |> Reference.SerializableSet.mem
             (override
             |> Target.get_regular
             |> Target.Regular.override_to_method
             |> Target.Regular.define_name_exn)
        |> Core.not)
      overrides


  type cap_overrides_result = {
    overrides: t;
    skipped_overrides: Target.t list;
  }

  (** If a method has too many overrides, ignore them. *)
  let cap_overrides ~analyze_all_overrides_targets ~maximum_overrides overrides =
    (* Keep the information of whether we're skipping overrides in a ref that we accumulate while we
       filter the map. *)
    let skipped_overrides = ref [] in
    let keep_override_edge ~key:member ~data:subtypes =
      if Target.Set.mem member analyze_all_overrides_targets then
        let () =
          Log.info
            "Analyzing all overrides of `%s` as per @AnalyzeAllOverrides"
            (Target.show_pretty member)
        in
        true
      else
        let number_of_overrides = List.length subtypes in
        match maximum_overrides with
        | Some cap ->
            if number_of_overrides < cap then
              true
            else begin
              Log.info
                "Omitting overrides for `%s`. The number of overrides %d exceeds the limit %d."
                (Target.show_pretty member)
                number_of_overrides
                cap;
              skipped_overrides := member :: !skipped_overrides;
              false
            end
        | None ->
            if number_of_overrides > 50 then
              Log.warning
                "`%s` has %d overrides, this might slow down the analysis considerably."
                (Target.show_pretty member)
                number_of_overrides;
            true
    in
    let overrides = Target.Map.Tree.filteri overrides ~f:keep_override_edge in
    { overrides; skipped_overrides = !skipped_overrides }


  let dump ~path overrides =
    (* We represent the override graph as a target graph, by representing class names as function targets.
     * This is technically wrong but works fine in this context. *)
    Target.Map.Tree.map ~f:(List.map ~f:Target.create_function) overrides |> TargetGraph.dump ~path
end

(** Override graph in the shared memory, a mapping from a method to classes directly overriding it. *)
module SharedMemory = struct
  module T =
    SaveLoadSharedMemory.MakeKeyValue
      (Target.SharedMemoryKey)
      (struct
        type t = Reference.t list

        let prefix = Hack_parallel.Std.Prefix.make ()

        let handle_prefix = Hack_parallel.Std.Prefix.make ()

        let description = "overriding types"
      end)

  type t = T.t

  let create = T.create

  (** Records a heap override graph in shared memory. *)
  let from_heap overrides = overrides |> Target.Map.Tree.to_alist |> T.of_alist_sequential

  let to_heap handle = handle |> T.to_alist |> Target.Map.Tree.of_alist_exn

  (** Remove an override graph from shared memory. This must be called before storing another
      override graph. *)
  let cleanup = T.cleanup

  let read_only = T.read_only

  module ReadOnly = struct
    type t = T.ReadOnly.t

    let get_overriding_types handle ~member = T.ReadOnly.get handle ~cache:true member

    let overrides_exist handle member = T.ReadOnly.mem handle member

    let expand_override_targets handle callees =
      let rec expand_and_gather expanded target =
        if not (Target.is_override target) then
          target :: expanded
        else
          let make_override at_type =
            target
            |> Target.as_regular_exn
               (* TODO(T204630385): Handle `Target.Parameterized` with `Override`. *)
            |> Target.Regular.create_derived_override_exn ~at_type
            |> Target.from_regular
          in
          let corresponding_method =
            (* In the override graph, keys can only be `Target.Regular.Method` and hence not
               `Target.Parameterized`. *)
            Target.get_corresponding_method_exn ~must_be_regular:false target
          in
          let overrides =
            handle
            |> get_overriding_types ~member:corresponding_method
            |> Option.value ~default:[]
            |> List.map ~f:make_override
          in
          corresponding_method :: List.fold overrides ~f:expand_and_gather ~init:expanded
      in
      List.fold callees ~init:[] ~f:expand_and_gather |> List.dedup_and_sort ~compare:Target.compare
  end

  let save_to_cache = T.save_to_cache

  let load_from_cache = T.load_from_cache
end

type skipped_overrides = Target.t list

type whole_program_overrides = {
  override_graph_heap: Heap.t;
  override_graph_shared_memory: SharedMemory.t;
  skipped_overrides: skipped_overrides;
}

(** Compute the override graph, which maps overide_targets (parent methods which are overridden) to
    all concrete methods overriding them, and save it to shared memory. *)
let build_whole_program_overrides
    ~scheduler
    ~static_analysis_configuration:
      ({ Configuration.StaticAnalysis.scheduler_policies; _ } as static_analysis_configuration)
    ~pyre_api
    ~skip_overrides_targets
    ~maximum_overrides
    ~analyze_all_overrides_targets
    ~qualifiers
  =
  let overrides =
    let combine ~key:_ left right = List.rev_append left right in
    let build_overrides overrides qualifier =
      match PyrePysaApi.ReadOnly.source_of_qualifier pyre_api qualifier with
      | None -> overrides
      | Some source ->
          let new_overrides =
            Heap.from_source ~pyre_api ~source
            |> Heap.skip_overrides ~to_skip:skip_overrides_targets
          in
          Target.Map.Tree.merge_skewed ~combine overrides new_overrides
    in
    let scheduler_policy =
      Scheduler.Policy.from_configuration_or_default
        scheduler_policies
        Configuration.ScheduleIdentifier.OverrideGraph
        ~default:
          (Scheduler.Policy.fixed_chunk_count
             ~minimum_chunks_per_worker:1
             ~minimum_chunk_size:1
             ~preferred_chunks_per_worker:1
             ())
    in
    Scheduler.map_reduce
      scheduler
      ~policy:scheduler_policy
      ~initial:Heap.empty
      ~map:(fun qualifiers -> List.fold qualifiers ~init:Heap.empty ~f:build_overrides)
      ~reduce:(Target.Map.Tree.merge_skewed ~combine)
      ~inputs:qualifiers
      ()
  in
  let { Heap.overrides = override_graph_heap; skipped_overrides } =
    Heap.cap_overrides ~analyze_all_overrides_targets ~maximum_overrides overrides
  in
  let override_graph_shared_memory = SharedMemory.from_heap override_graph_heap in
  let () =
    match static_analysis_configuration.Configuration.StaticAnalysis.save_results_to with
    | Some path ->
        let path = PyrePath.append path ~element:"override-graph.json" in
        Log.info "Writing the override graph to `%s`" (PyrePath.absolute path);
        Heap.dump ~path override_graph_heap
    | None -> ()
  in
  { override_graph_heap; override_graph_shared_memory; skipped_overrides }
