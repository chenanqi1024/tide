//
//  Models.swift
//  tide
//
//  Created by Codex on 2026/6/4.
//

import Foundation

struct SoundItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let url: String
    let cover: String
}

struct SoundsResponse: Decodable {
    let alarm: SoundItem
    let sounds: [SoundItem]
}

struct BreathingExercise: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let steps: [BreathingStep]
}

struct BreathingStep: Hashable {
    let kind: BreathingPhase
    let seconds: Int
}

enum BreathingPhase: String, Hashable {
    case inhale = "吸气"
    case hold = "屏息"
    case exhale = "呼气"
}

struct MeditationSession: Identifiable, Hashable {
    let id: String
    let title: String
    let intro: String
    let paragraphs: [String]
}

enum AppData {
    static let breathingExercises: [BreathingExercise] = [
        BreathingExercise(
            id: "box_4444",
            title: "4-4-4-4",
            summary: "适合紧张、焦虑、需要快速冷静/稳住情绪",
            steps: [
                BreathingStep(kind: .inhale, seconds: 4),
                BreathingStep(kind: .hold, seconds: 4),
                BreathingStep(kind: .exhale, seconds: 4),
                BreathingStep(kind: .hold, seconds: 4)
            ]
        ),
        BreathingExercise(
            id: "sleep_478",
            title: "4-7-8",
            summary: "适合睡前放松、帮助更快入眠",
            steps: [
                BreathingStep(kind: .inhale, seconds: 4),
                BreathingStep(kind: .hold, seconds: 7),
                BreathingStep(kind: .exhale, seconds: 8)
            ]
        ),
        BreathingExercise(
            id: "calm_55",
            title: "5-5",
            summary: "适合日常减压、恢复平静与专注（随时可做）",
            steps: [
                BreathingStep(kind: .inhale, seconds: 5),
                BreathingStep(kind: .exhale, seconds: 5)
            ]
        )
    ]

    static let meditations: [MeditationSession] = [
        MeditationSession(
            id: "quick_sleep",
            title: "快速入眠",
            intro: "用柔和的注意力把身体慢慢带入休息。",
            paragraphs: [
                "找一个舒服的姿势躺好，让肩膀自然下沉。",
                "把注意力放到呼吸上，不需要改变它，只是感受它。",
                "从额头开始，慢慢放松脸颊、下巴和颈部。",
                "让每一次呼气都带走一点紧绷。",
                "如果思绪出现，轻轻看见它，再回到呼吸。",
                "现在允许自己进入睡眠。"
            ]
        ),
        MeditationSession(
            id: "exam_stress",
            title: "考试压力",
            intro: "在压力中重新找回稳定感和清晰感。",
            paragraphs: [
                "先坐稳，感受双脚和地面的接触。",
                "吸气时告诉自己：我正在准备。",
                "呼气时告诉自己：我可以一步一步来。",
                "把注意力放回眼前最小的一件事。",
                "允许紧张存在，同时把行动交还给自己。"
            ]
        ),
        MeditationSession(
            id: "breath_practice",
            title: "呼吸练习",
            intro: "用简单的节奏把注意力带回当下。",
            paragraphs: [
                "轻轻闭上眼，或把视线放低。",
                "吸气，感受胸腔和腹部展开。",
                "呼气，感受身体慢慢松下来。",
                "把每一次呼吸当作一个新的开始。",
                "保持这个节奏，再停留片刻。"
            ]
        ),
        MeditationSession(
            id: "body_scan",
            title: "身体扫描",
            intro: "逐步觉察身体，释放不必要的用力。",
            paragraphs: [
                "把注意力放到头顶，感受那里有没有紧绷。",
                "慢慢移动到肩膀、手臂和手掌。",
                "继续觉察胸口、腹部和后背。",
                "再来到大腿、小腿和脚掌。",
                "最后感受整个身体被稳定地托住。"
            ]
        )
    ]
}
