"""
@generated by mypy-protobuf.  Do not edit manually!
isort:skip_file
"""
import builtins
import collections.abc
import sys

import google.protobuf.descriptor
import google.protobuf.internal.containers
import google.protobuf.message

if sys.version_info >= (3, 8):
    import typing as typing_extensions
else:
    import typing_extensions

DESCRIPTOR: google.protobuf.descriptor.FileDescriptor

@typing_extensions.final
class DebugTensorWatch(google.protobuf.message.Message):
    """Option for watching a node in TensorFlow Debugger (tfdbg)."""

    DESCRIPTOR: google.protobuf.descriptor.Descriptor

    NODE_NAME_FIELD_NUMBER: builtins.int
    OUTPUT_SLOT_FIELD_NUMBER: builtins.int
    DEBUG_OPS_FIELD_NUMBER: builtins.int
    DEBUG_URLS_FIELD_NUMBER: builtins.int
    TOLERATE_DEBUG_OP_CREATION_FAILURES_FIELD_NUMBER: builtins.int
    node_name: builtins.str
    """Name of the node to watch.
    Use "*" for wildcard. But note: currently, regex is not supported in
    general.
    """
    output_slot: builtins.int
    """Output slot to watch.
    The semantics of output_slot == -1 is that all outputs of the node
    will be watched (i.e., a wildcard).
    Other negative values of output_slot are invalid and will lead to
    errors currently.
    """
    @property
    def debug_ops(self) -> google.protobuf.internal.containers.RepeatedScalarFieldContainer[builtins.str]:
        """Name(s) of the debugging op(s).
        One or more than one probes on a tensor.
        e.g., {"DebugIdentity", "DebugNanCount"}
        """
    @property
    def debug_urls(self) -> google.protobuf.internal.containers.RepeatedScalarFieldContainer[builtins.str]:
        """URL(s) for debug targets(s).

        Supported URL formats are:
          - file:///foo/tfdbg_dump: Writes out Event content to file
            /foo/tfdbg_dump.  Assumes all directories can be created if they don't
            already exist.
          - grpc://localhost:11011: Sends an RPC request to an EventListener
            service running at localhost:11011 with the event.
          - memcbk:///event_key: Routes tensors to clients using the
            callback registered with the DebugCallbackRegistry for event_key.

        Each debug op listed in debug_ops will publish its output tensor (debug
        signal) to all URLs in debug_urls.

        N.B. Session::Run() supports concurrent invocations of the same inputs
        (feed keys), outputs and target nodes. If such concurrent invocations
        are to be debugged, the callers of Session::Run() must use distinct
        debug_urls to make sure that the streamed or dumped events do not overlap
        among the invocations.
        TODO(cais): More visible documentation of this in g3docs.
        """
    tolerate_debug_op_creation_failures: builtins.bool
    """Do not error out if debug op creation fails (e.g., due to dtype
    incompatibility). Instead, just log the failure.
    """
    def __init__(
        self,
        *,
        node_name: builtins.str | None = ...,
        output_slot: builtins.int | None = ...,
        debug_ops: collections.abc.Iterable[builtins.str] | None = ...,
        debug_urls: collections.abc.Iterable[builtins.str] | None = ...,
        tolerate_debug_op_creation_failures: builtins.bool | None = ...,
    ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal["debug_ops", b"debug_ops", "debug_urls", b"debug_urls", "node_name", b"node_name", "output_slot", b"output_slot", "tolerate_debug_op_creation_failures", b"tolerate_debug_op_creation_failures"]) -> None: ...

global___DebugTensorWatch = DebugTensorWatch

@typing_extensions.final
class DebugOptions(google.protobuf.message.Message):
    """Options for initializing DebuggerState in TensorFlow Debugger (tfdbg)."""

    DESCRIPTOR: google.protobuf.descriptor.Descriptor

    DEBUG_TENSOR_WATCH_OPTS_FIELD_NUMBER: builtins.int
    GLOBAL_STEP_FIELD_NUMBER: builtins.int
    RESET_DISK_BYTE_USAGE_FIELD_NUMBER: builtins.int
    @property
    def debug_tensor_watch_opts(self) -> google.protobuf.internal.containers.RepeatedCompositeFieldContainer[global___DebugTensorWatch]:
        """Debugging options"""
    global_step: builtins.int
    """Caller-specified global step count.
    Note that this is distinct from the session run count and the executor
    step count.
    """
    reset_disk_byte_usage: builtins.bool
    """Whether the total disk usage of tfdbg is to be reset to zero
    in this Session.run call. This is used by wrappers and hooks
    such as the local CLI ones to indicate that the dumped tensors
    are cleaned up from the disk after each Session.run.
    """
    def __init__(
        self,
        *,
        debug_tensor_watch_opts: collections.abc.Iterable[global___DebugTensorWatch] | None = ...,
        global_step: builtins.int | None = ...,
        reset_disk_byte_usage: builtins.bool | None = ...,
    ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal["debug_tensor_watch_opts", b"debug_tensor_watch_opts", "global_step", b"global_step", "reset_disk_byte_usage", b"reset_disk_byte_usage"]) -> None: ...

global___DebugOptions = DebugOptions

@typing_extensions.final
class DebuggedSourceFile(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor

    HOST_FIELD_NUMBER: builtins.int
    FILE_PATH_FIELD_NUMBER: builtins.int
    LAST_MODIFIED_FIELD_NUMBER: builtins.int
    BYTES_FIELD_NUMBER: builtins.int
    LINES_FIELD_NUMBER: builtins.int
    host: builtins.str
    """The host name on which a source code file is located."""
    file_path: builtins.str
    """Path to the source code file."""
    last_modified: builtins.int
    """The timestamp at which the source code file is last modified."""
    bytes: builtins.int
    """Byte size of the file."""
    @property
    def lines(self) -> google.protobuf.internal.containers.RepeatedScalarFieldContainer[builtins.str]:
        """Line-by-line content of the source code file."""
    def __init__(
        self,
        *,
        host: builtins.str | None = ...,
        file_path: builtins.str | None = ...,
        last_modified: builtins.int | None = ...,
        bytes: builtins.int | None = ...,
        lines: collections.abc.Iterable[builtins.str] | None = ...,
    ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal["bytes", b"bytes", "file_path", b"file_path", "host", b"host", "last_modified", b"last_modified", "lines", b"lines"]) -> None: ...

global___DebuggedSourceFile = DebuggedSourceFile

@typing_extensions.final
class DebuggedSourceFiles(google.protobuf.message.Message):
    DESCRIPTOR: google.protobuf.descriptor.Descriptor

    SOURCE_FILES_FIELD_NUMBER: builtins.int
    @property
    def source_files(self) -> google.protobuf.internal.containers.RepeatedCompositeFieldContainer[global___DebuggedSourceFile]:
        """A collection of source code files."""
    def __init__(
        self,
        *,
        source_files: collections.abc.Iterable[global___DebuggedSourceFile] | None = ...,
    ) -> None: ...
    def ClearField(self, field_name: typing_extensions.Literal["source_files", b"source_files"]) -> None: ...

global___DebuggedSourceFiles = DebuggedSourceFiles