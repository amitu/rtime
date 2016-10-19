package rtime

import (
	"net/http"
	_ "expvar"
	_ "net/http/pprof"

	rice "github.com/GeertJohan/go.rice"
)

func elmPage(w http.ResponseWriter, _ *http.Request) {
	w.Write(
		[]byte(`
			<!DOCTYPE html>
			<html>
				<head>
					<meta charset="utf-8" />
					<meta content="width=device-width, initial-scale=1.0" name="viewport" />
					<title>rtime</title>
					<link href="/static/style.css" rel="stylesheet" type="text/css" />
				</head>
				<body><script src="/static/elm.js"></script></body>
			</html>
		`),
	)
}

func ListenAndServe(listen string) {
	box := rice.MustFindBox("static")
	staticServer := http.StripPrefix("/static/", http.FileServer(box.HTTPBox()))
	http.Handle("/static/", staticServer)
	http.HandleFunc("/", elmPage)

	LOGGER.Info("starting http server", "listen", listen)
	LOGGER.Error("server_done", "err", http.ListenAndServe(listen, nil))
}
