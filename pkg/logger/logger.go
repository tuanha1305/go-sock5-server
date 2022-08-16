package logger

import (
	"fmt"
	"github.com/sirupsen/logrus"
	"os"
	"path/filepath"
	"sync"
)

// Level type
type Level uint32
type Fields map[string]interface{}

// These are the different logging levels. You can set the logging level to log
// on your instance of logger, obtained with `logrus.New()`.
const (
	// PanicLevel level, highest level of severity. Logs and then calls panic with the
	// message passed to Debug, Info, ...
	PanicLevel Level = iota
	// FatalLevel level. Logs and then calls `logger.Exit(1)`. It will exit even if the
	// logging level is set to Panic.
	FatalLevel
	// ErrorLevel level. Logs. Used for errors that should definitely be noted.
	// Commonly used for hooks to send errors to an error tracking service.
	ErrorLevel
	// WarnLevel level. Non-critical entries that deserve eyes.
	WarnLevel
	// InfoLevel level. General operational entries about what's going on inside the
	// application.
	InfoLevel
	// DebugLevel level. Usually only enabled when debugging. Very verbose logging.
	DebugLevel
	// TraceLevel level. Designates finer-grained informational events than the Debug.
	TraceLevel
)

const (
	maximumCallerDepth int = 25
	knownLogrusFrames  int = 4
	timeFormat             = "2006-01-02 15:04:05.000"
)

var (
	// Used for caller information initialisation
	callerInitOnce     sync.Once
	logrusPackage      string
	minimumCallerDepth = 1
	loggers            = make(map[string]*MyLogger)
	defaultLogger      = NewLogger(DebugLevel, "default")
)

// Infof logs a formatted info level log to the console
func Infof(format string, v ...interface{}) { defaultLogger.Infof(format, v...) }

// Tracef logs a formatted debug level log to the console
func Tracef(format string, v ...interface{}) { defaultLogger.Tracef(format, v...) }

// Debugf logs a formatted debug level log to the console
func Debugf(format string, v ...interface{}) { defaultLogger.Debugf(format, v...) }

// Warnf logs a formatted warn level log to the console
func Warnf(format string, v ...interface{}) { defaultLogger.Warnf(format, v...) }

// Errorf logs a formatted error level log to the console
func Errorf(format string, v ...interface{}) { defaultLogger.Errorf(format, v...) }

// Panicf logs a formatted panic level log to the console.
// The panic() function is called, which stops the ordinary flow of a goroutine.
func Panicf(format string, v ...interface{}) { defaultLogger.Panicf(format, v...) }

func Init(level string) {
	l := logrus.DebugLevel
	switch level {
	case "trace":
		l = logrus.TraceLevel
	case "debug":
		l = logrus.DebugLevel
	case "info":
		l = logrus.InfoLevel
	case "warn":
		l = logrus.WarnLevel
	case "error":
		l = logrus.ErrorLevel
	}
	defaultLogger.SetLevel(l)
}

type MyLogger struct {
	logger *logrus.Logger
	level  Level
	prefix string
}

func (ml *MyLogger) Level() string {
	switch ml.level {
	case PanicLevel:
		return "Panic"
	case FatalLevel:
		return "Fatal"
	case ErrorLevel:
		return "Error"
	case WarnLevel:
		return "Warn"
	case InfoLevel:
		return "Info"
	case DebugLevel:
		return "Debug"
	case TraceLevel:
		return "Trace"
	}
	return "Unkown"
}

func SetFileOutPutLog(path string) {
	dir := filepath.Dir(path)

	if _, err := os.Stat(dir); err != nil {
		if os.IsNotExist(err) {
			err := os.MkdirAll(dir, 0755)
			if err != nil {
				return
			}
		}
	}
	_, errorCreateFile := os.Create(path)
	if errorCreateFile != nil {
		fmt.Println("Create file log error!")
	}
	if l, found := loggers["default"]; found {
		file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0755)
		if err != nil {
			l.logger.Fatal(err)
		}
		l.logger.SetOutput(file)
	}
}

func (ml *MyLogger) Prefix() string {
	return ml.prefix
}

func (ml *MyLogger) SetLevel(level Level) {
	ml.logger.SetLevel(logrus.Level(level))
}

func NewLogger(level Level, prefix string) *logrus.Logger {
	if logger, found := loggers[prefix]; found {
		return logger.logger
	}
	l := logrus.New()
	l.SetOutput(os.Stdout)
	l.SetReportCaller(true)
	l.SetLevel(logrus.Level(level))
	l.SetFormatter(&TextFormatter{
		Prefix:          prefix,
		FullTimestamp:   true,
		TimestampFormat: timeFormat,
	})

	loggers[prefix] = &MyLogger{
		logger: l,
		level:  level,
		prefix: prefix,
	}
	return l
}

func NewLoggerWithFields(level Level, prefix string, fields Fields) *logrus.Logger {
	if logger, found := loggers[prefix]; found {
		return logger.logger
	}
	l := logrus.New()
	l.SetOutput(os.Stdout)
	l.SetReportCaller(true)
	l.SetLevel(logrus.Level(level))
	l.SetFormatter(&TextFormatter{
		Prefix:          prefix,
		Fields:          fields,
		FullTimestamp:   true,
		TimestampFormat: timeFormat,
	})

	loggers[prefix] = &MyLogger{
		logger: l,
		level:  level,
		prefix: prefix,
	}

	return l
}

func SetLogLevel(prefix string, level Level) error {
	if l, found := loggers[prefix]; found {
		l.level = level
		l.logger.SetLevel(logrus.Level(level))
		return nil
	}
	return fmt.Errorf("logger [%v] not found", prefix)
}

func GetLoggers() map[string]*MyLogger {
	return loggers
}
