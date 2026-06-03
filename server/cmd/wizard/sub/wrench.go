package sub

import (
	"bit-craft/cmd/wizard/core"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"charm.land/huh/v2"
	_ "github.com/googleapis/go-sql-spanner"
)

var ignoreTables = map[string]struct{}{
	"SchemaMigrations": {},
}

func WrenchMenu() {
	var retAction action
	form := huh.NewForm(
		huh.NewGroup(
			huh.NewSelect[action]().
				Title("Ent Operations").
				Options(
					huh.NewOption("Migrate New", migrateNew),
					huh.NewOption("Migrate Apply (dry-run)", migrateApplyDryRun),
					huh.NewOption("Migrate Apply", migrateApply),
					huh.NewOption("Migrate Fetch", migrateFetch),
					huh.NewOption("Migrate Split", migrateSplit),
					huh.NewOption("Cancel", migrateCancel),
				).
				Value(&retAction),
		),
	)

	if err := form.Run(); err != nil || retAction == migrateCancel {
		fmt.Println("Spanner operation cancelled, ware!")
		return
	}

	switch retAction {
	case migrateNew:
		core.ProcLog.Segment("migrate new")
		runMigrateNew()
		core.ProcLog.Line()
	case migrateApplyDryRun:
		core.ProcLog.Segment("migrate up dry-run")
		var env *core.EmulatorSpannerEnv
		var err error
		env, err = core.EmulatorSpanner()
		if err != nil {
			return
		}
		defer env.Cleanup()
		_ = os.Setenv("SPANNER_EMULATOR_HOST", env.Endpoint)
		runMigrate("up")
		core.ProcLog.Line()
	case migrateApply:
		core.ProcLog.Segment("migrate up")
		runMigrate("up")
		core.ProcLog.Line()
	case migrateFetch:
		core.ProcLog.Segment("migrate load")
		runMigrate("load")
		core.ProcLog.Line()
	case migrateSplit:
		core.ProcLog.Segment("schema.sql split")
		runMigrateSplit()
		core.ProcLog.Line()
	default:
		panic("unhandled default case")
	}

	// @note メニューを再帰呼び出し
	if retAction != migrateCancel {
		WrenchMenu()
	}
}

func runMigrateNew() {
	var name string
	_ = huh.NewInput().
		Title("Migration Name").
		Placeholder("add_u_item").
		Value(&name).
		Run()

	if name == "" {
		core.ProcLog.Info("migrate", "name is required")
		return
	}

	cmd := exec.Command("make", "-s", "migrate-new", "NAME="+name)
	//cmd.Stdout = os.Stdout
	//cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		core.ProcLog.Fatal("migrate", "new failed: %v", err)
	}

	core.ProcLog.Info("migrate", "successfully")
}

func runMigrate(target string) {
	action := "migrate " + target

	cmd := exec.Command("make", "-s", "migrate-"+target)
	cmd.Env = os.Environ()

	output, err := cmd.CombinedOutput()
	if err != nil {
		core.ProcLog.Info(action,
			"Failed with error:\n%s\n\nCommand output:\n%s",
			indentOutput(err.Error()),
			indentOutput(string(output)),
		)
		return
	}

	outStr := strings.TrimSpace(string(output))
	if len(outStr) > 0 {
		core.ProcLog.Info(action, "%s", outStr)
	}

	core.ProcLog.Info(action, "successfully")
}

func isIgnored(tableName string) bool {
	_, ok := ignoreTables[tableName]
	return ok
}

func runMigrateSplit() {

	outputDir := "schema/spanner"
	schema, _ := os.ReadFile(outputDir + "/_dev/schema.sql")
	statements := strings.Split(string(schema), ";")

	var indexStatements []string

	for _, s := range statements {
		s = strings.TrimSpace(s)
		if s == "" {
			continue
		}

		switch {
		case strings.HasPrefix(s, "CREATE TABLE"):
			// @note テーブル名を抽出
			lines := strings.Split(s, " ")
			tableName := lines[2] // CREATE TABLE [tableName] の想定

			// @note ファイル生成から除外
			if isIgnored(tableName) {
				continue
			}

			// @note ファイル生成を実行
			_ = os.WriteFile(filepath.Join(outputDir, tableName+".sql"), []byte(s+";"), 0666)

		case strings.HasPrefix(s, "CREATE UNIQUE INDEX") || strings.HasPrefix(s, "CREATE INDEX"):
			indexStatements = append(indexStatements, s+";")
		}
	}
	// @note インデックスを纏めて保存
	_ = os.WriteFile(filepath.Join(outputDir, "index.sql"), []byte(strings.Join(indexStatements, "\n\n")), 0666)

	core.ProcLog.Info("schema.sql split", "successfully")
}

func indentOutput(input string) string {
	lines := strings.Split(input, "\n")
	for i, line := range lines {
		lines[i] = "  " + line
	}
	return strings.Join(lines, "\n")
}
