//
//  ViewController.swift
//  apple-health-example
//
//  Created by Park SeoungHee on 2020/06/26.
//  Copyright © 2020 Josh. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    @IBOutlet var stepsLabel: UILabel!
    
    private enum HealthkitSetupError: Error {
      case notAvailableOnDevice
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        stepsLabel.text = "Loading..."
        updateStepCount()
    }
    
    func updateStepCount() {
        authorizeHealthKit { (authorized, error) in
            if let error = error {
                print(error as Any)
            } else if (authorized) {
                let type = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
                
                let date = Date()
                let cal = Calendar(identifier: Calendar.Identifier.gregorian)
                let newDate = cal.startOfDay(for: date)
                let predicate = HKQuery.predicateForSamples(withStart: newDate, end: Date(), options: .strictStartDate)
                var interval = DateComponents()
                interval.day = 1

                let query = HKStatisticsCollectionQuery(quantityType: type!, quantitySamplePredicate: predicate, options: [], anchorDate: newDate as Date, intervalComponents:interval)
                query.initialResultsHandler = { (query, results, error) in
                    var steps = 0.0

                    if results != nil {
                        results?.statistics().forEach({ (statistic) in
                            steps += statistic.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                        })
                    }
                    
                    let query = HKSampleQuery(sampleType: type!, predicate: predicate, limit: 0, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { (query, results, error) in
                         if let error = error {
                             print(error as Any)
                         } else if let results = results, !results.isEmpty {
                            for result in results as! [HKQuantitySample] {
                                if result.device == nil {
                                    steps -= result.quantity.doubleValue(for: HKUnit.count())
                                }
                            }
                            DispatchQueue.main.sync {
                                self.stepsLabel.text = "Step Count : \(Int(steps))"
                            }
                        }
                    }
                    HKHealthStore().execute(query)
                }
                HKHealthStore().execute(query)
            }
        }
    }
    
    func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        if !HKHealthStore.isHealthDataAvailable() {
            completion(false, HealthkitSetupError.notAvailableOnDevice)
        } else {
            let healthKitTypesToRead: Set<HKSampleType> = [
                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
            ]
            HKHealthStore().requestAuthorization(toShare: nil, read: healthKitTypesToRead) { (success, error) in
                completion(success, error)
            }
        }
    }
}



