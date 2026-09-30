package sub

import (
	"bit-craft/cmd/wizard/core"
	"os/exec"

	"charm.land/huh/v2"
)

func ProtoMenu() {
	runMenu("proto", "Proto Operations", []huh.Option[action]{
		huh.NewOption("Proto New", protoNew),
		huh.NewOption("Proto Gen", protoGen),
		huh.NewOption("Proto Gen Remove", protoGenRemove),
		huh.NewOption("Cancel", protoCancel),
	}, protoCancel, nil, func(ret action) {
		switch ret {
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
			runProtoGenRemove()
			core.ProcLog.Line()
		default:
			panic("unhandled default case")
		}
	})
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
	if err := core.RunAndLog(core.ProcLog, "proto", cmd); err != nil {
		core.ProcLog.Fatal("proto", "new failed: %v", err)
	}

	core.ProcLog.Info("proto", "create successfully")
}

func runProtoGen() {
	cmd := exec.Command("make", "-s", "proto-gen")
	if err := core.RunAndLog(core.ProcLog, "proto", cmd); err != nil {
		return
	}

	core.ProcLog.Info("proto", "generate successfully")
}

func runProtoGenRemove() {
	cmd := exec.Command("make", "-s", "proto-gen-clean")
	if err := core.RunAndLog(core.ProcLog, "proto", cmd); err != nil {
		core.ProcLog.Fatal("proto", "remove failed: %v", err)
	}

	core.ProcLog.Info("proto", "remove successfully")
}
