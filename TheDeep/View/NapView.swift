//
//  NapView.swift
//  TheDeep
//
//  Created by Haorong Li on 2024-12-10.
//

import SwiftUI
import HealthKit
import AVFoundation

struct NapView: View {
    @State private var isNapActive = false
    @State private var napMaxDuration: TimeInterval = 1800 // Default: 30 minutes (in seconds)
    @State private var alarmAfterREM: TimeInterval = 600 // Default: 10 minutes after REM (in seconds)
    @State private var remDetectedAt: Date? = nil // Tracks when REM is detected
    @State private var napStartTime: Date? = nil // Tracks when the nap starts
    @State private var timer: Timer? = nil
    @State private var showSettingsDialog = false // Controls the settings dialog
    @State private var remInput = 10 // User input for alarm after REM (in minutes)
    @State private var maxInput = 30 // User input for max nap duration (in minutes)
    let healthStore = HKHealthStore() // HealthKit instance

    var body: some View {
        VStack {
            Text("Take a Nap")
                .font(.title2)
                .bold()
                .padding()

            if !isNapActive {
                Button("Start Nap") {
                    showSettingsDialog = true // Show the settings dialog
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button("Stop Nap") {
                    stopNap()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showSettingsDialog) {
            // Settings dialog for setting nap times
            VStack {
                Text("Set Nap Settings")
                    .font(.headline)
                    .padding()

                HStack {
                    Text("Alarm After REM:")
                    Spacer()
                    TextField("Minutes", value: $remInput, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                }
                .padding()

                HStack {
                    Text("Max Nap Duration:")
                    Spacer()
                    TextField("Minutes", value: $maxInput, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                }
                .padding()

                HStack {
                    Button("Cancel") {
                        showSettingsDialog = false
                    }
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Spacer()

                    Button("Start Nap") {
                        alarmAfterREM = TimeInterval(remInput * 60) // Convert minutes to seconds
                        napMaxDuration = TimeInterval(maxInput * 60) // Convert minutes to seconds
                        startNap()
                        showSettingsDialog = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
            .padding()
        }
        .onDisappear {
            stopNap() // Ensure nap logic is cleaned up when the view disappears
        }
    }

    // Start the nap logic
    func startNap() {
        isNapActive = true
        napStartTime = Date()
        remDetectedAt = nil // Reset REM tracking
        monitorSleepData() // Start monitoring sleep stages
        
        // Set a timer to wake the user at the max duration
        timer = Timer.scheduledTimer(withTimeInterval: napMaxDuration, repeats: false) { _ in
            wakeUp(reason: "Max nap duration reached")
        }
    }

    // Stop the nap logic
    func stopNap() {
        isNapActive = false
        timer?.invalidate() // Stop any active timers
        timer = nil
    }

    // Wake up the user
    func wakeUp(reason: String) {
        stopNap()
        playAlarm()
        print("Alarm Triggered: \(reason)")
    }

    // Monitor sleep data
    func monitorSleepData() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let query = HKAnchoredObjectQuery(
            type: sleepType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { query, samples, deletedObjects, newAnchor, error in
            guard let samples = samples as? [HKCategorySample], self.isNapActive else { return }

            for sample in samples {
                if sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    handleREMDetected()
                    break
                }
            }
        }

        query.updateHandler = { query, samples, deletedObjects, newAnchor, error in
            guard let samples = samples as? [HKCategorySample], self.isNapActive else { return }

            for sample in samples {
                if sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    handleREMDetected()
                    break
                }
            }
        }

        healthStore.execute(query)
    }

    // Handle REM detection
    func handleREMDetected() {
        guard remDetectedAt == nil else { return } // Only handle the first REM detection
        remDetectedAt = Date()

        // Schedule an alarm after the "alarmAfterREM" duration
        timer?.invalidate() // Cancel any previous timers
        timer = Timer.scheduledTimer(withTimeInterval: alarmAfterREM, repeats: false) { _ in
            wakeUp(reason: "Alarm after REM sleep")
        }
    }

    // Play an alarm sound
    func playAlarm() {
        guard let soundURL = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else { return }
        var audioPlayer: AVAudioPlayer?
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Failed to play alarm sound: \(error)")
        }
    }
}
