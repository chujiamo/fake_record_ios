# VoidCast / 空录屏

VoidCast 是一个“丢弃型屏幕捕获”iOS 工程。用户通过 Apple 提供的系统选择器明确启动后，系统会把屏幕与音频采样交给本机处理器。处理器对每一个采样立即返回，不持有、不编码、不写入文件，也不通过网络发送。

## 能做与不能做

- 能：让系统屏幕捕获处于活动状态，同时不生成录像文件。iOS 27 使用 ScreenCaptureKit；iOS 16–26 使用“空录屏接收器”ReplayKit 广播扩展。
- 不能：拦截或删除控制中心的普通“屏幕录制”。普通录屏仍会保存到照片。
- 不能：静默开始广播。iOS 要求用户点按系统控件并在系统界面确认。
- “丢弃”表示扩展收到内存中的瞬时 `CMSampleBuffer` 后不保留。它不表示 iOS 从未在内存中创建采样。

## 架构

- `VoidCast`：SwiftUI 宿主 App。iOS 27 通过 `SCContentSharingPicker` 获取系统确认，再由 `SCStreamOutput` 丢弃屏幕和系统音频采样。
- `VoidCastSink`：iOS 16–26 的 Broadcast Upload Extension，`SampleHandler` 对视频、App 音频、麦克风音频全部立即返回。
- 无 App Group、照片权限、相机权限、麦克风权限、媒体写入或网络能力。
- 宿主只声明 `screen-capture` 后台模式，让 iOS 27 全屏捕获在切换 App 后继续；未声明音频、定位、推送等其他后台模式。
- 宿主提供 `NSScreenCaptureUsageDescription`，并在 `VoidCast.entitlements` 声明 iOS 27 所需的 `com.apple.developer.screen-recording`。

部署目标为 iOS 16.0。Xcode 27 SDK 已将 ReplayKit 广播扩展标记为“iOS 27 不再支持”，因此工程在 iOS 27 自动切换到 Apple 推荐的 ScreenCaptureKit；旧扩展仅作为 iOS 16–26 兼容路径。ScreenCaptureKit 的 iOS 27 API 在当前 SDK 中仍标注为 Beta，必须在签名真机上复验最终系统版本。

## 构建未签名 IPA

需要 macOS 与 Xcode。运行：

```zsh
./Scripts/package_unsigned_ipa.sh
```

输出：

```text
artifacts/VoidCast-unsigned.ipa
```

脚本使用真机 SDK 进行 Release 构建，显式关闭宿主 App 与扩展的代码签名，然后验证最终 IPA 的 `Payload/VoidCast.app/PlugIns/VoidCastSink.appex` 结构、扩展点配置、bundle id 父子关系、iOS 27 用途说明/后台模式/源码 entitlement，以及不存在签名/描述文件。

未签名 IPA 不能直接安装到普通未越狱 iPhone；安装前仍需使用开发者证书、企业证书或用户自己的侧载签名。重签名时，宿主 bundle id 与扩展 bundle id 必须保持父子关系。App 会从嵌入的扩展动态读取实际 bundle id，因此允许重签工具同时重写二者，无需修改 Swift 常量。

> iOS 27 特别要求：最终签名必须把 `com.apple.developer.screen-recording = true` 写入宿主 App 的签名，并且 provisioning profile 必须允许该 entitlement。只给 Mach-O 补普通签名、却丢弃此 entitlement 的侧载工具会导致 ScreenCaptureKit 启动失败。无签名 IPA 本身无法携带有效的签名 entitlement，这是签名阶段必须完成的步骤。

## 真机验收清单

编译和模拟器无法验证系统级广播行为。重签安装后应在目标 iPhone 上完成：

1. iOS 27：从 App 打开系统共享选择器并选择整个屏幕；iOS 16–26：选择“空录屏接收器”并开始广播。
2. 切换到其他 App 运行 1–2 分钟，再从系统指示器或控制中心停止。
3. 确认照片中没有新增录像，App/扩展容器中没有媒体文件，网络代理中没有上传。
4. 单独启动控制中心普通屏幕录制，确认它仍会正常保存到照片，以验证功能边界。

## 隐私审计

核心丢弃逻辑位于 `VoidCast/ScreenCaptureDropController.swift` 与 `VoidCastSink/SampleHandler.swift`。可用以下命令确认工程没有常见媒体落盘、照片库或网络调用：

```zsh
rg -n 'AVAssetWriter|PHPhotoLibrary|URLSession|NWConnection|FileHandle|Data\.write|CMSampleBufferGetImageBuffer' VoidCast VoidCastSink
```

预期结果为空。

## 开源许可证

本项目采用 **GNU 通用公共许可证第 3 版（GPL-3.0-only）** 授权。

有关详细的许可条款，请参阅 [LICENSE](LICENSE) 文件。
