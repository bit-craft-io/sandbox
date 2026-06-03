package core

import (
	"context"
	"fmt"
	"os"

	"cloud.google.com/go/spanner/admin/database/apiv1"
	adminpb "cloud.google.com/go/spanner/admin/database/apiv1/databasepb"
	instance "cloud.google.com/go/spanner/admin/instance/apiv1"
	"cloud.google.com/go/spanner/admin/instance/apiv1/instancepb"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

type EmulatorSpannerEnv struct {
	DSN      string
	Endpoint string
	Cleanup  func()
}

const (
	projectID     = "bc"
	instanceID    = "sandbox"
	dbName        = "local"
	emulatorImage = "gcr.io/cloud-spanner-emulator/emulator:latest"
)

func EmulatorSpanner() (*EmulatorSpannerEnv, error) {
	ctx := context.Background()
	req := testcontainers.GenericContainerRequest{
		ContainerRequest: testcontainers.ContainerRequest{
			Image:        emulatorImage,
			ExposedPorts: []string{"9010/tcp"},
			WaitingFor:   wait.ForListeningPort("9010/tcp"),
			Env: map[string]string{
				"SPANNER_EMULATOR_HOST": "0.0.0.0:9010",
			},
		},
		Started: true,
	}

	container, err := testcontainers.GenericContainer(ctx, req)
	if err != nil {
		return nil, err
	}

	endpoint, err := container.PortEndpoint(ctx, "9010/tcp", "http")
	if err != nil {
		_ = container.Terminate(ctx)
		return nil, err
	}

	emulatorHost := endpoint[7:]
	_ = os.Setenv("SPANNER_EMULATOR_HOST", emulatorHost)
	cleanup := func() {
		if err := container.Terminate(ctx); err != nil {
			SpannerLog.Fatal("container terminate", "terminate spanner\n %v")
		}
		SpannerLog.Info("cleanup", "terminate container")
	}

	newIns, err := instance.NewInstanceAdminClient(ctx)
	if err != nil {
		return nil, err
	}
	opIns, err := newIns.CreateInstance(ctx, &instancepb.CreateInstanceRequest{
		Parent:     fmt.Sprintf("projects/%s", projectID),
		InstanceId: instanceID,
		Instance: &instancepb.Instance{
			DisplayName: "Temporary Wizard Instance",
			NodeCount:   1,
		},
	})
	if err != nil {
		return nil, err
	}
	_, _ = opIns.Wait(ctx)

	newDb, err := database.NewDatabaseAdminClient(ctx)
	if err != nil {
		SpannerLog.Error("database new database admin client", err)
		return nil, err
	}

	opDb, err := newDb.CreateDatabase(ctx, &adminpb.CreateDatabaseRequest{
		Parent:          fmt.Sprintf("projects/%s/instances/%s", projectID, instanceID),
		CreateStatement: fmt.Sprintf("CREATE DATABASE %s", dbName),
	})
	if err != nil {
		return nil, err
	}
	_, _ = opDb.Wait(ctx)

	dsn := fmt.Sprintf(
		"projects/%s/instances/%s/databases/%s",
		projectID,
		instanceID,
		dbName,
	)

	return &EmulatorSpannerEnv{DSN: dsn, Endpoint: emulatorHost, Cleanup: cleanup}, nil
}
