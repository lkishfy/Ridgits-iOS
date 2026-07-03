import Foundation

/// OkCupid-style question bank sourced from Ridgits proprietary quiz packs.
/// Each question supports: your answer, acceptable partner answers, importance, dealbreaker.
enum QuizCatalog {
    static let questions: [QuizQuestion] = demographics + communication + intimacy + values + spicy

    static let demographics: [QuizQuestion] = [
        q("demo_000", "Demographics", "What is your gender?", [
            "Woman", "Man", "Non-binary", "Genderqueer/Genderfluid", "Prefer to self-describe"
        ], multiSelect: true),
        q("demo_001", "Demographics", "Who are you interested in meeting?", [
            "Women", "Men", "Non-binary people", "Genderqueer/Genderfluid people", "Anyone/Everyone"
        ], multiSelect: true),
        q("demo_002", "Demographics", "What are you looking for?", [
            "Relationship", "New friends", "Open to anything"
        ], multiSelect: true),
    ]

    static let communication: [QuizQuestion] = [
        q("comm_006", "Communication", "Which is worse?", [
            "Starving children",
            "People who use 'your' when they mean 'you're'",
            "Both are equally terrible",
            "Neither bothers me that much"
        ]),
        q("comm_009", "Communication", "How do you feel about double texting?", [
            "Totally fine, I do it all the time",
            "Okay occasionally if I have something to add",
            "Uncomfortable – feels too eager",
            "Never. I wait for them to respond."
        ]),
        q("comm_011", "Communication", "Should burning the American flag be illegal?", [
            "Yes, it's disrespectful",
            "No, free speech is important",
            "I'm not American / It's complicated",
            "I don't have strong feelings about this"
        ]),
        q("comm_012", "Communication", "How do you feel about voice memos?", [
            "Love them! So much better than typing",
            "Good for long messages",
            "Prefer text but will listen if someone sends one",
            "Hate them. Just text me."
        ]),
        q("comm_013", "Communication", "Someone uses 'literally' when they mean 'figuratively.' You:", [
            "Gently correct them",
            "Let it go – language evolves",
            "Judge them silently",
            "Don't notice or care"
        ]),
    ]

    static let intimacy: [QuizQuestion] = [
        q("intim_015", "Intimacy", "Would you rather:", [
            "Have many casual connections with exciting new people",
            "Have a few deep, long-term connections",
            "A mix of both",
            "I refuse to choose"
        ]),
        q("intim_016", "Intimacy", "Someone says they consider you their closest connection, but you're not there yet. You:", [
            "Reciprocate to make them feel good",
            "Say something like 'that means so much to me'",
            "Be honest about where I'm at",
            "This scenario makes me uncomfortable"
        ]),
    ]

    static let values: [QuizQuestion] = [
        q("val_001", "Values", "Is jealousy healthy in a relationship?", [
            "Yes, it shows you care",
            "Sometimes, in small doses",
            "Rarely – usually a red flag",
            "Never – trust should be default"
        ]),
        q("val_005", "Values", "Would you date someone who doesn't vote?", [
            "Yes, politics aren't everything",
            "Maybe, depending on why",
            "Probably not",
            "Absolutely not"
        ]),
    ]

    static let spicy: [QuizQuestion] = [
        q("ll_intim_006", "Intimacy", "Would you be willing to try role-playing in bed?", [
            "Yes, sounds fun!",
            "Maybe with the right person",
            "Probably not my thing",
            "No, I'd feel too awkward"
        ], isSpicy: true),
        q("ll_intim_008", "Intimacy", "How do you feel about morning breath kisses?", [
            "Totally fine, comes with the territory",
            "Okay once we're really comfortable",
            "Please brush your teeth first",
            "Absolutely not"
        ], isSpicy: true),
        q("ll_intim_014", "Intimacy", "How important is it that you and your partner have similar sex drives?", [
            "Extremely important – dealbreaker level",
            "Very important but we can compromise",
            "Somewhat important",
            "Not that important"
        ], isSpicy: true),
        q("ll_intim_015", "Intimacy", "Would you rather:", [
            "Have amazing sex with someone you barely know",
            "Have okay sex with someone you deeply love",
            "These aren't mutually exclusive",
            "I refuse to choose"
        ], isSpicy: true),
        q("ll_intim_017", "Intimacy", "How do you feel about farting in front of your partner?", [
            "Totally natural once we're comfortable",
            "Eventually, but not early on",
            "I'd prefer to keep some mystery",
            "Never – that's private"
        ], isSpicy: true),
        q("ll_intim_016", "Intimacy", "You're getting intimate and your partner says 'I love you' for the first time. You don't feel the same yet. You:", [
            "Say it back to make them feel good",
            "Say something like 'that means so much'",
            "Be honest that I'm not there yet",
            "This scenario is my nightmare"
        ], isSpicy: true),
        q("ll_intim_010", "Intimacy", "Would you date someone who was in a committed non-monogamous relationship?", [
            "Yes, I'm open to that",
            "Maybe, depending on the situation",
            "Probably not, but I'm not judging",
            "No, I need monogamy"
        ], isSpicy: true),
        q("ll_intim_012", "Intimacy", "How would you feel if your partner wanted to shower together regularly?", [
            "Love it, sounds intimate",
            "Sure, occasionally",
            "I need my shower time alone",
            "Logistically impractical"
        ], isSpicy: true),
        q("ll_intim_014b", "Intimacy", "Are you dominant or submissive in the bedroom?", [
            "Dominant",
            "Submissive",
            "Switch / depends on mood",
            "Prefer not to label it"
        ], isSpicy: true),
        q("ll_intim_022", "Intimacy", "For you personally, is sex one of the most important parts of a relationship?", [
            "Yes, absolutely",
            "Very important but not the only thing",
            "Somewhat important",
            "Not really"
        ], isSpicy: true),
        q("msg_sext", "Communication", "Sexting / risqué texts:", [
            "Love them – great foreplay",
            "Fine once we're established",
            "Only if they initiate first",
            "Not my thing"
        ], isSpicy: true),
        q("bnd_sex", "Values", "Sexual boundaries:", [
            "I need to discuss everything upfront",
            "We figure it out as we go",
            "Actions speak louder than words",
            "I prefer keeping things spontaneous"
        ], isSpicy: true),
        q("comm_015", "Communication", "Would you consider dating someone who has significantly different political views?", [
            "Yes, love a good debate",
            "Maybe if we avoid politics",
            "Unlikely – values matter too much",
            "Hard no"
        ]),
        q("intim_003", "Intimacy", "How do you feel about showing affection in public?", [
            "Love it – I'm naturally affectionate",
            "Enjoy it in moderation",
            "Prefer to keep it minimal in public",
            "Prefer to save affection for private settings"
        ]),
        q("intim_004", "Intimacy", "When watching a movie with someone, what's your comfort level?", [
            "Love to cuddle up or lean on each other",
            "Sit close but not necessarily touching",
            "Nearby but with personal space",
            "I prefer my own separate seat"
        ]),
    ]

    private static func q(
        _ id: String,
        _ category: String,
        _ text: String,
        _ labels: [String],
        multiSelect: Bool = false,
        isSpicy: Bool = false
    ) -> QuizQuestion {
        QuizQuestion(
            id: id,
            category: category,
            text: text,
            options: labels.enumerated().map { QuizOption(value: $0.offset, label: $0.element) },
            multiSelect: multiSelect,
            isSpicy: isSpicy
        )
    }
}
