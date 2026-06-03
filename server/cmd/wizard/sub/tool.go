package sub

import (
	"bit-craft/cmd/wizard/core"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"charm.land/huh/v2"
)

func ToolMenu() {
	tools := []toolType{
		{method: methodSnap, cmd: "protoc", source: "protobuf"},
		{method: methodShell, cmd: "atlas", source: "https://atlasgo.sh"},
		{method: methodGo, cmd: "protoc-gen-go", source: "google.golang.org/protobuf/cmd/protoc-gen-go"},
		{method: methodGo, cmd: "entc", source: "entgo.io/ent/cmd/entc", version: "v0.14.5"},
		{method: methodGo, cmd: "wrench", source: "github.com/cloudspannerecosystem/wrench", version: "latest"},
	}

	var retAction action
	form := huh.NewForm(
		huh.NewGroup(
			huh.NewSelect[action]().
				Title("Tooling Action").
				Options(
					huh.NewOption("Install All", toolInstallAll),
					huh.NewOption("Remove All", toolRemoveAll),
					huh.NewOption("Cancel", toolCancel),
				).
				Value(&retAction),
		),
	)

	if err := form.Run(); err != nil || retAction == toolCancel {
		core.ProcLog.Info("tool", "operation cancelled, ware!")
		return
	}

	for _, tool := range tools {
		switch retAction {
		case toolInstallAll:
			if checkTool(tool) {
				installTool(tool)
			}
		case toolRemoveAll:
			uninstallTool(tool)
		default:
			panic("unhandled default case")
		}
	}

	core.ProcLog.Segment("Operations completed\n" +
		"To reflect changes in your current shell, please run:\n" +
		"\n" +
		"  source ~/.bashrc" +
		"\n")
}

func checkTool(toolType toolType) bool {
	if _, err := exec.LookPath(toolType.cmd); err == nil {
		// fmt.Printf("[OK]   %-15s is already optimized and ready.\n", toolType.cmd)
		core.ProcLog.Info("tool", "[OK]   %-15s is already optimized and ready.", toolType.cmd)
		return false
	}

	// fmt.Printf("[WARN] %-15s missing. Initialize setup? (y/n): ", toolType.cmd)
	core.ProcLog.Prompt("tool", "[WARN] %-15s missing. Initialize setup? (Y/n): ", toolType.cmd)
	var response string
	_, _ = fmt.Scanln(&response)
	if response != "" && response != "y" && response != "Y" {
		return false
	}

	return true
}

func installTool(toolType toolType) {
	core.ProcLog.Info("tool", "deploying %s... Please hold on\n", toolType.cmd)
	var cmd *exec.Cmd
	switch toolType.method {
	case methodSnap:
		cmd = exec.Command("sudo", "snap", "install", toolType.source, "--classic")
	case methodShell:
		script := fmt.Sprintf("curl -sSf %s | sh -s -- --yes", toolType.source)
		cmd = exec.Command("sh", "-c", script)
	case methodGo:
		path := toolType.source
		if toolType.version != "" {
			path += "@" + toolType.version
		} else {
			path += "@latest"
		}
		args := []string{"install"}
		if toolType.tags != "" {
			args = append(args, "-tags", toolType.tags)
		}
		args = append(args, path)
		cmd = exec.Command("go", args...)
	default:
		return
	}

	//cmd.Stdout = os.Stdout
	//cmd.Stderr = os.Stderr
	//cmd.Stdin = os.Stdin
	core.ProcLog.Info("tool", "deploying %s...\n", toolType.cmd)
	if err := cmd.Run(); err != nil {
		core.ProcLog.Error("tool", err)
		return
	}
	core.ProcLog.Info("tool", "%s synchronized successfully", toolType.cmd)
}

func uninstallTool(toolType toolType) {
	var cmd *exec.Cmd

	switch toolType.method {
	case methodSnap:
		cmd = exec.Command("sudo", "snap", "remove", toolType.source)

	case methodShell:
		path, err := exec.LookPath(toolType.cmd)
		if err != nil {
			return
		}
		cmd = exec.Command("sudo", "rm", path)

	case methodGo:
		out, _ := exec.Command("go", "env", "GOPATH").Output()
		gopath := strings.TrimSpace(string(out))
		if gopath == "" {
			gopath = filepath.Join(os.Getenv("HOME"), "go")
		}
		target := filepath.Join(gopath, "bin", toolType.cmd)
		cmd = exec.Command("rm", "-f", target)
	}

	if cmd != nil {
		core.ProcLog.Info("tool", "deleting %s...", toolType.cmd)
		// @note 失敗しても処理続行 (|| true)
		_ = cmd.Run()
	}
}
