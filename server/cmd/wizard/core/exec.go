package core

import (
	"os/exec"
	"strings"
)

// RunAndLog runs cmd, capturing combined stdout/stderr. On failure it logs
// the captured output under action before returning the error, so a failing
// wrapped command (eg. `make ent-gen`) is never silently swallowed. On
// success it logs any output produced.
func RunAndLog(logger Logger, action string, cmd *exec.Cmd) error {
	output, err := cmd.CombinedOutput()
	if err != nil {
		logger.Info(action, "failed: %v\n%s", err, indent(string(output)))
		return err
	}

	if out := strings.TrimSpace(string(output)); out != "" {
		logger.Info(action, "%s", out)
	}
	return nil
}

func indent(s string) string {
	lines := strings.Split(s, "\n")
	for i, line := range lines {
		lines[i] = "  " + line
	}
	return strings.Join(lines, "\n")
}
