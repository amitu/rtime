package rtime

import (
	"net"
	"time"

	"github.com/juju/errors"
)

func HandlePacket(packet []byte) {
	LOGGER.Debug("udp_packet", "packet", string(packet))
	return
}

func UDPListen(addr string) {
	LOGGER.Info("udp_server_starting", "addr", addr)

	conn, err := net.ListenPacket("udp4", addr)
	if err != nil {
		LOGGER.Info("failed_to_start_sever", "err", errors.ErrorStack(err))
		return
	}

	obytes := make([]byte, 64*1024)
	start := time.Now()
	var bcount, count time.Duration

	for {
		buf := obytes
		n, _, err := conn.ReadFrom(buf)

		if err != nil {
			LOGGER.Warn("udp_read_failed", "err", errors.ErrorStack(err))
			continue
		}

		HandlePacket(buf)

		count += 1
		bcount += time.Duration(n)

		now := time.Now()
		diff := now.Sub(start)

		if diff > 1e9 {
			if count > 0 {
				LOGGER.Info(
					"udp_stats", "bps", bcount,
					"pps", count,
				)
			}
			start = now
			bcount, count = 0, 0
		}

	}
}
