import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.join(BASE_DIR, '../rtimeit'))
# print(sys.path)

SECRET_KEY = 'secret'
DEBUG = True
ALLOWED_HOSTS = ['*']

ROOT_URLCONF = 'tests.urls'
WSGI_APPLICATION = 'tests.wsgi.application'

DATABASES = {
     'default': {
         'ENGINE': 'django.db.backends.sqlite3',
         'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
     }
 }
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
]

MIDDLEWARE_CLASSES = [
    'djrtime.middlewares.TimeItMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
]

TEMPLATES = [
     {
         'BACKEND': 'django.template.backends.django.DjangoTemplates',
         'DIRS': [os.path.join(BASE_DIR, 'templates')],
         'APP_DIRS': True,
         'OPTIONS': {
             'context_processors': [
                 'django.template.context_processors.debug',
                 'django.template.context_processors.request',
                 'django.contrib.auth.context_processors.auth',
                 'django.contrib.messages.context_processors.messages',
             ],
         },
     },
 ]
