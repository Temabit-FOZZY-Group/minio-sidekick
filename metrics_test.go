package main

import (
	"math/rand"
	"testing"
	"time"
)

func TestConnStats_setAvgLatency(t *testing.T) {
	newConnStats("test").setAvgLatency(time.Duration(rand.Int63()), "GET", "")
	newConnStats("test").setAvgLatency(time.Duration(rand.Int63()), "GET", "/")
	newConnStats("test").setAvgLatency(time.Duration(rand.Int63()), "GET", "/core-data/Cheques/dbo__cheques")
}
