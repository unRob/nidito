import config_yourself as cy
from json import dumps as json_encode
from os import environ
from base64 import b64encode

file = cy.load.file(environ.get('CONFIG_FILE', 'config.yml'))
password = environ.get('CONFIG_PASSWORD')

data = dict(cy.Config(file, password = password))
del data['crypto']

def recurse (col, d, path):
    if isinstance(d, dict):
        for k, v in d.items():
            if str(k)[0] == '_':
                continue

            subpath = path + [str(k)]
            recurse(col, v, subpath)
    elif isinstance(d, list):
        if len(d) == 0 or isinstance(d[0], str):
            # add a copy of json-encoded data
            # useful for interpolation in toml configs and stuff
            col.append({
                'key': '/'.join(path + ["_json"]),
                'flags': 0,
                'value': b64encode(json_encode(d).encode('utf-8')).decode('utf-8'),
            })
        for k, v in enumerate(d):
            subpath = path + [str(k)]
            recurse(col, v, subpath)
    else:
        col.append({
            'key': '/'.join(path),
            'flags': 0,
            'value': b64encode(str(d).encode('utf-8')).decode('utf-8'),
        })


    return col

values = []

print(json_encode(recurse(values, data, ['nidito', 'config'])))
# consul kv import <(pipenv run python config-to-consul.py)
