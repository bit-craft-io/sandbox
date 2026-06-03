package core

import (
	"fmt"
	"io"
	"log"
	"strings"
	"time"
)

const YMDHMSFormat = "2006/01/02 15:04:05"

type Logger struct {
	Domain string
}

var (
	ProcLog    = Logger{Domain: "process"}
	SpannerLog = Logger{Domain: "spanner"}
	SchemaLog  = Logger{Domain: "schema"}
)

func (logger Logger) Segment(msg string, args ...any) {
	lineLen := 64
	separatorTop := strings.Repeat("-", lineLen)
	separatorBtm := strings.Repeat("-", lineLen)
	log.Printf("\n%s\n%s\n%s", separatorTop, fmt.Sprintf(msg, args...), separatorBtm)
}

func (logger Logger) Line() {
	lineLen := 64
	separator := strings.Repeat("-", lineLen)
	fmt.Println(separator)
}

func (logger Logger) Prompt(action, msg string, args ...any) {
	now := time.Now().Format(YMDHMSFormat)
	fmt.Printf(
		"%s [PROMPT][%s][%s] %s",
		now,
		logger.Domain,
		action,
		fmt.Sprintf(msg, args...),
	)
}

func (logger Logger) Info(action, msg string, args ...any) {
	log.Printf("[INFO  ][%s][%s] %s", logger.Domain, action, fmt.Sprintf(msg, args...))
}

func (logger Logger) Error(action string, err error) {
	log.Printf("[ERROR ][%s][%s] %v", logger.Domain, action, err)
}

func (logger Logger) Fatal(action, msg string, args ...any) {
	log.Fatalf("[FATAL ][%s][%s] %s", logger.Domain, action, fmt.Sprintf(msg, args...))
}

func LogOff() io.Writer {
	original := log.Writer()
	log.SetOutput(io.Discard)
	return original
}

func LogOn(original io.Writer) {
	log.SetOutput(original)
}
