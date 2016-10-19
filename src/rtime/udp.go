package rtime

import (
	"net"
	"time"

	"encoding/json"

	"github.com/juju/errors"
)

type packet struct {
	Host  string `json:"host"`
	App   string `json:"app"`
	Name  string `json:"name"`
	OTime int    `json:"otime"`
}

func HandlePacket(p *packet, data []byte) {
	LOGGER.Debug("udp_packet", "packet", string(data))
	p.Host = ""
	p.App = ""
	p.Name = ""
	p.OTime = 0

	err := json.Unmarshal(data, p)
	if err != nil {
		LOGGER.Warn(
			"udp_packet_parse_failed", "err", errors.ErrorStack(err),
			"packet", string(data),
		)
		return
	}

	LOGGER.Debug("udp_packet_parsed", "packet", p)
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
	var bcount, count int64
	opacket := &packet{}

	for {
		n, _, err := conn.ReadFrom(obytes)
		if err != nil {
			LOGGER.Warn("udp_read_failed", "err", errors.ErrorStack(err))
			continue
		}

		HandlePacket(opacket, obytes[:n])

		count += 1
		bcount += int64(n)

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
