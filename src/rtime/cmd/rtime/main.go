package main

import (
	"flag"

	"rtime"
)

func main() {
	HostPort := "127.0.0.1:6543"
	LogLevel := 4
	UDP := "127.0.0.1:6543"
	dbfile := "rtime.boltdb"

	flag.StringVar(&HostPort, "http", HostPort, "")
	flag.StringVar(&UDP, "udp", UDP, "")
	flag.StringVar(&dbfile, "dbfile", dbfile, "")
	flag.IntVar(
		&LogLevel, "log-level", LogLevel, "1:error 2: warn 3:info 4:trace",
	)

	flag.Parse()

	rtime.MustInitWriter(dbfile)

	rtime.SetLoggingVerbosity(LogLevel)
	go rtime.UDPListen(UDP)

	rtime.ListenAndServe(HostPort)
}
