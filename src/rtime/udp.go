package rtime

import (
	"net"
	"time"

	"encoding/json"

	"github.com/golang/snappy"
	"github.com/juju/errors"
)

type packet struct {
	Host  string `json:"host"`
	App   string `json:"app"`
	Name  string `json:"name"`
	OTime uint64 `json:"otime"`
}

func HandlePacket(data []byte, p *packet) {
	p.Host = ""
	p.App = ""
	p.Name = ""
	p.OTime = 0

	uncompressed, err := snappy.Decode(data, data)
	if err != nil {
		LOGGER.Warn(
			"snappy_decode_failed", "err", errors.ErrorStack(err),
			"packet", string(data),
		)
		return
	}

	err = json.Unmarshal(uncompressed, p)
	if err != nil {
		LOGGER.Warn(
			"udp_packet_parse_failed", "err", errors.ErrorStack(err),
			"packet", string(data),
		)
		return
	}

	Write(data, p)
}

func UDPListen(addr string) {
	LOGGER.Info("udp_server_starting", "addr", addr)

	conn, err := net.ListenPacket("udp4", addr)
	if err != nil {
		LOGGER.Info("failed_to_start_sever", "err", errors.ErrorStack(err))
		return
	}

	obytes := make([]byte, 64*1024*10)
	start := time.Now()
	var bcount, count int64
	opacket := &packet{}

	for {
		n, _, err := conn.ReadFrom(obytes)
		if err != nil {
			LOGGER.Warn("udp_read_failed", "err", errors.ErrorStack(err))
			continue
		}

		HandlePacket(obytes[:n], opacket)

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
