package rtime

import (
	"fmt"
	"os"
	"sync"
	"time"

	"github.com/inconshreveable/log15"
)

type LoggerStatsType struct {
	Warns  int `json:"warns"`
	Errors int `json:"errors"`
	Crits  int `json:"crits"`
}

var (
	LOGGER            log15.Logger
	LOGGER_STATS_Lock sync.Mutex
	LOGGER_STATS      = &LoggerStatsType{}
)

func LoggerStatter(r *log15.Record) error {
	LOGGER_STATS_Lock.Lock()
	defer LOGGER_STATS_Lock.Unlock()

	switch r.Lvl {
	case log15.LvlWarn:
		LOGGER_STATS.Warns += 1
	case log15.LvlError:
		LOGGER_STATS.Errors += 1
	case log15.LvlCrit:
		LOGGER_STATS.Crits += 1
	default:
	}

	return nil
}

// Logging verbosity level, from 0 (nothing) upwards.
func SetLoggingVerbosity(level int) {
	logfile := fmt.Sprintf("/tmp/rtime.%d.log", time.Now().UnixNano())

	LOGGER = log15.Root()

	LOGGER.SetHandler(
		log15.LvlFilterHandler(
			log15.Lvl(level),
			log15.CallerFuncHandler(
				log15.CallerStackHandler(
					"%v",
					log15.MultiHandler(
						// log15.Must.FileHandler(logfile, log15.LogfmtFormat()),
						log15.StreamHandler(os.Stderr, log15.TerminalFormat()),
						log15.FuncHandler(LoggerStatter),
					),
				),
			),
		),
	)

	LOGGER.Info(
		"logger_initialized", log15.Ctx{
			"logfile": logfile,
			"pid":     os.Getpid(),
			"level":   log15.Lvl(level).String(),
		},
	)
}
