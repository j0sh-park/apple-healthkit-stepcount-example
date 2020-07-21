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
        // 헬스 권한 체크
        authorizeHealthKit { (authorized, error) in
            if let error = error {
                print(error as Any)
            } else if (authorized) {
                let type = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
                
                let date = Date() // 현재 시간
                let cal = Calendar(identifier: Calendar.Identifier.gregorian)
                let newDate = cal.startOfDay(for: date) // 오늘자 시작 시간 (00:00)
                // 오늘자 시작 시간부터 현재시간까지 스탭 카운트 가져오기 쿼리
                let predicate = HKQuery.predicateForSamples(withStart: newDate, end: Date(), options: .strictStartDate)
                // 하루단위로 묶어서 가져오기
                var interval = DateComponents()
                interval.day = 1
                
                // 쿼리 실행
                let query = HKStatisticsCollectionQuery(quantityType: type!, quantitySamplePredicate: predicate, options: [], anchorDate: newDate as Date, intervalComponents:interval)
                query.initialResultsHandler = { (query, results, error) in
                    // 쿼리 결과
                    var steps = 0.0

                    if results != nil {
                        // 쿼리 결과 돌면서 steps에 더하기
                        results?.statistics().forEach({ (statistic) in
                            steps += statistic.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                        })
                    }
                    
                    // 오늘자 시작 시간부터 현재시간까지 스탭 카운트 가져오기 (묶지않고 raw 데이터 그대로)
                    let query = HKSampleQuery(sampleType: type!, predicate: predicate, limit: 0, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { (query, results, error) in
                         if let error = error {
                             print(error as Any)
                         } else if let results = results, !results.isEmpty {
                            // 결과 반복문
                            for result in results as! [HKQuantitySample] {
                                // 결과가 기기에서 들어온게 아니라면 (유저가 직접 입력)
                                if result.device == nil {
                                    // 아까 더한 steps에서 빼기
                                    steps -= result.quantity.doubleValue(for: HKUnit.count())
                                }
                            }
                            // 결과 steps 표시
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



