package sub

import (
	"bit-craft/cmd/wizard/core"
	"os/exec"

	"charm.land/huh/v2"
)

func EntMenu() {
	runMenu("ent", "Ent Operations", []huh.Option[action]{
		huh.NewOption("Ent Gen", entGen),
		huh.NewOption("Ent Gen Remove", entGenRemove),
		huh.NewOption("Ent New", entNew),
		huh.NewOption("Cancel", entCancel),
	}, entCancel, nil, func(ret action) {
		switch ret {
		case entGen:
			runEntGen()
		case entGenRemove:
			runEntGenRemove()
		case entNew:
			runEntNew()
		default:
			panic("unhandled default case")
		}
	})
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
	if err := core.RunAndLog(core.ProcLog, "ent", cmd); err != nil {
		core.ProcLog.Fatal("ent", "ent new failed: %v", err)
	}

	core.ProcLog.Info("ent", "successfully")
}

func runEntGen() {
	cmd := exec.Command("make", "-s", "ent-gen")
	if err := core.RunAndLog(core.ProcLog, "ent", cmd); err != nil {
		core.ProcLog.Fatal("ent", "generate failed: %v", err)
	}

	core.ProcLog.Info("ent", "generate successfully")
}

func runEntGenRemove() {
	cmd := exec.Command("make", "-s", "ent-gen-clean")
	if err := core.RunAndLog(core.ProcLog, "ent", cmd); err != nil {
		return
	}

	core.ProcLog.Info("ent", "remove successfully")
}

func toSnake(s string) string {
	var out []rune
	for i, r := range s {
		if 'A' <= r && r <= 'Z' {
			if i > 0 {
				out = append(out, '_')
			}
			r += 'a' - 'A'
		}
		out = append(out, r)
	}
	return string(out)
}
