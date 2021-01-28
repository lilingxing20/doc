import os
import six
from cryptography import fernet
import msgpack
import uuid
import time
import datetime
import base64
import sys
import hashlib
from oslo_utils import timeutils


_DEFAULT_AUTH_METHODS = ['external', 'password', 'token', 'oauth1', 'mapped',
                         'application_credential']

_ISO8601_TIME_FORMAT_SUBSECOND = '%Y-%m-%dT%H:%M:%S.%f'
_ISO8601_TIME_FORMAT = '%Y-%m-%dT%H:%M:%S'


def load_keys():
    """
    build a dictionary of key_number:encryption_key pairs.
    """
    key_repo = "/etc/keystone/fernet-keys/"
    keys = dict()
    for filename in os.listdir(key_repo):
        path = os.path.join(key_repo, str(filename))
        if os.path.isfile(path):
            with open(path, 'r') as key_file:
                try:
                    key_id = int(filename)
                except ValueError:
                    # nosec : name is not a number
                    pass
                else:
                    key = key_file.read()
                    if len(key) == 0:
                        print('Ignoring empty key found in key repository: %s', path)
                        continue
                    keys[key_id] = key
    # return the encryption_keys, sorted by key number, descending
    key_list = [keys[x] for x in sorted(keys.keys(), reverse=True)]
    return key_list


def convert_uuid_bytes_to_hex(uuid_byte_string):
    uuid_obj = uuid.UUID(bytes=uuid_byte_string)
    return uuid_obj.hex


def _convert_or_decode(is_stored_as_bytes, value):
    """Convert a value to text type, translating uuid -> hex if required.

    :param is_stored_as_bytes: whether value is already bytes
    :type is_stored_as_bytes: boolean
    :param value: value to attempt to convert to bytes
    :type value: str or bytes
    :rtype: str
    """
    if is_stored_as_bytes:
        return convert_uuid_bytes_to_hex(value)
    elif isinstance(value, bytes):
        return value.decode('utf-8')
    return value


def _convert_float_to_time_string(time_float):
    """Convert a floating point timestamp to a string.

    :param time_float: integer representing timestamp
    :returns: a time formatted strings

    """
    time_object = datetime.datetime.utcfromtimestamp(time_float)
    return isotime(time_object, subsecond=True)


def base64_encode(s):
    """Encode a URL-safe string.

    :type s: str
    :rtype: str

    """
    # urlsafe_b64encode() returns bytes so need to convert to
    # str, might as well do it before stripping.
    return base64.urlsafe_b64encode(s).decode('utf-8').rstrip('=')


## from keystone.common.utils import isotime
def isotime(at=None, subsecond=False):
    if not at:
        at = timeutils.utcnow()
    # NOTE(lbragstad): Datetime objects are immutable, so reassign the date we
    # are working with to itself as we drop microsecond precision.
    at = at.replace(microsecond=0)
    st = at.strftime(_ISO8601_TIME_FORMAT
                     if not subsecond
                     else _ISO8601_TIME_FORMAT_SUBSECOND)
    tz = at.tzinfo.tzname(None) if at.tzinfo else 'UTC'
    # Need to handle either iso8601 or python UTC format
    st += ('Z' if tz in ['UTC', 'UTC+00:00'] else tz)
    return st


def disassemble(payload):
    (is_stored_as_bytes, user_id) = payload[0]
    user_id = "user_id = " + _convert_or_decode(is_stored_as_bytes, user_id)
    methods = "method = " + ','.join(convert_integer_to_method_list(payload[1]))
    (is_stored_as_bytes, project_id) = payload[2]
    project_id = "project_id = " + _convert_or_decode(is_stored_as_bytes, project_id)
    expires_at_str = "expired_at = " + _convert_float_to_time_string(payload[3])
    #expires_at_str = "expired_at = " + time.strftime(_ISO8601_TIME_FORMAT,time.localtime((payload[3])))
    audit_ids = list(map(base64_encode, payload[4]))
    return (methods, user_id, project_id, expires_at_str, audit_ids)


def restore_padding(token):
    """Restore padding based on token size.

    :param token: token to restore padding on
    :type token: str
    :returns: token with correct padding

    """
    # Re-inflate the padding
    mod_returned = len(token) % 4
    if mod_returned:
        missing_padding = 4 - mod_returned
        token += '=' * missing_padding
    return token

def crypto():
    """
    Return a cryptography instance.
    """
    keys = load_keys()
    fernet_instances = [fernet.Fernet(key) for key in keys]
    return fernet.MultiFernet(fernet_instances)

def unpack(token):
    """Unpack a token, and validate the payload.

    :type token: str
    :rtype: bytes

    """
    token = restore_padding(token)
    crypto_instance = crypto()
    return crypto_instance.decrypt(token.encode('utf-8'))

def validate_token(token):
    """Validate a Fernet token and returns the payload attributes.

    :type token: str

    """
    serialized_payload = unpack(token)
    # TODO(melwitt): msgpack changed their data format in version 1.0, so
    # in order to support a rolling upgrade, we must pass raw=True to
    # support the old format. The try-except may be removed once the
    # N-1 release no longer supports msgpack < 1.0.
    try:
        versioned_payload = msgpack.unpackb(serialized_payload)
    except UnicodeDecodeError:
        versioned_payload = msgpack.unpackb(serialized_payload, raw=True)

    version, payload = versioned_payload[0], versioned_payload[1:]
    # print("token version: %s" % version)
    # print("token payload: %s" % payload)
    # version 2 is ProjectScopedPayload ,see keystone/token/providers/fernet/token_formatters.py
    if version == 2:
        return disassemble(payload)
    else:
        return None
# =====

def convert_uuid_hex_to_bytes(uuid_string):
    """Compress UUID formatted strings to bytes.

    :param uuid_string: uuid string to compress to bytes
    :returns: a byte representation of the uuid

    """
    uuid_obj = uuid.UUID(uuid_string)
    return uuid_obj.bytes


def _convert_time_string_to_float(time_string):
    """Convert a time formatted string to a float.

    :param time_string: time formatted string
    :returns: a timestamp as a float

    """
    time_object = timeutils.parse_isotime(time_string)
    return (timeutils.normalize_time(time_object) -
            datetime.datetime.utcfromtimestamp(0)).total_seconds()

def construct_method_map_from_config():
    """Determine authentication method types for deployment.

    :returns: a dictionary containing the methods and their indexes

    """
    method_map = dict()
    method_index = 1
    for method in _DEFAULT_AUTH_METHODS:
        method_map[method_index] = method
        method_index = method_index * 2

    return method_map

def convert_method_list_to_integer(methods):
    """Convert the method type(s) to an integer.

    :param methods: a list of method names
    :returns: an integer representing the methods

    """
    method_map = construct_method_map_from_config()

    method_ints = []
    for method in methods:
        for k, v in method_map.items():
            if v == method:
                method_ints.append(k)
    return sum(method_ints)

def convert_integer_to_method_list(method_int):
    """Convert an integer to a list of methods.

    :param method_int: an integer representing methods
    :returns: a corresponding list of methods

    """
    # If the method_int is 0 then no methods were used so return an empty
    # method list
    if method_int == 0:
        return []

    method_map = construct_method_map_from_config()
    method_ints = sorted(method_map, reverse=True)

    methods = []
    for m_int in method_ints:
        result = int(method_int / m_int)
        if result == 1:
            methods.append(method_map[m_int])
            method_int = method_int - m_int

    return methods

def random_urlsafe_str_to_bytes(s):
    """Convert string from :func:`random_urlsafe_str()` to bytes.

    :type s: str
    :rtype: bytes

    """
    # urlsafe_b64decode() requires str, unicode isn't accepted.
    s = str(s)

    # restore the padding (==) at the end of the string
    return base64.urlsafe_b64decode(s + '==')


def attempt_convert_uuid_hex_to_bytes(value):
    """Attempt to convert value to bytes or return value.

    :param value: value to attempt to convert to bytes
    :returns: tuple containing boolean indicating whether user_id was
              stored as bytes and uuid value as bytes or the original value

    """
    try:
        return (True, convert_uuid_hex_to_bytes(value))
    except (ValueError, TypeError):
        return (False, value)


def assemble(user_id, methods, system, project_id, domain_id,
             expires_at, audit_ids, trust_id, federated_group_ids,
             identity_provider_id, protocol_id, access_token_id,
             app_cred_id):
    b_user_id = attempt_convert_uuid_hex_to_bytes(user_id)
    methods = convert_method_list_to_integer(methods)
    b_project_id = attempt_convert_uuid_hex_to_bytes(project_id)
    expires_at_int = _convert_time_string_to_float(expires_at)
    b_audit_ids = list(map(random_urlsafe_str_to_bytes,
                       audit_ids))
    return (b_user_id, methods, b_project_id, expires_at_int, b_audit_ids)

def pack(payload):
    """Pack a payload for transport as a token.

    :type payload: bytes
    :rtype: str

    """
    # base64 padding (if any) is not URL-safe
    crypto_instance = crypto()
    return crypto_instance.encrypt(payload).rstrip(b'=').decode('utf-8')

def create_token(user_id, expires_at, audit_ids,
                 methods=None, system=None, domain_id=None,
                 project_id=None, trust_id=None, federated_group_ids=None,
                 identity_provider_id=None, protocol_id=None,
                 access_token_id=None, app_cred_id=None):
    """Given a set of payload attributes, generate a Fernet token."""
    version = 2
    payload = assemble(
        user_id, methods, system, project_id, domain_id, expires_at,
        audit_ids, trust_id, federated_group_ids, identity_provider_id,
        protocol_id, access_token_id, app_cred_id
    )

    versioned_payload = (version,) + payload
    serialized_payload = msgpack.packb(versioned_payload)
    token = pack(serialized_payload)

    if len(token) > 255:
        print('Fernet token created with length of %d '
              'characters, which exceeds 255 characters'
               % len(token))
    return token

def default_expire_time():
    """Determine when a fresh token should expire.

    Expiration time varies based on configuration (see ``[token] expiration``).

    :returns: a naive UTC datetime.datetime object

    """
    expire_delta = datetime.timedelta(seconds=3600)
    expires_at = timeutils.utcnow() + expire_delta
    return expires_at.replace(microsecond=0)


def random_urlsafe_str():
    """Generate a random URL-safe string.

    :rtype: str
    """
    # chop the padding (==) off the end of the encoding to save space
    return base64.urlsafe_b64encode(uuid.uuid4().bytes)[:-2].decode('utf-8')

# =====

if __name__ == '__main__':
    if len(sys.argv) > 1:
        token= sys.argv[1]
    else:
        print("Please input a fernet token:")
        exit()
    res = validate_token(token)
    if not res:
	print("Could only resolve ProjectScopedPayload!")
        exit()
    print("\nUnpack Token Info:")
    for i in res:
        print(i)


    print("\nCreate Token:")
    user_id = hashlib.sha256().hexdigest()
    project_id = hashlib.sha256().hexdigest()
    user_id = 'da1f1d2c930840529ac79c4fe332d7bd'
    project_id = '73cf8d10dfea4e6f860ab5ea278b1482'
    methods = _DEFAULT_AUTH_METHODS
    expires_at = isotime(default_expire_time(), subsecond=True)
    audit_ids = [random_urlsafe_str()]
    token = create_token(user_id, expires_at, audit_ids,
                 methods=methods, system=None, domain_id=None,
                 project_id=project_id, trust_id=None, federated_group_ids=None,
                 identity_provider_id=None, protocol_id=None,
                 access_token_id=None, app_cred_id=None)
    print(token)
    res = validate_token(token)
    if not res:
	print("Could only resolve ProjectScopedPayload!")
        exit()
    print("\nUnpack Token Info:")
    for i in res:
        print(i)

