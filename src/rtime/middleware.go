package rtime

import (
	"net/http"
	"strings"
	"time"

	"github.com/inconshreveable/log15"
	"github.com/juju/errors"
)

type CodeWriter struct {
	code int
	http.ResponseWriter
}

func (c *CodeWriter) WriteHeader(code int) {
	c.code = code
	c.ResponseWriter.WriteHeader(code)
}

func Midddleware(w http.ResponseWriter, r *http.Request) {
	clientIP := r.RemoteAddr
	if colon := strings.LastIndex(clientIP, ":"); colon != -1 {
		clientIP = clientIP[:colon]
	}

	w2 := &CodeWriter{200, w}

	start := time.Now()
	logger := LOGGER.New(
		"url", r.RequestURI, "method", r.Method, "ip", clientIP,
	)
	logger.Info("http_started")
	logger = logger.New(
		"time", log15.Lazy{func() interface{} { return time.Since(start) }},
		"code", log15.Lazy{func() interface{} { return w2.code }},
	)

	defer func() {
		if err := recover(); err != nil {
			err2, ok := err.(error)
			if ok {
				logger.Error(
					"server_error", "err", errors.ErrorStack(err2),
				)
			} else {
				logger.Error(
					"server_uerror", "err", err, "ip", clientIP,
				)
			}
			http.Error(w, http.StatusText(500), 500)
		}
	}()

	w.Header().Set("X-Frame-Options", "DENY")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("X-XSS-Protection", "1; mode=block")

	http.DefaultServeMux.ServeHTTP(w2, r)

	logger.Info("http_served")
}
