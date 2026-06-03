package sub

import (
	"bit-craft/cmd/wizard/core"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"charm.land/huh/v2"
)

func buildConfig() {
	var doChange bool
	form := huh.NewForm(
		huh.NewGroup(
			huh.NewConfirm().
				Title("Do you want to change the current settings?").
				Value(&doChange),
		),
	)

	if err := form.Run(); err != nil {
		core.ProcLog.Fatal("config", "operation cancelled, ware!")
	}

	if !doChange {
		core.ProcLog.Info("config", "Keep current settings. Happy coding, ware!")
		return
	}

	base := baseBuildDir
	finalPath := selectDirectory(base)
	saveConfig(finalPath)
}

func mustLoadConfig() *Config {
	data, err := os.ReadFile(configFilePath)
	if err != nil {
		core.ProcLog.Info("config", "config not found")
		buildConfig()

		data, err = os.ReadFile(configFilePath)
		if err != nil {
			core.ProcLog.Fatal("config", "Critical Error, ware!: %v", err)
		}
	}

	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		core.ProcLog.Fatal("config", "JSON Unmarshal Error, ware!: %v", err)
	}

	if cfg.TargetDir == "" {
		core.ProcLog.Fatal("config", "Critical Error: TargetDir is empty in config, ware!")
	}

	return &cfg
}

func selectDirectory(currentPath string) string {
	options := getSubDirectories(currentPath)
	var displayOptions []huh.Option[any]
	displayOptions = append(displayOptions, huh.NewOption[any]("[Select this directory]", configConfirm))
	if currentPath != baseBuildDir {
		displayOptions = append(displayOptions, huh.NewOption[any]("[Go back to parent]", configBack))
	}

	for _, opt := range options {
		displayOptions = append(displayOptions, huh.NewOption[any](opt.Key, opt.Value))
	}

	var selected any
	form := huh.NewForm(
		huh.NewGroup(
			huh.NewSelect[any]().
				Title(fmt.Sprintf("Current Path: %s", currentPath)).
				Options(displayOptions...).
				Value(&selected),
		),
	)

	err := form.Run()
	if err != nil {
		core.ProcLog.Fatal("config", "Error during directory selection: ", err)
	}

	switch value := selected.(type) {
	case action:
		switch value {
		case configBack:
			parent := filepath.Dir(currentPath)
			return selectDirectory(parent)
		case configConfirm:
			return currentPath
		}
	case string:
		// string型（サブディレクトリ名）だった場合
		nextPath := filepath.Join(currentPath, value)
		return selectDirectory(nextPath)
	}

	return currentPath
}

func getSubDirectories(basePath string) []huh.Option[string] {
	entries, err := os.ReadDir(basePath)
	if err != nil {
		return nil
	}

	var options []huh.Option[string]
	for _, entry := range entries {
		if entry.IsDir() {
			name := entry.Name()
			// Exclude the wizard itself and hidden directories (e.g., .git)
			if name == "wizard" || strings.HasPrefix(name, ".") {
				continue
			}
			options = append(options, huh.NewOption(name, name))
		}
	}
	return options
}

func saveConfig(targetPath string) {
	targetName := filepath.Base(targetPath)

	config := Config{
		TargetDir:  targetPath,
		TargetName: targetName,
	}

	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		core.ProcLog.Fatal("config", "Failed to marshal config to JSON: ", err)
	}

	err = os.WriteFile(configFilePath, data, 0644)
	if err != nil {
		core.ProcLog.Fatal("config", "Failed to write config file: ", err)
	}

	core.ProcLog.Info("config", "Configuration completed successfully!")
	core.ProcLog.Info("config", "Target Directory: %s", targetPath)
	core.ProcLog.Info("config", "Config File:      %s", configFilePath)
	core.ProcLog.Info("config", "Ready to go, ware!")
	BuildMenu()
}
