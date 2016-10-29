package main

import (
	"encoding/binary"
	"flag"
	"fmt"

	"github.com/boltdb/bolt"
)

func main() {
	dbfile := "rtime.boltdb"
	flag.StringVar(&dbfile, "dbfile", dbfile, "")

	flag.Parse()

	boltdb, err := bolt.Open(dbfile, 0600, &bolt.Options{ReadOnly: true})
	if err != nil {
		panic(err)
	}

	err = boltdb.View(func(tx *bolt.Tx) error {
		return tx.ForEach(func(name []byte, app *bolt.Bucket) error {
			fmt.Println(string(name))

			return app.ForEach(func(view, value []byte) error {
				if value != nil {
					fmt.Println(
						"     Non bucket entry: ", string(view), string(value),
					)
					return nil
				}

				fmt.Println("    ", string(view))
				return app.Bucket(view).ForEach(func(host, value []byte) error {
					if value != nil {
						fmt.Println(
							"         Non bucket entry: ",
							string(host), string(value),
						)
						return nil
					}

					fmt.Println("         ", string(host))
					err := app.Bucket(view).Bucket(host).Bucket([]byte("timings")).ForEach(func(ts, value []byte) error {
						fmt.Println("             ", string(ts), "ts:", binary.LittleEndian.Uint64(value))
						return nil
					})
					if err != nil {
						return err
					}

					err = app.Bucket(view).Bucket(host).Bucket([]byte("jsons")).ForEach(func(ts, value []byte) error {
						fmt.Println("             ", string(ts), "json:", string(value))
						return nil
					})
					if err != nil {
						return err
					}

					return app.Bucket(view).Bucket(host).ForEach(func(b, value []byte) error {
						if string(b) == "timings" || string(b) == "jsons" {
							return nil
						}

						if value != nil {
							fmt.Println(
								"             Non bucket entry: ",
								string(b), string(value),
							)
						} else {
							fmt.Println(
								"             Unknown bucket entry: ", string(b),
							)
						}
						return nil
					})
				})
			})
		})
	})

	if err != nil {
		panic(err)
	}
}
