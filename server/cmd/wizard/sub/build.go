package sub

import (
	"bit-craft/cmd/wizard/core"
	"fmt"
	"os/exec"

	"charm.land/huh/v2"
)

func BuildMenu() {
	runMenu("build", "Build Operations", []huh.Option[action]{
		huh.NewOption("Build Execute And Run", buildExecAndRun),
		huh.NewOption("Build Execute", buildExec),
		huh.NewOption("Build Config", buildConf),
		huh.NewOption("Cancel", buildCancel),
	}, buildCancel, func() {
		cfg := mustLoadConfig()
		core.ProcLog.Segment("Target: %s", cfg.TargetDir)
	}, func(ret action) {
		switch ret {
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
	})
}

func runBuildExec() error {
	cfg := mustLoadConfig()
	core.ProcLog.Info("build", "building %s via Makefile...", cfg.TargetName)

	cmd := exec.Command("make", "build",
		fmt.Sprintf("DIR=%s", cfg.TargetDir),
		fmt.Sprintf("NAME=%s", cfg.TargetName),
	)
	if err := core.RunAndLog(core.ProcLog, "build", cmd); err != nil {
		return err
	}

	core.ProcLog.Info("build", "create successfully")
	return nil
}

func appRun() {
	cfg := mustLoadConfig()
	core.ProcLog.Info("build", "launching %s via Makefile...", cfg.TargetName)

	cmd := exec.Command("make", "run",
		fmt.Sprintf("DIR=%s", cfg.TargetDir),
		fmt.Sprintf("NAME=%s", cfg.TargetName),
	)
	if err := core.RunAndLog(core.ProcLog, "build", cmd); err != nil {
		return
	}

	core.ProcLog.Info("build", "run successfully")
}
