package rtime

import (
	"encoding/json"
	"expvar"
	"fmt"
	"net/http"
	_ "net/http/pprof"
	"sync"
	"time"

	rice "github.com/GeertJohan/go.rice"
	"github.com/juju/errors"
)

var (
	cache = NewVDCache()
)

type VDCache struct {
	cache map[string]*ViewData
	sync.RWMutex
}

func (c *VDCache) String() string {
	c.RLock()
	defer c.RUnlock()

	return fmt.Sprintf("%d", len(c.cache))
}

func (c *VDCache) Add(vd *ViewData) {
	if vd == nil {
		return
	}

	c.Lock()
	defer c.Unlock()

	c.cache[vd.id] = vd
}

func (c *VDCache) Cleanup() {
	c.Lock()
	defer c.Unlock()

	list := []string{}

	for k, rd := range c.cache {
		if rd != nil && time.Since(rd.created) > time.Second*10*60 {
			list = append(list, k)
		}
	}

	for _, k := range list {
		delete(c.cache, k)
	}

	if len(list) > 0 {
		LOGGER.Info("cleaner_collected", "count", len(list))
	} else {
		LOGGER.Debug("cleaner_idled")
	}
}

func NewVDCache() *VDCache {
	return &VDCache{
		cache: make(map[string]*ViewData),
	}
}

func init() {
	expvar.Publish("VDCache_count", cache)
}

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

func viewAPI(w http.ResponseWriter, r *http.Request) {
	app := r.FormValue("app")
	if app == "" {
		reject(w, "app is required")
		LOGGER.Warn("app_missing")
		return
	}

	view := r.FormValue("view")
	if view == "" {
		reject(w, "view is required")
		LOGGER.Warn("view_missing")
		return
	}

	host := r.FormValue("host")

	floors := r.FormValue("floor")
	floor := uint64(0)
	if floors != "" {
		_, err := fmt.Sscanf(floors, "%d", &floor)
		if err != nil {
			reject(w, "invalid floor")
			LOGGER.Warn("invalid_floor")
			return
		}
	}

	ceilings := r.FormValue("ceiling")
	ceiling := uint64(0)
	if ceilings != "" {
		_, err := fmt.Sscanf(ceilings, "%d", &ceiling)
		if err != nil {
			reject(w, "invalid cieling")
			LOGGER.Warn("invalid_cieling")
			return
		}
	}

	LOGGER.Debug("ceiling", "ceilings", ceilings, "ceiling", ceiling)

	start := r.FormValue("start")
	if view == "" {
		reject(w, "start is required")
		return
	}

	end := r.FormValue("end")
	if view == "" {
		reject(w, "end is required")
		return
	}

	rd, err := GetViewData(app, view, host, start, end, floor, ceiling)
	if err != nil {
		LOGGER.Error("view_data_error", "err", errors.ErrorStack(err))
		reject(w, errors.ErrorStack(err))
		return
	}

	err = rd.writeTo(w)
	if err != nil {
		LOGGER.Error("view_data_error", "err", errors.ErrorStack(err))
		reject(w, errors.ErrorStack(err))
		return
	}

	cache.Add(rd)
}

func cleaner() {
	for {
		time.Sleep(time.Second * 60)
		cache.Cleanup()
	}
}

func ListenAndServe(listen string) {
	go cleaner()

	box := rice.MustFindBox("static")
	staticServer := http.StripPrefix("/static/", http.FileServer(box.HTTPBox()))
	http.Handle("/static/", staticServer)
	http.HandleFunc("/apps", appsAPI)
	http.HandleFunc("/views", viewsAPI)
	http.HandleFunc("/view", viewAPI)
	http.HandleFunc("/", elmPage)

	LOGGER.Info("http_server_starting", "listen", listen)
	LOGGER.Error(
		"server_done", "err",
		http.ListenAndServe(listen, http.HandlerFunc(Midddleware)),
	)
}
