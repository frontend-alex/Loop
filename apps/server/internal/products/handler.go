package products

import (
	"net/http"

	"loop.com/server/internal/httpx"
)

type handler struct {
	service Service
}

func NewHandler(service Service) *handler {
	return &handler{
		service: service,
	}
}

func (h *handler) TestHandler(w http.ResponseWriter, r *http.Request) {
	products := []string{"hello", "world"}

	httpx.JSON(w, http.StatusOK, products)
}
