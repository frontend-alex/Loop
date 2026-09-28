package app

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"gorm.io/gorm"
	"loop.com/server/internal/config"
	"loop.com/server/internal/health"
)

type Application struct {
	config        config.Config
	logger        *slog.Logger
	db            *gorm.DB
	healthHandler *health.Handler
}

func New(
	config config.Config,
	logger *slog.Logger,
	db *gorm.DB,
) *Application {
	return &Application{
		config:        config,
		logger:        logger,
		db:            db,
		healthHandler: health.NewHandler(db),
	}
}

func (app *Application) Run() error {
	server := &http.Server{
		Addr:         app.config.HTTP.Addr,
		Handler:      app.Router(),
		ReadTimeout:  app.config.HTTP.ReadTimeout,
		WriteTimeout: app.config.HTTP.WriteTimeout,
		IdleTimeout:  app.config.HTTP.IdleTimeout,
	}

	serverErrors := make(chan error, 1)

	go func() {
		app.logger.Info("Server started", "addr", server.Addr)

		if err := server.ListenAndServe(); err != nil &&
			!errors.Is(err, http.ErrServerClosed) {
			serverErrors <- err
		}
	}()

	shutdown := make(chan os.Signal, 1)
	signal.Notify(
		shutdown,
		syscall.SIGINT,
		syscall.SIGTERM,
	)

	defer signal.Stop(shutdown)

	select {
	case err := <-serverErrors:
		return err
	case signal := <-shutdown:
		app.logger.Info("Shutdown signal received", "signal", signal)
		ctx, cancel := context.WithTimeout(
			context.Background(),
			app.config.HTTP.ShutdownTimeout,
		)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			return err
		}

		app.logger.Info("Server stopped")

		return nil
	}
}
