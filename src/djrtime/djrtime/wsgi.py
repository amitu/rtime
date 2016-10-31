import django

from .handlers import TimeItHandler


def get_wsgi_application():
    try:
        django.setup(set_prefix=False)
    except TypeError:  # django < 1.10
        django.setup()

    return TimeItHandler()
