//
//  MatchSummary.swift
//  cokcok
//
//  Created by 최지웅 on 11/7/23.
//

import Foundation
import HealthKit

enum Player {
    case me, opponent
}

struct MatchSummary: Identifiable, Codable {
    var id: Int
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval
    var totalDistance: Double
    var totalEnergyBurned: Double
    var averageHeartRate: Double
    
    var myScore: Int
    var opponentScore: Int
    var history: String
    
    var backDrive: Int = 0
    var backHairpin: Int = 0
    var backHigh: Int = 0
    var backUnder: Int = 0
    var foreDrive: Int = 0
    var foreDrop: Int = 0
    var foreHairpin: Int = 0
    var foreHigh: Int = 0
    var foreSmash: Int = 0
    var foreUnder: Int = 0
    var longService: Int = 0
    var shortService: Int = 0
    
    // 새로운 점수 변동 기록 추가
    mutating func addScore(player: Player, timestamp:Date = Date()) {
        switch(player){
        case .me:
            history.append("m")
            myScore += 1
        case .opponent:
            history.append("o")
            opponentScore += 1
        }
    }
    // 히스토리에서 맨 뒤의 기록 제거
    mutating func removeScore(player: Player) {
        switch player {
        case .me:
            if let lastIndex = history.lastIndex(of: "m") {
                history.remove(at: lastIndex)
                myScore -= 1
            }
        case .opponent:
            if let lastIndex = history.lastIndex(of: "o") {
                history.remove(at: lastIndex)
                opponentScore -= 1
            }
        }
    }
    // 히스토리에서 맨 뒤의 기록 제거하고 점수를 0으로 초기화
    mutating func resetScore(player: Player) {
        switch player {
        case .me:
            myScore = 0
            history = String(repeating:"o", count: opponentScore)
        case .opponent:
            opponentScore = 0
            history = String(repeating: "m", count: myScore)
        }
    }
}


func generateRandomMatchSummaries(count: Int) -> [MatchSummary] {
    var matchSummaries = [MatchSummary]()
    let heartRateRange = 100.0...180.0

    for id in 1...count {
        let averageHeartRate = Double.random(in: heartRateRange)
        guard let workout: HKWorkout = generateRandomWorkout() else { return [] }
        var matchSummary = MatchSummary(id: id, startDate: workout.startDate, endDate: workout.endDate, duration: workout.duration, totalDistance: workout.totalDistance!.doubleValue(for: .meter()), totalEnergyBurned: workout.totalEnergyBurned!.doubleValue(for: .kilocalorie()), averageHeartRate: averageHeartRate, myScore: 0, opponentScore: 0, history:"")
        var currentTime = matchSummary.startDate
        let endTime = matchSummary.endDate
        while matchSummary.myScore < 21 && matchSummary.opponentScore < 21 && currentTime < endTime {
            let randomTimeInterval = TimeInterval(arc4random_uniform(60) + 1) // 1부터 60초 사이의 랜덤 시간 간격
            currentTime += randomTimeInterval
            let randomScore = Int(arc4random_uniform(2)) // 0 또는 1의 랜덤 점수
            let randomPlayer: Player = randomScore == 0 ? .me : .opponent
            matchSummary.addScore(player: randomPlayer, timestamp: currentTime)
        }
        matchSummaries.append(matchSummary)
    }

    return matchSummaries
}


func generateRandomWorkout() -> HKWorkout? {
    // 시작 시간을 일주일 전부터 오늘까지 랜덤으로 설정
    let endDate = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate)!
    let randomStartDate = Date(timeInterval: TimeInterval.random(in: startDate.timeIntervalSinceNow...endDate.timeIntervalSinceNow), since: Date())
    
    // 운동 종류를 설정 (예시로 배드민턴 사용)
    let workoutType = HKWorkoutActivityType.badminton
    
    // 운동 시간을 10분에서 30분 사이 랜덤으로 설정
    let workoutDuration = TimeInterval.random(in: 600...1800)
    
    // 칼로리를 분당 5~7칼로리로 랜덤으로 설정
    let calorieBurnedPerMinute = Double.random(in: 5...7)
    let totalCaloriesBurned = calorieBurnedPerMinute * (workoutDuration / 60)
    
    // totalDistance를 100m에서 1km 사이 랜덤으로 설정
    let totalDistance = Double.random(in: 100...1000)
    
    // HKWorkout 생성
    let workout = HKWorkout(activityType: workoutType, start: randomStartDate, end: randomStartDate.addingTimeInterval(workoutDuration), workoutEvents: nil, totalEnergyBurned: HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: totalCaloriesBurned), totalDistance: HKQuantity(unit: HKUnit.meter(), doubleValue: totalDistance), metadata: nil)
    
    return workout
}
