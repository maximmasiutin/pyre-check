(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

val run_taint_analysis
  :  static_analysis_configuration:Configuration.StaticAnalysis.t ->
  lookup_source:(ArtifactPath.t -> SourcePath.t option) ->
  scheduler:Scheduler.t ->
  unit ->
  unit

val initialize_and_verify_configuration
  :  static_analysis_configuration:Configuration.StaticAnalysis.t ->
  Taint.TaintConfiguration.Heap.t
