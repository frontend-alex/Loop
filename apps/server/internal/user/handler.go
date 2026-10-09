package user

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{
		service: service,
	}
}

// func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) (*User, error) {
// 	  h.service.GetUserByID()
// }
