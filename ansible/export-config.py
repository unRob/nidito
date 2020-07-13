import config_yourself as cy
from json import dumps as json_encode
from os import environ
from base64 import b64encode
from sys import argv

def is_primitive(el): return isinstance(el, (str, int, float))

class ConfigProcessor(object):
    def __init__(self, data, path):
        self._data = []
        self.process(data, path)

    def dict(self, data, path):
        pass

    def list(self, data, path):
        pass

    def primitive(self, data, path):
        pass

    def write(self, name):
        raise Exception(f"Unknown formatter {name}")

    def process(self, data, path):
        if isinstance(data, dict):
            self.dict(data, path)
        elif isinstance(data, list):
            self.list(data, path)
        else:
            self.primitive(data, path)

class Consul(ConfigProcessor):
    def primitive(self, data, path, raw=False):
        if raw:
            path += ["_json"]
            data = json_encode(data)

        self._data.append({
            'key': '/'.join(path),
            'flags': 0,
            'value': b64encode(str(data).encode('utf-8')).decode('utf-8'),
        })

    def list(self, data, path):
        if len(data) == 0 or all(map(is_primitive, data)):
            return self.primitive(data, path, raw=True)

        for k, v in enumerate(data):
            self.process(v, path + [str(k)])

    def dict(self, data, path):
        for k, v in data.items():
            if str(k)[0] == '_': pass
            self.process(v, path + [k])

    def write(self):
        return json_encode(self._data)


class Vault(ConfigProcessor):
    def __init__(self, data, path):
        self._data = {}
        self.process(data, path)

    def primitive(self, data, path, raw=False):
        self._data['/'.join(path)] = {"json": json_encode(data)} if raw else data

    def list(self, data, path):
        if len(data) == 0 or all(map(is_primitive, data)):
            return self.primitive(data, path, raw=True)
        else:
             for k, v in enumerate(data):
                self.process(v, path + [str(k)])

    def dict(self, data, path):
        top = dict()
        for k, v in data.items():
            if str(k)[0] == '_': pass
            elif not is_primitive(v): self.process(v, path + [str(k)])
            else: top[k] = v

        if len(top.keys()) > 0:
            self.primitive(top, path)

    def write(self):
        return "\n".join([
            f"{k} {json_encode(v)}" for k, v in self._data.items()
        ])

file = cy.load.file(environ.get('CONFIG_FILE', 'config.yml'))
password = environ.get('CONFIG_PASSWORD')
data = dict(cy.Config(file, password = password))
del data['crypto']

data['nodes']['json'] = json_encode(data['nodes'])

processor = Consul if argv[1:] == ["consul"] else Vault
print(processor(data, ['nidito', 'config']).write())
