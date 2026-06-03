package main

import (
	"bytes"
	"context"
	"io"
	"log"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"google.golang.org/protobuf/proto"

	agones "agones.dev/agones/sdks/go"

	pb "bit-craft/gen/proto/go"
)

func main() {
	log.Println("古代ロボ、再起動準備...")

	// 1. Agones SDKの初期化
	ctx := context.Background()
	sdk, err := agones.NewSDK()
	if err != nil {
		log.Fatalf("SDK初期化でコケた、カナンワ、ワレ！: %v", err)
	}

	// 2. Laravelへの通知処理（別スレッドで実行）
	go func() {
		// サーバーが完全に立ち上がるのを少し待つんや
		time.Sleep(2 * time.Second)
		sendToLaravel()
	}()

	// 3. ヘルスチェック（Agonesサイドカーに「生きてるで」と伝え続ける）
	go func() {
		tick := time.NewTicker(2 * time.Second)
		for {
			select {
			case <-tick.C:
				if err := sdk.Health(); err != nil {
					log.Printf("Healthチェック失敗、ワレ！: %v", err)
				}
			case <-ctx.Done():
				return
			}
		}
	}()

	// 4. Agonesに「Ready」を送信（これでGameServerがREADY状態になる）
	if err := sdk.Ready(); err != nil {
		log.Fatalf("Ready送信失敗、ソリャ、カナンワ、ワレ！: %v", err)
	}
	log.Println("Agones GameServer Ready!")

	// 5. 自身のHTTP待機（8081ポート）
	// Agonesのサイドカーが8080を使うから、ここは被らんようにするんや
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	route := chi.NewRouter()
	route.Post("/hallo", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/x-protobuf")
		res := &pb.ResHallo{
			IsSuccess: true,
			Message:   "hey sey, thanks!3",
		}
		data, err := proto.Marshal(res)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(data)
	})

	route.Post("/health", func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		defer r.Body.Close()

		reqPb := &pb.ReqHealth{}
		if err := proto.Unmarshal(body, reqPb); err != nil {
			w.WriteHeader(http.StatusUnsupportedMediaType)
			return
		}

		log.Println("health req:", reqPb)

		w.Header().Set("Content-Type", "application/x-protobuf")
		w.WriteHeader(http.StatusOK)

		res := &pb.ResHealth{
			IsSuccess: true,
			Message:   "Protobuf届いたで、おおきに！",
		}

		out, err := proto.Marshal(res)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		_, _ = w.Write(out)
	})

	log.Println("HTTP Server starting on :8081...")
	if err := http.ListenAndServe(":8081", nil); err != nil {
		log.Fatalf("HTTP Listen失敗、ワレ！: %v", err)
	}
}

// LaravelへPOST送信する関数
func sendToLaravel() {
	url := "http://host.docker.internal/api/gs-status" // Docker DesktopからホストのLaravelを叩く想定

	reqData := &pb.ReqHealth{
		Message: "Agonesから挨拶や、ワレ！",
	}

	data, err := proto.Marshal(reqData)
	if err != nil {
		log.Printf("シリアライズ失敗: %v", err)
		return
	}

	resp, err := http.Post(url, "application/x-protobuf", bytes.NewBuffer(data))
	if err != nil {
		log.Printf("LaravelへのPOST失敗（宛先おるか？）: %v", err)
		return
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	log.Printf("Laravelからの返事: %s (Status: %d)", string(body), resp.StatusCode)
}
