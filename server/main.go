package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"os"

	"github.com/heroiclabs/nakama-common/runtime"
	"github.com/vecno-io/metafab-space-whales/server/actor"
	"github.com/vecno-io/metafab-space-whales/server/meta"
)

func InitModule(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, initializer runtime.Initializer) error {
	if err := _validate_environment_variables(); err != nil {
		logger.Error("Enviroment variable: %v", err)
		return err		
	}
	if err := initializer.RegisterRpc("game_info", GameInfoRpc); err != nil {
		logger.Error("Unable to register rpc: game_info: %v", err)
		return err
	}
	if err := initializer.RegisterRpc("meta_register", meta.RegisterRpc); err != nil {
		logger.Error("Unable to register rpc: meta_register: %v", err)
		return err
	}
	if err := initializer.RegisterRpc("actor_mint", actor.MintRpc); err != nil {
		logger.Error("Unable to register rpc: actor_mint: %v", err)
		return err
	}
	if err := initializer.RegisterRpc("actor_create", actor.CreateRpc); err != nil {
		logger.Error("Unable to register rpc: actor_create: %v", err)
		return err
	}
	if err := initializer.RegisterRpc("actor_reserve", actor.ReserveRpc); err != nil {
		logger.Error("Unable to register rpc: actor_reserve: %v", err)
		return err
	}
	return nil
}

func GameInfoRpc(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	data, err := json.Marshal(map[string]interface{}{
		"game_id": os.Getenv("METAFAB_GAME_ID"),
		"public_key": os.Getenv("METAFAB_GAME_PUBLISH_KEY"),
		"game_wallet": os.Getenv("METAFAB_GAME_WALLET_ID"),
		"funding_wallet": os.Getenv("METAFAB_GAME_FUNDING_ID"),
		"dust_currency": os.Getenv("METAFAB_CURRENCY_DUST"),
		"actors_collection": os.Getenv("METAFAB_COLLECTION_ACTORS"),
		"sectors_collection": os.Getenv("METAFAB_COLLECTION_SECTORS"),
		"boosters_collection": os.Getenv("METAFAB_COLLECTION_BOOSTERS"),
	})
	if err != nil {
		logger.WithField("err", err).Error("json marshal actor")
		return "{}", errors.New("could encode game info")
	}
	return string(data), nil
}

func _validate_environment_variables() error {
	if len(os.Getenv("URL_IMAGE_ACTOR")) == 0 {
		return errors.New("missing .env: URL_IMAGE_ACTOR")
	}
	if len(os.Getenv("URL_EXTERN_ACTORS")) == 0 {
		return errors.New("missing .env: URL_EXTERN_ACTORS")
	}

	if len(os.Getenv("METAFAB_GAME_ID")) == 0 {
		return errors.New("missing .env: METAFAB_GAME_ID")
	}
	if len(os.Getenv("METAFAB_GAME_PASS")) == 0 {
		return errors.New("missing .env: METAFAB_GAME_PASS")
	}

	if len(os.Getenv("METAFAB_GAME_WALLET_ID")) == 0 {
		return errors.New("missing .env: METAFAB_GAME_WALLET_ID")
	}
	if len(os.Getenv("METAFAB_GAME_FUNDING_ID")) == 0 {
		return errors.New("missing .env: METAFAB_GAME_FUNDING_ID")
	}
	if len(os.Getenv("METAFAB_GAME_SECRET_KEY")) == 0 {
		return errors.New("missing .env: METAFAB_GAME_SECRET_KEY")
	}
	if len(os.Getenv("METAFAB_GAME_PUBLISH_KEY")) == 0 {
		return errors.New("missing .env: METAFAB_GAME_PUBLISH_KEY")
	}

	if len(os.Getenv("METAFAB_CURRENCY_DUST")) == 0 {
		return errors.New("missing .env: METAFAB_CURRENCY_DUST")
	}

	if len(os.Getenv("METAFAB_COLLECTION_ACTORS")) == 0 {
		return errors.New("missing .env: METAFAB_COLLECTION_ACTORS")
	}
	if len(os.Getenv("METAFAB_COLLECTION_SECTORS")) == 0 {
		return errors.New("missing .env: METAFAB_COLLECTION_SECTORS")
	}
	if len(os.Getenv("METAFAB_COLLECTION_BOOSTERS")) == 0 {
		return errors.New("missing .env: METAFAB_COLLECTION_BOOSTERS")
	}

	return nil
}
