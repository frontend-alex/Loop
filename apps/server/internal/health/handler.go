package health

import (
	"net/http"

	"gorm.io/gorm"
	"loop.com/server/internal/httpx"
)

type Handler struct {
	db *gorm.DB
}

func NewHandler(db *gorm.DB) *Handler {
	return &Handler{
		db: db,
	}
}

func (h *Handler) Live(w http.ResponseWriter, r *http.Request) {
	httpx.JSON(w, http.StatusNoContent, nil)
}

func (h *Handler) Ready(w http.ResponseWriter, r *http.Request) {
	err := h.db.WithContext(r.Context()).
		Exec("SELECT 1").
		Error

	if err != nil {
		http.Error(
			w,
			"database unavailable",
			http.StatusServiceUnavailable,
		)
		return
	}

	httpx.JSON(w, http.StatusNoContent, nil)
}
