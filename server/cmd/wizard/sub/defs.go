package sub

type Config struct {
	TargetDir  string `json:"target_dir"`
	TargetName string `json:"target_name"`
}

type action int

const (
	toolInstallAll action = iota
	toolRemoveAll
	toolCancel
)

const (
	migrateNew action = iota
	migrateApplyDryRun
	migrateApply
	migrateFetch
	migrateSplit
	migrateCancel
)

const (
	gormGen action = iota
	gormCancel
)

const (
	entGen action = iota
	entGenRemove
	entNew
	entCancel
)

const (
	protoNew action = iota
	protoGen
	protoGenRemove
	protoCancel
)

const (
	atlasDiff action = iota
	atlasCancel
	atlasApply
)

const (
	buildExecAndRun action = iota
	buildExec
	buildCancel
	buildConf
)

const (
	configConfirm action = iota
	configBack
)

type installMethod int

const (
	methodSnap installMethod = iota
	methodShell
	methodGo
)

type toolType struct {
	method  installMethod
	cmd     string
	source  string
	version string
	tags    string
}

//const (
//	migrationDir = "file://migrations"
//	entSchemaTo  = "ent://schema/ent"
//	entContainer = "docker://mysql/8/ent"
//)

const (
	baseBuildDir   = "cmd"
	configFilePath = "cmd/wizard/sub/.config.json"
)

const (
	ddlDir = "schema/spanner"
)

type opsEnv string

var typeOpsEnv = struct {
	Dev opsEnv
	Stg opsEnv
	Prd opsEnv
}{
	Dev: "dev",
	Stg: "stg",
	Prd: "prd",
}
