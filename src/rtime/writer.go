package rtime

import (
	"encoding/binary"
	"time"

	"github.com/boltdb/bolt"
	"github.com/juju/errors"
)

var (
	boltdb *bolt.DB
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
	boltdb.Update(func(tx *bolt.Tx) error {
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

		ts := []byte(time.Now().String())

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

		return nil
	})
}
