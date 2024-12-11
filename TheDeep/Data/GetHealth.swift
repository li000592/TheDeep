//
//  GetHealth.swift
//  TheDeep
//
//  Created by Haorong Li on 2024-12-10.
//

import HealthKit

let healthStore = HKHealthStore()

func requestHealthKitAuthorization() {
    let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    let typesToRead: Set = [sleepType]

    healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
        if success {
            print("HealthKit Authorization Success!")
        } else if let error = error {
            print("Error requesting HealthKit Authorization: \(error.localizedDescription)")
        }
    }
}

func fetchSleepData() {
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
    
    let query = HKAnchoredObjectQuery(
        type: sleepType,
        predicate: nil,
        anchor: nil,
        limit: HKObjectQueryNoLimit
    ) { (query, samples, deleted, newAnchor, error) in
        guard let samples = samples as? [HKCategorySample] else { return }
        
        for sample in samples {
            let start = sample.startDate
            let end = sample.endDate
            let value = sample.value  // 使用 value 判断深睡或浅睡
            print("Sleep Data: \(start) - \(end), value: \(value)")
        }
    }
    
    healthStore.execute(query)
}
