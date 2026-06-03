package sub

import (
	"bit-craft/cmd/wizard/core"
	"os"
	"os/exec"

	"charm.land/huh/v2"
	"github.com/joho/godotenv"
)

func AtlasMenu() {
	var retAction action
	form := huh.NewForm(
		huh.NewGroup(
			huh.NewSelect[action]().
				Title("Atlas Operations").
				Options(
					huh.NewOption("Atlas Diff", atlasDiff),
					huh.NewOption("Atlas Apply", atlasApply),
					huh.NewOption("Cancel", atlasCancel),
				).
				Value(&retAction),
		),
	)

	if err := form.Run(); err != nil || retAction == atlasCancel {
		core.ProcLog.Info("atlas", "operation cancelled, ware!")
		return
	}

	switch retAction {
	case atlasDiff:
		runAtlasDiff()
	case atlasApply:
		runAtlasApply()
	default:
		panic("unhandled default case")
	}
}

func runAtlasDiff() {
	var name string
	_ = huh.NewInput().
		Title("Diff Name").
		Placeholder("alter_u_item").
		Value(&name).
		Run()

	if name == "" {
		core.ProcLog.Info("atlas", "name is required")
		return
	}

	cmd := exec.Command("make", "-s", "atlas-diff",
		"NAME="+name,
	)
	//cmd.Stdout = os.Stdout
	//cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		core.ProcLog.Fatal("atlas", "atlas diff failed: %v", err)
	}
	core.ProcLog.Info("atlas", "successfully")
}

func runAtlasApply() {
	url := getDbUrl()
	if url == "" {
		core.ProcLog.Info("atlas", "env DB_URL is empty")
		return
	}

	cmd := exec.Command("make", "-s", "atlas-apply")
	cmd.Env = append(os.Environ(), "DB_URL="+url)
	//cmd.Stdout = os.Stdout
	//cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		core.ProcLog.Fatal("atlas", "atlas apply failed: %v", err)
	}
	core.ProcLog.Info("atlas", "apply successfully")
}

func getDbUrl() string {
	_ = godotenv.Load()
	return os.Getenv("DB_URL")
}
