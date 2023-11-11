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

struct MatchSummary: Identifiable {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval
    var totalDistance: Double
    var totalEnergyBurned: Double
    var averageHeartRate: Double
    
    var myScore: Int
    var opponentScore: Int
    var myScoreHistory: [Date] // 내 점수 변동 히스토리
    var opponentScoreHistory: [Date] // 상대의 점수 변동 히스토리
    
    // 새로운 점수 변동 기록 추가
    mutating func addScore(player: Player, timestamp:Date = Date()) {
        switch(player){
        case .me:
            myScoreHistory.append(timestamp)
            myScore += 1
        case .opponent:
            opponentScoreHistory.append(timestamp)
            opponentScore += 1
        }
    }
    // 히스토리에서 맨 뒤의 기록 제거
    mutating func removeScore(player: Player) {
        switch player {
        case .me:
            if !myScoreHistory.isEmpty {
                myScoreHistory.removeLast()
                myScore -= 1
            }
        case .opponent:
            if !opponentScoreHistory.isEmpty {
                opponentScoreHistory.removeLast()
                opponentScore -= 1
            }
        }
    }
    // 히스토리에서 맨 뒤의 기록 제거하고 점수를 0으로 초기화
    mutating func resetScore(player: Player) {
        switch player {
        case .me:
            myScoreHistory.removeAll()
            myScore = 0
        case .opponent:
            opponentScoreHistory.removeAll()
            opponentScore = 0
        }
    }
}


func generateRandomMatchSummaries(count: Int) -> [MatchSummary] {
    var matchSummaries = [MatchSummary]()
    let heartRateRange = 100.0...180.0

    for _ in 1...count {
        let averageHeartRate = Double.random(in: heartRateRange)
        guard let workout: HKWorkout = generateRandomWorkout() else { return [] }
        var matchSummary = MatchSummary(id: UUID(), startDate: workout.startDate, endDate: workout.endDate, duration: workout.duration, totalDistance: workout.totalDistance!.doubleValue(for: .meter()), totalEnergyBurned: workout.totalEnergyBurned!.doubleValue(for: .kilocalorie()), averageHeartRate: averageHeartRate, myScore: 0, opponentScore: 0, myScoreHistory: [], opponentScoreHistory: [])
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


//MARK: - 히스토리 그래프로 그리기
extension MatchSummary {
    func getHistory(myHistory: inout [(x: Int, y: Int)], opponentHistory: inout [(x: Int, y: Int)]) {
        var curTimestamp: Int = 1
        var curMyScore: Int = 0
        var curOpponentScore: Int = 0
        
        // 복사본을 만들어 히스토리와 비교
        var myDates = Array(self.myScoreHistory)
        var opponentDates = Array(self.opponentScoreHistory)
        
        // 두 히스토리 중 작은 날짜까지 반복
        while !myDates.isEmpty || !opponentDates.isEmpty {
            let myNextDate = myDates.first
            let opponentNextDate = opponentDates.first
            
            if let myDate = myNextDate, let opponentDate = opponentNextDate {
                if myDate < opponentDate {
                    curMyScore += 1
                    myHistory.append((curTimestamp, curMyScore))
                    myDates.removeFirst()
                } else if opponentDate < myDate {
                    curOpponentScore += 1
                    opponentHistory.append((curTimestamp, curOpponentScore))
                    opponentDates.removeFirst()
                } else { // 동시에 점수가 오르면
                    curMyScore += 1
                    curOpponentScore += 1
                    myHistory.append((curTimestamp, curMyScore))
                    opponentHistory.append((curTimestamp, curOpponentScore))
                    myDates.removeFirst()
                    opponentDates.removeFirst()
                }
            } else if let _ = myNextDate {
                curMyScore += 1
                myHistory.append((curTimestamp, curMyScore))
                myDates.removeFirst()
            } else if let _ = opponentNextDate {
                curOpponentScore += 1
                opponentHistory.append((curTimestamp, curOpponentScore))
                opponentDates.removeFirst()
            }
            curTimestamp += 1
        }
        curTimestamp -= 1
        if myHistory.last!.x == curTimestamp {
            opponentHistory.append((curTimestamp,curOpponentScore))
        }
        if opponentHistory.last!.x == curTimestamp {
            myHistory.append((curTimestamp,curMyScore))
        }
    }
}