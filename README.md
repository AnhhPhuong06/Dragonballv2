# Dragonball iOS — unsigned IPA

Project Xcode export từ Unity 2021.3.45f2, build cho thiết bị iOS arm64.

## Build trên GitHub Actions

Đưa toàn bộ nội dung thư mục này lên **gốc repo**, bao gồm `.github`,
`Classes`, `Data`, `Libraries` và `Unity-iPhone.xcodeproj`.

Phải cài Git LFS và chạy `git lfs install` **trước khi `git add` lần đầu**.
`.gitattributes` lưu các thư viện `Libraries/*.a` bằng LFS vì
`libiPhone-lib.a` vượt giới hạn file thông thường của GitHub.
Không upload thư viện này qua giao diện web GitHub.

Workflow **Build unsigned IPA** tự chạy khi push vào `main`/`master`.
Cũng có thể chạy trong **Actions → Build unsigned IPA → Run workflow**.
Khi thành công, tải artifact **Dragonball-unsigned-ipa**, giải nén để lấy
`Dragonball-unsigned.ipa`. Log nằm trong artifact **ios-build-log**.

Build dùng macOS 15, Xcode 16.4, cấu hình Release và tắt code signing/bitcode.
Không cần chứng chỉ Apple, provisioning profile hoặc Unity license để build
bản export Xcode này. Repo dùng Git LFS và Actions cần có quota tương ứng.

## Build trên máy Mac

```bash
git lfs pull
DEVELOPER_DIR=/Applications/Xcode_16.4.app/Contents/Developer bash scripts/build-unsigned-ipa.sh
```

Kết quả nằm ở `build/Dragonball-unsigned.ipa`.
IPA chưa ký cần được ký bằng công cụ/chứng chỉ phù hợp trước khi cài lên iPhone.
