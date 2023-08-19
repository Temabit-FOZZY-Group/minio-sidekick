package main

import (
	"testing"
	"time"
)

func Test_newConnStats(_ *testing.T) {
	newConnStats("test").setAvgLatency(5 * time.Second)
	newConnStats("test").setAvgLatency(5 * time.Second)
	newConnStats("test").setAvgLatency(5 * time.Second)
}
