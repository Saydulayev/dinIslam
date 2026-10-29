//
//  InlineProgressView.swift
//  dinIslamWidget
//
//  Строка над часами на экране блокировки.
//

import SwiftUI

struct InlineProgressView: View {
    let entry: ProgressEntry

    private var text: String {
        guard entry.dueReviewCount > 0 else {
            return "\(entry.streak) \(entry.streakLabel)"
        }
        return "\(entry.streak) · \(entry.strings.dueReview(entry.dueReviewCount))"
    }

    var body: some View {
        Label(text, systemImage: "flame.fill")
    }
}
