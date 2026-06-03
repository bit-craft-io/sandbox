package sub

import (
	"bit-craft/cmd/wizard/core"
	"os/exec"

	"charm.land/huh/v2"
)

func EntMenu() {
	var retAction action
	form := huh.NewForm(
		huh.NewGroup(
			huh.NewSelect[action]().
				Title("Ent Operations").
				Options(
					huh.NewOption("Ent Gen", entGen),
					huh.NewOption("Ent Gen Remove", entGenRemove),
					huh.NewOption("Ent New", entNew),
					huh.NewOption("Cancel", entCancel),
				).
				Value(&retAction),
		),
	)

	if err := form.Run(); err != nil || retAction == entCancel {
		core.ProcLog.Info("ent", "operation cancelled, ware!")
		return
	}

	switch retAction {
	case entGen:
		runEntGen()
	case entGenRemove:
		cmd := exec.Command("make", "-s", "ent-gen-clean")
		//cmd.Stdout = os.Stdout
		//cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			core.ProcLog.Error("ent", err)
			return
		}
		core.ProcLog.Info("ent", "remove successfully")
	case entNew:
		runEntNew()
	default:
		panic("unhandled default case")
	}
}

func runEntNew() {
	var name string

	_ = huh.NewInput().
		Title("Enter Schema Name (example: UItem)").
		Placeholder("UItem").
		Value(&name).
		Run()

	if name == "" {
		core.ProcLog.Info("ent", "name is required")
		return
	}

	cmd := exec.Command("make", "-s", "ent-new",
		"NAME="+name,
		"SNAKE_NAME="+toSnake(name),
	)

	//cmd.Stdout = os.Stdout
	//cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		core.ProcLog.Fatal("ent", "ent new failed: %v", err)
	}
	core.ProcLog.Info("ent", "successfully")
}

func runEntGen() {
	cmd := exec.Command("make", "-s", "ent-gen")

	//cmd.Stdout = os.Stdout
	//cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		core.ProcLog.Fatal("ent", "generate failed: %v", err)
	}
	core.ProcLog.Info("ent", "generate successfully")
}

func toSnake(s string) string {
	var out []rune
	for i, r := range s {
		if i == 1 {
			out = append(out, '_')
		}
		if 'A' <= r && r <= 'Z' {
			r += 'a' - 'A'
		}
		out = append(out, r)
	}
	return string(out)
}
