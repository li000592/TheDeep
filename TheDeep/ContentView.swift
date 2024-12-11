//
//  ContentView.swift
//  TheDeep
//
//  Created by Haorong Li on 2024-12-10.
//

import SwiftUI
import HealthKit
import Charts

struct ContentView: View {
    @State private var selectedTab = "Time Axis" // Tracks the selected tab
    @State private var sleepStages: [SleepStage] = [] // Sleep stage data
    let healthStore = HKHealthStore() // HealthKit instance

    var body: some View {
        VStack {
            // Add NapView
            NapView()
            Text("Sleep Score")
                .font(.title2)
                .bold()

            Text("Today")
                .foregroundColor(.gray)
                .font(.subheadline)

            VStack {
                Text("Sufficient Deep Sleep")
                    .font(.headline)
                    .padding(.top, 10)
                Text("Your sleep was long and deep. Such sleep is essential for strengthening immunity and repairing the body.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical)

            TabView(selection: $selectedTab) {
                // Time Axis Tab
                SleepStageChart(sleepStages: sleepStages)
                    .tag("Time Axis")

                // Stages Tab
                SleepStageList(sleepStages: sleepStages)
                    .tag("Stages")
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 300)

            // Custom Tabs
            HStack {
                Button(action: { selectedTab = "Time Axis" }) {
                    Text("Time Axis")
                        .foregroundColor(selectedTab == "Time Axis" ? .white : .blue)
                        .padding()
                        .background(selectedTab == "Time Axis" ? Color.blue : Color.clear)
                        .cornerRadius(8)
                }
                Spacer()
                Button(action: { selectedTab = "Stages" }) {
                    Text("Stages")
                        .foregroundColor(selectedTab == "Stages" ? .white : .blue)
                        .padding()
                        .background(selectedTab == "Stages" ? Color.blue : Color.clear)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)

//            Button(action: fetchSleepData) {
//                Text("Fetch Sleep Data")
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(8)
//            }
//            .padding(.top)
        }
        .padding()
        .onAppear {
            fetchSleepData() // Fetch sleep data when the view appears
        }
    }

    func fetchSleepData() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now) // Start of today
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictEndDate)

        let query = HKAnchoredObjectQuery(
            type: sleepType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { (query, samples, deleted, newAnchor, error) in
            guard let samples = samples as? [HKCategorySample] else { return }

            DispatchQueue.main.async {
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = .short
                dateFormatter.dateStyle = .none

                // Map HealthKit samples to SleepStage models
                self.sleepStages = samples.map { sample in
                    let type: String
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        type = "REM"
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        type = "Deep"
                    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        type = "Unspecified"
                    default:
                        type = "Light"
                    }
                    return SleepStage(
                        type: type,
                        start: dateFormatter.string(from: sample.startDate),
                        end: dateFormatter.string(from: sample.endDate),
                        duration: Int(sample.endDate.timeIntervalSince(sample.startDate) / 60) // Duration in minutes
                    )
                }
            }
        }

        healthStore.execute(query)
    }
}

// Sleep Stage Data Model
struct SleepStage: Identifiable {
    let id = UUID()
    let type: String
    let start: String
    let end: String
    let duration: Int // in minutes
}

// Sleep Stage Chart View
struct SleepStageChart: View {
    var sleepStages: [SleepStage]

    var body: some View {
        Chart {
            ForEach(sleepStages) { stage in
                BarMark(
                    x: .value("Stage", stage.type),
                    y: .value("Duration", stage.duration)
                )
                .foregroundStyle(by: .value("Stage Type", stage.type))
            }
        }
        .chartLegend(.hidden)
        .padding()
    }
}

// Sleep Stage List View
struct SleepStageList: View {
    var sleepStages: [SleepStage]

    var body: some View {
        List(sleepStages) { stage in
            VStack(alignment: .leading) {
                Text("\(stage.type) Sleep")
                    .font(.headline)
                Text("\(stage.start) - \(stage.end)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}
