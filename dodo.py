import glob

import os
os.environ["GOPATH"] = "%s:%s/vendor" % (os.getcwd(), os.getcwd())

DOIT_CONFIG = {
    "verbosity": 2,
    "default_tasks": ["elm", "rtime", "css"]
}



def task_rtime():
    return {
        "actions": ["/usr/local/bin/go install rtime/cmd/..."],
        "file_dep": (
            glob.glob("src/rtime/*.go")
            + glob.glob("src/rtime/*/*/*.go")
            + glob.glob("src/rtime/*/*.go")
        ),
        "targets": ["bin/rtime"],
    }


def task_pip():
    return {
        "actions": ["pip install -r requirements.txt"],
        "file_dep": ["requirements.txt"]
    }


def task_css():
    return {
        "actions": [
            (
                "sassc -I src/rcss/foundation-sites/scss/ -I src/rcss/Font-Awesome/scss/ "
                "src/rcss/main.scss src/rtime/static/style.css"
            )
        ],
        "targets": ["src/rtime/static/style.css"],
        "file_dep": glob.glob("src/rcss/*.scss"),
    }


def task_elm():
    return {
        "actions": [
            "cd src/relm && elm-make --warn --output elm-stuff/elm.js Main.elm",
            "cat src/relm/elm-stuff/elm.js src/rtime/static/elm-extra.js > src/rtime/static/elm.js",
        ],
        "targets": ["src/rtime/static/elm.js"],
        "file_dep": (
            glob.glob("src/relm/*.elm") + glob.glob("src/relm/*/*.elm")
            + ["src/rtime/static/elm-extra.js"]
        )
    }
