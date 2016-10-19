package main

import (
	"flag"

	"rtime"
)

func main() {
	HostPort := "127.0.0.1:6543"
	LogLevel := 4

	flag.StringVar(&HostPort, "listen", HostPort, "")
	flag.IntVar(
		&LogLevel, "log-level", LogLevel, "1:error 2: warn 3:info 4:trace",
	)
	flag.Parse()

	rtime.SetLoggingVerbosity(LogLevel)
	rtime.ListenAndServe(HostPort)
}
