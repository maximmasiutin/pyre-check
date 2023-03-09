import logging
import socket as _socket
import ssl as _ssl
import time
import types
from _typeshed import Incomplete, Unused
from collections.abc import Callable
from typing import Any, TypeVar
from typing_extensions import TypeAlias

from .matcher import MQTTMatcher as MQTTMatcher
from .properties import Properties as Properties
from .reasoncodes import ReasonCodes as ReasonCodes
from .subscribeoptions import SubscribeOptions as SubscribeOptions

ssl: types.ModuleType | None
socks: types.ModuleType | None
time_func = time.monotonic
HAVE_DNS: bool
EAGAIN: int | Incomplete
MQTTv31: int
MQTTv311: int
MQTTv5: int
unicode = str
basestring = str
CONNECT: int
CONNACK: int
PUBLISH: int
PUBACK: int
PUBREC: int
PUBREL: int
PUBCOMP: int
SUBSCRIBE: int
SUBACK: int
UNSUBSCRIBE: int
UNSUBACK: int
PINGREQ: int
PINGRESP: int
DISCONNECT: int
AUTH: int
MQTT_LOG_INFO: int
MQTT_LOG_NOTICE: int
MQTT_LOG_WARNING: int
MQTT_LOG_ERR: int
MQTT_LOG_DEBUG: int
LOGGING_LEVEL: dict[int, int]
CONNACK_ACCEPTED: int
CONNACK_REFUSED_PROTOCOL_VERSION: int
CONNACK_REFUSED_IDENTIFIER_REJECTED: int
CONNACK_REFUSED_SERVER_UNAVAILABLE: int
CONNACK_REFUSED_BAD_USERNAME_PASSWORD: int
CONNACK_REFUSED_NOT_AUTHORIZED: int
mqtt_cs_new: int
mqtt_cs_connected: int
mqtt_cs_disconnecting: int
mqtt_cs_connect_async: int
mqtt_ms_invalid: int
mqtt_ms_publish: int
mqtt_ms_wait_for_puback: int
mqtt_ms_wait_for_pubrec: int
mqtt_ms_resend_pubrel: int
mqtt_ms_wait_for_pubrel: int
mqtt_ms_resend_pubcomp: int
mqtt_ms_wait_for_pubcomp: int
mqtt_ms_send_pubrec: int
mqtt_ms_queued: int
MQTT_ERR_AGAIN: int
MQTT_ERR_SUCCESS: int
MQTT_ERR_NOMEM: int
MQTT_ERR_PROTOCOL: int
MQTT_ERR_INVAL: int
MQTT_ERR_NO_CONN: int
MQTT_ERR_CONN_REFUSED: int
MQTT_ERR_NOT_FOUND: int
MQTT_ERR_CONN_LOST: int
MQTT_ERR_TLS: int
MQTT_ERR_PAYLOAD_SIZE: int
MQTT_ERR_NOT_SUPPORTED: int
MQTT_ERR_AUTH: int
MQTT_ERR_ACL_DENIED: int
MQTT_ERR_UNKNOWN: int
MQTT_ERR_ERRNO: int
MQTT_ERR_QUEUE_SIZE: int
MQTT_ERR_KEEPALIVE: int
MQTT_CLIENT: int
MQTT_BRIDGE: int
MQTT_CLEAN_START_FIRST_ONLY: int
sockpair_data: bytes
_UserData: TypeAlias = Any
_Socket: TypeAlias = _socket.socket | _ssl.SSLSocket | Incomplete
_Payload: TypeAlias = str | bytes | bytearray | float
_ExtraHeader: TypeAlias = dict[str, str] | Callable[[dict[str, str]], dict[str, str]]
_OnLog: TypeAlias = Callable[[Client, _UserData, int, str], object]
_OnConnect: TypeAlias = Callable[[Client, _UserData, dict[str, int], int], object]
_OnConnectV5: TypeAlias = Callable[[Client, _UserData, dict[str, int], ReasonCodes, Properties | None], object]
_TOnConnect = TypeVar("_TOnConnect", _OnConnect, _OnConnectV5)
_OnConnectFail: TypeAlias = Callable[[Client, _UserData], object]
_OnSubscribe: TypeAlias = Callable[[Client, _UserData, int, tuple[int]], object]
_OnSubscribeV5: TypeAlias = Callable[[Client, _UserData, int, list[ReasonCodes], Properties], object]
_TOnSubscribe = TypeVar("_TOnSubscribe", _OnSubscribe, _OnSubscribeV5)
_OnMessage: TypeAlias = Callable[[Client, _UserData, MQTTMessage], object]
_OnPublish: TypeAlias = Callable[[Client, _UserData, int], object]
_OnUnsubscribe: TypeAlias = Callable[[Client, _UserData, int], object]
_OnUnsubscribeV5: TypeAlias = Callable[[Client, _UserData, int, Properties, list[ReasonCodes] | ReasonCodes], object]
_TOnUnsubscribe = TypeVar("_TOnUnsubscribe", _OnUnsubscribe, _OnUnsubscribeV5)
_OnDisconnect: TypeAlias = Callable[[Client, _UserData, int], object]
_OnDisconnectV5: TypeAlias = Callable[[Client, _UserData, ReasonCodes | None, Properties | None], object]
_TOnDisconnect = TypeVar("_TOnDisconnect", _OnDisconnect, _OnDisconnectV5)
_OnSocket: TypeAlias = Callable[[Client, _UserData, _Socket | WebsocketWrapper | None], object]

class WebsocketConnectionError(ValueError): ...

def error_string(mqtt_errno: int) -> str: ...
def connack_string(connack_code: int) -> str: ...
def base62(num: int, base: str = ..., padding: int = ...) -> str: ...
def topic_matches_sub(sub: str, topic: str) -> bool: ...

class MQTTMessageInfo:
    mid: int
    rc: int
    def __init__(self, mid: int) -> None: ...
    def __iter__(self) -> MQTTMessageInfo: ...
    def __next__(self) -> int: ...
    def next(self) -> int: ...
    def __getitem__(self, index: int) -> int: ...
    def wait_for_publish(self, timeout: float | None = ...) -> None: ...
    def is_published(self) -> bool: ...

class MQTTMessage:
    timestamp: int
    state: int
    dup: bool
    mid: int
    payload: bytes | bytearray
    qos: int
    retain: bool
    info: MQTTMessageInfo
    properties: Properties | None
    def __init__(self, mid: int = ..., topic: bytes | bytearray = ...) -> None: ...
    def __eq__(self, other: object) -> bool: ...
    def __ne__(self, other: object) -> bool: ...
    @property
    def topic(self) -> str: ...
    @topic.setter
    def topic(self, value: bytes | bytearray) -> None: ...

class Client:
    suppress_exceptions: bool
    def __init__(
        self,
        client_id: str | None = ...,
        clean_session: bool | None = ...,
        userdata: _UserData | None = ...,
        protocol: int = ...,
        transport: str = ...,
        reconnect_on_failure: bool = ...,
    ) -> None: ...
    def __del__(self) -> None: ...
    def reinitialise(self, client_id: str = ..., clean_session: bool = ..., userdata: _UserData | None = ...) -> None: ...
    def ws_set_options(self, path: str = ..., headers: _ExtraHeader | None = ...) -> None: ...
    def tls_set_context(self, context: _ssl.SSLContext | None = ...) -> None: ...
    def tls_set(
        self,
        ca_certs: str | None = ...,
        certfile: str | None = ...,
        keyfile: str | None = ...,
        cert_reqs: _ssl.VerifyMode | None = ...,
        tls_version: _ssl._SSLMethod | None = ...,
        ciphers: str | None = ...,
        keyfile_password: _ssl._PasswordType | None = ...,
    ) -> None: ...
    def tls_insecure_set(self, value: bool) -> None: ...
    def proxy_set(self, **proxy_args: Any) -> None: ...
    def enable_logger(self, logger: logging.Logger | None = ...) -> None: ...
    def disable_logger(self) -> None: ...
    def connect(
        self,
        host: str,
        port: int = ...,
        keepalive: int = ...,
        bind_address: str = ...,
        bind_port: int = ...,
        clean_start: int = ...,
        properties: Properties | None = ...,
    ) -> int: ...
    def connect_srv(
        self,
        domain: str | None = ...,
        keepalive: int = ...,
        bind_address: str = ...,
        clean_start: int = ...,
        properties: Properties | None = ...,
    ) -> int: ...
    def connect_async(
        self,
        host: str,
        port: int = ...,
        keepalive: int = ...,
        bind_address: str = ...,
        bind_port: int = ...,
        clean_start: int = ...,
        properties: Properties | None = ...,
    ) -> None: ...
    def reconnect_delay_set(self, min_delay: int = ..., max_delay: int = ...) -> None: ...
    def reconnect(self) -> int: ...
    def loop(self, timeout: float = ..., max_packets: int = ...) -> int: ...
    def publish(
        self, topic: str, payload: _Payload | None = ..., qos: int = ..., retain: bool = ..., properties: Properties | None = ...
    ) -> MQTTMessageInfo: ...
    def username_pw_set(self, username: str, password: str | bytes | bytearray | None = ...) -> None: ...
    def enable_bridge_mode(self) -> None: ...
    def is_connected(self) -> bool: ...
    def disconnect(self, reasoncode: ReasonCodes | None = ..., properties: Properties | None = ...) -> int: ...
    def subscribe(
        self,
        topic: str | tuple[str, SubscribeOptions] | list[tuple[str, SubscribeOptions]] | list[tuple[str, int]],
        qos: int = ...,
        options: SubscribeOptions | None = ...,
        properties: Properties | None = ...,
    ) -> tuple[int, int]: ...
    def unsubscribe(self, topic: str | list[str], properties: Properties | None = ...) -> tuple[int, int]: ...
    def loop_read(self, max_packets: int = ...) -> int: ...
    def loop_write(self, max_packets: int = ...) -> int: ...
    def want_write(self) -> bool: ...
    def loop_misc(self) -> int: ...
    def max_inflight_messages_set(self, inflight: int) -> None: ...
    def max_queued_messages_set(self, queue_size: int) -> Client: ...
    def message_retry_set(self, retry: Unused) -> None: ...
    def user_data_set(self, userdata: _UserData) -> None: ...
    def will_set(
        self, topic: str, payload: _Payload | None = ..., qos: int = ..., retain: bool = ..., properties: Properties | None = ...
    ) -> None: ...
    def will_clear(self) -> None: ...
    def socket(self) -> _Socket | WebsocketWrapper: ...
    def loop_forever(self, timeout: float = ..., max_packets: int = ..., retry_first_connection: bool = ...) -> int: ...
    def loop_start(self) -> int | None: ...
    def loop_stop(self, force: bool = ...) -> int | None: ...
    @property
    def on_log(self) -> _OnLog | None: ...
    @on_log.setter
    def on_log(self, func: _OnLog | None) -> None: ...
    def log_callback(self) -> Callable[[_OnLog], _OnLog]: ...
    @property
    def on_connect(self) -> _OnConnect | _OnConnectV5 | None: ...
    @on_connect.setter
    def on_connect(self, func: _OnConnect | _OnConnectV5 | None) -> None: ...
    def connect_callback(self) -> Callable[[_TOnConnect], _TOnConnect]: ...
    @property
    def on_connect_fail(self) -> _OnConnectFail | None: ...
    @on_connect_fail.setter
    def on_connect_fail(self, func: _OnConnectFail | None) -> None: ...
    def connect_fail_callback(self) -> Callable[[_OnConnectFail], _OnConnectFail]: ...
    @property
    def on_subscribe(self) -> _OnSubscribe | _OnSubscribeV5 | None: ...
    @on_subscribe.setter
    def on_subscribe(self, func: _OnSubscribe | _OnSubscribeV5 | None) -> None: ...
    def subscribe_callback(self) -> Callable[[_TOnSubscribe], _TOnSubscribe]: ...
    @property
    def on_message(self) -> _OnMessage | None: ...
    @on_message.setter
    def on_message(self, func: _OnMessage | None) -> None: ...
    def message_callback(self) -> Callable[[_OnMessage], _OnMessage]: ...
    @property
    def on_publish(self) -> _OnPublish | None: ...
    @on_publish.setter
    def on_publish(self, func: _OnPublish | None) -> None: ...
    def publish_callback(self) -> Callable[[_OnPublish], _OnPublish]: ...
    @property
    def on_unsubscribe(self) -> _OnUnsubscribe | _OnUnsubscribeV5 | None: ...
    @on_unsubscribe.setter
    def on_unsubscribe(self, func: _OnUnsubscribe | _OnUnsubscribeV5 | None) -> None: ...
    def unsubscribe_callback(self) -> Callable[[_TOnUnsubscribe], _TOnUnsubscribe]: ...
    @property
    def on_disconnect(self) -> _OnDisconnect | _OnDisconnectV5 | None: ...
    @on_disconnect.setter
    def on_disconnect(self, func: _OnDisconnect | _OnDisconnectV5 | None) -> None: ...
    def disconnect_callback(self) -> Callable[[_TOnDisconnect], _TOnDisconnect]: ...
    @property
    def on_socket_open(self) -> _OnSocket | None: ...
    @on_socket_open.setter
    def on_socket_open(self, func: _OnSocket | None) -> None: ...
    def socket_open_callback(self) -> Callable[[_OnSocket], _OnSocket]: ...
    @property
    def on_socket_close(self) -> _OnSocket | None: ...
    @on_socket_close.setter
    def on_socket_close(self, func: _OnSocket | None) -> None: ...
    def socket_close_callback(self) -> Callable[[_OnSocket], _OnSocket]: ...
    @property
    def on_socket_register_write(self) -> _OnSocket | None: ...
    @on_socket_register_write.setter
    def on_socket_register_write(self, func: _OnSocket | None) -> None: ...
    def socket_register_write_callback(self) -> Callable[[_OnSocket], _OnSocket]: ...
    @property
    def on_socket_unregister_write(self) -> _OnSocket | None: ...
    @on_socket_unregister_write.setter
    def on_socket_unregister_write(self, func: _OnSocket | None) -> None: ...
    def socket_unregister_write_callback(self) -> Callable[[_OnSocket], _OnSocket]: ...
    def message_callback_add(self, sub: str, callback: _OnMessage) -> None: ...
    def topic_callback(self, sub: str) -> Callable[[_OnMessage], _OnMessage]: ...
    def message_callback_remove(self, sub: str) -> None: ...

class WebsocketWrapper:
    OPCODE_CONTINUATION: int
    OPCODE_TEXT: int
    OPCODE_BINARY: int
    OPCODE_CONNCLOSE: int
    OPCODE_PING: int
    OPCODE_PONG: int
    connected: bool
    def __init__(
        self, socket: _Socket, host: str, port: int, is_ssl: bool, path: str, extra_headers: _ExtraHeader | None
    ) -> None: ...
    def __del__(self) -> None: ...
    def recv(self, length: int) -> bytes | bytearray | None: ...
    def read(self, length: int) -> bytes | bytearray | None: ...
    def send(self, data: bytes | bytearray) -> int: ...
    def write(self, data: bytes | bytearray) -> int: ...
    def close(self) -> None: ...
    def fileno(self) -> int: ...
    def pending(self) -> int: ...
    def setblocking(self, flag: bool) -> None: ...