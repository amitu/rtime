package rtime

import (
	"encoding/binary"
	"encoding/hex"
	"fmt"
	"math/rand"
	"time"

	"io"

	"github.com/boltdb/bolt"
	"github.com/juju/errors"
)

var (
	boltdb *bolt.DB
)

const (
	TFormat = "2006-01-02T15:04:05.999999"
)

func MustInitWriter(pth string) {
	var err error
	boltdb, err = bolt.Open(pth, 0600, nil)

	if err != nil {
		LOGGER.Error("db_open_failed", "err", errors.ErrorStack(err))
		panic(err)
	}
}

func Write(data []byte, p *packet) {
	err := boltdb.Update(func(tx *bolt.Tx) error {
		app, err := tx.CreateBucketIfNotExists([]byte(p.App))
		if err != nil {
			LOGGER.Error("cant_create_app_bucket", "err", errors.ErrorStack(err))
			return errors.Trace(err)
		}

		view, err := app.CreateBucketIfNotExists([]byte(p.Name))
		if err != nil {
			LOGGER.Error("cant_create_view_bucket", "err", errors.ErrorStack(err))
			return errors.Trace(err)
		}

		host, err := view.CreateBucketIfNotExists([]byte(p.Host))
		if err != nil {
			LOGGER.Error("cant_create_host_bucket", "err", errors.ErrorStack(err))
			return errors.Trace(err)
		}

		timings, err := host.CreateBucketIfNotExists([]byte("timings"))
		if err != nil {
			LOGGER.Error("cant_create_timings_bucket", "err", errors.ErrorStack(err))
			return errors.Trace(err)
		}

		jsons, err := host.CreateBucketIfNotExists([]byte("jsons"))
		if err != nil {
			LOGGER.Error("cant_create_jsons_bucket", "err", errors.ErrorStack(err))
			return errors.Trace(err)
		}

		ts := []byte(time.Now().Format(TFormat))
		LOGGER.Debug("key", "ts", string(ts))

		b := make([]byte, 8)
		binary.LittleEndian.PutUint64(b, p.OTime)

		err = timings.Put(ts, b)
		if err != nil {
			LOGGER.Error("cant_insert_timing", "err", errors.ErrorStack(err))
			return errors.Trace(err)
		}

		err = jsons.Put(ts, data)
		if err != nil {
			LOGGER.Error("cant_insert_json", "err", errors.ErrorStack(err))
			return errors.Trace(err)
		}

		LOGGER.Debug("inserted", "id", string(ts))
		return nil
	})

	if err != nil {
		LOGGER.Error("boltd_update_failed", "err", errors.ErrorStack(err))
	}
}

func ListViews(appname string) (views []string, err error) {
	err = errors.Trace(
		boltdb.View(func(tx *bolt.Tx) error {
			app := tx.Bucket([]byte(appname))
			if app == nil {
				LOGGER.Error("unknown_app", "app", appname)
				return errors.New("unknown app")
			}

			return errors.Trace(
				app.ForEach(func(name, value []byte) error {
					if value == nil {
						views = append(views, string(name))
					}
					return nil
				}),
			)
		}),
	)
	return
}

func ListApps() (apps []string, err error) {
	err = errors.Trace(
		boltdb.View(func(tx *bolt.Tx) error {
			return errors.Trace(
				tx.ForEach(func(name []byte, _ *bolt.Bucket) error {
					apps = append(apps, string(name))
					return nil
				}),
			)
		}),
	)
	return
}

func UniqueID() string {
	u := make([]byte, 16)
	_, err := rand.Read(u)
	if err != nil {
		LOGGER.Error("rand_failed", "err", errors.ErrorStack(err))
	}
	return hex.EncodeToString(u)
}

type ViewData struct {
	timings []uint16
	id      string
	ceiling uint64
	ids     []string  // not exported to clients
	created time.Time // not exported
}

func (vd *ViewData) writeTo(w io.Writer) error {
	LOGGER.Info("vd.id", "id", vd.id, "len", len(vd.id))
	for _, c := range vd.id {
		w.Write([]byte{byte(c), 0})
	}

	b := make([]byte, 8)
	binary.LittleEndian.PutUint64(b, vd.ceiling)
	w.Write(b)

	for _, v := range vd.timings {
		w.Write([]byte{byte(v % 256), byte(v / 256)})
	}
	return nil
}

func GetViewData(
	app, view, host, starts, ends string, floor, ceiling uint64,
) (*ViewData, error) {
	ids := []string{}
	timings := []uint64{}

	start, err := time.Parse(TFormat, starts)
	if err != nil {
		return nil, errors.Trace(err)
	}

	end, err := time.Parse(TFormat, ends)
	if err != nil {
		return nil, errors.Trace(err)
	}

	if end.Before(start) || end.UnixNano()-start.UnixNano() < 1024 {
		return nil, errors.New(
			fmt.Sprintf(
				"invalid start = %s, end = %s, close=%t",
				start.UnixNano(), end.UnixNano(), !end.Before(start),
			),
		)
	}

	err = errors.Trace(
		boltdb.View(func(tx *bolt.Tx) error {
			appb := tx.Bucket([]byte(app))
			if appb == nil {
				LOGGER.Error("unknown_app", "app", app)
				return errors.New("unknown app")
			}

			viewb := appb.Bucket([]byte(view))
			if viewb == nil {
				LOGGER.Error("unknown_view", "app", app, "view", view)
				return errors.New("unknown view")
			}

			if host == "" {
				err := viewb.ForEach(func(name, value []byte) error {
					if value != nil {
						// should never happen
						return nil
					}

					var err error

					ids, timings, err = process_host(
						viewb.Bucket(name), ids, timings, starts, ends,
					)

					return errors.Trace(err)
				})

				if err != nil {
					return errors.Trace(err)
				}
			} else {
				hostb := viewb.Bucket([]byte(host))
				if hostb == nil {
					LOGGER.Error(
						"unknown_host", "app", app, "view", view, "host", host,
					)
					return errors.New("unknown host")
				}

				var err error
				ids, timings, err = process_host(hostb, ids, timings, starts, ends)

				return errors.Trace(err)
			}

			return nil
		}),
	)

	if err != nil {
		return nil, errors.Trace(err)
	}

	ceiling, tdigest, idigest := diget(start, end, ids, timings, floor, ceiling)
	LOGGER.Debug("digest", "tdigest", tdigest, "idigest", idigest)
	return &ViewData{
		timings: tdigest,
		ids:     idigest,
		ceiling: ceiling,
		id:      UniqueID(),
		created: time.Now(),
	}, nil
}

func d2slot(snano, step uint64, dt string) uint16 {
	ts, err := time.Parse(TFormat, dt)
	if err != nil {
		LOGGER.Error("invalid_ts", "ts", dt)
		return 0
	}

	return uint16((uint64(ts.UnixNano()) - snano) / step)
}

func normalise(v, floor, ceiling uint64) uint8 {
	if v > ceiling {
		return 63
	}
	return uint8(64*(float32(v-floor)/float32(ceiling-floor)) - 1)
}

func pack(slot uint16, v uint8) uint16 {
	return uint16(v)*1024 + (slot % 1024)
}

func diget(
	start, end time.Time, ids []string, timings []uint64, floor, ceiling uint64,
) (uint64, []uint16, []string) {
	LOGGER.Info("digest", "ids", ids, "timings", timings)

	snano := uint64(start.UnixNano())
	step := (uint64(end.UnixNano()) - snano) / 1024

	tdigest := make([]uint16, 1024)
	idigest := make([]string, 1024)

	if ceiling == 0 {
		for _, v := range timings {
			if ceiling < v {
				ceiling = v
			}
		}
	}

	for i := range ids {
		slot := d2slot(snano, step, ids[i])
		idigest[slot] = ids[i]
		tdigest[slot] = pack(slot, normalise(timings[i], floor, ceiling))
	}

	return ceiling, tdigest, idigest
}

func process_host(
	hostb *bolt.Bucket, ids []string, timings []uint64, start, end string,
) ([]string, []uint64, error) {

	timingsb := hostb.Bucket([]byte("timings"))
	if timingsb == nil {
		LOGGER.Warn("no timings bucket")
		return ids, timings, nil
	}

	c := timingsb.Cursor()

	LOGGER.Debug("process_host", "start", start, "end", end)
	for k, v := c.Seek([]byte(start)); true; k, v = c.Next() {
		sk := string(k)
		if sk > end || sk == "" {
			break
		}

		if v == nil {
			// should never happen
			continue
		}

		ids = append(ids, sk)
		timings = append(timings, binary.LittleEndian.Uint64(v))
	}

	return ids, timings, nil
}

func JSON(id string) ([]byte, error) { return nil, nil }
