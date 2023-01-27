package meta

import (
	"context"
	"database/sql"
	"errors"

	"github.com/heroiclabs/nakama-common/runtime"
)

// Registers a new Metafab player to the user account, a player can only be linked once and needs to be unique.
func RegisterRpc(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Validate: Requires a registered user account (has email), without a metafab player;
	// device accounts (no e-mail) or accounts with Metadata can not register a metafab player.
	user_id, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok { 
		return "{}", errors.New("user id not found")
	}
	account, err := nk.AccountGetId(ctx, user_id)
	if err != nil {
		return "{}", errors.New("user account not found")
	}
	if len(account.Email) == 0 {
		return "{}", errors.New("invalid user account found (email)")
	}
	if len(account.Devices) > 0 {
		return "{}", errors.New("invalid user account found (device)")
	}
	if len(account.User.Metadata) > 3 {
		return "{}", errors.New("invalid user account found (metadata)")
	}
	var request RegisterReq
	if err := request.from_payload(user_id, logger, payload); nil != err {
		return "{}", err
	}
	// Store the registration request as metadata on the players account
	var accountData AccountData
	accountData.WalletId = request.WalletId
	accountData.MetafabId = request.MetafabId
	if err := nk.AccountUpdateId(
		ctx, user_id, account.User.Username, accountData.to_map(), 
		account.Email, "", "", "", "",
	); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": request.MetafabId,
		}).Error("failed to update acount data")
		return "0", errors.New("failed to save acount data")
	}
	// Setup the initial data and currency for the player
	// If the player owns less then 3 actors minting is open.
	if err := SetPlayerData(logger, request.MetafabId, &PlayerData{
		ProtectedData: ProtectedData{ ActorMints: 3, ActorMinted: 0 },
	}); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": request.MetafabId,
		}).Error("failed to init free mints")
		return "0", errors.New("failed to assign free mints")
	}
	return "{}", nil
}
