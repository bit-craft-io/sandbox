package sub

import (
	"bit-craft/cmd/wizard/core"
	"os/exec"

	"charm.land/huh/v2"
)

func ProtoMenu() {
	var retAction action
	form := huh.NewForm(
		huh.NewGroup(
			huh.NewSelect[action]().
				Title("Proto Operations").
				Options(
					huh.NewOption("Proto New", protoNew),
					huh.NewOption("Proto Gen", protoGen),
					huh.NewOption("Proto Gen Remove", protoGenRemove),
					huh.NewOption("Cancel", protoCancel),
				).
				Value(&retAction),
		),
	)

	if err := form.Run(); err != nil || retAction == protoCancel {
		core.ProcLog.Info("proto", "operation cancelled, ware!")
		return
	}

	switch retAction {
	case protoNew:
		core.ProcLog.Segment("create protobuf")
		runProtoNew()
		core.ProcLog.Line()
	case protoGen:
		core.ProcLog.Segment("generate protobuf")
		runProtoGen()
		core.ProcLog.Line()
	case protoGenRemove:
		core.ProcLog.Segment("remove protobuf")
		cmd := exec.Command("make", "-s", "proto-gen-clean")
		//cmd.Stdout = os.Stdout
		//cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			core.ProcLog.Fatal("proto", "remove failed: %v", err)
		}
		core.ProcLog.Info("proto", "remove successfully")
		core.ProcLog.Line()
	default:
		panic("unhandled default case")
	}

	// @note メニューを再帰呼び出し
	if retAction != protoCancel {
		ProtoMenu()
	}
}

func runProtoNew() {

	var name string

	_ = huh.NewInput().
		Title("Package Name (example: hallo)").
		Placeholder("hallo").
		Value(&name).
		Run()

	if name == "" {
		core.ProcLog.Info("proto", "name is required")
		return
	}

	cmd := exec.Command("make", "-s", "proto-new", "NAME="+name)
	//cmd.Stdout = os.Stdout
	//cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		core.ProcLog.Fatal("proto", "new failed: %v", err)
	}

	core.ProcLog.Info("proto", "create successfully")
}

func runProtoGen() {
	cmd := exec.Command("make", "-s", "proto-gen")
	//cmd.Stdout = os.Stdout
	//cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		core.ProcLog.Error("proto", err)
	}

	core.ProcLog.Info("proto", "generate successfully")
}
