import Foundation

// MARK: - Catalog types

/// A single problem from the Stat 110 problem sets (Joe Blitzstein, Harvard).
/// Each homework PDF contains two parallel sets: "Strategic Practice"
/// (grouped by topic, never graded — for warm-up) and "Homework" (the
/// actual numbered turn-in problems). We surface both as pickable items
/// because the user wants to log either kind as a homework problem.
public struct Stat110Problem: Identifiable, Hashable, Sendable {
    /// Stable string identifier so we can mark this problem "done" in the
    /// homework store regardless of how the user edits the title.
    /// Format: `stat110-hw{N}-{sp|hw}-{number}`
    /// Examples: `stat110-hw2-sp-1.1`, `stat110-hw2-hw-3`
    public let id: String
    public let setNumber: Int        // e.g. 2 for HW2
    public let kind: Kind
    /// Topic header (Strategic Practice only — Homework problems aren't
    /// grouped by topic in Blitzstein's PDFs).
    public let topic: String?
    /// As printed in the PDF: "1", "3", "1.2", etc.
    public let number: String
    /// Short human-readable summary of the problem.
    public let title: String

    public enum Kind: String, Hashable, Sendable {
        case strategicPractice
        case homework

        public var label: String {
            switch self {
            case .strategicPractice: return "Strategic Practice"
            case .homework:          return "Homework"
            }
        }
    }

    /// String used as the homework entry's `source` field — surfaces in
    /// the list/detail views ("Stat 110 HW2 Homework 3").
    public var sourceLabel: String {
        var s = "Stat 110 HW\(setNumber) \(kind.label) \(number)"
        if let topic { s += " — \(topic)" }
        return s
    }
}

public struct Stat110ProblemSet: Identifiable, Hashable, Sendable {
    public var id: Int { setNumber }
    public let setNumber: Int
    public let title: String          // "Strategic Practice & Homework 2"
    public let pdfURL: String
    public let problems: [Stat110Problem]

    public var strategicPractice: [Stat110Problem] {
        problems.filter { $0.kind == .strategicPractice }
    }
    public var homework: [Stat110Problem] {
        problems.filter { $0.kind == .homework }
    }

    /// Strategic-practice problems grouped by topic, preserving declaration order.
    public var spByTopic: [(topic: String, items: [Stat110Problem])] {
        var seen: [String: Int] = [:]
        var order: [String] = []
        for p in strategicPractice where p.topic != nil {
            if seen[p.topic!] == nil {
                seen[p.topic!] = order.count
                order.append(p.topic!)
            }
        }
        return order.map { t in
            (topic: t, items: strategicPractice.filter { $0.topic == t })
        }
    }
}

public enum Stat110Catalog {
    public static let all: [Stat110ProblemSet] = [hw2, hw3]

    public static func problemSet(number: Int) -> Stat110ProblemSet? {
        all.first { $0.setNumber == number }
    }

    public static func problem(id: String) -> Stat110Problem? {
        for set in all {
            if let p = set.problems.first(where: { $0.id == id }) { return p }
        }
        return nil
    }
}

// MARK: - HW2 (Fall 2011)
// Source: https://stat110.hsites.harvard.edu/sites/g/files/omnuum10111/files/stat110/files/strategic_practice_and_homework_2.pdf

private let hw2: Stat110ProblemSet = .init(
    setNumber: 2,
    title: "Strategic Practice & Homework 2",
    pdfURL: "https://stat110.hsites.harvard.edu/sites/g/files/omnuum10111/files/stat110/files/strategic_practice_and_homework_2.pdf",
    problems: [
        // --- Strategic Practice 2 ---
        .init(id: "stat110-hw2-sp-1.1", setNumber: 2, kind: .strategicPractice,
              topic: "Inclusion-Exclusion", number: "1.1",
              title: "P(all 4 seasons appear) among 7 people’s birthdays"),
        .init(id: "stat110-hw2-sp-1.2", setNumber: 2, kind: .strategicPractice,
              topic: "Inclusion-Exclusion", number: "1.2",
              title: "Alice picks 7 of 30 classes — P(class every Mon-Fri)"),

        .init(id: "stat110-hw2-sp-2.1", setNumber: 2, kind: .strategicPractice,
              topic: "Independence", number: "2.1",
              title: "Can an event be independent of itself? When?"),
        .init(id: "stat110-hw2-sp-2.2", setNumber: 2, kind: .strategicPractice,
              topic: "Independence", number: "2.2",
              title: "If A,B independent, are Aᶜ,Bᶜ independent?"),
        .init(id: "stat110-hw2-sp-2.3", setNumber: 2, kind: .strategicPractice,
              topic: "Independence", number: "2.3",
              title: "3 events pairwise independent but not mutually independent"),
        .init(id: "stat110-hw2-sp-2.4", setNumber: 2, kind: .strategicPractice,
              topic: "Independence", number: "2.4",
              title: "Non-independent A,B,C with P(A∩B∩C) = P(A)P(B)P(C)"),

        .init(id: "stat110-hw2-sp-3.1", setNumber: 2, kind: .strategicPractice,
              topic: "Thinking Conditionally", number: "3.1",
              title: "Lewis Carroll: bag with green+unknown marble; drew green"),
        .init(id: "stat110-hw2-sp-3.2", setNumber: 2, kind: .strategicPractice,
              topic: "Thinking Conditionally", number: "3.2",
              title: "Spam filter: P(spam | “free money”) via Bayes"),
        .init(id: "stat110-hw2-sp-3.3", setNumber: 2, kind: .strategicPractice,
              topic: "Thinking Conditionally", number: "3.3",
              title: "Two pieces of evidence E₁,E₂ — order-of-updating equivalence"),
        .init(id: "stat110-hw2-sp-3.4", setNumber: 2, kind: .strategicPractice,
              topic: "Thinking Conditionally", number: "3.4",
              title: "Crime, suspect A matches 10%-blood-type; P(A guilty), P(B matches)"),
        .init(id: "stat110-hw2-sp-3.5", setNumber: 2, kind: .strategicPractice,
              topic: "Thinking Conditionally", number: "3.5",
              title: "2 chess games vs. unknown-skill opponent — conditional independence"),

        // --- Homework 2 ---
        .init(id: "stat110-hw2-hw-1", setNumber: 2, kind: .homework,
              topic: nil, number: "1",
              title: "Arby’s belief system — Dutch-book argument for the axioms"),
        .init(id: "stat110-hw2-hw-2", setNumber: 2, kind: .homework,
              topic: nil, number: "2",
              title: "13-card hand — P(void in at least one suit)"),
        .init(id: "stat110-hw2-hw-3", setNumber: 2, kind: .homework,
              topic: nil, number: "3",
              title: "Three children A,B,C — is “A>B” independent of “A>C”?"),
        .init(id: "stat110-hw2-hw-4", setNumber: 2, kind: .homework,
              topic: nil, number: "4",
              title: "Fair vs. biased coin in hat — P(fair|HH); 10-flip count"),
        .init(id: "stat110-hw2-hw-5", setNumber: 2, kind: .homework,
              topic: nil, number: "5",
              title: "Murdered wife — P(husband guilty | abuse history, murdered)"),
        .init(id: "stat110-hw2-hw-6", setNumber: 2, kind: .homework,
              topic: nil, number: "6",
              title: "Two-child puzzle with birth-month — March-born girl variants"),
    ]
)

// MARK: - HW3 (Fall 2011)
// Source: https://stat110.hsites.harvard.edu/sites/g/files/omnuum10111/files/stat110/files/strategic_practice_and_homework_3.pdf

private let hw3: Stat110ProblemSet = .init(
    setNumber: 3,
    title: "Strategic Practice & Homework 3",
    pdfURL: "https://stat110.hsites.harvard.edu/sites/g/files/omnuum10111/files/stat110/files/strategic_practice_and_homework_3.pdf",
    problems: [
        // --- Strategic Practice 3 ---
        .init(id: "stat110-hw3-sp-1.1", setNumber: 3, kind: .strategicPractice,
              topic: "Continuing with Conditioning", number: "1.1",
              title: "Biased Monty Hall — opens Door 2 with prob p; switching odds (a,b,c)"),
        .init(id: "stat110-hw3-sp-1.2", setNumber: 3, kind: .strategicPractice,
              topic: "Continuing with Conditioning", number: "1.2",
              title: "True/False on independence of X,Y,Z (a,b,c,d)"),

        .init(id: "stat110-hw3-sp-2.1", setNumber: 3, kind: .strategicPractice,
              topic: "Simpson's Paradox", number: "2.1",
              title: "Can P(A|E)<P(B|E), P(A|Eᶜ)<P(B|Eᶜ) yet P(A)>P(B)? (a, b)"),
        .init(id: "stat110-hw3-sp-2.2", setNumber: 3, kind: .strategicPractice,
              topic: "Simpson's Paradox", number: "2.2",
              title: "Lisa, Homer & Stampy — ivory dealer Simpson's setup (a,b,c)"),

        .init(id: "stat110-hw3-sp-3.1", setNumber: 3, kind: .strategicPractice,
              topic: "Gambler's Ruin", number: "3.1",
              title: "Quit when ahead by $2; show P(ever ahead by $2) < 1/4"),

        .init(id: "stat110-hw3-sp-4.1", setNumber: 3, kind: .strategicPractice,
              topic: "Bernoulli and Binomial", number: "4.1",
              title: "World Series — P(A wins series); does 7-game assumption matter?"),
        .init(id: "stat110-hw3-sp-4.2", setNumber: 3, kind: .strategicPractice,
              topic: "Bernoulli and Binomial", number: "4.2",
              title: "n Bernoulli trials — given #successes, all sequences equally likely"),
        .init(id: "stat110-hw3-sp-4.3", setNumber: 3, kind: .strategicPractice,
              topic: "Bernoulli and Binomial", number: "4.3",
              title: "X+Y is Bin; X−Y isn't; P(X=k | X+Y=j) (a,b,c)"),

        // --- Homework 3 ---
        .init(id: "stat110-hw3-hw-1", setNumber: 3, kind: .homework,
              topic: nil, number: "1",
              title: "7-door (then n-door, m-goat) Monty Hall — should you switch?"),
        .init(id: "stat110-hw3-hw-2", setNumber: 3, kind: .homework,
              topic: nil, number: "2",
              title: "Bayes' rule in odds form — medical test, one-step vs. two-step update"),
        .init(id: "stat110-hw3-hw-3", setNumber: 3, kind: .homework,
              topic: nil, number: "3",
              title: "P(Aᵢ|B)>P(Aᵢ|C) but P(A₁∪A₂|B)<P(A₁∪A₂|C) — possible? story"),
        .init(id: "stat110-hw3-hw-4", setNumber: 3, kind: .homework,
              topic: nil, number: "4",
              title: "Calvin & Hobbes, win-by-two — P(Calvin wins) by LOTP + gambler's ruin"),
        .init(id: "stat110-hw3-hw-5", setNumber: 3, kind: .homework,
              topic: nil, number: "5",
              title: "Fair die running total — recursive pₙ, find p₇, show pₙ → 2/7"),
        .init(id: "stat110-hw3-hw-6", setNumber: 3, kind: .homework,
              topic: nil, number: "6",
              title: "A vs B trivia turns — PMFs; first-correct-wins, P(A wins)"),
        .init(id: "stat110-hw3-hw-7", setNumber: 3, kind: .homework,
              topic: nil, number: "7",
              title: "Noisy channel with parity bit — P(undetected errors), closed form"),
    ]
)
