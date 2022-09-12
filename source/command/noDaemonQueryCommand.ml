(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open Core

module ExitStatus = struct
  type t =
    | Ok
    | PyreError
  [@@deriving sexp, compare, hash]

  let exit_code = function
    | Ok -> 0
    | PyreError -> 1
end

module QueryConfiguration = struct
  type t = {
    base: CommandStartup.BaseConfiguration.t;
    query: string;
  }
  [@@deriving sexp, compare, hash]

  let of_yojson json =
    let open Yojson.Safe.Util in
    let open JsonParsing in
    (* Parsing logic *)
    try
      match CommandStartup.BaseConfiguration.of_yojson json with
      | Result.Error _ as error -> error
      | Result.Ok base ->
          let query = json |> string_member "query" ~default:"" in
          Result.Ok { base; query }
    with
    | Type_error (message, _)
    | Undefined (message, _) ->
        Result.Error message
    | other_exception -> Result.Error (Exn.to_string other_exception)


  let analysis_configuration_of
      {
        base =
          {
            CommandStartup.BaseConfiguration.source_paths;
            search_paths;
            excludes;
            checked_directory_allowlist;
            checked_directory_blocklist;
            extensions;
            log_path;
            global_root;
            local_root;
            debug;
            enable_type_comments;
            python_version = { Configuration.PythonVersion.major; minor; micro };
            parallel;
            number_of_workers;
            shared_memory =
              { Configuration.SharedMemory.heap_size; dependency_table_power; hash_table_power };
            remote_logging = _;
            profiling_output = _;
            memory_profiling_output = _;
          };
        query = _;
      }
    =
    Configuration.Analysis.create
      ~parallel
      ~analyze_external_sources:false
      ~filter_directories:checked_directory_allowlist
      ~ignore_all_errors:checked_directory_blocklist
      ~number_of_workers
      ~local_root:(Option.value local_root ~default:global_root)
      ~project_root:global_root
      ~search_paths:(List.map search_paths ~f:SearchPath.normalize)
      ~debug
      ~excludes
      ~extensions
      ~incremental_style:Configuration.Analysis.Shallow
      ~log_directory:(PyrePath.absolute log_path)
      ~python_major_version:major
      ~python_minor_version:minor
      ~python_micro_version:micro
      ~shared_memory_heap_size:heap_size
      ~shared_memory_dependency_table_power:dependency_table_power
      ~shared_memory_hash_table_power:hash_table_power
      ~enable_type_comments
      ~source_paths:(Configuration.SourcePaths.to_search_paths source_paths)
      ()
end

let get_environment configuration =
  Scheduler.with_scheduler ~configuration ~f:(fun _ ->
      let read_write_environment =
        Analysis.EnvironmentControls.create ~populate_call_graph:false configuration
        |> Analysis.ErrorsEnvironment.create
      in
      Analysis.OverlaidEnvironment.create read_write_environment)


let perform_query ~configuration ~build_system ~query () =
  let environment = get_environment configuration in
  let query_response =
    (* Add overlay support later *)
    Server.Query.parse_and_process_request ~environment ~build_system query None
  in
  Server.Response.to_yojson (Server.Response.Query query_response)


let run_query_on_query_configuration query_configuration =
  let { QueryConfiguration.base = { CommandStartup.BaseConfiguration.source_paths; _ }; query; _ } =
    query_configuration
  in
  Server.BuildSystem.with_build_system source_paths ~f:(fun build_system ->
      let query_response =
        perform_query
          ~configuration:(QueryConfiguration.analysis_configuration_of query_configuration)
          ~build_system
          ~query
          ()
      in
      Printf.printf "%s" (Yojson.Safe.to_string query_response);
      Lwt.return ExitStatus.Ok)


let run_query configuration_file =
  let exit_status =
    match CommandStartup.read_and_parse_json configuration_file ~f:QueryConfiguration.of_yojson with
    | Result.Error message ->
        let () = Log.info "Encountered error with message: %s" message in
        ExitStatus.PyreError
    | Result.Ok
        ({
           QueryConfiguration.base =
             {
               CommandStartup.BaseConfiguration.global_root;
               local_root;
               debug;
               remote_logging;
               profiling_output;
               memory_profiling_output;
               _;
             };
           _;
         } as query_configuration) ->
        CommandStartup.setup_global_states
          ~global_root
          ~local_root
          ~debug
          ~additional_logging_sections:[]
          ~remote_logging
          ~profiling_output
          ~memory_profiling_output
          ();
        Lwt_main.run
          (Lwt.catch
             (fun () -> run_query_on_query_configuration query_configuration)
             (fun exn ->
               let () = Log.info "Got exception: %s" (Exn.to_string exn) in
               Lwt.return ExitStatus.PyreError))
  in
  Statistics.flush ();
  exit (ExitStatus.exit_code exit_status)


let command =
  Printexc.record_backtrace true;
  let filename_argument = Command.Param.(anon ("filename" %: Filename.arg_type)) in
  Command.basic
    ~summary:"Runs a full check without a server"
    (Command.Param.map filename_argument ~f:(fun filename () -> run_query filename))