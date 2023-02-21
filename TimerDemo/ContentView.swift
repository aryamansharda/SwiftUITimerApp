//
//  ContentView.swift
//  TimerDemo
//
//  Created by Aryaman Sharda on 2/20/23.
//

import SwiftUI

class TimerViewModel: ObservableObject {
    enum TimerState {
        case running
        case paused
        case notStarted
    }

    // Total time in seconds
    private var totalTimeForCurrentSelection: Int {
        (selectedHoursAmount * 3600) + (selectedMinutesAmount * 60) + selectedSecondsAmount
    }

    // MARK: Public Properties
    @Published var selectedHoursAmount = 0
    @Published var selectedMinutesAmount = 0
    @Published var selectedSecondsAmount = 10
    @Published var state: TimerState = .notStarted

    // Powers the ProgressView
    @Published var secondsToCompletion = 0
    @Published var progress: Float = 0.0

    var completionDate = Date.now
    var timer = Timer()

    let hoursRange = 0...23
    let minutesRange = 0...59
    let secondsRange = 0...59

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            guard let self else { return }

            self.secondsToCompletion -= 1
            self.progress = Float(self.secondsToCompletion) / Float(self.totalTimeForCurrentSelection)

            // We can't do <= here because we need the time from T-1 seconds to
            // T-0 seconds to animate through first
            if self.secondsToCompletion < 0 {
                self.cancelTimer()
            }
        })

        // Checks tha the timer isn't currently paused
        guard secondsToCompletion == 0 else { return }

        secondsToCompletion = totalTimeForCurrentSelection
        progress = 1.0
        completionDate = Date.now.addingTimeInterval(Double(secondsToCompletion))
        state = .running
    }

    func pauseTimer() {
        timer.invalidate()
        state = .paused
    }

    func resumeTimer() {
        startTimer()
        state = .running
    }

    func cancelTimer() {
        timer.invalidate()

        secondsToCompletion = 0
        progress = 0
        state = .notStarted
    }
}

struct TimerView: View {
    @StateObject private var model = TimerViewModel()

    var timerControls: some View {
        HStack {
            Button("Cancel") {
                model.cancelTimer()
            }
            .buttonStyle(CancelButtonStyle())

            Spacer()

            switch model.state {
            case .notStarted:
                Button("Start") {
                    model.startTimer()
                }
                .buttonStyle(StartButtonStyle())
            case .paused:
                Button("Resume") {
                    model.resumeTimer()
                }
                .buttonStyle(PauseButtonStyle())
            case .running:
                Button("Pause") {
                    model.pauseTimer()
                }
                .buttonStyle(PauseButtonStyle())
            }
        }
        .padding(.horizontal, 32)
    }

    var timePickerControl: some View {
        HStack() {
            TimePickerView(title: "hours", range: model.hoursRange, binding: $model.selectedHoursAmount)
            TimePickerView(title: "min", range: model.minutesRange, binding: $model.selectedMinutesAmount)
            TimePickerView(title: "sec", range: model.secondsRange, binding: $model.selectedSecondsAmount)
        }
        .frame(width: 360, height: 255)
        .padding(.all, 32)
    }

    var progressView: some View {
        ZStack {
            withAnimation {
                CircularProgressView(progress: $model.progress)
            }

            VStack {
                Text(model.secondsToCompletion.asTimeString)
                    .font(.largeTitle)
                HStack {
                    Image(systemName: "bell.fill")
                    Text(model.completionDate, format: .dateTime.hour().minute())
                }
            }
        }
        .frame(width: 360, height: 255)
        .padding(.all, 32)
    }

    var body: some View {
        VStack {
            if model.state == .notStarted {
                timePickerControl
            } else {
                progressView
            }

            timerControls

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .foregroundColor(.white)
    }
}

struct CircularProgressView: View {
    @Binding var progress: Float

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 8.0)
                .opacity(0.3)
                .foregroundColor(Color("TimerButtonCancel"))
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 8.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color("TimerButtonPause"))
                // Ensures the animation starts from 12 o'clock
                .rotationEffect(Angle(degrees: 270))
        }
        // The progress animation will animate over 1 second which
        // allows for a continuous smooth update of the ProgressView
        .animation(.linear(duration: 1.0), value: progress)
    }
}

extension Int {
    var asTimeString: String {
        let hour = self / 3600
        let minute = self / 60 % 60
        let second = self % 60

        return String(format: "%02i:%02i:%02i", hour, minute, second)
    }
}

struct TimePickerView: View {
    // This is used to tighten up the spacing between the Picker and its
    // respective label
    //
    // This allows us to avoid having to use custom
    private let pickerViewTitlePadding: CGFloat = 4.0

    let title: String
    let range: ClosedRange<Int>
    let binding: Binding<Int>

    var body: some View {
        HStack(spacing: -pickerViewTitlePadding) {
            Picker(title, selection: binding) {
                ForEach(range, id: \.self) { timeIncrement in
                    HStack {
                        // Forces the text in the Picker to be right-aligned
                        Spacer()
                        Text("\(timeIncrement)")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .pickerStyle(InlinePickerStyle())
            .labelsHidden()

            Text(title)
                .fontWeight(.bold)
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
    }
}
