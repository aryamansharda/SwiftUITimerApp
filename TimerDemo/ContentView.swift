//
//  ContentView.swift
//  TimerDemo
//
//  Created by Aryaman Sharda on 2/20/23.
//

import SwiftUI

final class TimerViewModel: ObservableObject {
    // Represents the different states the timer can be in
    enum TimerState {
        case active
        case paused
        case resumed
        case cancelled
    }


    // MARK: Private Properties
    private var timer = Timer()
    private var totalTimeForCurrentSelection: Int {
        (selectedHoursAmount * 3600) + (selectedMinutesAmount * 60) + selectedSecondsAmount
    }

    // MARK: Public Properties
    @Published var selectedHoursAmount = 1
    @Published var selectedMinutesAmount = 5
    @Published var selectedSecondsAmount = 10
    @Published var state: TimerState = .cancelled {
        didSet {
            switch state {
            case .cancelled:
                timer.invalidate()
                secondsToCompletion = 0
                progress = 0

            case .active:
                startTimer()

                secondsToCompletion = totalTimeForCurrentSelection
                progress = 1.0

                updateCompletionDate()

            case .paused:
                timer.invalidate()

            case .resumed:
                startTimer()
                updateCompletionDate()
            }
        }
    }

    // Powers the ProgressView
    @Published var secondsToCompletion = 0
    @Published var progress: Float = 0.0
    @Published var completionDate = Date.now

    let hoursRange = 0...23
    let minutesRange = 0...59
    let secondsRange = 0...59

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            guard let self else { return }

            self.secondsToCompletion -= 1
            self.progress = Float(self.secondsToCompletion) / Float(self.totalTimeForCurrentSelection)

            // We can't do <= here because we need the time from T-1 seconds to
            // T-0 seconds to animate through first
            if self.secondsToCompletion < 0 {
                self.state = .cancelled
            }
        })
    }

    private func updateCompletionDate() {
        completionDate = Date.now.addingTimeInterval(Double(secondsToCompletion))
    }
}

struct TimerView: View {
    @StateObject private var model = TimerViewModel()

var timerControls: some View {
    HStack {
        Button("Cancel") {
            model.state = .cancelled
        }
        .buttonStyle(CancelButtonStyle())

        Spacer()

        switch model.state {
        case .cancelled:
            Button("Start") {
                model.state = .active
            }
            .buttonStyle(StartButtonStyle())
        case .paused:
            Button("Resume") {
                model.state = .resumed
            }
            .buttonStyle(PauseButtonStyle())
        case .active, .resumed:
            Button("Pause") {
                model.state = .paused
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
        if model.state == .cancelled {
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

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
    }
}
