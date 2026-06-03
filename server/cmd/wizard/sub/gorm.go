package sub

import (
	"bit-craft/cmd/wizard/core"
	"os"
	"path/filepath"
	"strings"

	"charm.land/huh/v2"
	spannergorm "github.com/googleapis/go-gorm-spanner"
	_ "github.com/googleapis/go-sql-spanner"
	"gorm.io/gen"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var ignoreDDLs = map[string]struct{}{
	"index.sql": {},
}

func GormMenu() {
	var retAction action
	form := huh.NewForm(
		huh.NewGroup(
			huh.NewSelect[action]().
				Title("Ent Operations").
				Options(
					huh.NewOption("Generate", gormGen),
					huh.NewOption("Cancel", gormCancel),
				).
				Value(&retAction),
		),
	)

	if err := form.Run(); err != nil || retAction == gormCancel {
		core.ProcLog.Info("gorm", "operation cancelled, ware!")
		return
	}

	switch retAction {
	case gormGen:
		core.ProcLog.Segment("generate sql to object")
		runGormGen()
		core.ProcLog.Line()
	default:
		panic("unhandled default case")
	}

	// @note メニューを再帰呼び出し
	if retAction != gormCancel {
		GormMenu()
	}
}

func runGormGen() {
	var env *core.EmulatorSpannerEnv
	var err error
	env, err = core.EmulatorSpanner()
	if err != nil {
		return
	}
	defer env.Cleanup()

	gormDb := mustGormDb(env.DSN)
	err = applyDDL(gormDb)
	if err != nil {
		return
	}

	generator := gen.NewGenerator(gen.Config{
		OutPath:      "gen/gorm",
		ModelPkgPath: "gen/gorm/model",

		Mode: gen.WithoutContext |
			gen.WithDefaultQuery |
			gen.WithQueryInterface,
	})

	generator.UseDB(gormDb)

	// @note model名が複数形になる
	// models := generator.GenerateAllTable()
	// generator.ApplyBasic(models...)

	// @note model名を単数形にする
	tables := mustDiscoverTables()
	var models []interface{}
	for _, table := range tables {
		modelName := toModelName(table)

		core.ProcLog.Info("generate", "%s -> %s", table, modelName)

		model := func() interface{} {
			// @note gorm が出力するログを破棄の設定
			original := core.LogOff()
			// @note gorm が出力するログを破棄の設定を戻す
			defer core.LogOn(original)
			return generator.GenerateModelAs(table, modelName)
		}()

		models = append(models, model)
	}

	func() {
		// @note gorm が出力するログを破棄の設定
		original := core.LogOff()
		// @note gorm が出力するログを破棄の設定を戻す
		defer core.LogOn(original)
		generator.ApplyBasic(models...)
		generator.Execute()
	}()

	core.ProcLog.Info("end", "generate")
	return
}

func mustGormDb(dsn string) *gorm.DB {
	gormDb, err := gorm.Open(
		spannergorm.New(
			spannergorm.Config{
				DriverName: "spanner",
				DSN:        dsn,
			}),
		// @note この設定をしても gorm でlogが呼ばれてるためログが出力される
		&gorm.Config{
			Logger: logger.Default.LogMode(logger.Silent),
		},
	)
	if err != nil {
		core.SpannerLog.Fatal("connect", "failed\n %v", err)
	}

	return gormDb
}

func applyDDL(db *gorm.DB) error {
	ddl := mustReadDDLFiles()
	cleaned := sanitizeDDL(ddl)
	statements := strings.Split(cleaned, ";")
	for _, stmt := range statements {
		stmt = strings.TrimSpace(stmt)

		if stmt == "" {
			continue
		}

		if err := db.Exec(stmt).Error; err != nil {
			// core.SchemaLog.Error("db.Exec", err)
			core.SchemaLog.Fatal("db.Exec failed", "error %v\n statement %s", err, stmt)
			return err
		}
	}

	return nil
}

func sanitizeDDL(content string) string {
	lines := strings.Split(content, "\n")

	var cleaned []string
	for _, line := range lines {
		line = strings.TrimSpace(line)

		if strings.HasPrefix(line, "--") {
			continue
		}

		if line == "" {
			continue
		}

		cleaned = append(cleaned, line)
	}

	return strings.Join(cleaned, "\n")
}

func mustReadDDLFiles() string {

	files, err := os.ReadDir(ddlDir)
	if err != nil {
		core.SchemaLog.Fatal("read dir", "%s\n %v", ddlDir, err)
	}

	var ddlBuilder strings.Builder
	for _, file := range files {
		if file.IsDir() || filepath.Ext(file.Name()) != ".sql" {
			continue
		}

		// @note ファイル生成から除外
		if _, ok := ignoreDDLs[file.Name()]; ok {
			continue
		}

		filePath := filepath.Join(ddlDir, file.Name())
		core.SchemaLog.Info("read file", "%s", filePath)

		content, err := os.ReadFile(filePath)
		if err != nil {
			core.SchemaLog.Fatal("read file", "%s\n %v", file.Name(), err)
		}

		ddlBuilder.Write(content)
		ddlBuilder.WriteString("\n")
	}

	finalDDL := ddlBuilder.String()

	if len(strings.TrimSpace(finalDDL)) == 0 {
		core.SchemaLog.Fatal("read file", "ddl is empty: %s", ddlDir)
	}

	return finalDDL
}

func mustDiscoverTables() []string {
	files, err := os.ReadDir(ddlDir)
	if err != nil {
		core.SchemaLog.Fatal("read dir", "%s\n %v", ddlDir, err)
	}

	var tables []string
	for _, file := range files {
		if file.IsDir() {
			continue
		}

		// @note ファイル生成から除外
		if _, ok := ignoreDDLs[file.Name()]; ok {
			continue
		}

		if filepath.Ext(file.Name()) != ".sql" {
			continue
		}

		tableName := strings.TrimSuffix(file.Name(), ".sql")
		tables = append(tables, tableName)
	}

	return tables
}

func toModelName(table string) string {
	parts := strings.Split(table, "_")

	for i, p := range parts {
		if len(p) == 0 {
			continue
		}
		parts[i] = strings.ToUpper(p[:1]) + p[1:]
	}

	return strings.Join(parts, "")
}
