package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/julienschmidt/httprouter"
	"github.com/sirupsen/logrus"
)

type ListenerNomadJob struct {
	Job string `json:"job"`
}

func (l *ListenerNomadJob) Run(ctx context.Context) error {
	server := os.Getenv("NOMAD_ADDR")
	httpClient := http.Client{}

	body := bytes.NewBufferString("{}")
	var req *http.Request
	var err error
	if strings.HasPrefix(server, "unix://") {
		req, err = http.NewRequest(http.MethodPost, fmt.Sprintf("http://localhost/v1/job/%s/dispatch", l.Job), body)
		if err != nil {
			return err
		}
		httpClient.Transport = &http.Transport{
			DialContext: func(_ context.Context, _, _ string) (net.Conn, error) {
				return net.Dial("unix", strings.TrimPrefix(server, "unix://"))
			},
		}
		req.Header["authorization"] = []string{"Bearer " + os.Getenv("NOMAD_TOKEN")}
	} else {
		req, err = http.NewRequest(http.MethodPost, fmt.Sprintf("%s/v1/job/%s/dispatch", server, l.Job), body)
		if err != nil {
			return err
		}
		req.Header["x-nomad-token"] = []string{os.Getenv("NOMAD_TOKEN")}
	}

	req.Header["content-type"] = []string{"application/json"}

	logrus.Infof("requesting %s %s", req.Method, req.URL)
	res, err := httpClient.Do(req)
	if err != nil {
		return err
	}

	if res.StatusCode > 202 {
		body := []byte{}
		if _, err := res.Body.Read(body); err != nil {
			logrus.Error("could not read response body: %s", err)
		}
		return fmt.Errorf("nomad request returned status code %d and data %s", res.StatusCode, body)
	}

	logrus.Infof("Nomad job dispatched: %s", l.Job)
	return nil
}

type Listener interface {
	Run(ctx context.Context) error
}

type Config map[string]map[string]any

var listeners = map[string]Listener{}

func loadListeners() error {
	rawListeners := &Config{}
	data, err := os.ReadFile(os.Getenv("LISTENERS_PATH"))
	if err != nil {
		return fmt.Errorf("Could not open listeners.json: %s", err)
	}

	if err := json.Unmarshal(data, &rawListeners); err != nil {
		return fmt.Errorf("Could not unserialize listeners.json: %s", err)
	}

	for name, config := range *rawListeners {
		var listener Listener
		kind, ok := config["kind"].(string)
		if !ok {
			return fmt.Errorf("Listener %s kind is not a string: %+v", name, config)
		}

		switch kind {
		case "nomad":
			target, ok := config["job"].(string)
			if !ok {
				return fmt.Errorf("Target nomad `job` for listener %s is not a string: %+v", name, config["job"])
			}
			listener = &ListenerNomadJob{target}
			logrus.Infof("%s => nomad:%s", name, target)
		default:
			return fmt.Errorf("unkown listener type for %s: %s", name, kind)
		}

		listeners[name] = listener
	}

	logrus.Infof("Serving %d listeners", len(listeners))
	return nil
}

type ListenerContext struct {
	Request *http.Request
	Params  httprouter.Params
}

func ServeListeners(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	response := "ok"
	listenerID := p.ByName("listener")
	listener, ok := listeners[listenerID]
	if ok {
		logrus.Infof("Triggered listener for %s", listenerID)
		ctx := context.WithValue(context.Background(), "evt", &ListenerContext{Request: r, Params: p})
		response = "processed"
		go func() {
			if err := listener.Run(ctx); err != nil {
				logrus.Errorf("Could not trigger listener: %s\n", err)
			}
		}()
	} else {
		logrus.Warnf("Unknown listener: %s", listenerID)
	}

	w.Write([]byte(response))
}

func main() {
	router := httprouter.New()
	logrus.SetFormatter(&logrus.TextFormatter{})

	level := logrus.InfoLevel
	if lls := os.Getenv("LOG_LEVEL"); lls != "" {
		logrus.Info(lls)
		ll, err := logrus.ParseLevel(strings.ToUpper(lls))
		if err == nil {
			level = ll
		}
	}
	logrus.SetLevel(level)
	logrus.Debug("Debug logging enabled")

	if err := loadListeners(); err != nil {
		logrus.Fatalf("Could not load listeners: %s", err)
	}

	router.GET("/-/:listener", ServeListeners)
	router.POST("/-/:listener", ServeListeners)

	go handleReloadSignal()
	if err := http.ListenAndServe(":"+os.Getenv("PORT"), router); err != nil {
		logrus.Error(err)
	}
}

func handleReloadSignal() {
	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGHUP)

	// foreach signal received
	for signal := range c {
		if signal == syscall.SIGHUP {
			go func() {
				logrus.Info("Reloading listeners")
				if err := loadListeners(); err != nil {
					logrus.Error("failed reloading listeners: %s", err)
				}
			}()
		}
	}
}
