package main

import (
	"bit-craft/cmd/wizard/core"
	"bit-craft/cmd/wizard/sub"
	"fmt"
	"os"

	"charm.land/huh/v2"
)

const banner = `
----------------------------------------------------------------
 ■■■■■   ■■■■  ■■■■■■      ■■■■  ■■■■■    ■■■■   ■■■■■■  ■■■■■■
 ■■   ■   ■■     ■■      ■■      ■■   ■  ■■   ■  ■■        ■■
 ■■■■■    ■■     ■■      ■■      ■■■■■   ■■■■■■  ■■■■      ■■
 ■■   ■   ■■     ■■      ■■      ■■  ■   ■■   ■  ■■        ■■
 ■■■■■   ■■■■    ■■        ■■■■  ■■   ■  ■■   ■  ■■        ■■
----------------------------------------------------------------
`

type wizardAction string

var TypeWizardAction = struct {
	Tool   wizardAction
	Proto  wizardAction
	Wrench wizardAction
	Gorm   wizardAction
	Ent    wizardAction
	Atlas  wizardAction
	Build  wizardAction
	Config wizardAction
	Exit   wizardAction
}{
	Tool:   "tool",
	Proto:  "proto",
	Wrench: "spanner",
	Gorm:   "gorm",
	Ent:    "ent",
	Atlas:  "atlas",
	Build:  "build",
	Config: "config",
	Exit:   "exit",
}

func main() {
	fmt.Print(banner)
	var action wizardAction

	form := huh.NewForm(
		huh.NewGroup(
			huh.NewSelect[wizardAction]().
				Title("Deployment Target").
				Description("Choose the module to initialize").
				Options(
					// @note aqua で管理(aqua_registryにあるもの)
					//huh.NewOption("Tool", TypeWizardAction.Tool),
					huh.NewOption("Wrench", TypeWizardAction.Wrench),
					huh.NewOption("Gorm", TypeWizardAction.Gorm),
					huh.NewOption("Proto", TypeWizardAction.Proto),
					// @note Ent と Atlas は使用しない
					// huh.NewOption("Ent", TypeWizardAction.Ent),
					// huh.NewOption("Atlas", TypeWizardAction.Atlas),
					huh.NewOption("Build", TypeWizardAction.Build),
					huh.NewOption("Exit", TypeWizardAction.Exit),
				).
				Value(&action),
		),
	)

	if err := form.Run(); err != nil {
		core.ProcLog.Error("interaction aborted", err)
		os.Exit(1)
	}

	switch action {
	case TypeWizardAction.Tool:
		sub.ToolMenu()
	case TypeWizardAction.Proto:
		sub.ProtoMenu()
	case TypeWizardAction.Wrench:
		sub.WrenchMenu()
	case TypeWizardAction.Gorm:
		sub.GormMenu()
	case TypeWizardAction.Ent:
		sub.EntMenu()
	case TypeWizardAction.Atlas:
		sub.AtlasMenu()
	case TypeWizardAction.Build:
		sub.BuildMenu()
	default:
		core.ProcLog.Info("wizard", "no action taken")
	}
}
