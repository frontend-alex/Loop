package products

import "context"

type Service interface {
	TestService(ctx context.Context) error
}

// implemntation
type svc struct {
	//repository
}

// constructor
func NewService() Service {
	return &svc{}
}

func (s *svc) TestService(ctx context.Context) error {
	return nil
}
