import os
import django

from djrtime.handlers import TimeItHandler

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'tests.settings')

if django.VERSION >= (1, 10):
    django.setup(set_prefix=False)
else:
    django.setup()

application = TimeItHandler()
