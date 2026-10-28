//
//  ParentalGateView.swift
//  Shinkeisuijaku
//
//  保護者の確認のダイアログ（Discussion #4 の Q5・仕様書の「ロックされた難易度を押したとき」）。
//  2 桁＋1 桁の足し算を出し、テンキー（0〜9・消す・決定）で答えを入れる。間違えたら別の問題に変える。
//  子どもに読まれにくいよう、文は漢字を含む大人向けにする（CLAUDE.md の方針 4）。
//  引き継ぎブックに保護者の確認の見本は無いので、ダイアログ（7 ページ）と通常・主なボタンの部品だけで組む。
//  通ったとき・やめたときの行き先は呼び出し側（おうちの方への画面・購入の流れ）が決める。
//

import SwiftUI

/// 保護者の確認のダイアログ
struct ParentalGateView: View {
    /// 合っていたとき
    let onPassed: () -> Void
    /// やめたとき（呼び出し元に戻る）
    let onCancel: () -> Void

    @State private var gate: ParentalGate
    /// 間違えたときに次の問題を選ぶ乱数
    @State private var generator: any RandomNumberGenerator

    /// テンキーの並び（電話と同じく 1 から上に並べ、最後の段は 消す・0・決定）
    private static let digitRows = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    /// - Parameters:
    ///   - generator: 問題を選ぶ乱数（撮影モード・テストでは種を固定したものを渡す）
    init(
        generator: any RandomNumberGenerator = SystemRandomNumberGenerator(),
        onPassed: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {}
    ) {
        var generator = generator
        _gate = State(initialValue: ParentalGate(using: &generator))
        _generator = State(initialValue: generator)
        self.onPassed = onPassed
        self.onCancel = onCancel
    }

    var body: some View {
        DialogContainer {
            Text("保護者の方へ")
                .appFont(Typography.dialogTitle)
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            Text("購入や設定に進む前に確認します。次の計算の答えを入力してください。")
                .appFont(Typography.body)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            questionView
            answerView
            // 行の高さはいつも取り、出さないときは見えなくするだけにする（出入りのたびに下のテンキーが上下に動かないように）
            Text("答えが違います。別の問題に変わりました。")
                .appFont(Typography.noteStrong)
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(gate.showsWrongNotice ? 1 : 0)
                .accessibilityHidden(!gate.showsWrongNotice)
                .accessibilityIdentifier("parentalGate.wrongNotice")
            keypad
            Button(action: onCancel) {
                Text("やめる")
                    .appFont(Typography.button)
                    .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
            }
            .buttonStyle(SurfaceButtonStyle())
            .accessibilityIdentifier("parentalGate.cancel")
        }
        .accessibilityIdentifier("parentalGate.dialog")
    }

    /// 問題（「12 ＋ 7 ＝ ？」）
    private var questionView: some View {
        Text("\(gate.question.augend) ＋ \(gate.question.addend) ＝ ？")
            .appFont(Typography.pairCountNumber)
            .foregroundStyle(Palette.text)
            .accessibilityLabel("問題 \(gate.question.augend) 足す \(gate.question.addend)")
            .accessibilityIdentifier("parentalGate.question")
    }

    /// 入れている答え。何も入れていないときも高さを保つ（入れるたびに下のテンキーが動かないように）
    private var answerView: some View {
        Text(gate.input.isEmpty ? " " : gate.input.text)
            .appFont(Typography.pairCountNumber)
            .foregroundStyle(Palette.accent)
            .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
            .background(Palette.background, in: RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius)
                    .stroke(Palette.border, lineWidth: Metrics.borderWidth)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("答え")
            .accessibilityValue(gate.input.isEmpty ? String(localized: "未入力") : gate.input.text)
            .accessibilityIdentifier("parentalGate.answer")
    }

    /// テンキー（0〜9・消す・決定）。ボタンの高さは通常のボタンと同じ 52（44 以上）
    private var keypad: some View {
        Grid(horizontalSpacing: Metrics.cardSpacing, verticalSpacing: Metrics.cardSpacing) {
            ForEach(Self.digitRows, id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { digit in
                        digitKey(digit)
                    }
                }
            }
            GridRow {
                Button {
                    gate.delete()
                } label: {
                    Text("消す")
                        .appFont(Typography.button)
                        .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
                }
                .buttonStyle(SurfaceButtonStyle())
                .accessibilityLabel("1 文字消す")
                .accessibilityIdentifier("parentalGate.delete")
                digitKey(0)
                Button("決定", action: submit)
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("parentalGate.submit")
            }
        }
    }

    private func digitKey(_ digit: Int) -> some View {
        Button {
            gate.enter(digit)
        } label: {
            Text(verbatim: String(digit))
                .appFont(Typography.difficultyButton)
                .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
        }
        .buttonStyle(SurfaceButtonStyle())
        .accessibilityIdentifier("parentalGate.key.\(digit)")
    }

    private func submit() {
        switch gate.submit(using: &generator) {
        case .passed:
            onPassed()
        case .wrong:
            AccessibilityNotification.Announcement(String(localized: "答えが違います。別の問題に変わりました。")).post()
        case .empty:
            break
        }
    }
}

/// 撮影モードの保護者の確認のダイアログ。種を固定した問題を、背景の色の上に出す（呼び出し元の画面はタスク 18・19 でつなぐ）
struct ParentalGateScreenshotDemoView: View {
    var body: some View {
        ZStack {
            Palette.background
                .ignoresSafeArea()
            ParentalGateView(generator: SeededRandomNumberGenerator(seed: 1))
        }
    }
}

#Preview {
    ParentalGateScreenshotDemoView()
}
