package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-xray-sdk-go/xray"
)

const defaultPort = "8080"
const defaultColor = "black"
const defaultStage = "default"

func getServerPort() string {
	port := os.Getenv("SERVER_PORT")
	if port != "" {
		return port
	}

	return defaultPort
}

func getColor() string {
	color := os.Getenv("COLOR")
	if color != "" {
		return color
	}

	return defaultColor
}

func getStage() string {
	stage := os.Getenv("STAGE")
	if stage != "" {
		return stage
	}

	return defaultStage
}

func xrayEnabled() bool {
	enabled := os.Getenv("ENABLE_ENVOY_XRAY_TRACING")
	return enabled == "1"
}

type colorHandler struct{}
func (h *colorHandler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	log.Println("color requested, responding with", getColor())
	fmt.Fprint(writer, getColor())
}

type pingHandler struct{}
func (h *pingHandler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	log.Println("ping requested, reponding with HTTP 200")
	writer.WriteHeader(http.StatusOK)
}

func main() {
	log.Printf("starting server (%s), listening on port %s", getColor(), getServerPort())

	handlers := map[string]http.Handler {
		"/color": &colorHandler{},
		"/ping": &pingHandler{},
	}

	if xrayEnabled() {
		log.Println("xray tracing enabled")
		xraySegmentNamer := xray.NewFixedSegmentNamer(fmt.Sprintf("%s-colorteller-%s", getStage(), getColor()))
		for route, handler := range handlers {
			handlers[route] = xray.Handler(xraySegmentNamer, handler)
		}
	}

	for route, handler := range handlers {
		http.Handle(route, handler)
	}

	log.Fatal(http.ListenAndServe(":"+getServerPort(), nil))
}
