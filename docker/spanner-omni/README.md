## 概要

- https://docs.cloud.google.com/spanner-omni/overview<br />
Spanner Omni は、デプロイの作成から 90 日後にデータの書き込みを停止

上記の理由により Spanner Emulator の方を使用する

### その他
- DataGrip で接続する場合
  - ドライバ<br />
  [google-cloud-spanner-jdbc-2.40.0-single-jar-with-dependencies.jar](https://repo1.maven.org/maven2/com/google/cloud/google-cloud-spanner-jdbc/2.40.0/google-cloud-spanner-jdbc-2.40.0-single-jar-with-dependencies.jar)
  - URL Only<br />
  URL: jdbc:spanner://localhost:15000/databases/local;usePlainText=true;isExperimentalHost=true
