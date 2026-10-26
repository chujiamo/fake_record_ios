import SwiftUI

struct ContentView: View {
    private let background = Color(red: 0.035, green: 0.045, blue: 0.075)
    private let panel = Color.white.opacity(0.075)
    private let cyan = Color(red: 0.25, green: 0.93, blue: 0.86)
    private let amber = Color(red: 1.00, green: 0.72, blue: 0.28)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            Circle()
                .fill(cyan.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 145, y: -310)
                .accessibilityHidden(true)

            ScrollView {
                VStack(spacing: 22) {
                    header
                    hero
                    launchPanel
                    privacyPanel
                    boundaryWarning
                    stopPanel
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            Label("VOIDCAST", systemImage: "circle.dotted.circle")
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(cyan)

            Spacer()

            Text("LOCAL DROP SINK")
                .font(.system(.caption2, design: .monospaced, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.06), in: Capsule())
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(cyan.opacity(0.15), lineWidth: 18)
                    .frame(width: 154, height: 154)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [cyan.opacity(0.2), cyan, cyan.opacity(0.2)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [3, 9])
                    )
                    .frame(width: 178, height: 178)

                Image(systemName: "waveform.badge.minus")
                    .font(.system(size: 54, weight: .medium))
                    .foregroundStyle(cyan)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityHidden(true)

            Text("丢弃型屏幕广播")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)

            Text("系统把屏幕与音频采样交给本机丢弃处理器后立即释放；不保存、不上传、不生成录像文件。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }

    private var launchPanel: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 13) {
                stepNumber("1")
                VStack(alignment: .leading, spacing: 5) {
                    Text("打开系统屏幕捕获面板")
                        .font(.headline)
                    Text(launchInstruction)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(amber)
                    .accessibilityHidden(true)
                Text("仅本软件的丢弃流程不生成录像；控制中心普通“屏幕录制”仍会保存到照片。")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(amber.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .accessibilityElement(children: .combine)

            systemLaunchControl

            HStack(alignment: .top, spacing: 13) {
                stepNumber("2")
                VStack(alignment: .leading, spacing: 5) {
                    Text("切换到需要使用的 App")
                        .font(.headline)
                    Text("广播运行期间，系统会显示屏幕捕获或共享指示器。状态请始终以系统界面为准。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
        .cardStyle(background: panel)
    }

    private var privacyPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("处理方式", systemImage: "checkmark.shield.fill")
                .font(.headline)
                .foregroundStyle(cyan)

            privacyRow(icon: "internaldrive", title: "不落盘", detail: "本软件不把捕获样本写入照片、文件或缓存")
            privacyRow(icon: "network.slash", title: "不上传", detail: "本软件不通过网络发送捕获样本")
            privacyRow(icon: "mic.slash", title: "音频同样丢弃", detail: "系统音频与任何到达的麦克风采样均不保留")
        }
        .cardStyle(background: panel)
    }

    private var boundaryWarning: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(amber)
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("重要边界")
                    .font(.headline)
                    .foregroundStyle(amber)
                Text("本软件不会拦截或删除控制中心的普通“屏幕录制”。只有明确启动本页的系统共享流程，或在旧版 iOS 选择“空录屏接收器”，捕获样本才会被丢弃；普通录屏仍会保存到照片。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(amber.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(amber.opacity(0.32), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var stopPanel: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "stop.circle")
                .foregroundStyle(cyan)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text("停止广播")
                    .font(.headline)
                Text(stopInstruction)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .cardStyle(background: panel)
        .accessibilityElement(children: .combine)
    }

    private var footer: some View {
        Text("iOS 会在内存中创建瞬时采样；“丢弃”表示处理器收到后不保留、不落盘、不上传。")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
    }

    @ViewBuilder
    private var systemLaunchControl: some View {
        if #available(iOS 27.0, *) {
            ScreenCaptureLaunchControl()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(cyan.opacity(0.13))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(cyan.opacity(0.42), lineWidth: 1)
                    }

                HStack(spacing: 15) {
                    BroadcastPickerButton()
                        .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("打开系统广播选择器")
                            .font(.headline)
                        Text("点按左侧圆形系统按钮")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
            }
            .frame(minHeight: 92)
        }
    }

    private var launchInstruction: String {
        if #available(iOS 27.0, *) {
            return "在系统面板中选择整个屏幕并确认；本软件随后接收并丢弃采样。"
        }
        return "在系统面板中选择“空录屏接收器”，再开始广播。"
    }

    private var stopInstruction: String {
        if #available(iOS 27.0, *) {
            return "可用本页的停止按钮、系统顶部捕获指示器或控制中心结束捕获。停止后本软件没有录像可供恢复。"
        }
        return "点按系统顶部的捕获指示器，或打开控制中心停止广播。停止后本软件没有录像可供恢复。"
    }

    private func stepNumber(_ number: String) -> some View {
        Text(number)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(background)
            .frame(width: 26, height: 26)
            .background(cyan, in: Circle())
            .accessibilityLabel("步骤 \(number)")
    }

    private func privacyRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 26)
                .foregroundStyle(cyan)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    func cardStyle(background: Color) -> some View {
        self
            .padding(18)
            .background(background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.09), lineWidth: 1)
            }
    }
}

#Preview {
    ContentView()
}
