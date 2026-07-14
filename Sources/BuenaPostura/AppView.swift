import BuenaPosturaCore
import CoreMotion
import SwiftUI

struct AppView: View {
    @ObservedObject var monitor: PostureMonitor

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    postureHero
                    calibrationPanel
                    primarySettings

                    if monitor.showsAdvancedSettings {
                        advancedSettings
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(16)
            }
            Divider()
            bottomBar
        }
        .frame(width: 388, height: 620)
        .background {
            ZStack {
                Color.black
                Rectangle().fill(.ultraThinMaterial)
                Color.black.opacity(0.42)
            }
        }
        .preferredColorScheme(.dark)
        .tint(LeanStyle.signal)
        .animation(.smooth(duration: 0.22), value: monitor.state)
        .animation(.smooth(duration: 0.22), value: monitor.score)
        .animation(.smooth(duration: 0.22), value: monitor.showsAdvancedSettings)
    }

    private var titleBar: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(LeanStyle.signal)
                .frame(width: 8, height: 8)
                .shadow(color: LeanStyle.signal.opacity(0.7), radius: 5)

            Text("BUENAPOSTURA")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.8)

            Spacer()

            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text("LOCAL / \(context.date.formatted(date: .omitted, time: .standard))")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(LeanStyle.muted)
            }

            statusPill
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.black.opacity(0.34))
    }

    private var postureHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                scoreRing

                VStack(alignment: .leading, spacing: 7) {
                    Text(heroTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .lineLimit(1)

                    Text(heroMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        capabilityBadge(title: connectionTitle, icon: connectionIcon, tint: connectionTint)
                        capabilityBadge(title: permissionTitle, icon: permissionIcon, tint: permissionTint)
                    }
                }

                Spacer(minLength: 0)
            }

            scoreMeter
            angleReadout
        }
        .panelStyle()
    }

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.16), lineWidth: 9)
            Circle()
                .trim(from: 0, to: max(0.02, monitor.score))
                .stroke(
                    stateColor.gradient,
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int(monitor.score * 100))")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("%")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 88, height: 88)
        .accessibilityLabel("Riesgo postural \(Int(monitor.score * 100)) por ciento")
    }

    private var scoreMeter: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Riesgo")
                Spacer()
                Text(riskLabel)
                    .foregroundStyle(stateColor)
            }
            .font(.caption.weight(.medium))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.secondary.opacity(0.16))
                    Capsule()
                        .fill(scoreGradient)
                        .frame(width: max(8, proxy.size.width * monitor.score))
                }
            }
            .frame(height: 8)
        }
    }

    private var angleReadout: some View {
        HStack(spacing: 8) {
            metricChip(title: "Pitch", value: degrees(monitor.currentSample.pitch))
            metricChip(title: "Roll", value: degrees(monitor.currentSample.roll))
            metricChip(title: "Yaw", value: degrees(monitor.currentSample.yaw))
        }
    }

    private var calibrationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("02 / CALIBRACIÓN")
                Spacer()
                Text(calibrationProgress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                calibrationStep(
                    title: "Postura buena",
                    subtitle: "Siéntate derecho",
                    icon: "checkmark.circle.fill",
                    isDone: monitor.hasGoodPosture,
                    actionTitle: monitor.hasGoodPosture ? "Actualizar" : "Guardar"
                ) {
                    monitor.captureGoodPosture()
                }

                calibrationStep(
                    title: "Postura mala",
                    subtitle: "Inclínate un poco",
                    icon: "exclamationmark.triangle.fill",
                    isDone: monitor.hasBadPosture,
                    actionTitle: monitor.hasBadPosture ? "Actualizar" : "Guardar"
                ) {
                    monitor.captureBadPosture()
                }
            }
        }
        .panelStyle()
    }

    private var primarySettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("03 / AJUSTES")
                Spacer()
                Button {
                    monitor.showsAdvancedSettings.toggle()
                } label: {
                    Label(monitor.showsAdvancedSettings ? "Menos" : "Más", systemImage: monitor.showsAdvancedSettings ? "chevron.up" : "slider.horizontal.3")
                        .labelStyle(.titleAndIcon)
                }
                .controlSize(.small)
            }

            slider(
                title: "Sensibilidad",
                value: $monitor.settings.sensitivity,
                range: 0.2...1,
                step: 0.01,
                display: "\(Int(monitor.settings.sensitivity * 100))%"
            )

            slider(
                title: "Avisar después",
                value: $monitor.settings.alertAfterSeconds,
                range: 5...120,
                step: 5,
                display: "\(Int(monitor.settings.alertAfterSeconds))s"
            )
        }
        .panelStyle()
    }

    private var advancedSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("04 / AVANZADO")

            slider(
                title: "Cooldown",
                value: $monitor.settings.cooldownSeconds,
                range: 60...1800,
                step: 60,
                display: "\(Int(monitor.settings.cooldownSeconds / 60))m"
            )
            slider(
                title: "Tolerancia al mirar hacia abajo",
                value: $monitor.settings.lookingDownToleranceDegrees,
                range: 0...45,
                step: 1,
                display: "\(Int(monitor.settings.lookingDownToleranceDegrees))°"
            )
            slider(
                title: "Suavizado",
                value: $monitor.settings.smoothing,
                range: 0.05...0.45,
                step: 0.01,
                display: "\(Int(monitor.settings.smoothing * 100))%"
            )
        }
        .panelStyle()
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            Button {
                monitor.toggle()
            } label: {
                Label(monitor.isRunning ? "Pausar" : "Iniciar", systemImage: monitor.isRunning ? "pause.fill" : "play.fill")
            }
            .keyboardShortcut(.space, modifiers: [])
            .buttonStyle(.borderedProminent)
            .tint(monitor.isRunning ? LeanStyle.line : LeanStyle.signal)
            .foregroundStyle(monitor.isRunning ? Color.white : Color.black)
            .help("Espacio")

            Button {
                monitor.snooze()
            } label: {
                Label("10 min", systemImage: "clock")
            }
            .help("Pausar recordatorios por 10 minutos")

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .help("Salir")
        }
        .controlSize(.regular)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.34))
    }

    private var statusPill: some View {
        Label(monitor.state.rawValue, systemImage: stateIcon)
            .font(.caption.weight(.medium))
            .lineLimit(1)
            .foregroundStyle(stateColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(stateColor.opacity(0.12), in: Capsule())
    }

    private func calibrationStep(
        title: String,
        subtitle: String,
        icon: String,
        isDone: Bool,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .foregroundStyle(isDone ? .green : .secondary)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button(actionTitle, action: action)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!monitor.hasCurrentSample)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func slider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        display: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                Spacer()
                Text(display)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            Slider(value: value, in: range, step: step)
        }
    }

    private func capabilityBadge(title: String, icon: String, tint: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private func metricChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.medium))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.1)
            .foregroundStyle(LeanStyle.muted)
    }

    private func degrees(_ radians: Double) -> String {
        String(format: "%.1f°", radians * 180 / .pi)
    }

    private var heroTitle: String {
        switch monitor.state {
        case .good: "Vas bien"
        case .drifting: "Corrige suavemente"
        case .slouching: "Momento de enderezarte"
        case .paused: "Pausado"
        case .monitoring: "Listo para calibrar"
        case .waitingForHeadphones: "Conecta tus AirPods"
        case .unsupported: "No compatible"
        case .unauthorized: "Falta permiso"
        }
    }

    private var heroMessage: String {
        switch monitor.state {
        case .good:
            "Tu cabeza está cerca de la postura buena calibrada."
        case .drifting:
            "La lectura se está alejando. Ajusta tu postura antes de que moleste."
        case .slouching:
            "Sube el pecho, relaja los hombros y mira al frente."
        case .paused:
            "No se enviarán avisos mientras dure la pausa."
        case .monitoring:
            "Guarda una postura buena y una mala para activar el score."
        case .waitingForHeadphones:
            "Usa AirPods compatibles con head tracking."
        case .unsupported:
            "Este equipo o audio no entrega motion data compatible."
        case .unauthorized:
            "Habilita Movimiento para BuenaPostura en Configuración del Sistema."
        }
    }

    private var riskLabel: String {
        if monitor.score >= 0.72 { return "alto" }
        if monitor.score >= 0.45 { return "medio" }
        return "bajo"
    }

    private var calibrationProgress: String {
        switch (monitor.hasGoodPosture, monitor.hasBadPosture) {
        case (true, true): "2 de 2"
        case (true, false), (false, true): "1 de 2"
        case (false, false): "0 de 2"
        }
    }

    private var connectionTitle: String {
        monitor.isConnected || monitor.canMonitor ? "AirPods" : "Sin AirPods"
    }

    private var connectionIcon: String {
        monitor.isConnected || monitor.canMonitor ? "airpodspro" : "airpodspro.chargingcase.wireless"
    }

    private var connectionTint: Color {
        monitor.isConnected || monitor.canMonitor ? .green : .secondary
    }

    private var permissionTitle: String {
        if monitor.motionPermission == .denied || monitor.motionPermission == .restricted {
            return "Sin permiso"
        }
        return "Local"
    }

    private var permissionIcon: String {
        if monitor.motionPermission == .denied || monitor.motionPermission == .restricted {
            return "lock.fill"
        }
        return "lock.open.fill"
    }

    private var permissionTint: Color {
        if monitor.motionPermission == .denied || monitor.motionPermission == .restricted {
            return .red
        }
        return .blue
    }

    private var scoreGradient: Color {
        LeanStyle.signal
    }

    private var stateIcon: String {
        switch monitor.state {
        case .good: "checkmark.circle.fill"
        case .drifting: "arrow.down.forward.circle.fill"
        case .slouching: "exclamationmark.triangle.fill"
        case .unsupported: "xmark.octagon.fill"
        case .paused: "pause.circle.fill"
        case .monitoring: "waveform.path.ecg"
        case .waitingForHeadphones: "airpodspro"
        case .unauthorized: "lock.circle.fill"
        }
    }

    private var stateColor: Color {
        switch monitor.state {
        case .good: LeanStyle.signal
        case .drifting: .white
        case .slouching: .white
        case .unsupported: LeanStyle.muted
        case .unauthorized: LeanStyle.muted
        case .paused: LeanStyle.muted
        case .monitoring: LeanStyle.signal
        case .waitingForHeadphones: LeanStyle.muted
        }
    }
}

private enum LeanStyle {
    static let signal = Color(red: 53 / 255, green: 209 / 255, blue: 90 / 255)
    static let muted = Color(white: 176 / 255)
    static let line = Color(white: 36 / 255)
}

private extension View {
    func panelStyle() -> some View {
        self
            .padding(12)
            .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(LeanStyle.line, lineWidth: 0.75)
            }
    }
}
