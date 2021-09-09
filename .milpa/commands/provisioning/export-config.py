import config_yourself as cy
from json import dumps as json_encode
from os import environ, path as _path
from sys import argv

def is_primitive(el): return isinstance(el, (str, int, float))

class Vault():
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

    def process(self, data, path):
        if isinstance(data, dict):
            self.dict(data, path)
        elif isinstance(data, list):
            self.list(data, path)
        else:
            self.primitive(data, path)

def load_file(path):
    file = cy.load.file(path)
    password = environ.get('CONFIG_PASSWORD')
    data = dict(cy.Config(file, password = password))
    del data['crypto']
    return data

data = {}
for file in argv[1:]:
    name = _path.basename(file).split(".")[0]
    data[name] = load_file(file)

print(Vault(data, ['nidito', 'config']).write())

