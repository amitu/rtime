class Frame(dict):
    def __init__(self, name=None, *args, **kwargs):
        super(Frame, self).__init__(*args, **kwargs)
        if name:
            self.name = name

    def get_current_frame(self):
        if not self.stack:
            self.stack.insert(-1, Frame())
        return self.stack[-1]

    def get_name(self):
        return self.get('name')

    def set_name(self, name):
        if not name:
            raise ValueError('name cannot be set empty')
        self['name'] = name

    name = property(get_name, set_name)

    @property
    def stack(self):
        return self.setdefault('stack', [])

    def push_frame(self, name):
        self.stack.append(Frame(name=name))

    def add_frame_data(self, **kwargs):
        self.update(kwargs)
