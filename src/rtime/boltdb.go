package rtime

import (
	"encoding/binary"
	"encoding/hex"
	"math/rand"
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

		ts := []byte(time.Now().String())
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
	ids     []string  // not exported to clients
	created time.Time // not exported
}

func GetViewData(
	app, view, host, start, end string, floor, ceiling int,
) (*ViewData, error) {
	ids := []string{}
	timings := []uint64{}

	err := errors.Trace(
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
						viewb.Bucket(name), ids, timings, start, end,
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
				ids, timings, err = process_host(hostb, ids, timings, start, end)

				return errors.Trace(err)
			}

			return nil
		}),
	)

	if err != nil {
		return nil, errors.Trace(err)
	}

	return &ViewData{
		timings: diget(ids, timings, floor, ceiling),
		ids:     ids,
		id:      UniqueID(),
		created: time.Now(),
	}, nil
}

func diget(ids []string, timings []uint64, floor, ceiling int) []uint16 {
	return nil
}

func process_host(
	hostb *bolt.Bucket, ids []string, timings []uint64, start, end string,
) ([]string, []uint64, error) {
	err := hostb.ForEach(func(name, value []byte) error {
		if value == nil {
			// should never happen
			return nil
		}

		ids = append(ids, string(name))
		timings = append(timings, binary.LittleEndian.Uint64(value))

		return nil
	})

	return ids, timings, errors.Trace(err)
}

func JSON(id string) ([]byte, error) { return nil, nil }
