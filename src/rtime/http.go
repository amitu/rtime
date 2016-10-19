package rtime

import (
	"encoding/json"
	_ "expvar"
	"net/http"
	_ "net/http/pprof"

	rice "github.com/GeertJohan/go.rice"
	"github.com/juju/errors"
)

type EResult struct {
	Result interface{} `json:"result"`
	Error  string      `json:"error"`
}

func reject(w http.ResponseWriter, reason string) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	j, err := json.Marshal(&EResult{Error: reason})
	if err != nil {
		LOGGER.Error("reject_json_failed", "err", errors.ErrorStack(err))
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Error(w, string(j), http.StatusBadRequest)
}

func respond(w http.ResponseWriter, result interface{}) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	j, err := json.Marshal(&EResult{Result: result})
	if err != nil {
		LOGGER.Error("respond_json_failed", "err", errors.ErrorStack(err))
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Write(j)
}

func elmPage(w http.ResponseWriter, _ *http.Request) {
	w.Write(
		[]byte(`
			<!DOCTYPE html>
			<html>
				<head>
					<meta charset="utf-8" />
					<meta content="width=device-width,
						  initial-scale=1.0" name="viewport" />
					<title>rtime</title>
					<link href="/static/style.css" rel="stylesheet"
					      type="text/css" />
				</head>
				<body data-csrf="asd"><script src="/static/elm.js"></script></body>
			</html>
		`),
	)
}

func appsAPI(w http.ResponseWriter, _ *http.Request) {
	apps, err := ListApps()
	if err != nil {
		LOGGER.Error("list_app_failed", "err", errors.ErrorStack(err))
		reject(w, errors.ErrorStack(err))
		return
	}

	respond(w, apps)
}

func viewsAPI(w http.ResponseWriter, r *http.Request) {
	app := r.FormValue("app")
	if app == "" {
		reject(w, "app is required")
		return
	}

	views, err := ListViews(app)
	if err != nil {
		LOGGER.Error("list_app_failed", "err", errors.ErrorStack(err))
		reject(w, errors.ErrorStack(err))
		return
	}

	respond(w, views)
}

func ListenAndServe(listen string) {
	box := rice.MustFindBox("static")
	staticServer := http.StripPrefix("/static/", http.FileServer(box.HTTPBox()))
	http.Handle("/static/", staticServer)
	http.HandleFunc("/apps", appsAPI)
	http.HandleFunc("/views", viewsAPI)
	http.HandleFunc("/", elmPage)

	LOGGER.Info("http_server_starting", "listen", listen)
	LOGGER.Error("server_done", "err", http.ListenAndServe(listen, nil))
}
