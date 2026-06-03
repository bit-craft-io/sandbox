package sub

import (
	"bit-craft/cmd/wizard/core"
	"fmt"
	"os/exec"

	"charm.land/huh/v2"
)

func BuildMenu() {

	cfg := mustLoadConfig()
	core.ProcLog.Segment("Target: %s", cfg.TargetDir)

	var retAction action
	form := huh.NewForm(
		huh.NewGroup(
			huh.NewSelect[action]().
				Title("Build Operations").
				Options(
					huh.NewOption("Build Execute And Run", buildExecAndRun),
					huh.NewOption("Build Execute", buildExec),
					huh.NewOption("Build Config", buildConf),
					huh.NewOption("Cancel", buildCancel),
				).
				Value(&retAction),
		),
	)

	if err := form.Run(); err != nil || retAction == buildCancel {
		core.ProcLog.Info("build", "operation cancelled, ware!")
		return
	}

	switch retAction {
	case buildExecAndRun:
		core.ProcLog.Segment("create binary")
		if err := runBuildExec(); err != nil {
			return
		}
		core.ProcLog.Segment("run binary")
		appRun()
		core.ProcLog.Line()
	case buildExec:
		core.ProcLog.Segment("create binary")
		_ = runBuildExec()
		core.ProcLog.Line()
	case buildConf:
		core.ProcLog.Segment("build config")
		buildConfig()
		core.ProcLog.Line()
	default:
		panic("unhandled default case")
	}

	// @note メニューを再帰呼び出し
	if retAction != buildCancel {
		BuildMenu()
	}
}

func runBuildExec() error {
	cfg := mustLoadConfig()
	core.ProcLog.Info("build", "building %s via Makefile...", cfg.TargetName)

	// @note execute make command
	cmd := exec.Command("make", "build",
		fmt.Sprintf("DIR=%s", cfg.TargetDir),
		fmt.Sprintf("NAME=%s", cfg.TargetName),
	)

	// @note display log
	//cmd.Stdout = os.Stdout
	//cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		core.ProcLog.Error("build", err)
		return err
	}

	core.ProcLog.Info("build", "create successfully")
	return nil
}

func appRun() {
	cfg := mustLoadConfig()
	core.ProcLog.Info("build", "launching %s via Makefile...", cfg.TargetName)

	// @note execute make command
	cmd := exec.Command("make", "run",
		fmt.Sprintf("DIR=%s", cfg.TargetDir),
		fmt.Sprintf("NAME=%s", cfg.TargetName),
	)

	// @note display log
	//cmd.Stdout = os.Stdout
	//cmd.Stderr = os.Stderr
	//cmd.Stdin = os.Stdin
	if err := cmd.Run(); err != nil {
		core.ProcLog.Error("build", err)
		return
	}

	core.ProcLog.Info("build", "run successfully")
	return
}
