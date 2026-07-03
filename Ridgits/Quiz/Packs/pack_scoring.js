// Love Language & Romantic Compatibility Quiz - Original Questions
// These questions focus specifically on romantic relationships and dating.
// Contains only questions unique to romantic contexts (not in main personality quiz).
// © 2025 GEISTS, LLC. All rights reserved.

const LOVE_LANGUAGE_QUIZ_ITEMS = [
  // Romantic Communication (3 unique questions)
  {
    id: "ll_comm_007",
    category: "Romantic Communication",
    text: "How comfortable are you saying 'I love you' first?",
    options: [
      { value: 0, label: "Very – I say it when I feel it" },
      { value: 1, label: "Somewhat – if the moment feels right" },
      { value: 2, label: "Prefer to wait for them to say it first" },
      { value: 3, label: "Very cautious – need to be absolutely sure" }
    ]
  },
  {
    id: "ll_comm_017",
    category: "Romantic Communication",
    text: "You're about to sleep with someone for the first time. Do you leave the lights on?",
    options: [
      { value: 0, label: "All the way on" },
      { value: 1, label: "Dimmed or candles" },
      { value: 2, label: "Off completely" },
      { value: 3, label: "Whatever they prefer" }
    ]
  },

  // Intimacy & Romance (22 unique questions)
  {
    id: "ll_intim_000",
    category: "Intimacy",
    text: "How important is physical chemistry on a first date?",
    options: [
      { value: 0, label: "Crucial – I need to feel that spark immediately" },
      { value: 1, label: "Important, but can develop over time" },
      { value: 2, label: "Somewhat important, but personality matters more" },
      { value: 3, label: "Not very – I need emotional connection first" }
    ]
  },
  {
    id: "ll_intim_001",
    category: "Intimacy",
    text: "When do you typically feel ready for physical intimacy?",
    options: [
      { value: 0, label: "When there's strong mutual attraction" },
      { value: 1, label: "After a few great dates and conversations" },
      { value: 2, label: "Once emotional connection is established" },
      { value: 3, label: "Within a committed, exclusive relationship" }
    ]
  },
  {
    id: "ll_intim_002",
    category: "Intimacy",
    text: "How do you feel about sleeping over on the first date?",
    options: [
      { value: 0, label: "If the vibe is right, why not?" },
      { value: 1, label: "Open to it but no expectations" },
      { value: 2, label: "Prefer to wait a bit" },
      { value: 3, label: "Definitely not – too soon" }
    ]
  },
  {
    id: "ll_intim_003",
    category: "Intimacy",
    text: "How do you feel about public displays of affection?",
    options: [
      { value: 0, label: "Love it – I'm naturally affectionate" },
      { value: 1, label: "Enjoy it in moderation (hand-holding, light kisses)" },
      { value: 2, label: "Prefer to keep it minimal in public" },
      { value: 3, label: "Uncomfortable with PDA, prefer private affection" }
    ]
  },
  {
    id: "ll_intim_004",
    category: "Intimacy",
    text: "Do you prefer to be the big spoon or little spoon?",
    options: [
      { value: 0, label: "Big spoon" },
      { value: 1, label: "Little spoon" },
      { value: 2, label: "Switch it up" },
      { value: 3, label: "I need my space when I sleep" }
    ]
  },
  {
    id: "ll_intim_006",
    category: "Intimacy",
    text: "Would you be willing to try role-playing in bed?",
    options: [
      { value: 0, label: "Yes, sounds fun!" },
      { value: 1, label: "Maybe with the right person" },
      { value: 2, label: "Probably not my thing" },
      { value: 3, label: "No, I'd feel too awkward" }
    ]
  },
  {
    id: "ll_intim_008",
    category: "Intimacy",
    text: "How do you feel about morning breath kisses?",
    options: [
      { value: 0, label: "Totally fine, comes with the territory" },
      { value: 1, label: "Okay once we're really comfortable" },
      { value: 2, label: "Please brush your teeth first" },
      { value: 3, label: "Absolutely not" }
    ]
  },
  {
    id: "ll_intim_010",
    category: "Intimacy",
    text: "Would you date someone who was in a committed non-monogamous relationship?",
    options: [
      { value: 0, label: "Yes, I'm open to that" },
      { value: 1, label: "Maybe, depending on the situation" },
      { value: 2, label: "Probably not, but I'm not judging" },
      { value: 3, label: "No, I need monogamy" }
    ]
  },
  {
    id: "ll_intim_011",
    category: "Intimacy",
    text: "Should your partner be your best friend?",
    options: [
      { value: 0, label: "Absolutely yes" },
      { value: 1, label: "Ideally, but not required" },
      { value: 2, label: "No, I keep friendship and romance separate" },
      { value: 3, label: "I'm not sure" }
    ]
  },
  {
    id: "ll_intim_012",
    category: "Intimacy",
    text: "How would you feel if your partner wanted to shower together regularly?",
    options: [
      { value: 0, label: "Love it, sounds intimate" },
      { value: 1, label: "Sure, occasionally" },
      { value: 2, label: "I need my shower time alone" },
      { value: 3, label: "Logistically impractical" }
    ]
  },
  {
    id: "ll_intim_014",
    category: "Intimacy",
    text: "How important is it that you and your partner have similar sex drives?",
    options: [
      { value: 0, label: "Extremely important – dealbreaker level" },
      { value: 1, label: "Very important but we can compromise" },
      { value: 2, label: "Somewhat important" },
      { value: 3, label: "Not that important" }
    ]
  },
  {
    id: "ll_intim_015",
    category: "Intimacy",
    text: "Would you rather:",
    options: [
      { value: 0, label: "Have amazing sex with someone you barely know" },
      { value: 1, label: "Have okay sex with someone you deeply love" },
      { value: 2, label: "These aren't mutually exclusive" },
      { value: 3, label: "I refuse to choose" }
    ]
  },
  {
    id: "ll_intim_016",
    category: "Intimacy",
    text: "You're getting intimate and your partner says 'I love you' for the first time. You don't feel the same yet. You:",
    options: [
      { value: 0, label: "Say it back to make them feel good" },
      { value: 1, label: "Say something like 'that means so much'" },
      { value: 2, label: "Be honest that I'm not there yet" },
      { value: 3, label: "This scenario is my nightmare" }
    ]
  },
  {
    id: "ll_intim_017",
    category: "Intimacy",
    text: "How do you feel about farting in front of your partner?",
    options: [
      { value: 0, label: "Natural and funny, no big deal" },
      { value: 1, label: "Eventually it happens" },
      { value: 2, label: "I'd be mortified" },
      { value: 3, label: "Never. Some mystery is good." }
    ]
  },
  {
    id: "ll_intim_018",
    category: "Intimacy",
    text: "Your ideal date night involves:",
    options: [
      { value: 0, label: "Adventure and trying something new together" },
      { value: 1, label: "Romantic dinner and intimate conversation" },
      { value: 2, label: "Cozy night in with movies or cooking" },
      { value: 3, label: "Cultural experience like a concert or museum" }
    ]
  },
  {
    id: "ll_intim_019",
    category: "Intimacy",
    text: "What does intimacy mean to you beyond physical connection?",
    options: [
      { value: 0, label: "Complete emotional vulnerability and openness" },
      { value: 1, label: "Deep understanding of each other's inner worlds" },
      { value: 2, label: "Unwavering trust and reliability" },
      { value: 3, label: "Accepting each other fully, flaws and all" }
    ]
  },
  {
    id: "ll_intim_020",
    category: "Intimacy",
    text: "Would you ask for a brief back massage on your second date (shirt on)?",
    options: [
      { value: 0, label: "Yes, absolutely – physical touch builds connection" },
      { value: 1, label: "Maybe, if the vibe feels right" },
      { value: 2, label: "Probably not – too forward for a second date" },
      { value: 3, label: "No – I'd wait until we're more comfortable" }
    ]
  },
  {
    id: "ll_intim_023",
    category: "Intimacy",
    text: "For you personally, is sex one of the most important parts of a relationship?",
    options: [
      { value: 0, label: "Yes, it's essential for connection" },
      { value: 1, label: "Very important but not the most important" },
      { value: 2, label: "Somewhat important" },
      { value: 3, label: "Not very important" }
    ]
  },
  {
    id: "ll_intim_024",
    category: "Intimacy",
    text: "Are you dominant or submissive in the bedroom?",
    options: [
      { value: 0, label: "I am vanilla" },
      { value: 1, label: "I am submissive" },
      { value: 2, label: "I am a switch" },
      { value: 3, label: "I am dominant" }
    ]
  },
  {
    id: "ll_intim_025",
    category: "Intimacy",
    text: "It would bother me if my partner consumed porn.",
    options: [
      { value: 0, label: "Strongly agree – it would bother me a lot" },
      { value: 1, label: "Somewhat agree – I'd prefer they didn't" },
      { value: 2, label: "Neutral – it depends on the context" },
      { value: 3, label: "Somewhat disagree – doesn't bother me much" },
      { value: 4, label: "Strongly disagree – doesn't bother me at all" }
    ]
  },

  // Dating Values (8 unique questions)
  {
    id: "ll_vals_002",
    category: "Dating Values",
    text: "What's your stance on wanting children?",
    options: [
      { value: 0, label: "Definitely want children" },
      { value: 1, label: "Open to it with the right partner" },
      { value: 2, label: "Unsure – could go either way" },
      { value: 3, label: "Have kid(s) already but don't want more" },
      { value: 4, label: "Definitely don't want children" }
    ]
  },
  {
    id: "ll_vals_003",
    category: "Dating Values",
    text: "Would you date someone who has a kid?",
    options: [
      { value: 0, label: "Yes, no problem" },
      { value: 1, label: "Depends on the situation" },
      { value: 2, label: "Probably not" },
      { value: 3, label: "Definitely not" }
    ]
  },
  {
    id: "ll_vals_004",
    category: "Dating Values",
    text: "Are you willing to date someone with a disability?",
    options: [
      { value: 0, label: "Yes, absolutely" },
      { value: 1, label: "Yes, it depends on the disability and our compatibility" },
      { value: 2, label: "I'm not sure / I'd have to think about it" },
      { value: 3, label: "Probably not" }
    ]
  },
  {
    id: "ll_vals_005",
    category: "Dating Values",
    text: "How do you approach finances in a relationship?",
    options: [
      { value: 0, label: "Completely joint – what's mine is ours" },
      { value: 1, label: "Mostly shared with some personal accounts" },
      { value: 2, label: "Split expenses but keep finances separate" },
      { value: 3, label: "Completely independent financial lives" }
    ]
  },
  {
    id: "ll_vals_006",
    category: "Dating Values",
    text: "Should the man always pay on dates?",
    options: [
      { value: 0, label: "Yes, traditionally" },
      { value: 1, label: "On the first date, then split" },
      { value: 2, label: "Split everything equally" },
      { value: 3, label: "Whoever asks should pay, regardless of gender" }
    ]
  },
  {
    id: "ll_vals_008",
    category: "Dating Values",
    text: "Would you consider relocating for a partner's job?",
    options: [
      { value: 0, label: "Absolutely, if we're serious" },
      { value: 1, label: "Yes, depending on the circumstances" },
      { value: 2, label: "Maybe if we're married or engaged" },
      { value: 3, label: "No, my career/location is too important" }
    ]
  },
  {
    id: "ll_vals_010",
    category: "Dating Values",
    text: "How do you feel about living together before marriage?",
    options: [
      { value: 0, label: "Absolutely necessary to test compatibility" },
      { value: 1, label: "Prefer it but not required" },
      { value: 2, label: "Open to it but would rather wait" },
      { value: 3, label: "Prefer to wait until marriage" }
    ]
  },

  // Relationship Dynamics (4 unique questions)
  {
    id: "ll_socl_004",
    category: "Relationship Dynamics",
    text: "How do you feel about your partner having close friends of the opposite sex?",
    options: [
      { value: 0, label: "Totally fine – trust is everything" },
      { value: 1, label: "Okay with it but appreciate transparency" },
      { value: 2, label: "Somewhat uncomfortable but willing to work through it" },
      { value: 3, label: "Prefer clear boundaries in this area" }
    ]
  },
  {
    id: "ll_socl_005",
    category: "Relationship Dynamics",
    text: "How do you handle jealousy in relationships?",
    options: [
      { value: 0, label: "I don't really get jealous – I trust easily" },
      { value: 1, label: "Occasional jealousy but I communicate about it" },
      { value: 2, label: "Sometimes struggle with it but work on it" },
      { value: 3, label: "Tend to be protective of relationships" }
    ]
  },
  {
    id: "ll_socl_006",
    category: "Relationship Dynamics",
    text: "How many people have you slept with?",
    options: [
      { value: 0, label: "0-2" },
      { value: 1, label: "3-10" },
      { value: 2, label: "11-25" },
      { value: 3, label: "More than 25 / None of your business" }
    ]
  },
  {
    id: "ll_socl_014",
    category: "Relationship Dynamics",
    text: "Would you ever do a threesome?",
    options: [
      { value: 0, label: "Yes, I'd be interested" },
      { value: 1, label: "Maybe with the right people" },
      { value: 2, label: "Probably not but never say never" },
      { value: 3, label: "Definitely not my thing" }
    ]
  },

  // Commitment & Future (12 unique questions)
  {
    id: "ll_comt_000",
    category: "Commitment",
    text: "What are you ultimately looking for?",
    options: [
      { value: 0, label: "Life partner and eventual marriage" },
      { value: 1, label: "Long-term committed relationship" },
      { value: 2, label: "Open to seeing where things go naturally" },
      { value: 3, label: "Casual dating and companionship" }
    ]
  },
  {
    id: "ll_comt_001",
    category: "Commitment",
    text: "How long do you typically date before becoming exclusive?",
    options: [
      { value: 0, label: "1-2 dates if there's strong chemistry" },
      { value: 1, label: "A few weeks to a month" },
      { value: 2, label: "2-3 months of consistent dating" },
      { value: 3, label: "Several months – I take my time" },
      { value: 4, label: "I don't want to be in an exclusive relationship" }
    ]
  },
  {
    id: "ll_comt_002",
    category: "Commitment",
    text: "How do you feel about marriage?",
    options: [
      { value: 0, label: "Definitely want to get married" },
      { value: 1, label: "Open to it with the right person" },
      { value: 2, label: "Unsure – don't need marriage to commit" },
      { value: 3, label: "Don't believe in marriage" }
    ]
  },
  {
    id: "ll_comt_003",
    category: "Commitment",
    text: "Would you stay in a relationship if you were no longer in love?",
    options: [
      { value: 0, label: "Never – love is essential" },
      { value: 1, label: "Maybe if there were other factors (kids, etc.)" },
      { value: 2, label: "Yes, love changes over time" },
      { value: 3, label: "I'm not sure" }
    ]
  },
  {
    id: "ll_comt_013",
    category: "Commitment",
    text: "Could you forgive infidelity?",
    options: [
      { value: 0, label: "Never – immediate dealbreaker" },
      { value: 1, label: "Probably not but depends on circumstances" },
      { value: 2, label: "Maybe with couples therapy" },
      { value: 3, label: "Yes, people make mistakes" }
    ]
  },
  {
    id: "ll_comt_014",
    category: "Commitment",
    text: "How long was your longest relationship?",
    options: [
      { value: 0, label: "Never been in a relationship" },
      { value: 1, label: "Less than 6 months" },
      { value: 2, label: "6 months to 2 years" },
      { value: 3, label: "2-5 years" },
      { value: 4, label: "More than 5 years" }
    ]
  },
  {
    id: "ll_comt_021",
    category: "Commitment",
    text: "What relationship style are you most interested in?",
    options: [
      { value: 0, label: "Monogamy – exclusive with one person" },
      { value: 1, label: "Open relationship – committed but sexually open" },
      { value: 2, label: "Polyamory – multiple romantic relationships" },
      { value: 3, label: "Relationship anarchy – no hierarchies or rules" },
      { value: 4, label: "Exploring/Not sure yet" }
    ]
  },
  {
    id: "ll_comt_022",
    category: "Commitment",
    text: "How do you feel about non-monogamy?",
    options: [
      { value: 0, label: "Not for me – I prefer exclusive relationships" },
      { value: 1, label: "Open to discussing with the right person" },
      { value: 2, label: "Interested but haven't explored it" },
      { value: 3, label: "Experienced and prefer ethical non-monogamy" }
    ]
  },
  {
    id: "ll_comt_023",
    category: "Commitment",
    text: "Would you be comfortable with your partner having other romantic connections?",
    options: [
      { value: 0, label: "No – I need complete romantic exclusivity" },
      { value: 1, label: "Maybe sexual but not romantic connections" },
      { value: 2, label: "Yes, with clear communication and boundaries" },
      { value: 3, label: "Yes, and I prefer relationship autonomy" }
    ]
  },
  {
    id: "ll_comt_025",
    category: "Commitment",
    text: "How do you feel about long distance relationships?",
    options: [
      { value: 0, label: "Open to it – distance doesn't matter with the right person" },
      { value: 1, label: "Maybe for the right person, temporarily" },
      { value: 2, label: "Prefer not to but would consider it" },
      { value: 3, label: "Absolutely not – need physical proximity" }
    ]
  },
  {
    id: "ll_comt_026",
    category: "Commitment",
    text: "Does emotional entanglement count as cheating?",
    options: [
      { value: 0, label: "Yes, absolutely – emotional cheating is still cheating" },
      { value: 1, label: "It depends on the situation and context" },
      { value: 2, label: "Not really – cheating is only physical" },
      { value: 3, label: "I'm not sure what counts as emotional entanglement" }
    ]
  },

  // Additional questions to reach 50
  {
    id: "ll_intim_026",
    category: "Intimacy",
    text: "How do you feel about kissing on a first date?",
    options: [
      { value: 0, label: "Absolutely – if the chemistry is there, go for it" },
      { value: 1, label: "Maybe a quick kiss if it feels right" },
      { value: 2, label: "Prefer to wait until the second or third date" },
      { value: 3, label: "I'd rather wait until we're more serious" }
    ]
  },
  {
    id: "ll_intim_027",
    category: "Intimacy",
    text: "How important is it that your partner initiates intimacy?",
    options: [
      { value: 0, label: "Very – I prefer when they make the first move" },
      { value: 1, label: "Somewhat – I like a balance of both initiating" },
      { value: 2, label: "Not very – I'm usually the one to initiate" },
      { value: 3, label: "Doesn't matter – either way works for me" }
    ]
  },
  {
    id: "ll_comm_022",
    category: "Romantic Communication",
    text: "How do you prefer to have 'the talk' about becoming official?",
    options: [
      { value: 0, label: "Direct conversation – I bring it up clearly" },
      { value: 1, label: "Wait for the other person to bring it up" },
      { value: 2, label: "Let it happen naturally without a formal talk" },
      { value: 3, label: "I avoid defining relationships if possible" }
    ]
  },
  {
    id: "ll_vals_021",
    category: "Dating Values",
    text: "How do you feel about dating apps?",
    options: [
      { value: 0, label: "Love them – it's how I meet most people" },
      { value: 1, label: "Useful but I prefer meeting people organically" },
      { value: 2, label: "Only use them occasionally" },
      { value: 3, label: "Avoid them – I prefer real-life connections" }
    ]
  },
  {
    id: "ll_socl_020",
    category: "Relationship Dynamics",
    text: "How do you feel about your partner following their ex on social media?",
    options: [
      { value: 0, label: "Totally fine – the past is the past" },
      { value: 1, label: "Okay but I'd want to know about it" },
      { value: 2, label: "Would prefer they didn't but won't demand it" },
      { value: 3, label: "Uncomfortable with it – I'd want them to unfollow" }
    ]
  },
  {
    id: "ll_comt_027",
    category: "Commitment",
    text: "How do you feel about getting engaged before living together?",
    options: [
      { value: 0, label: "Traditional and romantic – I like the idea" },
      { value: 1, label: "Either way is fine with me" },
      { value: 2, label: "Prefer to live together first" },
      { value: 3, label: "Absolutely must live together before engagement" }
    ]
  }
];

// Love Language Archetypes
const LOVE_LANGUAGE_ARCHETYPES = [
  {
    name: "The Hopeless Romantic",
    description: "You believe in love at first sight and aren't afraid to dive in headfirst. You're affectionate, expressive, and view relationships as the center of a fulfilling life.",
    characteristics: [
      "Emotionally expressive",
      "Relationship-focused",
      "Romantic gestures",
      "Fast-moving"
    ],
    suggestions: [
      "Balance romantic ideals with realistic expectations",
      "Allow relationships time to develop naturally",
      "Find a partner who matches your enthusiasm and isn't scared by intensity"
    ]
  },
  {
    name: "The Thoughtful Partner",
    description: "You approach relationships with intention and care. You value deep connection, open communication, and building something meaningful over time.",
    characteristics: [
      "Emotionally intelligent",
      "Patient",
      "Great communicator",
      "Relationship-oriented"
    ],
    suggestions: [
      "Don't overthink – sometimes it's okay to just enjoy the moment",
      "Trust your instincts alongside your analysis",
      "Find someone who appreciates depth and is ready for emotional intimacy"
    ]
  },
  {
    name: "The Independent Spirit",
    description: "You value your autonomy and bring a sense of self to your relationships. You're looking for a partner who enhances your life without defining it.",
    characteristics: [
      "Self-sufficient",
      "Balanced",
      "Respects boundaries",
      "Takes time to commit"
    ],
    suggestions: [
      "Remember to make time for vulnerability and intimacy",
      "Let your partner in when it feels right",
      "Find someone confident who has their own full life"
    ]
  },
  {
    name: "The Adventure Seeker",
    description: "You want a partner to explore life with. You value spontaneity, new experiences, and a relationship that feels exciting and dynamic.",
    characteristics: [
      "Spontaneous",
      "Energetic",
      "Experience-focused",
      "Fun-loving"
    ],
    suggestions: [
      "Don't forget to create stability amidst the excitement",
      "Build deeper roots while staying adventurous",
      "Find someone who's up for anything and shares your zest for life"
    ]
  },
  {
    name: "The Slow Burn",
    description: "You believe the best relationships develop gradually. You need time to build trust and prefer friendship as the foundation of romance.",
    characteristics: [
      "Cautious",
      "Friendship-first",
      "Loyal",
      "Values trust deeply"
    ],
    suggestions: [
      "Be open to unexpected connections that don't fit your timeline",
      "Sometimes chemistry arrives before comfort",
      "Find someone patient who understands that good things take time"
    ]
  },
  {
    name: "The Practical Partner",
    description: "You approach relationships with your head and your heart. You value compatibility, shared goals, and building a life together that makes sense.",
    characteristics: [
      "Logical",
      "Goal-oriented",
      "Stable",
      "Values compatibility"
    ],
    suggestions: [
      "Leave room for passion and spontaneity",
      "Sometimes the heart knows what the head can't calculate",
      "Find someone who shares your life vision and values"
    ]
  },
  {
    name: "The Free Spirit",
    description: "You're open to wherever life takes you. You don't believe in forcing relationships and prefer to let things unfold naturally without pressure.",
    characteristics: [
      "Go-with-the-flow",
      "Non-traditional",
      "Present-focused",
      "Open-minded"
    ],
    suggestions: [
      "Communicate your needs even when going with the flow",
      "Be clear about what you're looking for to avoid mismatched expectations",
      "Find someone who doesn't need labels or timelines"
    ]
  },
  {
    name: "The Balanced One",
    description: "You've found equilibrium between independence and partnership, passion and stability, planning and spontaneity. You bring well-rounded energy to relationships.",
    characteristics: [
      "Adaptable",
      "Well-balanced",
      "Emotionally mature",
      "Stable yet fun"
    ],
    suggestions: [
      "Don't be afraid to lean into your preferences more strongly",
      "Your balance is a strength – use it to navigate relationship challenges",
      "Find someone who appreciates your balanced approach"
    ]
  },
  {
    name: "The Protector",
    description: "You show love through acts of service and making your partner feel safe. You're reliable, consistent, and express affection by taking care of the people you love.",
    characteristics: [
      "Nurturing",
      "Reliable",
      "Acts of service",
      "Protective instincts"
    ],
    suggestions: [
      "Remember to let others take care of you too – receiving is also an act of love",
      "Balance protection with allowing your partner independence",
      "Find someone who appreciates being cared for and reciprocates in their own way"
    ]
  },
  {
    name: "The Passionate Lover",
    description: "Physical touch is your primary love language. You crave intimacy and closeness, expressing and feeling love most deeply through physical presence.",
    characteristics: [
      "Physically affectionate",
      "Sensual",
      "Craves closeness",
      "Expressive through touch"
    ],
    suggestions: [
      "Develop other ways to connect when physical touch isn't possible",
      "Communicate that physical touch is your love language",
      "Find someone equally comfortable with physical intimacy and touch"
    ]
  },
  {
    name: "The Devotee",
    description: "When you love, you love completely. You're all-in, prioritizing your relationship and your partner above most other things. Your loyalty is unshakeable.",
    characteristics: [
      "Deeply loyal",
      "All-in commitment",
      "Partner-focused",
      "Sacrificial love"
    ],
    suggestions: [
      "Maintain your individual identity and friendships outside the relationship",
      "Ensure your devotion is reciprocated",
      "Find someone who won't take advantage of your devotion and reciprocates fully"
    ]
  },
  {
    name: "The Communicator",
    description: "Words are your love language. You need to hear 'I love you,' crave meaningful conversations, and express your feelings verbally. Silent love doesn't register for you.",
    characteristics: [
      "Verbally expressive",
      "Needs verbal affirmation",
      "Deep conversationalist",
      "Articulate emotions"
    ],
    suggestions: [
      "Learn to recognize love expressed through actions, not just words",
      "Be patient with partners who show love differently",
      "Find someone who expresses their feelings openly and enjoys talking"
    ]
  },
  {
    name: "The Quality Timer",
    description: "Undivided attention is how you give and receive love. You crave meaningful time together without distractions. Being truly present is the greatest gift to you.",
    characteristics: [
      "Present-focused",
      "Values undivided attention",
      "Creates meaningful moments",
      "Dislikes distractions"
    ],
    suggestions: [
      "Understand that some people show love through busy schedules juggling responsibilities",
      "Communicate your need for dedicated quality time",
      "Find someone who puts away their phone and gives you their full attention"
    ]
  },
  {
    name: "The Playful Partner",
    description: "Laughter and fun are at the heart of your relationships. You keep things light, enjoy teasing, and believe couples who play together stay together.",
    characteristics: [
      "Humorous",
      "Playful teasing",
      "Keeps romance fun",
      "Avoids heavy drama"
    ],
    suggestions: [
      "Be willing to engage with serious topics when necessary",
      "Balance playfulness with emotional depth",
      "Find someone with a great sense of humor who doesn't take themselves too seriously"
    ]
  },
  {
    name: "The Soulmate Seeker",
    description: "You're searching for 'the one' – that deep, cosmic connection that feels fated. You believe in destiny, twin flames, and love that transcends the ordinary.",
    characteristics: [
      "Spiritually connected",
      "Believes in destiny",
      "Seeks deep soul connection",
      "Idealistic about love"
    ],
    suggestions: [
      "Great relationships are built, not just found – even soulmates require work",
      "Stay open to connections that don't feel instantly cosmic",
      "Find someone who shares your belief in deeper meaning and spiritual connection"
    ]
  },
  {
    name: "The Secure Attacher",
    description: "You have a healthy relationship with intimacy and independence. You're comfortable with closeness and can handle separation without anxiety. You communicate needs clearly.",
    characteristics: [
      "Emotionally stable",
      "Clear communicator",
      "Comfortable with intimacy",
      "Secure in self"
    ],
    suggestions: [
      "Your security is a gift – use it to help partners feel safe too",
      "Be patient with partners who have different attachment styles",
      "You can adapt to different styles – find someone who values healthy communication"
    ]
  },
  {
    name: "The Traditionalist",
    description: "You value classic romance and traditional relationship milestones. Marriage, family, and building a conventional life together are important to you.",
    characteristics: [
      "Values tradition",
      "Milestone-oriented",
      "Family-focused",
      "Conventional romance"
    ],
    suggestions: [
      "Stay open to partners whose timelines differ from yours",
      "Traditional values can coexist with modern flexibility",
      "Find someone who shares your vision of traditional commitment and family"
    ]
  },
  {
    name: "The Modern Lover",
    description: "You reject traditional relationship scripts and create your own rules. You're open to non-traditional arrangements and believe love should be defined by those in it.",
    characteristics: [
      "Non-traditional",
      "Creates own rules",
      "Open-minded about structure",
      "Rejects norms"
    ],
    suggestions: [
      "Communicate your preferences clearly – don't assume others share your flexibility",
      "Be upfront about your relationship style from the start",
      "Find someone equally flexible about relationship definitions and expectations"
    ]
  }
];

// Quiz metadata
const LOVE_LANGUAGE_QUIZ_META = {
  id: "love-language",
  title: "Love Language",
  description: "Discover your romantic communication style, intimacy preferences, and what you need in a partner.",
  questionCount: LOVE_LANGUAGE_QUIZ_ITEMS.length,
  estimatedTime: "10-12 minutes",
  categories: [
    "Romantic Communication",
    "Intimacy",
    "Dating Values",
    "Relationship Dynamics",
    "Commitment"
  ]
};

// Calculate archetype based on answers
function calculateLoveLanguageArchetype(answers) {
  // Score trackers for each category
  let communicationScore = 0;
  let communicationCount = 0;
  let intimacyScore = 0;
  let intimacyCount = 0;
  let valuesScore = 0;
  let valuesCount = 0;
  let dynamicsScore = 0;
  let dynamicsCount = 0;
  let commitmentScore = 0;
  let commitmentCount = 0;

  Object.entries(answers).forEach(([key, value]) => {
    const q = LOVE_LANGUAGE_QUIZ_ITEMS.find(i => i.id === key);
    if (q) {
      switch (q.category) {
        case 'Romantic Communication':
          communicationScore += value;
          communicationCount++;
          break;
        case 'Intimacy':
          intimacyScore += value;
          intimacyCount++;
          break;
        case 'Dating Values':
          valuesScore += value;
          valuesCount++;
          break;
        case 'Relationship Dynamics':
          dynamicsScore += value;
          dynamicsCount++;
          break;
        case 'Commitment':
          commitmentScore += value;
          commitmentCount++;
          break;
      }
    }
  });

  // Calculate averages (0-3 scale where 0 is typically more expressive/open, 3 is more reserved/cautious)
  const avgComm = communicationCount > 0 ? communicationScore / communicationCount : 1.5;
  const avgIntim = intimacyCount > 0 ? intimacyScore / intimacyCount : 1.5;
  const avgVals = valuesCount > 0 ? valuesScore / valuesCount : 1.5;
  const avgDyn = dynamicsCount > 0 ? dynamicsScore / dynamicsCount : 1.5;
  const avgComt = commitmentCount > 0 ? commitmentScore / commitmentCount : 1.5;

  // Overall expressiveness (lower = more expressive/romantic, higher = more reserved/independent)
  const overallAvg = (avgComm + avgIntim + avgVals + avgDyn + avgComt) / 5;

  // Determine archetype based on patterns
  // Physical/Touch focused
  if (avgIntim < 1.2) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[9], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Passionate Lover
  }
  
  // Words/Communication focused  
  if (avgComm < 1.0 && avgIntim > 1.5) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[11], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Communicator
  }
  
  // Very traditional and commitment focused
  if (avgComt < 1.0 && avgVals < 1.5) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[16], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Traditionalist
  }
  
  // Very non-traditional
  if (avgComt > 2.5 && avgVals > 2.0) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[17], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Modern Lover
  }
  
  // All-in devotion
  if (avgDyn < 1.0 && avgComt < 1.5) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[10], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Devotee
  }
  
  // Very secure and balanced
  if (overallAvg >= 1.3 && overallAvg <= 1.8 && Math.abs(avgComm - avgIntim) < 0.5) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[15], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Secure Attacher
  }
  
  // Quality time focused
  if (avgDyn < 1.3 && avgComm > 1.5) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[12], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Quality Timer
  }
  
  // Playful
  if (avgComm < 1.5 && avgIntim > 1.8 && avgDyn < 1.5) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[13], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Playful Partner
  }
  
  // Soulmate seeker - idealistic
  if (avgIntim < 1.5 && avgComt < 1.2) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[14], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Soulmate Seeker
  }
  
  // Protector - acts of service
  if (avgVals < 1.3 && avgDyn > 1.5) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[8], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Protector
  }

  // Original 8 archetypes based on overall patterns
  if (overallAvg < 0.8) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[0], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Hopeless Romantic
  }
  if (avgComm < 1.2 && avgIntim >= 1.5) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[1], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Thoughtful Partner
  }
  if (avgDyn > 2.2 && avgComt > 2.0) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[2], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Independent Spirit
  }
  if (avgIntim < 1.5 && avgVals > 1.8) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[3], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Adventure Seeker
  }
  if (avgComt > 2.0 && avgIntim > 2.0) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[4], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Slow Burn
  }
  if (avgVals < 1.5 && avgComt < 1.8) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[5], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Practical Partner
  }
  if (avgComt > 2.5) {
    return { archetype: LOVE_LANGUAGE_ARCHETYPES[6], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Free Spirit
  }

  // Default to The Balanced One
  return { archetype: LOVE_LANGUAGE_ARCHETYPES[7], scores: { communication: avgComm, intimacy: avgIntim, values: avgVals, dynamics: avgDyn, commitment: avgComt } }; // The Balanced One
}


// Situationship Pattern Pack - 50 Questions
// Helps users understand their relationship patterns and why they might be stuck in undefined connections
// © 2025 GEISTS, LLC. All rights reserved.

const SITUATIONSHIP_QUIZ_ITEMS = [
  // Attachment & Commitment Patterns (15 questions)
  {
    id: "sit_000",
    category: "Attachment",
    text: "How do you typically feel when someone starts showing serious interest in you?",
    options: [
      { value: 0, label: "Excited and ready to explore where it goes" },
      { value: 1, label: "Cautiously optimistic but a bit nervous" },
      { value: 2, label: "Anxious about getting hurt or disappointed" },
      { value: 3, label: "Suddenly less interested or feeling trapped" }
    ]
  },
  {
    id: "sit_001",
    category: "Attachment",
    text: "When do you prefer to define the relationship?",
    options: [
      { value: 0, label: "Early on - I need clarity about where things stand" },
      { value: 1, label: "After a few months when we know each other better" },
      { value: 2, label: "I wait for them to bring it up first" },
      { value: 3, label: "I prefer to keep things undefined and organic" }
    ]
  },
  {
    id: "sit_002",
    category: "Attachment",
    text: "How do you respond when someone you're dating becomes emotionally available?",
    options: [
      { value: 0, label: "I feel more connected and want to deepen things" },
      { value: 1, label: "I appreciate it but take time to reciprocate" },
      { value: 2, label: "I feel pressure to match their emotional intensity" },
      { value: 3, label: "I start to pull back or question the relationship" }
    ]
  },
  {
    id: "sit_003",
    category: "Attachment",
    text: "What usually happens to your past undefined relationships?",
    options: [
      { value: 0, label: "They eventually become defined or end clearly" },
      { value: 1, label: "They naturally evolve or fade out peacefully" },
      { value: 2, label: "They drag on longer than they should" },
      { value: 3, label: "They end abruptly or with confusion" }
    ]
  },
  {
    id: "sit_004",
    category: "Attachment",
    text: "How comfortable are you with relationship labels?",
    options: [
      { value: 0, label: "Very comfortable - labels provide helpful clarity" },
      { value: 1, label: "Somewhat comfortable - depends on the situation" },
      { value: 2, label: "Uncomfortable - they feel restrictive" },
      { value: 3, label: "Very uncomfortable - I actively avoid them" }
    ]
  },
  {
    id: "sit_005",
    category: "Attachment",
    text: "What's your pattern with emotionally unavailable people?",
    options: [
      { value: 0, label: "I recognize it early and move on" },
      { value: 1, label: "I give them time but have clear boundaries" },
      { value: 2, label: "I try to help them open up" },
      { value: 3, label: "I'm often attracted to unavailable people" }
    ]
  },
  {
    id: "sit_006",
    category: "Attachment",
    text: "How do you feel about introducing someone you're dating to friends/family?",
    options: [
      { value: 0, label: "Excited - it's a natural step forward" },
      { value: 1, label: "Open to it when timing feels right" },
      { value: 2, label: "Hesitant - it feels like a big commitment" },
      { value: 3, label: "Resistant - I keep dating life very separate" }
    ]
  },
  {
    id: "sit_007",
    category: "Attachment",
    text: "What happens when you start developing deeper feelings?",
    options: [
      { value: 0, label: "I communicate them openly" },
      { value: 1, label: "I show them through actions gradually" },
      { value: 2, label: "I hide them until I know they feel the same" },
      { value: 3, label: "I distance myself or sabotage the connection" }
    ]
  },
  {
    id: "sit_008",
    category: "Attachment",
    text: "How do you handle someone asking 'What are we?'",
    options: [
      { value: 0, label: "I'm grateful they brought it up and answer honestly" },
      { value: 1, label: "I engage in the conversation thoughtfully" },
      { value: 2, label: "I deflect or say I need more time" },
      { value: 3, label: "I feel panicked or trapped by the question" }
    ]
  },
  {
    id: "sit_009",
    category: "Attachment",
    text: "What's your relationship with being 'exclusive' but not 'official'?",
    options: [
      { value: 0, label: "I see them as basically the same thing" },
      { value: 1, label: "Exclusive is a natural step toward official" },
      { value: 2, label: "I prefer the exclusive-but-not-official phase" },
      { value: 3, label: "I resist both equally" }
    ]
  },
  {
    id: "sit_010",
    category: "Attachment",
    text: "How do you typically end situationships?",
    options: [
      { value: 0, label: "Direct conversation about incompatibility" },
      { value: 1, label: "Gradual honest communication about needs" },
      { value: 2, label: "Slow fade - less contact over time" },
      { value: 3, label: "Ghosting or sudden disappearance" }
    ]
  },
  {
    id: "sit_011",
    category: "Attachment",
    text: "What attracts you most in early dating?",
    options: [
      { value: 0, label: "Emotional availability and clear communication" },
      { value: 1, label: "Balanced interest with mutual effort" },
      { value: 2, label: "Mystery and chase - not knowing where I stand" },
      { value: 3, label: "Physical chemistry above all else" }
    ]
  },
  {
    id: "sit_012",
    category: "Attachment",
    text: "How do you feel about future planning with someone you're dating?",
    options: [
      { value: 0, label: "I naturally include them in future thoughts" },
      { value: 1, label: "I'm open to making plans a few weeks out" },
      { value: 2, label: "I prefer staying present and spontaneous" },
      { value: 3, label: "Future talk makes me want to run" }
    ]
  },
  {
    id: "sit_013",
    category: "Attachment",
    text: "What's your experience with commitment anxiety?",
    options: [
      { value: 0, label: "I rarely experience it" },
      { value: 1, label: "I feel it sometimes but work through it" },
      { value: 2, label: "It's a consistent pattern for me" },
      { value: 3, label: "It controls most of my relationship decisions" }
    ]
  },
  {
    id: "sit_014",
    category: "Attachment",
    text: "How do you handle jealousy in undefined relationships?",
    options: [
      { value: 0, label: "I communicate my feelings and seek clarity" },
      { value: 1, label: "I reflect on whether I want exclusivity" },
      { value: 2, label: "I suffer silently since we're not official" },
      { value: 3, label: "I date other people to avoid feeling jealous" }
    ]
  },

  // Communication & Boundaries (12 questions)
  {
    id: "sit_015",
    category: "Communication",
    text: "How clearly do you express your relationship expectations?",
    options: [
      { value: 0, label: "Very clearly from early on" },
      { value: 1, label: "I communicate them as they become relevant" },
      { value: 2, label: "I hint at them but avoid direct conversation" },
      { value: 3, label: "I keep expectations vague to avoid conflict" }
    ]
  },
  {
    id: "sit_016",
    category: "Communication",
    text: "When you feel confused about where things stand, you:",
    options: [
      { value: 0, label: "Ask directly for clarification" },
      { value: 1, label: "Wait for the right moment to bring it up" },
      { value: 2, label: "Look for hints and clues instead of asking" },
      { value: 3, label: "Assume the worst and protect yourself emotionally" }
    ]
  },
  {
    id: "sit_017",
    category: "Communication",
    text: "How do you respond to mixed signals?",
    options: [
      { value: 0, label: "I address them directly and seek clarity" },
      { value: 1, label: "I observe patterns before deciding to talk" },
      { value: 2, label: "I overthink them and feel anxious" },
      { value: 3, label: "I mirror the mixed signals back" }
    ]
  },
  {
    id: "sit_018",
    category: "Communication",
    text: "How comfortable are you saying 'I need more from this relationship'?",
    options: [
      { value: 0, label: "Very comfortable - my needs matter" },
      { value: 1, label: "Somewhat comfortable with the right person" },
      { value: 2, label: "Uncomfortable - worried about their reaction" },
      { value: 3, label: "Very uncomfortable - I'd rather just leave" }
    ]
  },
  {
    id: "sit_019",
    category: "Communication",
    text: "What's your texting pattern in situationships?",
    options: [
      { value: 0, label: "Consistent and genuine communication" },
      { value: 1, label: "Responsive but not always initiating" },
      { value: 2, label: "Strategic - careful about frequency and timing" },
      { value: 3, label: "Hot and cold - varies by mood/interest level" }
    ]
  },
  {
    id: "sit_020",
    category: "Communication",
    text: "How do you set boundaries in undefined relationships?",
    options: [
      { value: 0, label: "Clearly and directly from the start" },
      { value: 1, label: "I communicate them as situations arise" },
      { value: 2, label: "I struggle to set boundaries without labels" },
      { value: 3, label: "I avoid setting boundaries to keep things casual" }
    ]
  },
  {
    id: "sit_021",
    category: "Communication",
    text: "How do you handle disagreements in situationships?",
    options: [
      { value: 0, label: "Address them directly like any relationship" },
      { value: 1, label: "Discuss them if they're important" },
      { value: 2, label: "Minimize them since we're 'not official'" },
      { value: 3, label: "Avoid conflict entirely or end things" }
    ]
  },
  {
    id: "sit_022",
    category: "Communication",
    text: "What's your approach to emotional vulnerability in early dating?",
    options: [
      { value: 0, label: "I'm open and authentic from the beginning" },
      { value: 1, label: "I gradually share as trust builds" },
      { value: 2, label: "I hold back until they're vulnerable first" },
      { value: 3, label: "I keep things surface-level to protect myself" }
    ]
  },
  {
    id: "sit_023",
    category: "Communication",
    text: "How do you communicate your availability and interest level?",
    options: [
      { value: 0, label: "Directly through words and consistent actions" },
      { value: 1, label: "Through actions more than words" },
      { value: 2, label: "Subtly - letting them figure it out" },
      { value: 3, label: "Ambiguously - keeping options open" }
    ]
  },
  {
    id: "sit_024",
    category: "Communication",
    text: "What happens when someone asks about your past relationships?",
    options: [
      { value: 0, label: "I share openly and honestly" },
      { value: 1, label: "I share highlights and key lessons" },
      { value: 2, label: "I give vague answers" },
      { value: 3, label: "I deflect or change the subject" }
    ]
  },
  {
    id: "sit_025",
    category: "Communication",
    text: "How do you handle 'the talk' about exclusivity?",
    options: [
      { value: 0, label: "I initiate it when I'm ready" },
      { value: 1, label: "I participate openly if they bring it up" },
      { value: 2, label: "I'm hesitant and need time to decide" },
      { value: 3, label: "I avoid it or end things rather than have it" }
    ]
  },
  {
    id: "sit_026",
    category: "Communication",
    text: "How do you handle someone who's breadcrumbing you?",
    options: [
      { value: 0, label: "I call it out and set clear expectations" },
      { value: 1, label: "I match their energy and see if it improves" },
      { value: 2, label: "I keep hoping they'll change" },
      { value: 3, label: "I'm often the one breadcrumbing" }
    ]
  },

  // Self-Awareness & Patterns (12 questions)
  {
    id: "sit_027",
    category: "Self-Awareness",
    text: "How aware are you of your relationship patterns?",
    options: [
      { value: 0, label: "Very aware - I actively reflect on them" },
      { value: 1, label: "Somewhat aware - I notice some patterns" },
      { value: 2, label: "Limited awareness - just starting to notice" },
      { value: 3, label: "Not very aware - patterns surprise me" }
    ]
  },
  {
    id: "sit_028",
    category: "Self-Awareness",
    text: "What role does fear play in your relationship choices?",
    options: [
      { value: 0, label: "Minimal - I make choices from desire, not fear" },
      { value: 1, label: "Some - I notice it but work through it" },
      { value: 2, label: "Significant - fear often influences my choices" },
      { value: 3, label: "Major - fear drives most relationship decisions" }
    ]
  },
  {
    id: "sit_029",
    category: "Self-Awareness",
    text: "How do you typically feel after a situationship ends?",
    options: [
      { value: 0, label: "Clear about what I learned and ready to move forward" },
      { value: 1, label: "Disappointed but understanding it wasn't right" },
      { value: 2, label: "Confused about what went wrong" },
      { value: 3, label: "Stuck ruminating for a long time" }
    ]
  },
  {
    id: "sit_030",
    category: "Self-Awareness",
    text: "What draws you to undefined relationships?",
    options: [
      { value: 0, label: "Nothing - they're not my preference" },
      { value: 1, label: "Sometimes they just happen naturally" },
      { value: 2, label: "The freedom and lack of pressure" },
      { value: 3, label: "Fear of commitment or being fully known" }
    ]
  },
  {
    id: "sit_031",
    category: "Self-Awareness",
    text: "How do you handle being alone between relationships?",
    options: [
      { value: 0, label: "I enjoy it and use it for growth" },
      { value: 1, label: "I'm comfortable but miss partnership" },
      { value: 2, label: "I'm uncomfortable and quickly seek connection" },
      { value: 3, label: "I immediately look for the next person" }
    ]
  },
  {
    id: "sit_032",
    category: "Self-Awareness",
    text: "What patterns do you notice in who you're attracted to?",
    options: [
      { value: 0, label: "Emotionally available people who communicate well" },
      { value: 1, label: "Varied - no clear pattern" },
      { value: 2, label: "People who are inconsistent or hard to read" },
      { value: 3, label: "Emotionally unavailable or avoidant people" }
    ]
  },
  {
    id: "sit_033",
    category: "Self-Awareness",
    text: "How do you define a successful relationship?",
    options: [
      { value: 0, label: "Deep emotional connection and commitment" },
      { value: 1, label: "Mutual respect and healthy communication" },
      { value: 2, label: "Having fun and chemistry without drama" },
      { value: 3, label: "I'm not sure what success looks like" }
    ]
  },
  {
    id: "sit_034",
    category: "Self-Awareness",
    text: "How much do your past experiences influence current dating?",
    options: [
      { value: 0, label: "I've processed them and moved forward" },
      { value: 1, label: "Some influence but I'm aware of it" },
      { value: 2, label: "Significant influence - still healing" },
      { value: 3, label: "Heavy influence - patterns keep repeating" }
    ]
  },
  {
    id: "sit_035",
    category: "Self-Awareness",
    text: "What's your biggest fear in relationships?",
    options: [
      { value: 0, label: "Not finding the right person" },
      { value: 1, label: "Being hurt or disappointed" },
      { value: 2, label: "Losing myself or my independence" },
      { value: 3, label: "Being trapped or controlled" }
    ]
  },
  {
    id: "sit_036",
    category: "Self-Awareness",
    text: "How do you react when someone mirrors your unavailability?",
    options: [
      { value: 0, label: "I don't tend to be unavailable" },
      { value: 1, label: "I appreciate the space but stay connected" },
      { value: 2, label: "It bothers me - I want them to pursue" },
      { value: 3, label: "I suddenly become more interested" }
    ]
  },
  {
    id: "sit_037",
    category: "Self-Awareness",
    text: "What role does self-esteem play in your relationship choices?",
    options: [
      { value: 0, label: "I have healthy self-esteem that guides good choices" },
      { value: 1, label: "Generally positive but occasionally doubt myself" },
      { value: 2, label: "Low self-esteem affects my choices often" },
      { value: 3, label: "I accept less than I deserve regularly" }
    ]
  },
  {
    id: "sit_038",
    category: "Self-Awareness",
    text: "How do you feel about someone who's 'too available'?",
    options: [
      { value: 0, label: "I appreciate their interest and consistency" },
      { value: 1, label: "It's nice but I need them to have their own life" },
      { value: 2, label: "It makes me less interested" },
      { value: 3, label: "It's a major turn-off" }
    ]
  },

  // Emotional Availability (11 questions)
  {
    id: "sit_039",
    category: "Emotional",
    text: "How emotionally available are you right now?",
    options: [
      { value: 0, label: "Very available - ready for real connection" },
      { value: 1, label: "Mostly available - working through minor blocks" },
      { value: 2, label: "Somewhat unavailable - still processing past hurt" },
      { value: 3, label: "Emotionally unavailable - not ready for serious connection" }
    ]
  },
  {
    id: "sit_040",
    category: "Emotional",
    text: "What happens when things start getting 'real'?",
    options: [
      { value: 0, label: "I lean in and embrace deeper connection" },
      { value: 1, label: "I proceed cautiously but stay present" },
      { value: 2, label: "I feel scared and need space" },
      { value: 3, label: "I find reasons why it won't work" }
    ]
  },
  {
    id: "sit_041",
    category: "Emotional",
    text: "How do you show care in early dating?",
    options: [
      { value: 0, label: "Openly through words and thoughtful actions" },
      { value: 1, label: "Primarily through actions and presence" },
      { value: 2, label: "Subtly - afraid of seeming too interested" },
      { value: 3, label: "I hold back to protect myself" }
    ]
  },
  {
    id: "sit_042",
    category: "Emotional",
    text: "How comfortable are you receiving emotional support?",
    options: [
      { value: 0, label: "Very comfortable - I can be vulnerable" },
      { value: 1, label: "Somewhat comfortable with the right person" },
      { value: 2, label: "Uncomfortable - I prefer being self-sufficient" },
      { value: 3, label: "Very uncomfortable - I avoid it" }
    ]
  },
  {
    id: "sit_043",
    category: "Emotional",
    text: "What's your relationship with emotional intimacy?",
    options: [
      { value: 0, label: "I crave and pursue deep emotional connection" },
      { value: 1, label: "I value it but need time to build it" },
      { value: 2, label: "It makes me uncomfortable or vulnerable" },
      { value: 3, label: "I actively avoid it" }
    ]
  },
  {
    id: "sit_044",
    category: "Emotional",
    text: "How do you handle someone being emotionally needy?",
    options: [
      { value: 0, label: "With patience and clear communication about balance" },
      { value: 1, label: "I try to meet their needs while maintaining boundaries" },
      { value: 2, label: "I feel overwhelmed and withdraw" },
      { value: 3, label: "I immediately distance myself" }
    ]
  },
  {
    id: "sit_045",
    category: "Emotional",
    text: "How do you process feelings about someone you're dating?",
    options: [
      { value: 0, label: "I acknowledge them and communicate openly" },
      { value: 1, label: "I reflect privately then share when ready" },
      { value: 2, label: "I suppress them to avoid vulnerability" },
      { value: 3, label: "I distract myself or deny them" }
    ]
  },
  {
    id: "sit_046",
    category: "Emotional",
    text: "What's your capacity for sustained emotional presence?",
    options: [
      { value: 0, label: "High - I can maintain connection consistently" },
      { value: 1, label: "Good - with occasional need for space" },
      { value: 2, label: "Limited - I need frequent breaks" },
      { value: 3, label: "Low - I struggle with sustained connection" }
    ]
  },
  {
    id: "sit_047",
    category: "Emotional",
    text: "How do you respond to someone crying or being very emotional?",
    options: [
      { value: 0, label: "I move toward them and provide comfort" },
      { value: 1, label: "I stay present and ask how I can help" },
      { value: 2, label: "I feel awkward but try to be supportive" },
      { value: 3, label: "I feel uncomfortable and don't know what to do" }
    ]
  },
  {
    id: "sit_048",
    category: "Emotional",
    text: "What's your pattern with vulnerability?",
    options: [
      { value: 0, label: "I share openly and invite reciprocal vulnerability" },
      { value: 1, label: "I'm vulnerable when it feels safe" },
      { value: 2, label: "I'm vulnerable only after they are" },
      { value: 3, label: "I avoid vulnerability at all costs" }
    ]
  },
  {
    id: "sit_049",
    category: "Emotional",
    text: "How ready are you for a committed relationship right now?",
    options: [
      { value: 0, label: "Very ready - actively seeking commitment" },
      { value: 1, label: "Open to it with the right person" },
      { value: 2, label: "Uncertain - says yes but acts unsure" },
      { value: 3, label: "Not ready - prefer keeping things casual" }
    ]
  }
];

// Situationship Archetypes
const SITUATIONSHIP_ARCHETYPES = [
  {
    name: "The Conscious Dater",
    description: "You have strong self-awareness and clear boundaries. You're emotionally available and communicate your needs effectively. Situationships aren't your pattern - you naturally move toward defined relationships or move on.",
    characteristics: [
      "Emotionally available and aware",
      "Sets clear boundaries early",
      "Communicates needs directly",
      "Recognizes incompatibility quickly"
    ],
    suggestions: [
      "Continue trusting your instincts about what you need",
      "Help potential partners understand your communication style",
      "Be patient with those who need more time to open up",
      "Remember that your clarity is a strength, not a flaw"
    ]
  },
  {
    name: "The Anxious Attacher",
    description: "You crave connection but fear rejection, often staying in undefined situations hoping they'll evolve. You're highly attuned to others' emotions but may neglect your own needs. Your relationships lack clarity because you're afraid to rock the boat.",
    characteristics: [
      "Highly relationship-focused",
      "Difficulty setting boundaries",
      "Seeks reassurance frequently",
      "Stays in situations hoping for change"
    ],
    suggestions: [
      "Practice stating your needs without apologizing",
      "Build self-worth independent of relationship status",
      "Notice when you're pursuing emotionally unavailable people",
      "Set a timeline for clarity and honor it",
      "Work on self-soothing anxiety rather than seeking reassurance"
    ]
  },
  {
    name: "The Avoidant Attacher",
    description: "You value independence and feel trapped by commitment. When things get serious, you pull away or find flaws. Situationships feel safer because they don't require full vulnerability or merging of lives.",
    characteristics: [
      "Values independence highly",
      "Uncomfortable with emotional intimacy",
      "Withdraws when things deepen",
      "Keeps dating life compartmentalized"
    ],
    suggestions: [
      "Explore what commitment means to you (it doesn't mean losing yourself)",
      "Practice small acts of vulnerability regularly",
      "Notice when you're self-sabotaging good connections",
      "Work on communicating needs instead of disappearing",
      "Consider whether past hurts are blocking present opportunities"
    ]
  },
  {
    name: "The Healer/Fixer",
    description: "You're drawn to potential rather than reality. You stay in undefined relationships trying to help someone become emotionally available. Your empathy is a gift, but you often give more than you receive.",
    characteristics: [
      "Highly empathetic",
      "Sees potential in partners",
      "Stays in hope of change",
      "Neglects own needs while helping others"
    ],
    suggestions: [
      "Date people for who they are now, not who they could be",
      "Notice the pattern of choosing emotionally unavailable people",
      "Practice receiving as much as you give",
      "Set boundaries around emotional labor",
      "Redirect helping energy toward yourself and your growth"
    ]
  },
  {
    name: "The Serial Situationshipper",
    description: "Multiple undefined relationships is your comfort zone. You might be avoiding deeper work, staying busy with surface connections. You're excellent at starting things but struggle with deepening them.",
    characteristics: [
      "Keeps multiple connections going",
      "Avoids depth and definition",
      "Excellent at surface-level dating",
      "Difficulty sustaining deeper connection"
    ],
    suggestions: [
      "Explore what you're avoiding by keeping things surface",
      "Try being single for a period to understand yourself",
      "Practice staying through discomfort instead of moving on",
      "Build emotional capacity through therapy or self-work",
      "Date with intention rather than distraction"
    ]
  },
  {
    name: "The Fearful Attacher",
    description: "You want connection but fear getting hurt. You send mixed signals because you're genuinely conflicted. You pursue then withdraw, creating the chaos you're trying to avoid. Situationships match your internal ambivalence.",
    characteristics: [
      "Wants closeness but fears it",
      "Sends mixed signals",
      "Inconsistent behavior patterns",
      "Struggles with trust"
    ],
    suggestions: [
      "Work on healing past relationship trauma",
      "Practice consistent behavior even when scared",
      "Communicate your fears instead of acting them out",
      "Build secure friendships as a foundation",
      "Consider therapy to process attachment wounds",
      "Be honest when you're not ready for relationship"
    ]
  }
];

// Calculate archetype based on answers
function calculateSituationshipArchetype(answers) {
  const scores = {
    attachment: 0,
    communication: 0,
    selfAwareness: 0,
    emotional: 0
  };

  let counts = {
    attachment: 0,
    communication: 0,
    selfAwareness: 0,
    emotional: 0
  };

  // Calculate average scores by category
  SITUATIONSHIP_QUIZ_ITEMS.forEach((question) => {
    const answer = answers[question.id];
    if (answer !== undefined && answer !== null) {
      const category = question.category.toLowerCase();
      if (category.includes('attachment')) {
        scores.attachment += answer;
        counts.attachment++;
      } else if (category.includes('communication')) {
        scores.communication += answer;
        counts.communication++;
      } else if (category.includes('self-awareness')) {
        scores.selfAwareness += answer;
        counts.selfAwareness++;
      } else if (category.includes('emotional')) {
        scores.emotional += answer;
        counts.emotional++;
      }
    }
  });

  // Calculate averages
  const avgAttachment = counts.attachment > 0 ? scores.attachment / counts.attachment : 0;
  const avgCommunication = counts.communication > 0 ? scores.communication / counts.communication : 0;
  const avgSelfAwareness = counts.selfAwareness > 0 ? scores.selfAwareness / counts.selfAwareness : 0;
  const avgEmotional = counts.emotional > 0 ? scores.emotional / counts.emotional : 0;

  // Determine archetype based on patterns
  const overallAvg = (avgAttachment + avgCommunication + avgSelfAwareness + avgEmotional) / 4;

  // Conscious Dater: Low scores across the board (healthy patterns)
  if (overallAvg < 1.0) {
    return {
      archetype: SITUATIONSHIP_ARCHETYPES[0],
      scores: {
        attachment: avgAttachment,
        communication: avgCommunication,
        selfAwareness: avgSelfAwareness,
        emotional: avgEmotional
      }
    };
  }

  // Anxious Attacher: High emotional + communication scores, low self-awareness
  if (avgEmotional > 2.0 && avgCommunication > 2.0 && avgSelfAwareness > 1.5) {
    return {
      archetype: SITUATIONSHIP_ARCHETYPES[1],
      scores: {
        attachment: avgAttachment,
        communication: avgCommunication,
        selfAwareness: avgSelfAwareness,
        emotional: avgEmotional
      }
    };
  }

  // Avoidant Attacher: High attachment + emotional avoidance scores
  if (avgAttachment > 2.5 && avgEmotional > 2.5) {
    return {
      archetype: SITUATIONSHIP_ARCHETYPES[2],
      scores: {
        attachment: avgAttachment,
        communication: avgCommunication,
        selfAwareness: avgSelfAwareness,
        emotional: avgEmotional
      }
    };
  }

  // Healer/Fixer: High emotional scores, moderate communication
  if (avgEmotional > 2.0 && avgCommunication < 2.0 && avgAttachment < 2.0) {
    return {
      archetype: SITUATIONSHIP_ARCHETYPES[3],
      scores: {
        attachment: avgAttachment,
        communication: avgCommunication,
        selfAwareness: avgSelfAwareness,
        emotional: avgEmotional
      }
    };
  }

  // Serial Situationshipper: Moderate-high across all, especially attachment avoidance
  if (avgAttachment > 2.0 && overallAvg > 1.8 && overallAvg < 2.5) {
    return {
      archetype: SITUATIONSHIP_ARCHETYPES[4],
      scores: {
        attachment: avgAttachment,
        communication: avgCommunication,
        selfAwareness: avgSelfAwareness,
        emotional: avgEmotional
      }
    };
  }

  // Fearful Attacher: High variability, high attachment + emotional scores
  return {
    archetype: SITUATIONSHIP_ARCHETYPES[5],
    scores: {
      attachment: avgAttachment,
      communication: avgCommunication,
      selfAwareness: avgSelfAwareness,
      emotional: avgEmotional
    }
  };
}



// Self-Sabotage Pack - 50 Questions
// Identifies behaviors that hold you back and strategies to break free from limiting patterns
// © 2025 GEISTS, LLC. All rights reserved.

const SELF_SABOTAGE_QUIZ_ITEMS = [
  // Fear & Resistance Patterns (13 questions)
  {
    id: "sab_000",
    category: "Fear",
    text: "When something good is happening in your life, you typically:",
    options: [
      { value: 0, label: "Feel grateful and enjoy it fully" },
      { value: 1, label: "Feel happy but slightly worried it won't last" },
      { value: 2, label: "Wait for the other shoe to drop" },
      { value: 3, label: "Find ways to undermine or complicate it" }
    ]
  },
  {
    id: "sab_001",
    category: "Fear",
    text: "How do you respond when someone compliments you?",
    options: [
      { value: 0, label: "Accept it graciously and say thank you" },
      { value: 1, label: "Feel pleased but slightly uncomfortable" },
      { value: 2, label: "Deflect or minimize the compliment" },
      { value: 3, label: "Reject it or point out why they're wrong" }
    ]
  },
  {
    id: "sab_002",
    category: "Fear",
    text: "When you're close to achieving a goal, you:",
    options: [
      { value: 0, label: "Push through with excitement and determination" },
      { value: 1, label: "Feel nervous but stay committed" },
      { value: 2, label: "Start doubting yourself or procrastinating" },
      { value: 3, label: "Often give up or create obstacles" }
    ]
  },
  {
    id: "sab_003",
    category: "Fear",
    text: "What's your relationship with success?",
    options: [
      { value: 0, label: "I feel worthy of success and work toward it" },
      { value: 1, label: "I want success but sometimes doubt I deserve it" },
      { value: 2, label: "Success makes me uncomfortable or guilty" },
      { value: 3, label: "I fear success more than failure" }
    ]
  },
  {
    id: "sab_004",
    category: "Fear",
    text: "How do you handle positive attention?",
    options: [
      { value: 0, label: "I receive it comfortably" },
      { value: 1, label: "I appreciate it but feel a bit self-conscious" },
      { value: 2, label: "I feel anxious and want to hide" },
      { value: 3, label: "I actively avoid or deflect it" }
    ]
  },
  {
    id: "sab_005",
    category: "Fear",
    text: "When you start succeeding at something new, you:",
    options: [
      { value: 0, label: "Feel proud and motivated to continue" },
      { value: 1, label: "Feel good but wonder if it's beginner's luck" },
      { value: 2, label: "Start questioning if you really deserve it" },
      { value: 3, label: "Find ways to quit or mess it up" }
    ]
  },
  {
    id: "sab_006",
    category: "Fear",
    text: "What happens when things are going 'too well'?",
    options: [
      { value: 0, label: "I appreciate it and stay present" },
      { value: 1, label: "I feel grateful but slightly anxious" },
      { value: 2, label: "I brace for something bad to happen" },
      { value: 3, label: "I unconsciously create problems or drama" }
    ]
  },
  {
    id: "sab_007",
    category: "Fear",
    text: "How comfortable are you with being happy?",
    options: [
      { value: 0, label: "Very comfortable - I embrace happiness" },
      { value: 1, label: "Mostly comfortable with occasional guilt" },
      { value: 2, label: "Uncomfortable - happiness feels unsafe" },
      { value: 3, label: "Very uncomfortable - I distrust good feelings" }
    ]
  },
  {
    id: "sab_008",
    category: "Fear",
    text: "When someone treats you really well, you:",
    options: [
      { value: 0, label: "Feel grateful and treat them well in return" },
      { value: 1, label: "Appreciate it but wonder why they're so nice" },
      { value: 2, label: "Question their motives or authenticity" },
      { value: 3, label: "Push them away or test them" }
    ]
  },
  {
    id: "sab_009",
    category: "Fear",
    text: "What's your relationship with receiving help?",
    options: [
      { value: 0, label: "I accept help graciously when needed" },
      { value: 1, label: "I accept but feel like I owe them" },
      { value: 2, label: "I'm uncomfortable and prefer to struggle alone" },
      { value: 3, label: "I refuse help even when I need it" }
    ]
  },
  {
    id: "sab_010",
    category: "Fear",
    text: "How do you respond to opportunities?",
    options: [
      { value: 0, label: "I evaluate and pursue exciting opportunities" },
      { value: 1, label: "I consider them carefully but sometimes overthink" },
      { value: 2, label: "I doubt whether I'm qualified or ready" },
      { value: 3, label: "I talk myself out of them or self-reject" }
    ]
  },
  {
    id: "sab_011",
    category: "Fear",
    text: "What's your inner dialogue about your worthiness?",
    options: [
      { value: 0, label: "I'm worthy of good things" },
      { value: 1, label: "I'm working on believing I'm worthy" },
      { value: 2, label: "I struggle to feel worthy" },
      { value: 3, label: "I fundamentally don't feel worthy" }
    ]
  },
  {
    id: "sab_012",
    category: "Fear",
    text: "When you imagine your ideal future, you:",
    options: [
      { value: 0, label: "Feel excited and motivated" },
      { value: 1, label: "Feel hopeful but realistic" },
      { value: 2, label: "Feel doubtful it could happen for you" },
      { value: 3, label: "Can't let yourself imagine it" }
    ]
  },

  // Self-Destructive Behaviors (12 questions)
  {
    id: "sab_013",
    category: "Behavior",
    text: "How often do you procrastinate on important things?",
    options: [
      { value: 0, label: "Rarely - I handle important tasks promptly" },
      { value: 1, label: "Sometimes - usually work through it" },
      { value: 2, label: "Often - it causes problems" },
      { value: 3, label: "Constantly - it's a major pattern" }
    ]
  },
  {
    id: "sab_014",
    category: "Behavior",
    text: "When stressed, you're most likely to:",
    options: [
      { value: 0, label: "Use healthy coping strategies" },
      { value: 1, label: "Mix healthy and unhealthy coping" },
      { value: 2, label: "Turn to avoidance or numbing behaviors" },
      { value: 3, label: "Engage in clearly self-destructive behaviors" }
    ]
  },
  {
    id: "sab_015",
    category: "Behavior",
    text: "How do you handle conflict in relationships?",
    options: [
      { value: 0, label: "Address it directly with care" },
      { value: 1, label: "Try to resolve it but sometimes avoid" },
      { value: 2, label: "Avoid it or blow it out of proportion" },
      { value: 3, label: "Create bigger conflict or sabotage the relationship" }
    ]
  },
  {
    id: "sab_016",
    category: "Behavior",
    text: "When you commit to something, you:",
    options: [
      { value: 0, label: "Follow through consistently" },
      { value: 1, label: "Usually follow through with occasional slip-ups" },
      { value: 2, label: "Start strong but often don't finish" },
      { value: 3, label: "Rarely follow through on commitments" }
    ]
  },
  {
    id: "sab_017",
    category: "Behavior",
    text: "How do you treat yourself when you make a mistake?",
    options: [
      { value: 0, label: "With compassion and learning mindset" },
      { value: 1, label: "With some self-criticism but overall kindness" },
      { value: 2, label: "Harshly - I'm very self-critical" },
      { value: 3, label: "Brutally - I punish myself mentally" }
    ]
  },
  {
    id: "sab_018",
    category: "Behavior",
    text: "What's your pattern with healthy habits?",
    options: [
      { value: 0, label: "I maintain them consistently" },
      { value: 1, label: "I maintain them but occasionally slip" },
      { value: 2, label: "I start and stop frequently" },
      { value: 3, label: "I actively resist healthy habits" }
    ]
  },
  {
    id: "sab_019",
    category: "Behavior",
    text: "How do you respond to your own boundaries?",
    options: [
      { value: 0, label: "I set and honor them" },
      { value: 1, label: "I set them but sometimes compromise" },
      { value: 2, label: "I set them but regularly violate them" },
      { value: 3, label: "I don't set boundaries for myself" }
    ]
  },
  {
    id: "sab_020",
    category: "Behavior",
    text: "When you're doing well, your habits:",
    options: [
      { value: 0, label: "Stay consistent - they support my success" },
      { value: 1, label: "Stay mostly consistent" },
      { value: 2, label: "Start to slip - I relax too much" },
      { value: 3, label: "Fall apart - I self-sabotage success" }
    ]
  },
  {
    id: "sab_021",
    category: "Behavior",
    text: "How do you handle success or progress?",
    options: [
      { value: 0, label: "Build on it and keep momentum" },
      { value: 1, label: "Celebrate then refocus" },
      { value: 2, label: "Downplay it and lose momentum" },
      { value: 3, label: "Undermine it through poor choices" }
    ]
  },
  {
    id: "sab_022",
    category: "Behavior",
    text: "What's your relationship with self-care?",
    options: [
      { value: 0, label: "It's a priority I maintain consistently" },
      { value: 1, label: "I practice it but not always consistently" },
      { value: 2, label: "I know I should but rarely do it" },
      { value: 3, label: "I actively neglect myself" }
    ]
  },
  {
    id: "sab_023",
    category: "Behavior",
    text: "How often do you keep promises to yourself?",
    options: [
      { value: 0, label: "Almost always" },
      { value: 1, label: "Usually" },
      { value: 2, label: "Sometimes" },
      { value: 3, label: "Rarely" }
    ]
  },
  {
    id: "sab_024",
    category: "Behavior",
    text: "When things get hard, you:",
    options: [
      { value: 0, label: "Push through with determination" },
      { value: 1, label: "Keep going with support" },
      { value: 2, label: "Consider quitting but usually don't" },
      { value: 3, label: "Give up or self-sabotage" }
    ]
  },

  // Beliefs & Self-Talk (13 questions)
  {
    id: "sab_025",
    category: "Beliefs",
    text: "What's your most common self-talk?",
    options: [
      { value: 0, label: "Encouraging and supportive" },
      { value: 1, label: "Mostly positive with some criticism" },
      { value: 2, label: "Critical and doubting" },
      { value: 3, label: "Harsh and defeating" }
    ]
  },
  {
    id: "sab_026",
    category: "Beliefs",
    text: "How do you view your past failures?",
    options: [
      { value: 0, label: "As learning experiences and growth opportunities" },
      { value: 1, label: "Disappointed but understanding" },
      { value: 2, label: "As evidence of my inadequacy" },
      { value: 3, label: "As proof I'll never succeed" }
    ]
  },
  {
    id: "sab_027",
    category: "Beliefs",
    text: "What do you believe you deserve?",
    options: [
      { value: 0, label: "Love, success, and happiness" },
      { value: 1, label: "Good things but I have to earn them" },
      { value: 2, label: "Only what I can achieve through struggle" },
      { value: 3, label: "Not much - good things happen to others" }
    ]
  },
  {
    id: "sab_028",
    category: "Beliefs",
    text: "How do you explain your successes to yourself?",
    options: [
      { value: 0, label: "I earned them through effort and ability" },
      { value: 1, label: "Combination of my work and good timing" },
      { value: 2, label: "Mostly luck or external factors" },
      { value: 3, label: "Accident, luck, or others' mistakes" }
    ]
  },
  {
    id: "sab_029",
    category: "Beliefs",
    text: "What's your core belief about yourself?",
    options: [
      { value: 0, label: "I'm capable and worthy" },
      { value: 1, label: "I'm okay but flawed" },
      { value: 2, label: "I'm fundamentally flawed but trying" },
      { value: 3, label: "I'm broken or not enough" }
    ]
  },
  {
    id: "sab_030",
    category: "Beliefs",
    text: "When you look in the mirror, your first thought is:",
    options: [
      { value: 0, label: "Positive or neutral acceptance" },
      { value: 1, label: "Mixed - some positive, some critical" },
      { value: 2, label: "Primarily critical" },
      { value: 3, label: "Harsh and rejecting" }
    ]
  },
  {
    id: "sab_031",
    category: "Beliefs",
    text: "How do you complete this: 'People like me...'",
    options: [
      { value: 0, label: "'...can achieve their goals'" },
      { value: 1, label: "'...have to work hard for everything'" },
      { value: 2, label: "'...don't usually get lucky breaks'" },
      { value: 3, label: "'...don't deserve good things'" }
    ]
  },
  {
    id: "sab_032",
    category: "Beliefs",
    text: "What's your relationship with your potential?",
    options: [
      { value: 0, label: "I'm actively working to reach it" },
      { value: 1, label: "I believe in it but face obstacles" },
      { value: 2, label: "I doubt I have much potential" },
      { value: 3, label: "I don't believe I have meaningful potential" }
    ]
  },
  {
    id: "sab_033",
    category: "Beliefs",
    text: "How do you view your worthiness of love?",
    options: [
      { value: 0, label: "I'm worthy of love as I am" },
      { value: 1, label: "I'm worthy but need to work on myself" },
      { value: 2, label: "I'll be worthy when I'm better/different" },
      { value: 3, label: "I'm fundamentally unworthy of real love" }
    ]
  },
  {
    id: "sab_034",
    category: "Beliefs",
    text: "When you achieve something, your inner voice says:",
    options: [
      { value: 0, label: "'I did it! I'm proud of myself'" },
      { value: 1, label: "'That's good, but I could have done better'" },
      { value: 2, label: "'That wasn't really that hard/impressive'" },
      { value: 3, label: "'Anyone could have done that'" }
    ]
  },
  {
    id: "sab_035",
    category: "Beliefs",
    text: "What do you believe about change?",
    options: [
      { value: 0, label: "I can change and grow" },
      { value: 1, label: "Change is possible but difficult" },
      { value: 2, label: "Real change is unlikely for me" },
      { value: 3, label: "I can't really change who I am" }
    ]
  },
  {
    id: "sab_036",
    category: "Beliefs",
    text: "How do you view your mistakes?",
    options: [
      { value: 0, label: "Natural part of learning and growth" },
      { value: 1, label: "Disappointing but not defining" },
      { value: 2, label: "Evidence of my inadequacy" },
      { value: 3, label: "Proof I'll always fail" }
    ]
  },
  {
    id: "sab_037",
    category: "Beliefs",
    text: "What's your belief about happiness?",
    options: [
      { value: 0, label: "I deserve to be happy" },
      { value: 1, label: "Happiness is earned through effort" },
      { value: 2, label: "Happiness is for other people" },
      { value: 3, label: "I don't deserve lasting happiness" }
    ]
  },

  // Patterns & Awareness (12 questions)
  {
    id: "sab_038",
    category: "Patterns",
    text: "How aware are you of your self-sabotaging patterns?",
    options: [
      { value: 0, label: "Very aware - I actively work on them" },
      { value: 1, label: "Somewhat aware - I'm learning" },
      { value: 2, label: "Limited awareness - patterns surprise me" },
      { value: 3, label: "Not aware - I don't see the patterns" }
    ]
  },
  {
    id: "sab_039",
    category: "Patterns",
    text: "When you notice yourself self-sabotaging, you:",
    options: [
      { value: 0, label: "Stop and redirect to healthier choices" },
      { value: 1, label: "Notice but don't always stop it" },
      { value: 2, label: "Notice but feel powerless to stop" },
      { value: 3, label: "Don't notice until after the damage" }
    ]
  },
  {
    id: "sab_040",
    category: "Patterns",
    text: "How often do you repeat the same self-destructive patterns?",
    options: [
      { value: 0, label: "Rarely - I learn and change" },
      { value: 1, label: "Sometimes - working on breaking cycles" },
      { value: 2, label: "Often - same patterns keep emerging" },
      { value: 3, label: "Constantly - feel stuck in loops" }
    ]
  },
  {
    id: "sab_041",
    category: "Patterns",
    text: "What triggers your self-sabotage most?",
    options: [
      { value: 0, label: "I've identified and manage my triggers" },
      { value: 1, label: "Success, intimacy, or vulnerability" },
      { value: 2, label: "Stress or any discomfort" },
      { value: 3, label: "Almost anything good happening" }
    ]
  },
  {
    id: "sab_042",
    category: "Patterns",
    text: "How do your relationships typically end?",
    options: [
      { value: 0, label: "Mutual decision or clear incompatibility" },
      { value: 1, label: "Natural drifting or honest conversations" },
      { value: 2, label: "Me pushing them away or creating distance" },
      { value: 3, label: "Me sabotaging when things get good" }
    ]
  },
  {
    id: "sab_043",
    category: "Patterns",
    text: "What's your pattern with opportunities?",
    options: [
      { value: 0, label: "I recognize and pursue them" },
      { value: 1, label: "I sometimes hesitate but usually go for it" },
      { value: 2, label: "I often let them pass" },
      { value: 3, label: "I actively avoid or ruin them" }
    ]
  },
  {
    id: "sab_044",
    category: "Patterns",
    text: "How do you handle periods of stability?",
    options: [
      { value: 0, label: "I appreciate and maintain them" },
      { value: 1, label: "I enjoy them but worry a bit" },
      { value: 2, label: "I feel uncomfortable and restless" },
      { value: 3, label: "I unconsciously create chaos" }
    ]
  },
  {
    id: "sab_045",
    category: "Patterns",
    text: "What happens when you're close to a breakthrough?",
    options: [
      { value: 0, label: "I push through to achieve it" },
      { value: 1, label: "I feel resistance but work through it" },
      { value: 2, label: "I often quit right before succeeding" },
      { value: 3, label: "I always sabotage right at the finish line" }
    ]
  },
  {
    id: "sab_046",
    category: "Patterns",
    text: "How much do you repeat your family's patterns?",
    options: [
      { value: 0, label: "I've broken unhealthy family patterns" },
      { value: 1, label: "I'm working on breaking them" },
      { value: 2, label: "I repeat many of them" },
      { value: 3, label: "I'm living out the same patterns" }
    ]
  },
  {
    id: "sab_047",
    category: "Patterns",
    text: "What's your relationship with therapy or self-work?",
    options: [
      { value: 0, label: "Active participant in my growth" },
      { value: 1, label: "I do some self-work regularly" },
      { value: 2, label: "I know I should but resist" },
      { value: 3, label: "I avoid it or sabotage the process" }
    ]
  },
  {
    id: "sab_048",
    category: "Patterns",
    text: "When you identify a pattern, you:",
    options: [
      { value: 0, label: "Create a plan to change it" },
      { value: 1, label: "Try to change but struggle" },
      { value: 2, label: "Feel aware but helpless" },
      { value: 3, label: "Continue the pattern anyway" }
    ]
  },
  {
    id: "sab_049",
    category: "Patterns",
    text: "How ready are you to change your self-sabotaging patterns?",
    options: [
      { value: 0, label: "Very ready - actively working on change" },
      { value: 1, label: "Ready but need support" },
      { value: 2, label: "Ambivalent - want change but scared" },
      { value: 3, label: "Not ready - patterns feel safer than change" }
    ]
  }
];

// Self-Sabotage Archetypes
const SELF_SABOTAGE_ARCHETYPES = [
  {
    name: "The Self-Aware Overcomer",
    description: "You have strong awareness of any self-limiting patterns and actively work to overcome them. You practice self-compassion, maintain healthy habits, and believe in your capacity for growth and change.",
    characteristics: [
      "High self-awareness",
      "Practices self-compassion",
      "Maintains healthy boundaries and habits",
      "Growth-oriented mindset"
    ],
    suggestions: [
      "Continue your self-work and celebrate progress",
      "Share your growth practices with others",
      "Stay vigilant during stressful periods",
      "Remember that maintaining growth is also growth"
    ]
  },
  {
    name: "The Imposter",
    description: "Despite evidence of your capabilities, you doubt your worthiness and attribute success to luck or external factors. You fear being 'found out' and unconsciously undermine your achievements to match your internal self-image.",
    characteristics: [
      "Attributes success to external factors",
      "Persistent self-doubt despite evidence",
      "Fear of being exposed as fraud",
      "Difficulty internalizing achievements"
    ],
    suggestions: [
      "Keep a success journal documenting your contributions",
      "Challenge thoughts about luck with evidence",
      "Practice accepting compliments without deflecting",
      "Work with a therapist on core beliefs about worthiness",
      "Connect with others who experience imposter syndrome"
    ]
  },
  {
    name: "The Upper Limit Problem",
    description: "You unconsciously have a 'set point' for how much success, love, or happiness you can tolerate. When you exceed it, you self-sabotage back to your comfort zone. Good things make you anxious because they feel unfamiliar.",
    characteristics: [
      "Sabotages when things go well",
      "Discomfort with sustained happiness",
      "Creates problems during good times",
      "Has a tolerance ceiling for good feelings"
    ],
    suggestions: [
      "Read 'The Big Leap' by Gay Hendricks",
      "Practice tolerating good feelings in small doses",
      "Notice when you're about to self-sabotage and pause",
      "Work on expanding your capacity for happiness",
      "Challenge beliefs about deserving good things"
    ]
  },
  {
    name: "The Perfectionist Procrastinator",
    description: "Your impossibly high standards paralyze you. You procrastinate because you fear failure, so you protect your ego by not really trying. 'I didn't fail, I just didn't do my best' becomes your shield against vulnerability.",
    characteristics: [
      "All-or-nothing thinking",
      "Chronic procrastination",
      "Fear of failure prevents action",
      "Uses lack of effort as excuse"
    ],
    suggestions: [
      "Practice 'good enough' rather than perfect",
      "Set process goals instead of outcome goals",
      "Take small imperfect actions daily",
      "Work on separating self-worth from performance",
      "Challenge perfectionist thoughts with evidence"
    ]
  },
  {
    name: "The Repeater",
    description: "You repeat the same painful patterns across relationships, jobs, and life situations. You might be unconsciously recreating family dynamics or trying to master old wounds. The patterns feel familiar, even when they hurt.",
    characteristics: [
      "Repeats same patterns across life areas",
      "Attracts similar situations repeatedly",
      "Comfort with familiar dysfunction",
      "Limited awareness of patterns"
    ],
    suggestions: [
      "Work with a therapist on family-of-origin issues",
      "Journal about patterns across different life areas",
      "Pause before making major decisions - is this the pattern?",
      "Build new neural pathways through different choices",
      "Surround yourself with people who model healthier patterns"
    ]
  },
  {
    name: "The Self-Punisher",
    description: "You carry deep shame or guilt and punish yourself through self-sabotage. You don't believe you deserve good things, so you unconsciously ensure you don't have them. Your inner critic is brutal and constant.",
    characteristics: [
      "Harsh, punitive self-talk",
      "Deep-seated shame or guilt",
      "Believes suffering is deserved",
      "Actively denies self good things"
    ],
    suggestions: [
      "Seek therapy - this requires professional support",
      "Practice self-compassion exercises daily",
      "Work on trauma healing (EMDR, IFS, somatic work)",
      "Challenge beliefs about deserving punishment",
      "Build relationship with inner child work",
      "Consider whether religious or family shame needs processing"
    ]
  }
];

// Calculate archetype based on answers
function calculateSelfSabotageArchetype(answers) {
  const scores = {
    fear: 0,
    behavior: 0,
    beliefs: 0,
    patterns: 0
  };

  let counts = {
    fear: 0,
    behavior: 0,
    beliefs: 0,
    patterns: 0
  };

  // Calculate average scores by category
  SELF_SABOTAGE_QUIZ_ITEMS.forEach((question) => {
    const answer = answers[question.id];
    if (answer !== undefined && answer !== null) {
      const category = question.category.toLowerCase();
      if (category.includes('fear')) {
        scores.fear += answer;
        counts.fear++;
      } else if (category.includes('behavior')) {
        scores.behavior += answer;
        counts.behavior++;
      } else if (category.includes('beliefs')) {
        scores.beliefs += answer;
        counts.beliefs++;
      } else if (category.includes('patterns')) {
        scores.patterns += answer;
        counts.patterns++;
      }
    }
  });

  // Calculate averages
  const avgFear = counts.fear > 0 ? scores.fear / counts.fear : 0;
  const avgBehavior = counts.behavior > 0 ? scores.behavior / counts.behavior : 0;
  const avgBeliefs = counts.beliefs > 0 ? scores.beliefs / counts.beliefs : 0;
  const avgPatterns = counts.patterns > 0 ? scores.patterns / counts.patterns : 0;

  // Determine archetype based on patterns
  const overallAvg = (avgFear + avgBehavior + avgBeliefs + avgPatterns) / 4;

  // Self-Aware Overcomer: Low scores across the board
  if (overallAvg < 1.0) {
    return {
      archetype: SELF_SABOTAGE_ARCHETYPES[0],
      scores: {
        fear: avgFear,
        behavior: avgBehavior,
        beliefs: avgBeliefs,
        patterns: avgPatterns
      }
    };
  }

  // Imposter: High beliefs scores, moderate behavior
  if (avgBeliefs > 2.5 && avgBehavior < 2.0) {
    return {
      archetype: SELF_SABOTAGE_ARCHETYPES[1],
      scores: {
        fear: avgFear,
        behavior: avgBehavior,
        beliefs: avgBeliefs,
        patterns: avgPatterns
      }
    };
  }

  // Upper Limit Problem: High fear, moderate-high behavior during success
  if (avgFear > 2.5 && avgBehavior > 2.0) {
    return {
      archetype: SELF_SABOTAGE_ARCHETYPES[2],
      scores: {
        fear: avgFear,
        behavior: avgBehavior,
        beliefs: avgBeliefs,
        patterns: avgPatterns
      }
    };
  }

  // Perfectionist Procrastinator: High behavior + beliefs, moderate fear
  if (avgBehavior > 2.5 && avgBeliefs > 2.0) {
    return {
      archetype: SELF_SABOTAGE_ARCHETYPES[3],
      scores: {
        fear: avgFear,
        behavior: avgBehavior,
        beliefs: avgBeliefs,
        patterns: avgPatterns
      }
    };
  }

  // Repeater: High patterns score
  if (avgPatterns > 2.5) {
    return {
      archetype: SELF_SABOTAGE_ARCHETYPES[4],
      scores: {
        fear: avgFear,
        behavior: avgBehavior,
        beliefs: avgBeliefs,
        patterns: avgPatterns
      }
    };
  }

  // Self-Punisher: High across all categories
  return {
    archetype: SELF_SABOTAGE_ARCHETYPES[5],
    scores: {
      fear: avgFear,
      behavior: avgBehavior,
      beliefs: avgBeliefs,
      patterns: avgPatterns
    }
  };
}



// Social Battery Pack - 50 Questions
// Learn your social energy levels and how to recharge effectively while maintaining meaningful connections
// © 2025 GEISTS, LLC. All rights reserved.

const SOCIAL_BATTERY_QUIZ_ITEMS = [
  // Energy & Recharge Patterns (15 questions)
  {
    id: "soc_000",
    category: "Energy",
    text: "After spending time with people, you typically feel:",
    options: [
      { value: 0, label: "Energized and wanting more social time" },
      { value: 1, label: "Content but ready for some alone time" },
      { value: 2, label: "Drained and need to recharge alone" },
      { value: 3, label: "Completely exhausted and depleted" }
    ]
  },
  {
    id: "soc_001",
    category: "Energy",
    text: "How do you recharge your social battery?",
    options: [
      { value: 0, label: "Being around people energizes me" },
      { value: 1, label: "Mix of social time and solo activities" },
      { value: 2, label: "Quiet alone time with minimal stimulation" },
      { value: 3, label: "Complete isolation and solitude" }
    ]
  },
  {
    id: "soc_002",
    category: "Energy",
    text: "How much alone time do you need daily?",
    options: [
      { value: 0, label: "Very little - I thrive on social interaction" },
      { value: 1, label: "1-2 hours to decompress" },
      { value: 2, label: "3-4 hours to feel recharged" },
      { value: 3, label: "Most of my day - minimal social interaction" }
    ]
  },
  {
    id: "soc_003",
    category: "Energy",
    text: "After a full day of work/socializing, you prefer to:",
    options: [
      { value: 0, label: "Go out with friends or attend events" },
      { value: 1, label: "Have quiet dinner with close friend/partner" },
      { value: 2, label: "Be alone and do calming activities" },
      { value: 3, label: "Be completely alone in silence" }
    ]
  },
  {
    id: "soc_004",
    category: "Energy",
    text: "How do you feel about surprise visitors or calls?",
    options: [
      { value: 0, label: "Excited! Always happy for unexpected connection" },
      { value: 1, label: "Depends on my mood and energy level" },
      { value: 2, label: "Usually not happy - I need advance notice" },
      { value: 3, label: "Extremely uncomfortable - major boundary violation" }
    ]
  },
  {
    id: "soc_005",
    category: "Energy",
    text: "Your ideal weekend includes:",
    options: [
      { value: 0, label: "Multiple social activities and events" },
      { value: 1, label: "Balance of social plans and downtime" },
      { value: 2, label: "Mostly alone with one social activity" },
      { value: 3, label: "Complete solitude and no social obligations" }
    ]
  },
  {
    id: "soc_006",
    category: "Energy",
    text: "How quickly does your social battery drain?",
    options: [
      { value: 0, label: "Rarely drains - social time charges me" },
      { value: 1, label: "Gradually - can do several hours before needing break" },
      { value: 2, label: "Relatively quickly - 2-3 hours is my limit" },
      { value: 3, label: "Very quickly - I'm drained within an hour" }
    ]
  },
  {
    id: "soc_007",
    category: "Energy",
    text: "How do you feel about small talk?",
    options: [
      { value: 0, label: "I enjoy it - it's a way to connect" },
      { value: 1, label: "It's fine but I prefer deeper conversation" },
      { value: 2, label: "It drains me - I find it superficial" },
      { value: 3, label: "I actively avoid it - it's exhausting" }
    ]
  },
  {
    id: "soc_008",
    category: "Energy",
    text: "When your battery is low, you:",
    options: [
      { value: 0, label: "Rarely happens - I thrive in social settings" },
      { value: 1, label: "Take a short break then return to socializing" },
      { value: 2, label: "Need several hours alone to recover" },
      { value: 3, label: "Need a full day or more of isolation" }
    ]
  },
  {
    id: "soc_009",
    category: "Energy",
    text: "How do you feel in large groups?",
    options: [
      { value: 0, label: "Excited and energized" },
      { value: 1, label: "Okay if I can have smaller conversations" },
      { value: 2, label: "Uncomfortable and overwhelmed" },
      { value: 3, label: "Extremely anxious and depleted" }
    ]
  },
  {
    id: "soc_010",
    category: "Energy",
    text: "Your energy pattern throughout the day is:",
    options: [
      { value: 0, label: "Builds with social interaction" },
      { value: 1, label: "Steady with social breaks" },
      { value: 2, label: "Depletes with social interaction" },
      { value: 3, label: "Rapidly depletes - protective of energy" }
    ]
  },
  {
    id: "soc_011",
    category: "Energy",
    text: "How do you recover from a social event that drained you?",
    options: [
      { value: 0, label: "Don't usually feel drained from social events" },
      { value: 1, label: "Quick rest then back to normal" },
      { value: 2, label: "Need several hours of quiet time" },
      { value: 3, label: "Need a full day or more to recover" }
    ]
  },
  {
    id: "soc_012",
    category: "Energy",
    text: "How do you feel about back-to-back social commitments?",
    options: [
      { value: 0, label: "Love it! More the merrier" },
      { value: 1, label: "Can handle it occasionally" },
      { value: 2, label: "Avoid it - need buffer time between" },
      { value: 3, label: "Never do it - would completely drain me" }
    ]
  },
  {
    id: "soc_013",
    category: "Energy",
    text: "When you're low energy, social interaction feels:",
    options: [
      { value: 0, label: "Helpful - it lifts my mood" },
      { value: 1, label: "Neutral - depends on the interaction" },
      { value: 2, label: "Challenging - I push through" },
      { value: 3, label: "Impossible - I avoid it entirely" }
    ]
  },
  {
    id: "soc_014",
    category: "Energy",
    text: "How do you feel about being alone for extended periods?",
    options: [
      { value: 0, label: "Lonely and restless" },
      { value: 1, label: "Fine for a while, then miss people" },
      { value: 2, label: "Comfortable and peaceful" },
      { value: 3, label: "Ideal - I thrive in solitude" }
    ]
  },

  // Social Preferences & Boundaries (13 questions)
  {
    id: "soc_015",
    category: "Preferences",
    text: "Your ideal social gathering size is:",
    options: [
      { value: 0, label: "Large party or event (20+ people)" },
      { value: 1, label: "Medium gathering (8-15 people)" },
      { value: 2, label: "Small group (3-5 people)" },
      { value: 3, label: "One-on-one only" }
    ]
  },
  {
    id: "soc_016",
    category: "Preferences",
    text: "How do you prefer to socialize?",
    options: [
      { value: 0, label: "Frequent, varied social activities" },
      { value: 1, label: "Regular meetups with established friends" },
      { value: 2, label: "Infrequent but meaningful gatherings" },
      { value: 3, label: "Very rare, carefully selected interactions" }
    ]
  },
  {
    id: "soc_017",
    category: "Preferences",
    text: "How do you feel about phone calls?",
    options: [
      { value: 0, label: "Love them - prefer talking to texting" },
      { value: 1, label: "Fine for close friends/family" },
      { value: 2, label: "Avoid when possible - prefer text" },
      { value: 3, label: "Rarely answer - cause anxiety" }
    ]
  },
  {
    id: "soc_018",
    category: "Preferences",
    text: "Your stance on last-minute plans:",
    options: [
      { value: 0, label: "Love spontaneity - usually say yes" },
      { value: 1, label: "Open to it if I have energy" },
      { value: 2, label: "Prefer advance notice - usually decline" },
      { value: 3, label: "Almost never accept - need mental preparation" }
    ]
  },
  {
    id: "soc_019",
    category: "Preferences",
    text: "How many close friends do you need?",
    options: [
      { value: 0, label: "Many - I have a large social circle" },
      { value: 1, label: "Several close friends (5-8)" },
      { value: 2, label: "Few close friends (2-4)" },
      { value: 3, label: "1-2 very close friends is enough" }
    ]
  },
  {
    id: "soc_020",
    category: "Preferences",
    text: "How do you handle social obligations you don't want to attend?",
    options: [
      { value: 0, label: "Usually go and end up enjoying it" },
      { value: 1, label: "Assess my energy and decide" },
      { value: 2, label: "Often cancel or decline" },
      { value: 3, label: "Avoid committing in the first place" }
    ]
  },
  {
    id: "soc_021",
    category: "Preferences",
    text: "Your preferred way to spend time with friends:",
    options: [
      { value: 0, label: "Active outings and events" },
      { value: 1, label: "Mix of going out and staying in" },
      { value: 2, label: "Quiet activities at home" },
      { value: 3, label: "Parallel activities with minimal interaction" }
    ]
  },
  {
    id: "soc_022",
    category: "Preferences",
    text: "How comfortable are you saying no to social invitations?",
    options: [
      { value: 0, label: "Rarely say no - I love socializing" },
      { value: 1, label: "Somewhat comfortable - I prioritize energy" },
      { value: 2, label: "Very comfortable - I protect my energy" },
      { value: 3, label: "I default to no unless very motivated" }
    ]
  },
  {
    id: "soc_023",
    category: "Preferences",
    text: "How do you feel about being the center of attention?",
    options: [
      { value: 0, label: "Love it - I thrive on it" },
      { value: 1, label: "Don't mind it occasionally" },
      { value: 2, label: "Uncomfortable - I prefer supporting role" },
      { value: 3, label: "Terrible - I avoid it at all costs" }
    ]
  },
  {
    id: "soc_024",
    category: "Preferences",
    text: "Your ideal vacation with friends/partner includes:",
    options: [
      { value: 0, label: "Constant together time and activities" },
      { value: 1, label: "Mix of together time and independent activities" },
      { value: 2, label: "Significant alone time built in" },
      { value: 3, label: "Separate accommodations or solo vacation preferred" }
    ]
  },
  {
    id: "soc_025",
    category: "Preferences",
    text: "How do you handle networking or meeting new people?",
    options: [
      { value: 0, label: "Excited - love meeting new people" },
      { value: 1, label: "Can do it when needed" },
      { value: 2, label: "Draining but I manage" },
      { value: 3, label: "Extremely difficult and exhausting" }
    ]
  },
  {
    id: "soc_026",
    category: "Preferences",
    text: "How many social activities per week feels right?",
    options: [
      { value: 0, label: "5+ times a week" },
      { value: 1, label: "3-4 times a week" },
      { value: 2, label: "1-2 times a week" },
      { value: 3, label: "Once a week or less" }
    ]
  },
  {
    id: "soc_027",
    category: "Preferences",
    text: "Your relationship with social media interaction:",
    options: [
      { value: 0, label: "Actively engage - it's energizing" },
      { value: 1, label: "Moderate use - enjoy but need breaks" },
      { value: 2, label: "Minimal use - find it draining" },
      { value: 3, label: "Rarely engage - it depletes me" }
    ]
  },

  // Relationship Patterns (12 questions)
  {
    id: "soc_028",
    category: "Relationships",
    text: "In a relationship, how much together time do you need?",
    options: [
      { value: 0, label: "As much as possible - love being together" },
      { value: 1, label: "Several times a week" },
      { value: 2, label: "A few times a week with space between" },
      { value: 3, label: "Limited time - need lots of independence" }
    ]
  },
  {
    id: "soc_029",
    category: "Relationships",
    text: "How do you feel when a partner needs a lot of social time?",
    options: [
      { value: 0, label: "Great - I do too!" },
      { value: 1, label: "Fine - I'll join sometimes" },
      { value: 2, label: "Challenging - we need compromise" },
      { value: 3, label: "Incompatible - major source of conflict" }
    ]
  },
  {
    id: "soc_030",
    category: "Relationships",
    text: "How important is it that your partner understands your social battery?",
    options: [
      { value: 0, label: "Not very - I'm socially flexible" },
      { value: 1, label: "Somewhat - helps avoid misunderstandings" },
      { value: 2, label: "Very important - crucial for compatibility" },
      { value: 3, label: "Essential - deal-breaker if they don't get it" }
    ]
  },
  {
    id: "soc_031",
    category: "Relationships",
    text: "When dating, how quickly do you need alone time after dates?",
    options: [
      { value: 0, label: "I don't - could spend days together" },
      { value: 1, label: "Not immediately but eventually" },
      { value: 2, label: "Pretty soon - within hours" },
      { value: 3, label: "Immediately - I need to decompress" }
    ]
  },
  {
    id: "soc_032",
    category: "Relationships",
    text: "How do you handle a partner who wants constant communication?",
    options: [
      { value: 0, label: "Love it - I want that too" },
      { value: 1, label: "Can handle regular check-ins" },
      { value: 2, label: "Feels overwhelming - need boundaries" },
      { value: 3, label: "Suffocating - major red flag" }
    ]
  },
  {
    id: "soc_033",
    category: "Relationships",
    text: "Your ideal living situation with a partner:",
    options: [
      { value: 0, label: "Together all the time - shared space" },
      { value: 1, label: "Together but with personal spaces" },
      { value: 2, label: "Separate rooms/spaces within home" },
      { value: 3, label: "Separate homes - visit regularly" }
    ]
  },
  {
    id: "soc_034",
    category: "Relationships",
    text: "How do you feel about spending holidays with partner's family?",
    options: [
      { value: 0, label: "Excited - love big family gatherings" },
      { value: 1, label: "Happy to participate in moderation" },
      { value: 2, label: "Tolerate but need breaks" },
      { value: 3, label: "Extremely draining - avoid when possible" }
    ]
  },
  {
    id: "soc_035",
    category: "Relationships",
    text: "When you need alone time, your partner should:",
    options: [
      { value: 0, label: "I rarely need alone time in relationships" },
      { value: 1, label: "Give me an hour or two" },
      { value: 2, label: "Give me several hours or a day" },
      { value: 3, label: "Understand I need regular extended time alone" }
    ]
  },
  {
    id: "soc_036",
    category: "Relationships",
    text: "How do you balance friend time vs partner time?",
    options: [
      { value: 0, label: "Love doing both - very social" },
      { value: 1, label: "Naturally balance both" },
      { value: 2, label: "Struggle - limited social energy" },
      { value: 3, label: "Barely manage partner time - little left for friends" }
    ]
  },
  {
    id: "soc_037",
    category: "Relationships",
    text: "Your feelings about couples who spend all their time together:",
    options: [
      { value: 0, label: "Admire it - relationship goals" },
      { value: 1, label: "To each their own" },
      { value: 2, label: "Seems codependent" },
      { value: 3, label: "Sounds suffocating and unhealthy" }
    ]
  },
  {
    id: "soc_038",
    category: "Relationships",
    text: "How much do you text/call your partner during the day?",
    options: [
      { value: 0, label: "Constantly - love staying connected" },
      { value: 1, label: "A few times with meaningful updates" },
      { value: 2, label: "Minimal - mostly logistics" },
      { value: 3, label: "Rarely - prefer face-to-face time" }
    ]
  },
  {
    id: "soc_039",
    category: "Relationships",
    text: "Past relationship conflicts often involved:",
    options: [
      { value: 0, label: "Not enough shared social activities" },
      { value: 1, label: "Balancing different social needs" },
      { value: 2, label: "Me needing more space than partner liked" },
      { value: 3, label: "Partners feeling neglected by my need for alone time" }
    ]
  },

  // Self-Awareness & Management (10 questions)
  {
    id: "soc_040",
    category: "Awareness",
    text: "How aware are you of your current social battery level?",
    options: [
      { value: 0, label: "Very aware - I track it actively" },
      { value: 1, label: "Somewhat aware - notice when low" },
      { value: 2, label: "Limited awareness - often run on empty" },
      { value: 3, label: "Not aware until I crash" }
    ]
  },
  {
    id: "soc_041",
    category: "Awareness",
    text: "How well do you communicate your social needs?",
    options: [
      { value: 0, label: "Very clearly and proactively" },
      { value: 1, label: "Pretty well when asked" },
      { value: 2, label: "Struggle to articulate them" },
      { value: 3, label: "Hide them to avoid seeming antisocial" }
    ]
  },
  {
    id: "soc_042",
    category: "Awareness",
    text: "How do you feel about your social battery needs?",
    options: [
      { value: 0, label: "Fully accepting and comfortable" },
      { value: 1, label: "Mostly accepting" },
      { value: 2, label: "Wish I needed less alone time" },
      { value: 3, label: "Ashamed or frustrated by my limits" }
    ]
  },
  {
    id: "soc_043",
    category: "Awareness",
    text: "How good are you at honoring your social limits?",
    options: [
      { value: 0, label: "Excellent - I protect my energy" },
      { value: 1, label: "Pretty good - occasional overextension" },
      { value: 2, label: "Poor - often push beyond limits" },
      { value: 3, label: "Very poor - regularly burn out" }
    ]
  },
  {
    id: "soc_044",
    category: "Awareness",
    text: "Do you feel guilty about needing alone time?",
    options: [
      { value: 0, label: "Not at all - it's self-care" },
      { value: 1, label: "Occasionally feel guilty" },
      { value: 2, label: "Often feel guilty" },
      { value: 3, label: "Constantly feel guilty and selfish" }
    ]
  },
  {
    id: "soc_045",
    category: "Awareness",
    text: "How well do others understand your social battery?",
    options: [
      { value: 0, label: "Very well - I've communicated it clearly" },
      { value: 1, label: "Somewhat - close people get it" },
      { value: 2, label: "Poorly - often misunderstood" },
      { value: 3, label: "Not at all - they think I'm being rude/distant" }
    ]
  },
  {
    id: "soc_046",
    category: "Awareness",
    text: "What happens when you ignore your social battery needs?",
    options: [
      { value: 0, label: "Rarely happens - I'm attuned to them" },
      { value: 1, label: "Get tired but recover quickly" },
      { value: 2, label: "Become irritable and withdrawn" },
      { value: 3, label: "Completely burn out or shut down" }
    ]
  },
  {
    id: "soc_047",
    category: "Awareness",
    text: "How do you prevent social burnout?",
    options: [
      { value: 0, label: "Not an issue - socializing energizes me" },
      { value: 1, label: "Balance social time with rest" },
      { value: 2, label: "Carefully manage and limit social commitments" },
      { value: 3, label: "Avoid most social situations preventatively" }
    ]
  },
  {
    id: "soc_048",
    category: "Awareness",
    text: "How has your awareness of your social battery evolved?",
    options: [
      { value: 0, label: "Always been naturally social" },
      { value: 1, label: "Learned to understand and manage it" },
      { value: 2, label: "Still learning - improving" },
      { value: 3, label: "Struggle to understand or accept it" }
    ]
  },
  {
    id: "soc_049",
    category: "Awareness",
    text: "How satisfied are you with your social life?",
    options: [
      { value: 0, label: "Very satisfied - it matches my needs" },
      { value: 1, label: "Mostly satisfied with minor adjustments needed" },
      { value: 2, label: "Somewhat unsatisfied - working on changes" },
      { value: 3, label: "Very unsatisfied - major disconnect" }
    ]
  }
];

// Social Battery Archetypes
const SOCIAL_BATTERY_ARCHETYPES = [
  {
    name: "The Social Energizer",
    description: "You gain energy from social interaction and thrive in group settings. Being alone for too long drains you. You're the connector who brings people together and creates vibrant social circles.",
    characteristics: [
      "Energized by social interaction",
      "Large social circle",
      "Enjoys frequent gatherings",
      "Feels lonely when alone too long"
    ],
    suggestions: [
      "Build in some quiet time to prevent burnout",
      "Practice being comfortable with solitude",
      "Be mindful that others may need more alone time",
      "Ensure social activities are meaningful, not just frequent",
      "Find partners/friends who match your social energy"
    ]
  },
  {
    name: "The Balanced Ambivert",
    description: "You thrive on a healthy balance of social time and solitude. You can adapt to different social situations but need to recharge appropriately. You're comfortable both in groups and alone.",
    characteristics: [
      "Flexible social energy",
      "Adapts to situations well",
      "Needs balance of social/alone time",
      "Good at self-regulation"
    ],
    suggestions: [
      "Continue honoring your need for balance",
      "Communicate your needs clearly to others",
      "Don't over-schedule social commitments",
      "Check in with yourself regularly about energy levels",
      "Model healthy boundaries for others"
    ]
  },
  {
    name: "The Selective Socializer",
    description: "You enjoy meaningful social connections but in limited doses. Quality over quantity is your motto. You prefer small groups and one-on-one time. Frequent socializing drains you significantly.",
    characteristics: [
      "Prefers quality over quantity",
      "Small social circle",
      "Enjoys deep conversations",
      "Needs significant recharge time"
    ],
    suggestions: [
      "Honor your social limits without guilt",
      "Choose quality interactions over obligation",
      "Communicate your needs to friends/partners",
      "Build in recovery time after social events",
      "Find friends who respect your boundaries"
    ]
  },
  {
    name: "The Introverted Recharger",
    description: "Social interaction significantly drains your energy, even when you enjoy it. You need substantial alone time to recharge and function well. You're highly sensitive to stimulation and prefer calm, quiet environments.",
    characteristics: [
      "Drains quickly in social settings",
      "Needs extended alone time",
      "Sensitive to overstimulation",
      "Values solitude highly"
    ],
    suggestions: [
      "Protect your alone time fiercely",
      "Schedule recovery time after social events",
      "Educate partners/friends about your needs",
      "Choose low-stimulation social activities",
      "Don't apologize for your energy needs",
      "Consider careers/lifestyles that honor your nature"
    ]
  },
  {
    name: "The Social Anxiety Manager",
    description: "Your low social battery may be driven more by anxiety than natural temperament. Social situations trigger stress responses that drain you. With support and strategies, your tolerance could expand.",
    characteristics: [
      "Anxiety in social situations",
      "Avoids social interaction",
      "Drains quickly from stress",
      "May want more connection but feels blocked"
    ],
    suggestions: [
      "Consider therapy for social anxiety",
      "Practice gradual exposure to social situations",
      "Develop coping strategies for anxiety",
      "Distinguish anxiety from natural introversion",
      "Join supportive groups or communities",
      "Be compassionate with yourself during growth"
    ]
  },
  {
    name: "The Highly Sensitive Hermit",
    description: "You're extremely sensitive to social stimulation and prefer extensive solitude. Large amounts of alone time are essential for your wellbeing. You may have just 1-2 close relationships that feel manageable.",
    characteristics: [
      "Highly sensitive to stimulation",
      "Prefers extensive solitude",
      "Very limited social needs",
      "Deep need for quiet and peace"
    ],
    suggestions: [
      "Honor your unique needs without shame",
      "Create a life that supports your nature",
      "Find understanding friends/partners",
      "Set very clear boundaries early",
      "Ensure you have meaningful connection even if limited",
      "Consider whether trauma or other factors need addressing"
    ]
  }
];

// Calculate archetype based on answers
function calculateSocialBatteryArchetype(answers) {
  const scores = {
    energy: 0,
    preferences: 0,
    relationships: 0,
    awareness: 0
  };

  let counts = {
    energy: 0,
    preferences: 0,
    relationships: 0,
    awareness: 0
  };

  // Calculate average scores by category
  SOCIAL_BATTERY_QUIZ_ITEMS.forEach((question) => {
    const answer = answers[question.id];
    if (answer !== undefined && answer !== null) {
      const category = question.category.toLowerCase();
      if (category.includes('energy')) {
        scores.energy += answer;
        counts.energy++;
      } else if (category.includes('preferences')) {
        scores.preferences += answer;
        counts.preferences++;
      } else if (category.includes('relationships')) {
        scores.relationships += answer;
        counts.relationships++;
      } else if (category.includes('awareness')) {
        scores.awareness += answer;
        counts.awareness++;
      }
    }
  });

  // Calculate averages
  const avgEnergy = counts.energy > 0 ? scores.energy / counts.energy : 0;
  const avgPreferences = counts.preferences > 0 ? scores.preferences / counts.preferences : 0;
  const avgRelationships = counts.relationships > 0 ? scores.relationships / counts.relationships : 0;
  const avgAwareness = counts.awareness > 0 ? scores.awareness / counts.awareness : 0;

  // Determine archetype based on patterns
  const overallAvg = (avgEnergy + avgPreferences + avgRelationships + avgAwareness) / 4;

  // Social Energizer: Very low scores - energized by socializing
  if (overallAvg < 0.75) {
    return {
      archetype: SOCIAL_BATTERY_ARCHETYPES[0],
      scores: {
        energy: avgEnergy,
        preferences: avgPreferences,
        relationships: avgRelationships,
        awareness: avgAwareness
      }
    };
  }

  // Balanced Ambivert: Low-moderate scores
  if (overallAvg >= 0.75 && overallAvg < 1.5) {
    return {
      archetype: SOCIAL_BATTERY_ARCHETYPES[1],
      scores: {
        energy: avgEnergy,
        preferences: avgPreferences,
        relationships: avgRelationships,
        awareness: avgAwareness
      }
    };
  }

  // Social Anxiety Manager: High scores but low awareness or mismatched patterns
  if (overallAvg >= 2.0 && avgAwareness > 2.0) {
    return {
      archetype: SOCIAL_BATTERY_ARCHETYPES[4],
      scores: {
        energy: avgEnergy,
        preferences: avgPreferences,
        relationships: avgRelationships,
        awareness: avgAwareness
      }
    };
  }

  // Selective Socializer: Moderate-high scores with good awareness
  if (overallAvg >= 1.5 && overallAvg < 2.25 && avgAwareness < 2.0) {
    return {
      archetype: SOCIAL_BATTERY_ARCHETYPES[2],
      scores: {
        energy: avgEnergy,
        preferences: avgPreferences,
        relationships: avgRelationships,
        awareness: avgAwareness
      }
    };
  }

  // Introverted Recharger: High scores with balanced awareness
  if (overallAvg >= 2.25 && overallAvg < 2.75) {
    return {
      archetype: SOCIAL_BATTERY_ARCHETYPES[3],
      scores: {
        energy: avgEnergy,
        preferences: avgPreferences,
        relationships: avgRelationships,
        awareness: avgAwareness
      }
    };
  }

  // Highly Sensitive Hermit: Very high scores across all categories
  return {
    archetype: SOCIAL_BATTERY_ARCHETYPES[5],
    scores: {
      energy: avgEnergy,
      preferences: avgPreferences,
      relationships: avgRelationships,
      awareness: avgAwareness
    }
  };
}



// Messaging Style Pack - 50 Questions
// Understand how your texting habits shape attraction—your tone, pacing, and the signals you send without realizing it.
// © 2025 GEISTS, LLC. All rights reserved.

const MESSAGING_QUIZ_ITEMS = [
  // Tone & Emotion (13 questions)
  {
    id: "msg_000",
    category: "Tone",
    text: "How often do you use emojis in your messages?",
    options: [
      { value: 0, label: "Frequently - almost every message" },
      { value: 1, label: "Occasionally to soften the tone" },
      { value: 2, label: "Rarely - only for emphasis" },
      { value: 3, label: "Never - I prefer plain text" }
    ]
  },
  {
    id: "msg_001",
    category: "Tone",
    text: "When someone texts 'K', how do you interpret it?",
    options: [
      { value: 0, label: "They're busy or just acknowledging" },
      { value: 1, label: "A bit short, but maybe fine" },
      { value: 2, label: "Passive-aggressive or mad" },
      { value: 3, label: "I don't overthink it" }
    ]
  },
  {
    id: "msg_002",
    category: "Tone",
    text: "How do you handle serious conversations over text?",
    options: [
      { value: 0, label: "I prefer to call or meet up" },
      { value: 1, label: "I send long, thoughtful paragraphs" },
      { value: 2, label: "I try to keep it light and avoid conflict" },
      { value: 3, label: "I get defensive or shut down" }
    ]
  },
  {
    id: "msg_003",
    category: "Tone",
    text: "Your typical message length is:",
    options: [
      { value: 0, label: "Long paragraphs with lots of detail" },
      { value: 1, label: "Medium - a few sentences" },
      { value: 2, label: "Short and concise" },
      { value: 3, label: "One or two words mostly" }
    ]
  },
  {
    id: "msg_004",
    category: "Tone",
    text: "Do you use exclamation marks?",
    options: [
      { value: 0, label: "Yes! Lots of them to show enthusiasm!" },
      { value: 1, label: "Sometimes, to be polite" },
      { value: 2, label: "Rarely" },
      { value: 3, label: "Never - they feel fake" }
    ]
  },
  {
    id: "msg_005",
    category: "Tone",
    text: "How sarcastic are you over text?",
    options: [
      { value: 0, label: "Very - it's my love language" },
      { value: 1, label: "Sometimes, with people who get it" },
      { value: 2, label: "Rarely - it gets lost in translation" },
      { value: 3, label: "Never - I'm very literal" }
    ]
  },
  {
    id: "msg_006",
    category: "Tone",
    text: "When you're excited, you:",
    options: [
      { value: 0, label: "Text immediately with all caps/emojis" },
      { value: 1, label: "Share the news calmly" },
      { value: 2, label: "Wait for the right moment" },
      { value: 3, label: "Keep it to myself mostly" }
    ]
  },
  {
    id: "msg_007",
    category: "Tone",
    text: "How do you express affection via text?",
    options: [
      { value: 0, label: "Words of affirmation and hearts" },
      { value: 1, label: "Sending memes or links they'd like" },
      { value: 2, label: "Checking in regularly" },
      { value: 3, label: "I don't really do that over text" }
    ]
  },
  {
    id: "msg_008",
    category: "Tone",
    text: "If someone sends a dry text, you:",
    options: [
      { value: 0, label: "Try to liven up the conversation" },
      { value: 1, label: "Match their energy" },
      { value: 2, label: "Assume they're not interested" },
      { value: 3, label: "Ignore it" }
    ]
  },
  {
    id: "msg_009",
    category: "Tone",
    text: "How much do you use GIFs/memes?",
    options: [
      { value: 0, label: "Constantly - it's 50% of my chat" },
      { value: 1, label: "Occasionally for a laugh" },
      { value: 2, label: "Rarely" },
      { value: 3, label: "Never" }
    ]
  },
  {
    id: "msg_010",
    category: "Tone",
    text: "When upset, your texting style becomes:",
    options: [
      { value: 0, label: "Short and cold" },
      { value: 1, label: "Verbose and explanatory" },
      { value: 2, label: "Passive-aggressive" },
      { value: 3, label: "I stop texting completely" }
    ]
  },
  {
    id: "msg_011",
    category: "Tone",
    text: "How do you handle compliments over text?",
    options: [
      { value: 0, label: "Love them, respond enthusiastically" },
      { value: 1, label: "Say thanks politely" },
      { value: 2, label: "Deflect with humor" },
      { value: 3, label: "Ignore or change subject" }
    ]
  },
  {
    id: "msg_012",
    category: "Tone",
    text: "Your 'good morning' texts are:",
    options: [
      { value: 0, label: "Daily and cheerful" },
      { value: 1, label: "Occasional/When I feel like it" },
      { value: 2, label: "Only in response to theirs" },
      { value: 3, label: "Non-existent" }
    ]
  },

  // Pacing & Frequency (13 questions)
  {
    id: "msg_013",
    category: "Pacing",
    text: "How quickly do you typically reply?",
    options: [
      { value: 0, label: "Almost instantly" },
      { value: 1, label: "Within an hour or so" },
      { value: 2, label: "Within the day" },
      { value: 3, label: "Days later (I'm bad at texting)" }
    ]
  },
  {
    id: "msg_014",
    category: "Pacing",
    text: "If they take hours to reply, you:",
    options: [
      { value: 0, label: "Double text or check in" },
      { value: 1, label: "Wait patiently" },
      { value: 2, label: "Wait exactly that long to reply back" },
      { value: 3, label: "Lose interest" }
    ]
  },
  {
    id: "msg_015",
    category: "Pacing",
    text: "Do you play 'the waiting game'?",
    options: [
      { value: 0, label: "No, I reply when I see it" },
      { value: 1, label: "Sometimes, to not look desperate" },
      { value: 2, label: "Yes, usually" },
      { value: 3, label: "I don't play games, I'm just busy" }
    ]
  },
  {
    id: "msg_016",
    category: "Pacing",
    text: "Double texting makes you feel:",
    options: [
      { value: 0, label: "Totally fine, I have lots to say" },
      { value: 1, label: "Okay if it's relevant" },
      { value: 2, label: "Anxious/Annoying" },
      { value: 3, label: "I would never do it" }
    ]
  },
  {
    id: "msg_017",
    category: "Pacing",
    text: "Your ideal texting frequency with a partner:",
    options: [
      { value: 0, label: "All day, constant stream" },
      { value: 1, label: "A few check-ins throughout the day" },
      { value: 2, label: "Morning and night mainly" },
      { value: 3, label: "Only for logistics/making plans" }
    ]
  },
  {
    id: "msg_018",
    category: "Pacing",
    text: "When you see a message but can't reply fully:",
    options: [
      { value: 0, label: "I send a quick 'busy rn' text" },
      { value: 1, label: "I leave it unread so I remember" },
      { value: 2, label: "I read it and reply mentally (then forget)" },
      { value: 3, label: "I ignore it until I'm free" }
    ]
  },
  {
    id: "msg_019",
    category: "Pacing",
    text: "How do you feel about 'left on read'?",
    options: [
      { value: 0, label: "It triggers major anxiety" },
      { value: 1, label: "Annoying but I get over it" },
      { value: 2, label: "Indifferent" },
      { value: 3, label: "I do it to others often" }
    ]
  },
  {
    id: "msg_020",
    category: "Pacing",
    text: "Late night texts (after 11pm):",
    options: [
      { value: 0, label: "Love them, that's when we vibe" },
      { value: 1, label: "Okay if we're close" },
      { value: 2, label: "Annoying, I'm sleeping" },
      { value: 3, label: "Major red flag" }
    ]
  },
  {
    id: "msg_021",
    category: "Pacing",
    text: "If the conversation dies, you:",
    options: [
      { value: 0, label: "Start a new topic immediately" },
      { value: 1, label: "Let it sit for a bit then reach out" },
      { value: 2, label: "Wait for them to restart it" },
      { value: 3, label: "Let it die forever" }
    ]
  },
  {
    id: "msg_022",
    category: "Pacing",
    text: "How often do you check your phone?",
    options: [
      { value: 0, label: "Constantly attached to it" },
      { value: 1, label: "Regularly" },
      { value: 2, label: "Every few hours" },
      { value: 3, label: "I often forget where it is" }
    ]
  },
  {
    id: "msg_023",
    category: "Pacing",
    text: "Texting during work/school:",
    options: [
      { value: 0, label: "I text throughout the day anyway" },
      { value: 1, label: "Only on breaks" },
      { value: 2, label: "Rarely" },
      { value: 3, label: "Never, focus mode is on" }
    ]
  },
  {
    id: "msg_024",
    category: "Pacing",
    text: "Response time expectations:",
    options: [
      { value: 0, label: "I expect replies within minutes" },
      { value: 1, label: "Within the hour is polite" },
      { value: 2, label: "Whenever they can is fine" },
      { value: 3, label: "I don't track it at all" }
    ]
  },
  {
    id: "msg_025",
    category: "Pacing",
    text: "Leaving a conversation:",
    options: [
      { value: 0, label: "I say 'bye' or 'talk later'" },
      { value: 1, label: "I react to the last message" },
      { value: 2, label: "I just stop replying" },
      { value: 3, label: "I ghost mostly" }
    ]
  },

  // Initiation & Signals (12 questions)
  {
    id: "msg_026",
    category: "Initiation",
    text: "How often do you initiate the conversation?",
    options: [
      { value: 0, label: "Almost always (80%+)" },
      { value: 1, label: "Often (60-70%)" },
      { value: 2, label: "About half the time (50%)" },
      { value: 3, label: "Rarely/Never (<20%)" }
    ]
  },
  {
    id: "msg_027",
    category: "Initiation",
    text: "Asking to meet up:",
    options: [
      { value: 0, label: "I ask directly and often" },
      { value: 1, label: "I hint at it hoping they ask" },
      { value: 2, label: "I wait for them to ask always" },
      { value: 3, label: "I avoid meeting up usually" }
    ]
  },
  {
    id: "msg_028",
    category: "Initiation",
    text: "How direct are you about your interest?",
    options: [
      { value: 0, label: "Very direct ('I like you')" },
      { value: 1, label: "Flirty but playful" },
      { value: 2, label: "Subtle hints only" },
      { value: 3, label: "Hard to read / Poker face" }
    ]
  },
  {
    id: "msg_029",
    category: "Initiation",
    text: "Sending the first text after a date:",
    options: [
      { value: 0, label: "I do it immediately if I had fun" },
      { value: 1, label: "I wait a few hours or next day" },
      { value: 2, label: "I wait for them to do it" },
      { value: 3, label: "I don't usually follow up" }
    ]
  },
  {
    id: "msg_030",
    category: "Initiation",
    text: "Asking questions:",
    options: [
      { value: 0, label: "I ask lots of deep questions" },
      { value: 1, label: "I keep the ball rolling" },
      { value: 2, label: "I answer more than I ask" },
      { value: 3, label: "I give one-word answers mostly" }
    ]
  },
  {
    id: "msg_031",
    category: "Initiation",
    text: "When you like someone, you text:",
    options: [
      { value: 0, label: "More often and longer" },
      { value: 1, label: "About the same as usual" },
      { value: 2, label: "Less (I get nervous)" },
      { value: 3, label: "Calculatedly (to maintain power)" }
    ]
  },
  {
    id: "msg_032",
    category: "Initiation",
    text: "Reaction to 'We need to talk':",
    options: [
      { value: 0, label: "Immediate panic/Ask 'Why?'" },
      { value: 1, label: "Anxious waiting" },
      { value: 2, label: "Calm curiosity" },
      { value: 3, label: "Ignore/Avoid" }
    ]
  },
  {
    id: "msg_033",
    category: "Initiation",
    text: "Do you screen-shot chats to friends?",
    options: [
      { value: 0, label: "Yes, dissecting every word" },
      { value: 1, label: "Sometimes for advice" },
      { value: 2, label: "Rarely" },
      { value: 3, label: "Never, it's private" }
    ]
  },
  {
    id: "msg_034",
    category: "Initiation",
    text: "Sexting/Risque texts:",
    options: [
      { value: 0, label: "I initiate often" },
      { value: 1, label: "I reciprocate if comfortable" },
      { value: 2, label: "I awkwardly change subject" },
      { value: 3, label: "Not my thing at all" }
    ]
  },
  {
    id: "msg_035",
    category: "Initiation",
    text: "Texting exes:",
    options: [
      { value: 0, label: "I do it when lonely/drunk" },
      { value: 1, label: "Cordial check-ins sometimes" },
      { value: 2, label: "Only for logistics" },
      { value: 3, label: "Blocked/Deleted" }
    ]
  },
  {
    id: "msg_036",
    category: "Initiation",
    text: "Group chats vs 1-on-1:",
    options: [
      { value: 0, label: "Prefer 1-on-1 intimacy" },
      { value: 1, label: "Like both equally" },
      { value: 2, label: "Prefer group (less pressure)" },
      { value: 3, label: "Dislike texting generally" }
    ]
  },
  {
    id: "msg_037",
    category: "Initiation",
    text: "Sending photos/selfies:",
    options: [
      { value: 0, label: "Often, sharing my day" },
      { value: 1, label: "Sometimes if I look good" },
      { value: 2, label: "Rarely" },
      { value: 3, label: "Never" }
    ]
  },

  // Subtext & Anxiety (12 questions)
  {
    id: "msg_038",
    category: "Subtext",
    text: "Overthinking messages:",
    options: [
      { value: 0, label: "I analyze every punctuation mark" },
      { value: 1, label: "I worry if tone seems off" },
      { value: 2, label: "Only if it's ambiguous" },
      { value: 3, label: "I take it at face value" }
    ]
  },
  {
    id: "msg_039",
    category: "Subtext",
    text: "Editing messages before sending:",
    options: [
      { value: 0, label: "I rewrite multiple times" },
      { value: 1, label: "Quick proofread" },
      { value: 2, label: "Send it raw (typos and all)" },
      { value: 3, label: "Voice note (easier)" }
    ]
  },
  {
    id: "msg_040",
    category: "Subtext",
    text: "Deleting messages for everyone:",
    options: [
      { value: 0, label: "I do it if I panic after sending" },
      { value: 1, label: "Only for typos" },
      { value: 2, label: "Rarely" },
      { value: 3, label: "Never, own what you said" }
    ]
  },
  {
    id: "msg_041",
    category: "Subtext",
    text: "Checking if they're online:",
    options: [
      { value: 0, label: "Obsessively checking status" },
      { value: 1, label: "Noticed it casually" },
      { value: 2, label: "Don't pay attention" },
      { value: 3, label: "I have that feature off" }
    ]
  },
  {
    id: "msg_042",
    category: "Subtext",
    text: "Typing bubbles anxiety:",
    options: [
      { value: 0, label: "High - watching them appear/disappear" },
      { value: 1, label: "Moderate curiosity" },
      { value: 2, label: "Low" },
      { value: 3, label: "Don't notice" }
    ]
  },
  {
    id: "msg_043",
    category: "Subtext",
    text: "Interpreting silence:",
    options: [
      { value: 0, label: "They hate me / something is wrong" },
      { value: 1, label: "They're probably busy" },
      { value: 2, label: "They'll reply later" },
      { value: 3, label: "Didn't notice they hadn't replied" }
    ]
  },
  {
    id: "msg_044",
    category: "Subtext",
    text: "Texting etiquette rules:",
    options: [
      { value: 0, label: "I follow strict unwritten rules" },
      { value: 1, label: "I try to be polite" },
      { value: 2, label: "Loose guidelines" },
      { value: 3, label: "No rules, just chaos" }
    ]
  },
  {
    id: "msg_045",
    category: "Subtext",
    text: "Ghosting vs Slow Fade:",
    options: [
      { value: 0, label: "Slow fade is kinder" },
      { value: 1, label: "Ghosting is easier" },
      { value: 2, label: "Direct rejection is best" },
      { value: 3, label: "I don't think about it" }
    ]
  },
  {
    id: "msg_046",
    category: "Subtext",
    text: "Re-reading old chats:",
    options: [
      { value: 0, label: "Often, for nostalgia or analysis" },
      { value: 1, label: "Sometimes" },
      { value: 2, label: "Only to find info" },
      { value: 3, label: "Never, look forward not back" }
    ]
  },
  {
    id: "msg_047",
    category: "Subtext",
    text: "Using 'haha' or 'lol':",
    options: [
      { value: 0, label: "As punctuation for everything" },
      { value: 1, label: "When actually funny" },
      { value: 2, label: "Rarely" },
      { value: 3, label: "Never" }
    ]
  },
  {
    id: "msg_048",
    category: "Subtext",
    text: "Texting games perception:",
    options: [
      { value: 0, label: "Necessary evil of dating" },
      { value: 1, label: "Annoying but present" },
      { value: 2, label: "Waste of time" },
      { value: 3, label: "What games?" }
    ]
  },
  {
    id: "msg_049",
    category: "Subtext",
    text: "Fear of being 'too much':",
    options: [
      { value: 0, label: "Constant worry" },
      { value: 1, label: "Occasional concern" },
      { value: 2, label: "Rarely" },
      { value: 3, label: "Never, I am enough" }
    ]
  }
];

// Archetypes
const MESSAGING_ARCHETYPES = [
  {
    id: "msg_arch_1",
    name: "The Textual Healer",
    description: "You use messaging to build deep connection. You're responsive, engaged, and thoughtful. You value consistency and clarity.",
    characteristics: [
      "High responsiveness",
      "Emotionally expressive",
      "Values consistency",
      "Dislikes games"
    ],
    suggestions: [
      "Remember not everyone texts at your speed",
      "Save some depth for in-person",
      "Don't over-give to dry texters"
    ]
  },
  {
    id: "msg_arch_2",
    name: "The Novelist",
    description: "You have a lot to say and you say it all. Long paragraphs, multiple bubbles, deep thoughts. You value thorough communication.",
    characteristics: [
      "Detailed responses",
      "Prefers depth over brevity",
      "Intellectual approach",
      "Can be overwhelming to some"
    ],
    suggestions: [
      "Check if the other person is matching your energy",
      "Try sending voice notes for long stories",
      "Break up big blocks of text"
    ]
  },
  {
    id: "msg_arch_3",
    name: "The Ghost Writer",
    description: "You're elusive. You reply when you can, often days later. You prioritize your offline life and can be hard to pin down.",
    characteristics: [
      "Slow response time",
      "Low initiation",
      "Protective of time",
      "Can seem uninterested"
    ],
    suggestions: [
      "Communicate your texting style early on",
      "Try 5-minute reply windows to clear backlog",
      "Don't let silence be mistaken for rejection"
    ]
  },
  {
    id: "msg_arch_4",
    name: "The Emoji Cryptographer",
    description: "Your texts are short, playful, and often ambiguous. You rely on vibes, emojis, and subtext rather than direct words.",
    characteristics: [
      "High emoji usage",
      "Playful/Flirty tone",
      "Avoids serious topics over text",
      "Fun but confusing"
    ],
    suggestions: [
      "Use words for important plans or feelings",
      "Clarify if you sense confusion",
      "Make sure you're being taken seriously"
    ]
  },
  {
    id: "msg_arch_5",
    name: "The Anxious Awaiter",
    description: "Texting causes you significant stress. You overanalyze tone, timing, and punctuation. You need reassurance through digital contact.",
    characteristics: [
      "High anxiety around pacing",
      "Over-analysis of subtext",
      "Needs frequent check-ins",
      "Fears silence"
    ],
    suggestions: [
      "Turn off read receipts/active status",
      "Focus on their actions, not just texts",
      "Self-soothe during silence gaps"
    ]
  },
  {
    id: "msg_arch_6",
    name: "The Dry Responder",
    description: "You keep it practical. Short answers, few questions, zero fluff. You view texting as a utility, not a relationship builder.",
    characteristics: [
      "Brief responses",
      "Low emotion in text",
      "Practical focus",
      "Hard to read"
    ],
    suggestions: [
      "Add one question to keep convos alive",
      "Use an occasional emoji for warmth",
      "Call if you hate typing"
    ]
  }
];

function calculateMessagingArchetype(answers) {
  // Logic to calculate archetype based on answers
  // Simple majority logic for now, or weighted scoring
  
  // Calculate scores for Tone (0-3), Pacing (0-3), Initiation (0-3), Subtext (0-3)
  // This mirrors the logic in other quizzes
  
  // Mapping to archetypes (Simplified logic)
  // High Pacing + High Tone -> Textual Healer
  // Low Pacing -> Ghost Writer
  // High Subtext (Anxiety) -> Anxious Awaiter
  // Low Tone + Low Initiation -> Dry Responder
  // High Tone + High Length -> Novelist
  // High Subtext + Low Clarity -> Emoji Cryptographer

  let toneScore = 0;
  let pacingScore = 0;
  let initiationScore = 0;
  let subtextScore = 0;
  let count = 0;

  Object.entries(answers).forEach(([key, value]) => {
    const q = MESSAGING_QUIZ_ITEMS.find(i => i.id === key);
    if (q) {
      if (q.category === 'Tone') toneScore += value; // 0=High Expressive, 3=Low Expressive
      if (q.category === 'Pacing') pacingScore += value; // 0=Fast, 3=Slow
      if (q.category === 'Initiation') initiationScore += value; // 0=High Init, 3=Low Init
      if (q.category === 'Subtext') subtextScore += value; // 0=High Anxiety/Analysis, 3=Low
      count++;
    }
  });

  // Normalize (Approximate)
  // Low value sum = High Trait (because 0 is usually "High/Active")
  
  // Note: In this quiz setup:
  // Pacing: 0=Fast, 3=Slow.
  // Tone: 0=Expressive, 3=Dry.
  // Initiation: 0=Active, 3=Passive.
  // Subtext: 0=Anxious/High Analysis, 3=Chill/Face Value.

  // Determine dominant trait
  const avgPacing = pacingScore / 13;
  const avgTone = toneScore / 13;
  const avgInitiation = initiationScore / 12;
  const avgSubtext = subtextScore / 12;

  if (avgSubtext < 1.2) return MESSAGING_ARCHETYPES[4]; // Anxious Awaiter
  if (avgPacing > 2.0) return MESSAGING_ARCHETYPES[2]; // Ghost Writer
  if (avgTone > 2.0) return MESSAGING_ARCHETYPES[5]; // Dry Responder
  if (avgTone < 1.0 && avgPacing < 1.5) return MESSAGING_ARCHETYPES[1]; // Novelist (Expressive)
  if (avgInitiation < 1.5) return MESSAGING_ARCHETYPES[0]; // Textual Healer
  
  return MESSAGING_ARCHETYPES[3]; // Emoji Cryptographer (Default/Middle)
}



// Boundary Patterns Pack - 50 Questions
// See how you set, hold, or break your standards—and how it affects the connections you choose.
// © 2025 GEISTS, LLC. All rights reserved.

const BOUNDARY_QUIZ_ITEMS = [
  // Emotional Boundaries (13 questions)
  {
    id: "bnd_000",
    category: "Emotional Boundaries",
    text: "When a friend is upset, you typically:",
    options: [
      { value: 0, label: "Feel their pain as if it's your own (absorb it)" },
      { value: 1, label: "Listen supportively but keep separation" },
      { value: 2, label: "Try to fix it immediately to stop the feelings" },
      { value: 3, label: "Feel overwhelmed and withdraw" }
    ]
  },
  {
    id: "bnd_001",
    category: "Emotional Boundaries",
    text: "How comfortable are you saying 'no' to a request?",
    options: [
      { value: 0, label: "Very uncomfortable - I feel guilty" },
      { value: 1, label: "It depends on who asks" },
      { value: 2, label: "Reasonably comfortable" },
      { value: 3, label: "Very comfortable - I protect my time" }
    ]
  },
  {
    id: "bnd_002",
    category: "Emotional Boundaries",
    text: "If someone criticizes you, you:",
    options: [
      { value: 0, label: "Internalize it and feel terrible" },
      { value: 1, label: "Consider if it's true, then decide" },
      { value: 2, label: "Defend myself aggressively" },
      { value: 3, label: "Dismiss it completely" }
    ]
  },
  {
    id: "bnd_003",
    category: "Emotional Boundaries",
    text: "Do you feel responsible for your partner's happiness?",
    options: [
      { value: 0, label: "Yes, if they are unhappy I failed" },
      { value: 1, label: "Somewhat, I want to contribute to it" },
      { value: 2, label: "No, we are responsible for ourselves" },
      { value: 3, label: "Not at all, that's their job" }
    ]
  },
  {
    id: "bnd_004",
    category: "Emotional Boundaries",
    text: "When you need help, you:",
    options: [
      { value: 0, label: "Wait for someone to notice" },
      { value: 1, label: "Hint at it" },
      { value: 2, label: "Ask clearly and directly" },
      { value: 3, label: "Never ask, I do it myself" }
    ]
  },
  {
    id: "bnd_005",
    category: "Emotional Boundaries",
    text: "Sharing personal information early in dating:",
    options: [
      { value: 0, label: "I overshare to build intimacy fast" },
      { value: 1, label: "I share a balanced amount" },
      { value: 2, label: "I hold back significantly" },
      { value: 3, label: "I share nothing personal" }
    ]
  },
  {
    id: "bnd_006",
    category: "Emotional Boundaries",
    text: "If a plan changes last minute, you:",
    options: [
      { value: 0, label: "Accommodate them even if it hurts me" },
      { value: 1, label: "Feel annoyed but adapt" },
      { value: 2, label: "Express frustration" },
      { value: 3, label: "Cancel the whole thing" }
    ]
  },
  {
    id: "bnd_007",
    category: "Emotional Boundaries",
    text: "How much does others' approval matter?",
    options: [
      { value: 0, label: "It defines my worth" },
      { value: 1, label: "It matters a lot" },
      { value: 2, label: "It's nice but not essential" },
      { value: 3, label: "I don't care at all" }
    ]
  },
  {
    id: "bnd_008",
    category: "Emotional Boundaries",
    text: "When someone crosses a line, you:",
    options: [
      { value: 0, label: "Stay silent to keep peace" },
      { value: 1, label: "Make a joke about it" },
      { value: 2, label: "Tell them to stop" },
      { value: 3, label: "Cut them out immediately" }
    ]
  },
  {
    id: "bnd_009",
    category: "Emotional Boundaries",
    text: "Do you tend to fix or save people?",
    options: [
      { value: 0, label: "Yes, I attract 'projects'" },
      { value: 1, label: "Sometimes I help too much" },
      { value: 2, label: "I offer support but don't fix" },
      { value: 3, label: "No, sink or swim" }
    ]
  },
  {
    id: "bnd_010",
    category: "Emotional Boundaries",
    text: "After a conflict, you:",
    options: [
      { value: 0, label: "Apologize even if not wrong" },
      { value: 1, label: "Analyze what happened" },
      { value: 2, label: "Wait for them to apologize" },
      { value: 3, label: "Pretend it didn't happen" }
    ]
  },
  {
    id: "bnd_011",
    category: "Emotional Boundaries",
    text: "Your emotional walls are:",
    options: [
      { value: 0, label: "Non-existent (Open book)" },
      { value: 1, label: "Low fences (Gated access)" },
      { value: 2, label: "High walls (Hard to climb)" },
      { value: 3, label: "Fortress (Impenetrable)" }
    ]
  },
  {
    id: "bnd_012",
    category: "Emotional Boundaries",
    text: "Saying what you really think:",
    options: [
      { value: 0, label: "I adjust my opinion to fit in" },
      { value: 1, label: "I filter heavily" },
      { value: 2, label: "I speak my truth mostly" },
      { value: 3, label: "I'm brutally honest" }
    ]
  },

  // Time & Energy (13 questions)
  {
    id: "bnd_013",
    category: "Time",
    text: "How often do you feel drained by others?",
    options: [
      { value: 0, label: "Constantly" },
      { value: 1, label: "Often" },
      { value: 2, label: "Occasionally" },
      { value: 3, label: "Rarely" }
    ]
  },
  {
    id: "bnd_014",
    category: "Time",
    text: "If you're busy and a friend calls:",
    options: [
      { value: 0, label: "I answer anyway" },
      { value: 1, label: "I text 'can't talk'" },
      { value: 2, label: "I ignore it and call back later" },
      { value: 3, label: "I get irritated" }
    ]
  },
  {
    id: "bnd_015",
    category: "Time",
    text: "Your schedule is typically:",
    options: [
      { value: 0, label: "Overbooked with others' needs" },
      { value: 1, label: "Busy but manageable" },
      { value: 2, label: "Balanced with me-time" },
      { value: 3, label: "Rigidly protected" }
    ]
  },
  {
    id: "bnd_016",
    category: "Time",
    text: "Doing favors you don't want to do:",
    options: [
      { value: 0, label: "I do them often" },
      { value: 1, label: "I make excuses" },
      { value: 2, label: "I politely decline" },
      { value: 3, label: "I say no bluntly" }
    ]
  },
  {
    id: "bnd_017",
    category: "Time",
    text: "How much alone time do you get?",
    options: [
      { value: 0, label: "None, I feel guilty taking it" },
      { value: 1, label: "Not enough" },
      { value: 2, label: "Enough to recharge" },
      { value: 3, label: "As much as I want" }
    ]
  },
  {
    id: "bnd_018",
    category: "Time",
    text: "When people are late:",
    options: [
      { value: 0, label: "I wait indefinitely without complaint" },
      { value: 1, label: "I wait but feel resentful" },
      { value: 2, label: "I set a limit (e.g. 15 mins)" },
      { value: 3, label: "I leave immediately" }
    ]
  },
  {
    id: "bnd_019",
    category: "Time",
    text: "Work/Life boundaries:",
    options: [
      { value: 0, label: "I work/respond at all hours" },
      { value: 1, label: "I try to separate but fail" },
      { value: 2, label: "I have clear off-hours" },
      { value: 3, label: "I am unreachable outside work" }
    ]
  },
  {
    id: "bnd_020",
    category: "Time",
    text: "Resting feels like:",
    options: [
      { value: 0, label: "Laziness / Wasted time" },
      { value: 1, label: "Something I earn after work" },
      { value: 2, label: "Necessary recharging" },
      { value: 3, label: "My priority" }
    ]
  },
  {
    id: "bnd_021",
    category: "Time",
    text: "Canceling plans for self-care:",
    options: [
      { value: 0, label: "I never do it" },
      { value: 1, label: "I lie about why" },
      { value: 2, label: "I do it honestly if needed" },
      { value: 3, label: "I do it frequently" }
    ]
  },
  {
    id: "bnd_022",
    category: "Time",
    text: "Availability availability:",
    options: [
      { value: 0, label: "Always available to everyone" },
      { value: 1, label: "Available to close circle only" },
      { value: 2, label: "Selective availability" },
      { value: 3, label: "Hard to reach" }
    ]
  },
  {
    id: "bnd_023",
    category: "Time",
    text: "Hosting/Planning:",
    options: [
      { value: 0, label: "I do all the work" },
      { value: 1, label: "I do more than my share" },
      { value: 2, label: "I share the load" },
      { value: 3, label: "I show up as a guest" }
    ]
  },
  {
    id: "bnd_024",
    category: "Time",
    text: "When tired:",
    options: [
      { value: 0, label: "I push through for others" },
      { value: 1, label: "I complain but keep going" },
      { value: 2, label: "I stop and rest" },
      { value: 3, label: "I disappear" }
    ]
  },
  {
    id: "bnd_025",
    category: "Time",
    text: "Responding to crisis:",
    options: [
      { value: 0, label: "I drop everything immediately" },
      { value: 1, label: "I help as much as I can" },
      { value: 2, label: "I assess if I can help" },
      { value: 3, label: "I avoid getting involved" }
    ]
  },

  // Physical & Digital (12 questions)
  {
    id: "bnd_026",
    category: "Digital",
    text: "Phone access:",
    options: [
      { value: 0, label: "Partner has full access/passwords" },
      { value: 1, label: "I share if asked" },
      { value: 2, label: "Private unless specific reason" },
      { value: 3, label: "Strictly private" }
    ]
  },
  {
    id: "bnd_027",
    category: "Physical",
    text: "Personal space:",
    options: [
      { value: 0, label: "I prefer constant closeness" },
      { value: 1, label: "I adapt to them" },
      { value: 2, label: "I need my bubble" },
      { value: 3, label: "Don't touch me without asking" }
    ]
  },
  {
    id: "bnd_028",
    category: "Digital",
    text: "Social media interactions:",
    options: [
      { value: 0, label: "I tag/post them constantly" },
      { value: 1, label: "I engage regularly" },
      { value: 2, label: "Minimal interaction" },
      { value: 3, label: "I keep relationship offline" }
    ]
  },
  {
    id: "bnd_029",
    category: "Physical",
    text: "PDA (Public Displays of Affection):",
    options: [
      { value: 0, label: "Anytime, anywhere" },
      { value: 1, label: "If they initiate it" },
      { value: 2, label: "Comfortable with limits" },
      { value: 3, label: "Uncomfortable generally" }
    ]
  },
  {
    id: "bnd_030",
    category: "Digital",
    text: "Tracking location:",
    options: [
      { value: 0, label: "We share locations 24/7" },
      { value: 1, label: "Share for safety mostly" },
      { value: 2, label: "Only temporarily" },
      { value: 3, label: "Never, it's invasive" }
    ]
  },
  {
    id: "bnd_031",
    category: "Physical",
    text: "Borrowing items:",
    options: [
      { value: 0, label: "What's mine is yours" },
      { value: 1, label: "Ask first but usually yes" },
      { value: 2, label: "Some things are off limits" },
      { value: 3, label: "I don't share personal items" }
    ]
  },
  {
    id: "bnd_032",
    category: "Digital",
    text: "Response expectations:",
    options: [
      { value: 0, label: "Immediate replies expected" },
      { value: 1, label: "Timely replies expected" },
      { value: 2, label: "Reply when convenient" },
      { value: 3, label: "No expectations" }
    ]
  },
  {
    id: "bnd_033",
    category: "Physical",
    text: "Sleep preferences:",
    options: [
      { value: 0, label: "Cuddling all night mandatory" },
      { value: 1, label: "Start cuddling, sleep separate" },
      { value: 2, label: "Need my own space to sleep" },
      { value: 3, label: "Separate beds/rooms preferred" }
    ]
  },
  {
    id: "bnd_034",
    category: "Digital",
    text: "Unfollowing/Blocking:",
    options: [
      { value: 0, label: "I rarely do it, feels mean" },
      { value: 1, label: "Only for toxicity" },
      { value: 2, label: "Curate feed liberally" },
      { value: 3, label: "Quick to block" }
    ]
  },
  {
    id: "bnd_035",
    category: "Physical",
    text: "Guests in your home:",
    options: [
      { value: 0, label: "Open door policy anytime" },
      { value: 1, label: "Welcome with short notice" },
      { value: 2, label: "Planned visits only" },
      { value: 3, label: "My home is my sanctuary (no guests)" }
    ]
  },
  {
    id: "bnd_036",
    category: "Digital",
    text: "Digital detox:",
    options: [
      { value: 0, label: "Impossible for me" },
      { value: 1, label: "Hard but I try" },
      { value: 2, label: "Regular practice" },
      { value: 3, label: "I'm barely online anyway" }
    ]
  },
  {
    id: "bnd_037",
    category: "Physical",
    text: "Sexual boundaries:",
    options: [
      { value: 0, label: "Hard for me to say no" },
      { value: 1, label: "Go with the flow" },
      { value: 2, label: "Communicated clearly" },
      { value: 3, label: "Strict and rigid" }
    ]
  },

  // Standards & Values (12 questions)
  {
    id: "bnd_038",
    category: "Values",
    text: "Compromise in relationships:",
    options: [
      { value: 0, label: "I give up what I want for them" },
      { value: 1, label: "I compromise often" },
      { value: 2, label: "I meet halfway" },
      { value: 3, label: "My way or highway" }
    ]
  },
  {
    id: "bnd_039",
    category: "Values",
    text: "Dealbreakers:",
    options: [
      { value: 0, label: "I ignore them if I like someone" },
      { value: 1, label: "I negotiate them" },
      { value: 2, label: "I hold firm on big ones" },
      { value: 3, label: "One strike and you're out" }
    ]
  },
  {
    id: "bnd_040",
    category: "Values",
    text: "Money lending:",
    options: [
      { value: 0, label: "I lend even if I can't afford it" },
      { value: 1, label: "I lend to help out" },
      { value: 2, label: "Only amounts I can lose" },
      { value: 3, label: "Never lend money" }
    ]
  },
  {
    id: "bnd_041",
    category: "Values",
    text: "Political/Religious differences:",
    options: [
      { value: 0, label: "I adopt their views" },
      { value: 1, label: "Avoid talking about it" },
      { value: 2, label: "Respectful disagreement" },
      { value: 3, label: "Must match mine perfectly" }
    ]
  },
  {
    id: "bnd_042",
    category: "Values",
    text: "Tolerating bad behavior:",
    options: [
      { value: 0, label: "I make excuses for them" },
      { value: 1, label: "I hope it changes" },
      { value: 2, label: "I address it once" },
      { value: 3, label: "Immediate exit" }
    ]
  },
  {
    id: "bnd_043",
    category: "Values",
    text: "Self-respect vs relationship:",
    options: [
      { value: 0, label: "Relationship comes first" },
      { value: 1, label: "It's a balance" },
      { value: 2, label: "Self-respect leads" },
      { value: 3, label: "Self-preservation above all" }
    ]
  },
  {
    id: "bnd_044",
    category: "Values",
    text: "Second chances:",
    options: [
      { value: 0, label: "Unlimited chances" },
      { value: 1, label: "Many chances" },
      { value: 2, label: "One or two max" },
      { value: 3, label: "Zero tolerance" }
    ]
  },
  {
    id: "bnd_045",
    category: "Values",
    text: "Listening to intuition:",
    options: [
      { value: 0, label: "I ignore red flags" },
      { value: 1, label: "I doubt my gut" },
      { value: 2, label: "I trust it mostly" },
      { value: 3, label: "I follow it blindly" }
    ]
  },
  {
    id: "bnd_046",
    category: "Values",
    text: "Peer pressure:",
    options: [
      { value: 0, label: "I cave easily" },
      { value: 1, label: "Hard to resist" },
      { value: 2, label: "I can stand my ground" },
      { value: 3, label: "Unaffected by it" }
    ]
  },
  {
    id: "bnd_047",
    category: "Values",
    text: "Changing for a partner:",
    options: [
      { value: 0, label: "I mold myself to them" },
      { value: 1, label: "I change to please them" },
      { value: 2, label: "I grow, but don't change core" },
      { value: 3, label: "I refuse to change" }
    ]
  },
  {
    id: "bnd_048",
    category: "Values",
    text: "Respecting others' boundaries:",
    options: [
      { value: 0, label: "I take them personally/feel rejected" },
      { value: 1, label: "I struggle but try" },
      { value: 2, label: "I respect them" },
      { value: 3, label: "I appreciate them" }
    ]
  },
  {
    id: "bnd_049",
    category: "Values",
    text: "Walking away:",
    options: [
      { value: 0, label: "Impossible until forced" },
      { value: 1, label: "Very difficult/dragged out" },
      { value: 2, label: "Doable when necessary" },
      { value: 3, label: "Easy and quick" }
    ]
  }
];

// Archetypes
const BOUNDARY_ARCHETYPES = [
  {
    id: "bnd_arch_1",
    name: "The Open Door",
    description: "You have highly permeable boundaries. You are generous, empathetic, and often put others' needs before your own, risking burnout and resentment.",
    characteristics: [
      "High empathy",
      "Difficulty saying no",
      "Fears rejection",
      "Over-gives"
    ],
    suggestions: [
      "Practice small 'no's daily",
      "Pause before agreeing to requests",
      "Recognize that boundaries create respect"
    ]
  },
  {
    id: "bnd_arch_2",
    name: "The Fortress",
    description: "You have rigid, impenetrable boundaries. You protect yourself fiercely, but may keep out connection and intimacy in the process.",
    characteristics: [
      "Highly self-protective",
      "Avoids vulnerability",
      "Independent to a fault",
      "Quick to cut ties"
    ],
    suggestions: [
      "Experiment with lowering the drawbridge",
      "Distinguish between safe and unsafe vulnerability",
      "Allow people to support you"
    ]
  },
  {
    id: "bnd_arch_3",
    name: "The Chameleon",
    description: "Your boundaries shift depending on who you are with. You adapt to avoid conflict or gain approval, often losing sight of your own needs.",
    characteristics: [
      "High adaptability",
      "Conflict avoidant",
      "Unclear sense of self",
      "People-pleasing"
    ],
    suggestions: [
      "Identify your non-negotiables",
      "Practice stating your preference first",
      "Notice when you are performing"
    ]
  },
  {
    id: "bnd_arch_4",
    name: "The Negotiator",
    description: "You have healthy, flexible boundaries. You communicate needs clearly but can adapt. You respect yourself and others simultaneously.",
    characteristics: [
      "Clear communication",
      "Self-respect",
      "Flexibility",
      "Resilience"
    ],
    suggestions: [
      "Continue modeling healthy limits",
      "Teach others how to treat you",
      "Maintain self-care routines"
    ]
  },
  {
    id: "bnd_arch_5",
    name: "The Guardian",
    description: "You are protective of your time and energy but fair. You prioritize stability and clear rules in relationships.",
    characteristics: [
      "Consistent limits",
      "Predictable",
      "Protective",
      "Sometimes rigid"
    ],
    suggestions: [
      "Ensure rules don't stifle spontaneity",
      "Check in if rules need updating",
      "Communicate the 'why' behind limits"
    ]
  },
  {
    id: "bnd_arch_6",
    name: "The Over-Giver",
    description: "You define your worth by how much you do for others. Your boundaries are non-existent when it comes to service and helping.",
    characteristics: [
      "Service-oriented",
      "Self-sacrificing",
      "Resentful secretly",
      "Needs to be needed"
    ],
    suggestions: [
      "Stop 'saving' people",
      "Let others experience consequences",
      "Give from overflow, not depletion"
    ]
  }
];

function calculateBoundaryArchetype(answers) {
  // 0 = Porous/Weak, 3 = Rigid/Strong
  
  let emotionalScore = 0;
  let timeScore = 0;
  let physicalScore = 0;
  let valuesScore = 0;

  Object.entries(answers).forEach(([key, value]) => {
    const q = BOUNDARY_QUIZ_ITEMS.find(i => i.id === key);
    if (q) {
      if (q.category === 'Emotional Boundaries') emotionalScore += value;
      if (q.category === 'Time') timeScore += value;
      if (q.category === 'Physical' || q.category === 'Digital') physicalScore += value;
      if (q.category === 'Values') valuesScore += value;
    }
  });

  const avgEmotional = emotionalScore / 13;
  const avgTime = timeScore / 13;
  const avgTotal = (emotionalScore + timeScore + physicalScore + valuesScore) / 50;

  // Logic:
  // Low Avg (< 1) -> Open Door / Over-Giver
  // High Avg (> 2.2) -> Fortress
  // Middle (1.5 - 2.2) -> Negotiator / Guardian
  // Inconsistent (High Var) -> Chameleon

  if (avgTotal < 0.8) return BOUNDARY_ARCHETYPES[5]; // Over-Giver
  if (avgTotal < 1.2) return BOUNDARY_ARCHETYPES[0]; // Open Door
  if (avgTotal > 2.4) return BOUNDARY_ARCHETYPES[1]; // Fortress
  if (avgTotal > 1.8 && avgTotal <= 2.4) return BOUNDARY_ARCHETYPES[4]; // Guardian
  
  // Check for Chameleon (inconsistency - though simple avg doesn't capture it well, we use middle range)
  if (Math.abs(avgEmotional - avgTime) > 1.0) return BOUNDARY_ARCHETYPES[2]; // Chameleon (varies by context)

  return BOUNDARY_ARCHETYPES[3]; // Negotiator (Healthy Middle)
}



// Attraction Signals Pack - 50 Questions
// Learn what draws people to you, what you project, and how others interpret your presence.
// © 2025 GEISTS, LLC. All rights reserved.

const ATTRACTION_QUIZ_ITEMS = [
  // Social Presence (Magnetism) (13 questions)
  {
    id: "att_000",
    category: "Magnetism",
    text: "When you walk into a party, you:",
    options: [
      { value: 0, label: "Make an entrance and greet everyone" },
      { value: 1, label: "Find a friend immediately" },
      { value: 2, label: "Stand back and observe first" },
      { value: 3, label: "Try to be invisible" }
    ]
  },
  {
    id: "att_001",
    category: "Magnetism",
    text: "How often do strangers approach you?",
    options: [
      { value: 0, label: "Very often, I have 'talk to me' energy" },
      { value: 1, label: "Occasionally" },
      { value: 2, label: "Rarely" },
      { value: 3, label: "Never, I have 'do not disturb' energy" }
    ]
  },
  {
    id: "att_002",
    category: "Magnetism",
    text: "In conversation, you are usually:",
    options: [
      { value: 0, label: "The storyteller / Entertainer" },
      { value: 1, label: "The active listener" },
      { value: 2, label: "The debater" },
      { value: 3, label: "Quiet / Passive" }
    ]
  },
  {
    id: "att_003",
    category: "Magnetism",
    text: "Your eye contact style is:",
    options: [
      { value: 0, label: "Intense and lingering" },
      { value: 1, label: "Warm and engaging" },
      { value: 2, label: "Shy / I look away often" },
      { value: 3, label: "Avoidant" }
    ]
  },
  {
    id: "att_004",
    category: "Magnetism",
    text: "How expressive is your body language?",
    options: [
      { value: 0, label: "Very - lots of gestures and touch" },
      { value: 1, label: "Moderately expressive" },
      { value: 2, label: "Controlled and still" },
      { value: 3, label: "Closed off (arms crossed)" }
    ]
  },
  {
    id: "att_005",
    category: "Magnetism",
    text: "Your laugh is:",
    options: [
      { value: 0, label: "Loud and infectious" },
      { value: 1, label: "Polite chuckle" },
      { value: 2, label: "Quiet smile" },
      { value: 3, label: "I rarely laugh out loud" }
    ]
  },
  {
    id: "att_006",
    category: "Magnetism",
    text: "People describe your energy as:",
    options: [
      { value: 0, label: "Exciting / Electric" },
      { value: 1, label: "Warm / Comforting" },
      { value: 2, label: "Calm / Grounded" },
      { value: 3, label: "Intimidating / Cold" }
    ]
  },
  {
    id: "att_007",
    category: "Magnetism",
    text: "Are you comfortable being the center of attention?",
    options: [
      { value: 0, label: "I love it / Thrive on it" },
      { value: 1, label: "It's okay for a bit" },
      { value: 2, label: "I prefer one-on-one" },
      { value: 3, label: "I hate it" }
    ]
  },
  {
    id: "att_008",
    category: "Magnetism",
    text: "Flirting style:",
    options: [
      { value: 0, label: "Bold and direct" },
      { value: 1, label: "Playful teasing" },
      { value: 2, label: "Subtle signals" },
      { value: 3, label: "I don't know how to flirt" }
    ]
  },
  {
    id: "att_009",
    category: "Magnetism",
    text: "Your dress sense:",
    options: [
      { value: 0, label: "Bold / Statement pieces" },
      { value: 1, label: "Stylish / Put together" },
      { value: 2, label: "Casual / Comfortable" },
      { value: 3, label: "To blend in" }
    ]
  },
  {
    id: "att_010",
    category: "Magnetism",
    text: "Group dynamics:",
    options: [
      { value: 0, label: "I lead the group naturally" },
      { value: 1, label: "I'm a key participant" },
      { value: 2, label: "I observe from the edge" },
      { value: 3, label: "I feel excluded" }
    ]
  },
  {
    id: "att_011",
    category: "Magnetism",
    text: "Compliments:",
    options: [
      { value: 0, label: "I give them freely and often" },
      { value: 1, label: "I give meaningful ones occasionally" },
      { value: 2, label: "I feel awkward giving them" },
      { value: 3, label: "I rarely notice things to compliment" }
    ]
  },
  {
    id: "att_012",
    category: "Magnetism",
    text: "Charisma self-rating:",
    options: [
      { value: 0, label: "High - I can charm anyone" },
      { value: 1, label: "Moderate - usually liked" },
      { value: 2, label: "Low - I'm an acquired taste" },
      { value: 3, label: "None - I'm socially awkward" }
    ]
  },

  // Mystery & Intrigue (13 questions)
  {
    id: "att_013",
    category: "Mystery",
    text: "How much do you reveal on a first date?",
    options: [
      { value: 0, label: "My whole life story" },
      { value: 1, label: "A good amount, keep it flowing" },
      { value: 2, label: "Just enough to pique interest" },
      { value: 3, label: "Very little, I'm guarded" }
    ]
  },
  {
    id: "att_014",
    category: "Mystery",
    text: "Do people say you're hard to read?",
    options: [
      { value: 0, label: "Never, I'm an open book" },
      { value: 1, label: "Sometimes" },
      { value: 2, label: "Often" },
      { value: 3, label: "Always" }
    ]
  },
  {
    id: "att_015",
    category: "Mystery",
    text: "Social media presence:",
    options: [
      { value: 0, label: "I post everything I do" },
      { value: 1, label: "Curated highlights" },
      { value: 2, label: "Cryptic or artistic posts" },
      { value: 3, label: "Ghost / Private / No posts" }
    ]
  },
  {
    id: "att_016",
    category: "Mystery",
    text: "When asked 'What are you thinking?':",
    options: [
      { value: 0, label: "I say exactly what it is" },
      { value: 1, label: "I summarize it" },
      { value: 2, label: "I deflect playfully" },
      { value: 3, label: "I say 'nothing'" }
    ]
  },
  {
    id: "att_017",
    category: "Mystery",
    text: "Predictability:",
    options: [
      { value: 0, label: "I'm very consistent and predictable" },
      { value: 1, label: "Mostly consistent" },
      { value: 2, label: "I like to surprise people" },
      { value: 3, label: "I'm chaotic / unpredictable" }
    ]
  },
  {
    id: "att_018",
    category: "Mystery",
    text: "Availability:",
    options: [
      { value: 0, label: "Always available" },
      { value: 1, label: "Available but busy" },
      { value: 2, label: "Hard to pin down" },
      { value: 3, label: "Aloof / Distant" }
    ]
  },
  {
    id: "att_019",
    category: "Mystery",
    text: "Emotional transparency:",
    options: [
      { value: 0, label: "My face shows everything" },
      { value: 1, label: "I share feelings easily" },
      { value: 2, label: "I keep a poker face" },
      { value: 3, label: "I repress/hide emotions" }
    ]
  },
  {
    id: "att_020",
    category: "Mystery",
    text: "The 'Chase':",
    options: [
      { value: 0, label: "I hate games, no chase" },
      { value: 1, label: "I like a little pursuit" },
      { value: 2, label: "I enjoy being chased" },
      { value: 3, label: "I make it impossible to catch me" }
    ]
  },
  {
    id: "att_021",
    category: "Mystery",
    text: "Unanswered questions:",
    options: [
      { value: 0, label: "I answer everything fully" },
      { value: 1, label: "I answer most things" },
      { value: 2, label: "I leave them wanting more" },
      { value: 3, label: "I dodge questions" }
    ]
  },
  {
    id: "att_022",
    category: "Mystery",
    text: "Depth vs Breadth:",
    options: [
      { value: 0, label: "I go deep fast" },
      { value: 1, label: "Balanced approach" },
      { value: 2, label: "Layers, peeled slowly" },
      { value: 3, label: "Surface level only" }
    ]
  },
  {
    id: "att_023",
    category: "Mystery",
    text: "Responding to texts:",
    options: [
      { value: 0, label: "Instantly" },
      { value: 1, label: "Reasonably" },
      { value: 2, label: "Sporadically / Unpredictably" },
      { value: 3, label: "Slowly" }
    ]
  },
  {
    id: "att_024",
    category: "Mystery",
    text: "Leaving a party:",
    options: [
      { value: 0, label: "Long goodbyes to everyone" },
      { value: 1, label: "Say bye to host" },
      { value: 2, label: "Irish exit (disappear)" },
      { value: 3, label: "I leave early unnoticed" }
    ]
  },
  {
    id: "att_025",
    category: "Mystery",
    text: "Personal history:",
    options: [
      { value: 0, label: "I share my past freely" },
      { value: 1, label: "Share relevant parts" },
      { value: 2, label: "Share vaguely" },
      { value: 3, label: "My past is a secret" }
    ]
  },

  // Availability (12 questions)
  {
    id: "att_026",
    category: "Availability",
    text: "Schedule flexibility:",
    options: [
      { value: 0, label: "I clear my schedule for dates" },
      { value: 1, label: "I fit dates in where I can" },
      { value: 2, label: "My time is scarce" },
      { value: 3, label: "I'm always 'busy'" }
    ]
  },
  {
    id: "att_027",
    category: "Availability",
    text: "Emotional readiness:",
    options: [
      { value: 0, label: "100% ready for love" },
      { value: 1, label: "Open but cautious" },
      { value: 2, label: "Still healing / unsure" },
      { value: 3, label: "Emotionally unavailable" }
    ]
  },
  {
    id: "att_028",
    category: "Availability",
    text: "Future planning:",
    options: [
      { value: 0, label: "I plan months ahead" },
      { value: 1, label: "Plan a few weeks ahead" },
      { value: 2, label: "Plan day-by-day" },
      { value: 3, label: "Spontaneous only" }
    ]
  },
  {
    id: "att_029",
    category: "Availability",
    text: "Introducing to friends:",
    options: [
      { value: 0, label: "Immediately" },
      { value: 1, label: "After a few weeks" },
      { value: 2, label: "After months" },
      { value: 3, label: "Never / Keep separate" }
    ]
  },
  {
    id: "att_030",
    category: "Availability",
    text: "Vulnerability:",
    options: [
      { value: 0, label: "I cry/share feelings openly" },
      { value: 1, label: "I share feelings with trust" },
      { value: 2, label: "I struggle to be vulnerable" },
      { value: 3, label: "I never show weakness" }
    ]
  },
  {
    id: "att_031",
    category: "Availability",
    text: "Priorities:",
    options: [
      { value: 0, label: "Relationship is #1 priority" },
      { value: 1, label: "Balanced with work/friends" },
      { value: 2, label: "Work/Hobbies come first" },
      { value: 3, label: "Freedom is #1" }
    ]
  },
  {
    id: "att_032",
    category: "Availability",
    text: "Consistency:",
    options: [
      { value: 0, label: "Reliable as a rock" },
      { value: 1, label: "Mostly reliable" },
      { value: 2, label: "Flaky sometimes" },
      { value: 3, label: "Very inconsistent" }
    ]
  },
  {
    id: "att_033",
    category: "Availability",
    text: "Commitment style:",
    options: [
      { value: 0, label: "Eager to commit" },
      { value: 1, label: "Take it slow but steady" },
      { value: 2, label: "Commitment phobic" },
      { value: 3, label: "Anti-commitment" }
    ]
  },
  {
    id: "att_034",
    category: "Availability",
    text: "Communication frequency:",
    options: [
      { value: 0, label: "Constant contact" },
      { value: 1, label: "Daily check-ins" },
      { value: 2, label: "Every few days" },
      { value: 3, label: "Rarely" }
    ]
  },
  {
    id: "att_035",
    category: "Availability",
    text: "Dependability:",
    options: [
      { value: 0, label: "I'm the one everyone calls" },
      { value: 1, label: "I help when I can" },
      { value: 2, label: "I prefer not to be relied on" },
      { value: 3, label: "Don't count on me" }
    ]
  },
  {
    id: "att_036",
    category: "Availability",
    text: "Intimacy speed:",
    options: [
      { value: 0, label: "Fast and intense" },
      { value: 1, label: "Gradual build" },
      { value: 2, label: "Slow burn" },
      { value: 3, label: "Stalled" }
    ]
  },
  {
    id: "att_037",
    category: "Availability",
    text: "Space needs:",
    options: [
      { value: 0, label: "I hate being alone" },
      { value: 1, label: "I like some alone time" },
      { value: 2, label: "I need lots of space" },
      { value: 3, label: "I prefer solitude" }
    ]
  },

  // Confidence & Projection (12 questions)
  {
    id: "att_038",
    category: "Confidence",
    text: "Self-assuredness:",
    options: [
      { value: 0, label: "I know I'm a catch" },
      { value: 1, label: "I feel good about myself" },
      { value: 2, label: "I have doubts often" },
      { value: 3, label: "I feel unworthy" }
    ]
  },
  {
    id: "att_039",
    category: "Confidence",
    text: "Handling rejection:",
    options: [
      { value: 0, label: "Their loss, I move on" },
      { value: 1, label: "It stings but I recover" },
      { value: 2, label: "I take it very personally" },
      { value: 3, label: "I avoid risks to avoid it" }
    ]
  },
  {
    id: "att_040",
    category: "Confidence",
    text: "Initiating dates:",
    options: [
      { value: 0, label: "I ask without hesitation" },
      { value: 1, label: "I ask if I get signals" },
      { value: 2, label: "I wait to be asked" },
      { value: 3, label: "I never initiate" }
    ]
  },
  {
    id: "att_041",
    category: "Confidence",
    text: "Jealousy:",
    options: [
      { value: 0, label: "Rarely jealous, I'm secure" },
      { value: 1, label: "Sometimes, usually mild" },
      { value: 2, label: "Often jealous" },
      { value: 3, label: "Possessive / Controlling" }
    ]
  },
  {
    id: "att_042",
    category: "Confidence",
    text: "Setting standards:",
    options: [
      { value: 0, label: "High standards, no settling" },
      { value: 1, label: "Reasonable standards" },
      { value: 2, label: "I settle often" },
      { value: 3, label: "I take what I can get" }
    ]
  },
  {
    id: "att_043",
    category: "Confidence",
    text: "Walking away from bad situations:",
    options: [
      { value: 0, label: "Immediately" },
      { value: 1, label: "After trying to fix it" },
      { value: 2, label: "I stay too long" },
      { value: 3, label: "I feel trapped" }
    ]
  },
  {
    id: "att_044",
    category: "Confidence",
    text: "Body image:",
    options: [
      { value: 0, label: "I love my body" },
      { value: 1, label: "I accept my body" },
      { value: 2, label: "I'm self-conscious" },
      { value: 3, label: "I hide my body" }
    ]
  },
  {
    id: "att_045",
    category: "Confidence",
    text: "Opinions of others:",
    options: [
      { value: 0, label: "Don't care what they think" },
      { value: 1, label: "I listen but decide myself" },
      { value: 2, label: "I seek validation" },
      { value: 3, label: "I'm ruled by others' views" }
    ]
  },
  {
    id: "att_046",
    category: "Confidence",
    text: "Assertiveness:",
    options: [
      { value: 0, label: "I ask for what I want" },
      { value: 1, label: "I can be assertive" },
      { value: 2, label: "I'm passive" },
      { value: 3, label: "I'm a doormat" }
    ]
  },
  {
    id: "att_047",
    category: "Confidence",
    text: "Risk taking:",
    options: [
      { value: 0, label: "I love risks in love" },
      { value: 1, label: "Calculated risks" },
      { value: 2, label: "Risk averse" },
      { value: 3, label: "Safe choices only" }
    ]
  },
  {
    id: "att_048",
    category: "Confidence",
    text: "Authenticity:",
    options: [
      { value: 0, label: "Unapologetically me" },
      { value: 1, label: "Mostly authentic" },
      { value: 2, label: "I mask often" },
      { value: 3, label: "I don't know who I am" }
    ]
  },
  {
    id: "att_049",
    category: "Confidence",
    text: "Comparison:",
    options: [
      { value: 0, label: "I don't compare myself" },
      { value: 1, label: "Occasionally" },
      { value: 2, label: "Often compare" },
      { value: 3, label: "Constantly feel inferior" }
    ]
  }
];

// Archetypes
const ATTRACTION_ARCHETYPES = [
  {
    id: "att_arch_1",
    name: "The Siren",
    description: "You are highly magnetic, confident, and slightly mysterious. You draw people in effortlessly but may struggle with availability or depth initially.",
    characteristics: [
      "High magnetism",
      "Moderate mystery",
      "High confidence",
      "Selective availability"
    ],
    suggestions: [
      "Ensure you're attracting the right kind of attention",
      "Practice vulnerability to deepen bonds",
      "Don't rely solely on charm"
    ]
  },
  {
    id: "att_arch_2",
    name: "The Best Friend",
    description: "You are warm, available, and open. People feel safe and comfortable with you instantly, but you might lack the 'mystery' spark initially.",
    characteristics: [
      "High availability",
      "Low mystery",
      "Warm magnetism",
      "Steady confidence"
    ],
    suggestions: [
      "Hold back a little to create intrigue",
      "Don't be too available too soon",
      "Prioritize your own needs"
    ]
  },
  {
    id: "att_arch_3",
    name: "The Enigma",
    description: "You are mysterious and hard to read. People are intrigued by you but often unsure where they stand, which can be both attractive and frustrating.",
    characteristics: [
      "High mystery",
      "Low availability",
      "Subtle magnetism",
      "Guarded confidence"
    ],
    suggestions: [
      "Share more to build trust",
      "Clarify your intentions",
      "Let people see the real you"
    ]
  },
  {
    id: "att_arch_4",
    name: "The Powerhouse",
    description: "You are confident, assertive, and magnetic. You know what you want and go for it. Your intensity can be intoxicating or intimidating.",
    characteristics: [
      "High confidence",
      "High magnetism",
      "Clear availability",
      "Low mystery"
    ],
    suggestions: [
      "Check if others feel overpowered",
      "Show your softer side",
      "Allow others to lead sometimes"
    ]
  },
  {
    id: "att_arch_5",
    name: "The Wallflower",
    description: "You are observant and reserved. You may have a rich inner world but struggle to project it, often feeling overlooked in social settings.",
    characteristics: [
      "Low magnetism projection",
      "High mystery (unintentional)",
      "Low confidence",
      "Variable availability"
    ],
    suggestions: [
      "Practice taking up space",
      "Share your thoughts more vocally",
      "Take small social risks"
    ]
  },
  {
    id: "att_arch_6",
    name: "The Charmer",
    description: "You are socially skilled and adaptable. You can make anyone feel special, but may struggle with deep authenticity or being seen as a 'player'.",
    characteristics: [
      "High magnetism",
      "Adaptable confidence",
      "Variable availability",
      "Low mystery"
    ],
    suggestions: [
      "Focus on quality over quantity",
      "Be authentic rather than just charming",
      "Build deeper connections"
    ]
  }
];

function calculateAttractionArchetype(answers) {
  let magnetismScore = 0;
  let mysteryScore = 0;
  let availabilityScore = 0;
  let confidenceScore = 0;

  Object.entries(answers).forEach(([key, value]) => {
    const q = ATTRACTION_QUIZ_ITEMS.find(i => i.id === key);
    if (q) {
      // Note: Value 0 is usually the "High/Active/Strong" trait in my questions
      // Magnetism: 0=High, 3=Low
      // Mystery: 0=Open(Low Mystery), 3=Closed(High Mystery) -> WAIT. 
      // Let's check Mystery q's.
      // "Reveal on first date": 0=Whole life(Low Mystery), 3=Very little(High Mystery).
      // So for Mystery, 0 is Low Mystery, 3 is High Mystery.
      
      // Availability: 0=Always(High), 3=Never(Low).
      // Confidence: 0=High, 3=Low.

      if (q.category === 'Magnetism') magnetismScore += (3 - value); // Invert so high score = high magnetism
      if (q.category === 'Mystery') mysteryScore += value; // 3=High Mystery
      if (q.category === 'Availability') availabilityScore += (3 - value); // 0=High Avail
      if (q.category === 'Confidence') confidenceScore += (3 - value); // 0=High Conf
    }
  });

  const avgMag = magnetismScore / 13;
  const avgMys = mysteryScore / 13;
  const avgAvail = availabilityScore / 12;
  const avgConf = confidenceScore / 12;

  // Logic
  // High Mag + High Conf + Low Mys -> Powerhouse
  // High Mag + High Mys -> Siren
  // High Avail + Low Mys -> Best Friend
  // High Mys + Low Avail -> Enigma
  // Low Mag + Low Conf -> Wallflower
  // High Mag + Adaptable -> Charmer

  if (avgMag < 1.5 && avgConf < 1.5) return ATTRACTION_ARCHETYPES[4]; // Wallflower
  if (avgMys > 2.0 && avgAvail < 1.5) return ATTRACTION_ARCHETYPES[2]; // Enigma
  if (avgMag > 2.0 && avgConf > 2.0 && avgMys < 1.5) return ATTRACTION_ARCHETYPES[3]; // Powerhouse
  if (avgAvail > 2.2 && avgMys < 1.2) return ATTRACTION_ARCHETYPES[1]; // Best Friend
  if (avgMag > 1.8 && avgMys > 1.8) return ATTRACTION_ARCHETYPES[0]; // Siren
  
  return ATTRACTION_ARCHETYPES[5]; // Charmer (Default)
}



// Desire Logic Pack - 50 Questions (Ultra Exclusive)
// What triggers your attraction — mentally, emotionally, and socially.
// This is deeper than "attraction style." It uncovers what actually turns your attraction on or off, patterns you don't consciously see, why you pursue certain people, and the instinct blueprint behind your choices.
// © 2025 GEISTS, LLC. All rights reserved.

const DESIRE_LOGIC_QUIZ_ITEMS = [
  // Mental Triggers (13 questions)
  {
    id: "des_000",
    category: "Mental",
    text: "You're most attracted to someone who:",
    options: [
      { value: 0, label: "Challenges your intellect" },
      { value: 1, label: "Shares your worldview" },
      { value: 2, label: "Has a different perspective" },
      { value: 3, label: "Is easy to understand" }
    ]
  },
  {
    id: "des_001",
    category: "Mental",
    text: "When someone corrects you in conversation, you:",
    options: [
      { value: 0, label: "Get excited - I love mental sparring" },
      { value: 1, label: "Feel respected that they're honest" },
      { value: 2, label: "Feel slightly defensive" },
      { value: 3, label: "Feel embarrassed or annoyed" }
    ]
  },
  {
    id: "des_002",
    category: "Mental",
    text: "Intellectual curiosity is:",
    options: [
      { value: 0, label: "Essential - non-negotiable" },
      { value: 1, label: "Very attractive" },
      { value: 2, label: "Nice to have" },
      { value: 3, label: "Not important" }
    ]
  },
  {
    id: "des_003",
    category: "Mental",
    text: "You're drawn to people who:",
    options: [
      { value: 0, label: "Know more than you about something" },
      { value: 1, label: "Are teachable and curious" },
      { value: 2, label: "Match your knowledge level" },
      { value: 3, label: "Don't overthink things" }
    ]
  },
  {
    id: "des_004",
    category: "Mental",
    text: "A conversation that makes you feel attracted is:",
    options: [
      { value: 0, label: "Debating philosophy until 3am" },
      { value: 1, label: "Sharing ideas and learning together" },
      { value: 2, label: "Light banter and jokes" },
      { value: 3, label: "Comfortable silence" }
    ]
  },
  {
    id: "des_005",
    category: "Mental",
    text: "When someone uses big words or references you don't know:",
    options: [
      { value: 0, label: "I ask them to explain - I'm intrigued" },
      { value: 1, label: "I look it up later" },
      { value: 2, label: "I feel a bit intimidated" },
      { value: 3, label: "I tune out or feel put off" }
    ]
  },
  {
    id: "des_006",
    category: "Mental",
    text: "Your ideal partner's education level:",
    options: [
      { value: 0, label: "Advanced degree or equivalent knowledge" },
      { value: 1, label: "College educated" },
      { value: 2, label: "Self-taught with life experience" },
      { value: 3, label: "Doesn't matter to me" }
    ]
  },
  {
    id: "des_007",
    category: "Mental",
    text: "You lose attraction when someone:",
    options: [
      { value: 0, label: "Can't hold an intellectual conversation" },
      { value: 1, label: "Doesn't question anything" },
      { value: 2, label: "Is too serious all the time" },
      { value: 3, label: "Talks too much about ideas" }
    ]
  },
  {
    id: "des_008",
    category: "Mental",
    text: "You're most intrigued by someone who:",
    options: [
      { value: 0, label: "Has expertise in something niche" },
      { value: 1, label: "Asks thoughtful questions" },
      { value: 2, label: "Keeps conversations light" },
      { value: 3, label: "Doesn't overthink" }
    ]
  },
  {
    id: "des_009",
    category: "Mental",
    text: "The way someone thinks affects your attraction:",
    options: [
      { value: 0, label: "More than anything else" },
      { value: 1, label: "Significantly" },
      { value: 2, label: "Somewhat" },
      { value: 3, label: "Not really" }
    ]
  },
  {
    id: "des_010",
    category: "Mental",
    text: "When someone explains their complex job or hobby:",
    options: [
      { value: 0, label: "I'm fascinated and ask follow-ups" },
      { value: 1, label: "I listen with interest" },
      { value: 2, label: "I try to understand but get lost" },
      { value: 3, label: "I zone out" }
    ]
  },
  {
    id: "des_011",
    category: "Mental",
    text: "A turn-on for you is:",
    options: [
      { value: 0, label: "Watching them solve a problem" },
      { value: 1, label: "Hearing them explain something" },
      { value: 2, label: "Their sense of humor" },
      { value: 3, label: "Their physical presence" }
    ]
  },
  {
    id: "des_012",
    category: "Mental",
    text: "You pursue people who make you:",
    options: [
      { value: 0, label: "Think in new ways" },
      { value: 1, label: "Feel understood" },
      { value: 2, label: "Feel comfortable" },
      { value: 3, label: "Feel desired" }
    ]
  },

  // Emotional Triggers (13 questions)
  {
    id: "des_013",
    category: "Emotional Desire",
    text: "Your attraction is triggered when someone:",
    options: [
      { value: 0, label: "Shows vulnerability first" },
      { value: 1, label: "Makes you feel safe" },
      { value: 2, label: "Creates emotional intensity" },
      { value: 3, label: "Keeps things surface level" }
    ]
  },
  {
    id: "des_014",
    category: "Emotional Desire",
    text: "You're most drawn to people who are:",
    options: [
      { value: 0, label: "Emotionally available and open" },
      { value: 1, label: "Mysterious and hard to read" },
      { value: 2, label: "Emotionally independent" },
      { value: 3, label: "Low-drama and steady" }
    ]
  },
  {
    id: "des_015",
    category: "Emotional Desire",
    text: "When someone cries in front of you:",
    options: [
      { value: 0, label: "I feel deeply connected" },
      { value: 1, label: "I feel trusted and close" },
      { value: 2, label: "I feel uncomfortable" },
      { value: 3, label: "I feel overwhelmed" }
    ]
  },
  {
    id: "des_016",
    category: "Emotional Desire",
    text: "You pursue people who:",
    options: [
      { value: 0, label: "Need you emotionally" },
      { value: 1, label: "Balance your emotional needs" },
      { value: 2, label: "Are emotionally self-sufficient" },
      { value: 3, label: "Keep emotions to themselves" }
    ]
  },
  {
    id: "des_017",
    category: "Emotional Desire",
    text: "Emotional intensity is:",
    options: [
      { value: 0, label: "Essential for attraction" },
      { value: 1, label: "Very appealing" },
      { value: 2, label: "Nice in moderation" },
      { value: 3, label: "A red flag" }
    ]
  },
  {
    id: "des_018",
    category: "Emotional Desire",
    text: "You're attracted to partners who:",
    options: [
      { value: 0, label: "Mirror your emotions" },
      { value: 1, label: "Validate your feelings" },
      { value: 2, label: "Challenge your emotional patterns" },
      { value: 3, label: "Don't get too emotional" }
    ]
  },
  {
    id: "des_019",
    category: "Emotional Desire",
    text: "When someone shares a deep fear with you:",
    options: [
      { value: 0, label: "I'm immediately more attracted" },
      { value: 1, label: "I feel honored and closer" },
      { value: 2, label: "I feel the weight of responsibility" },
      { value: 3, label: "I feel uneasy" }
    ]
  },
  {
    id: "des_020",
    category: "Emotional Desire",
    text: "Your attraction grows when someone:",
    options: [
      { value: 0, label: "Depends on you for support" },
      { value: 1, label: "Opens up gradually" },
      { value: 2, label: "Maintains healthy boundaries" },
      { value: 3, label: "Handles everything themselves" }
    ]
  },
  {
    id: "des_021",
    category: "Emotional Desire",
    text: "You lose attraction when someone:",
    options: [
      { value: 0, label: "Is emotionally closed off" },
      { value: 1, label: "Is too needy" },
      { value: 2, label: "Doesn't understand your feelings" },
      { value: 3, label: "Is too emotional" }
    ]
  },
  {
    id: "des_022",
    category: "Emotional Desire",
    text: "Emotional chemistry is:",
    options: [
      { value: 0, label: "The foundation of attraction" },
      { value: 1, label: "Very important" },
      { value: 2, label: "Important but not everything" },
      { value: 3, label: "Secondary to other factors" }
    ]
  },
  {
    id: "des_023",
    category: "Emotional Desire",
    text: "You're most attracted when someone:",
    options: [
      { value: 0, label: "Seeks your emotional validation" },
      { value: 1, label: "Creates emotional safety" },
      { value: 2, label: "Is emotionally independent" },
      { value: 3, label: "Keeps emotions private" }
    ]
  },
  {
    id: "des_024",
    category: "Emotional Desire",
    text: "When someone is having a hard time, you:",
    options: [
      { value: 0, label: "Feel more connected to them" },
      { value: 1, label: "Want to help and support" },
      { value: 2, label: "Feel like they need space" },
      { value: 3, label: "Feel drained or overwhelmed" }
    ]
  },
  {
    id: "des_025",
    category: "Emotional Desire",
    text: "You pursue people who make you feel:",
    options: [
      { value: 0, label: "Needed and essential" },
      { value: 1, label: "Understood and seen" },
      { value: 2, label: "Calm and stable" },
      { value: 3, label: "Excited and alive" }
    ]
  },

  // Social Triggers (12 questions)
  {
    id: "des_026",
    category: "Social",
    text: "You're most attracted to someone who:",
    options: [
      { value: 0, label: "Is popular and well-liked" },
      { value: 1, label: "Has a tight-knit friend group" },
      { value: 2, label: "Is more of a loner" },
      { value: 3, label: "Social status doesn't matter" }
    ]
  },
  {
    id: "des_027",
    category: "Social",
    text: "When someone is the center of attention:",
    options: [
      { value: 0, label: "I'm very attracted" },
      { value: 1, label: "I'm intrigued" },
      { value: 2, label: "I'm neutral" },
      { value: 3, label: "I'm turned off" }
    ]
  },
  {
    id: "des_028",
    category: "Social",
    text: "You're drawn to people who:",
    options: [
      { value: 0, label: "Have high social status" },
      { value: 1, label: "Are respected in their community" },
      { value: 2, label: "Don't care about status" },
      { value: 3, label: "Are authentic regardless of status" }
    ]
  },
  {
    id: "des_029",
    category: "Social",
    text: "A turn-on is when someone:",
    options: [
      { value: 0, label: "Introduces you to important people" },
      { value: 1, label: "Includes you in their social circle" },
      { value: 2, label: "Prefers one-on-one time" },
      { value: 3, label: "Doesn't mix social and romantic" }
    ]
  },
  {
    id: "des_030",
    category: "Social",
    text: "You lose attraction when someone:",
    options: [
      { value: 0, label: "Is a social outcast" },
      { value: 1, label: "Can't hold conversations at parties" },
      { value: 2, label: "Is too social and never alone" },
      { value: 3, label: "Social factors don't affect me" }
    ]
  },
  {
    id: "des_031",
    category: "Social",
    text: "You pursue people who:",
    options: [
      { value: 0, label: "Elevate your social standing" },
      { value: 1, label: "Fit into your social world" },
      { value: 2, label: "Have their own social life" },
      { value: 3, label: "Match your social preferences" }
    ]
  },
  {
    id: "des_032",
    category: "Social",
    text: "When you see how someone interacts in a group:",
    options: [
      { value: 0, label: "It significantly affects my attraction" },
      { value: 1, label: "It gives me useful information" },
      { value: 2, label: "It doesn't change much" },
      { value: 3, label: "I prefer to see them one-on-one" }
    ]
  },
  {
    id: "des_033",
    category: "Social",
    text: "You're attracted to people who:",
    options: [
      { value: 0, label: "Everyone wants to be around" },
      { value: 1, label: "Have genuine connections" },
      { value: 2, label: "Are selective about friends" },
      { value: 3, label: "Are independent" }
    ]
  },
  {
    id: "des_034",
    category: "Social",
    text: "Social proof affects your attraction:",
    options: [
      { value: 0, label: "A lot - if others want them, I do too" },
      { value: 1, label: "Somewhat" },
      { value: 2, label: "A little" },
      { value: 3, label: "Not at all" }
    ]
  },
  {
    id: "des_035",
    category: "Social",
    text: "You're most intrigued by someone who:",
    options: [
      { value: 0, label: "Is sought after by others" },
      { value: 1, label: "Is well-respected" },
      { value: 2, label: "Doesn't follow social norms" },
      { value: 3, label: "Is genuine regardless of popularity" }
    ]
  },
  {
    id: "des_036",
    category: "Social",
    text: "When someone is a social butterfly:",
    options: [
      { value: 0, label: "I'm very attracted" },
      { value: 1, label: "I'm interested" },
      { value: 2, label: "I'm neutral" },
      { value: 3, label: "I prefer more reserved people" }
    ]
  },
  {
    id: "des_037",
    category: "Social",
    text: "Your attraction is influenced by:",
    options: [
      { value: 0, label: "How others see them" },
      { value: 1, label: "Their social skills" },
      { value: 2, label: "Their independence from groups" },
      { value: 3, label: "Only their individual qualities" }
    ]
  },

  // Instinct/Pattern Recognition (12 questions)
  {
    id: "des_038",
    category: "Instinct",
    text: "You know you're attracted when you feel:",
    options: [
      { value: 0, label: "An immediate physical pull" },
      { value: 1, label: "Curiosity and intrigue" },
      { value: 2, label: "Comfort and ease" },
      { value: 3, label: "A challenge to pursue" }
    ]
  },
  {
    id: "des_039",
    category: "Instinct",
    text: "Your gut feeling about attraction is usually:",
    options: [
      { value: 0, label: "Accurate - I trust it completely" },
      { value: 1, label: "Usually right" },
      { value: 2, label: "Mixed results" },
      { value: 3, label: "Often wrong - I overthink" }
    ]
  },
  {
    id: "des_040",
    category: "Instinct",
    text: "You pursue people who:",
    options: [
      { value: 0, label: "Feel familiar somehow" },
      { value: 1, label: "Feel like a good match" },
      { value: 2, label: "Feel new and different" },
      { value: 3, label: "Feel safe and predictable" }
    ]
  },
  {
    id: "des_041",
    category: "Instinct",
    text: "When attraction doesn't make logical sense:",
    options: [
      { value: 0, label: "I follow it anyway" },
      { value: 1, label: "I explore why I feel it" },
      { value: 2, label: "I question it" },
      { value: 3, label: "I ignore it" }
    ]
  },
  {
    id: "des_042",
    category: "Instinct",
    text: "You're most drawn to people who remind you of:",
    options: [
      { value: 0, label: "Past partners (good or bad)" },
      { value: 1, label: "A parent or caregiver" },
      { value: 2, label: "An ideal you've imagined" },
      { value: 3, label: "No one - they're unique" }
    ]
  },
  {
    id: "des_043",
    category: "Instinct",
    text: "Your attraction patterns tend to be:",
    options: [
      { value: 0, label: "Very consistent - same type" },
      { value: 1, label: "Similar but evolving" },
      { value: 2, label: "All over the place" },
      { value: 3, label: "Hard to identify a pattern" }
    ]
  },
  {
    id: "des_044",
    category: "Instinct",
    text: "You pursue people who trigger:",
    options: [
      { value: 0, label: "Old emotional patterns" },
      { value: 1, label: "New possibilities" },
      { value: 2, label: "A sense of completion" },
      { value: 3, label: "Logic over feeling" }
    ]
  },
  {
    id: "des_045",
    category: "Instinct",
    text: "When someone feels 'off' but checks all boxes:",
    options: [
      { value: 0, label: "I trust the feeling and avoid them" },
      { value: 1, label: "I give them a chance" },
      { value: 2, label: "I rationalize the feeling away" },
      { value: 3, label: "I ignore my instincts" }
    ]
  },
  {
    id: "des_046",
    category: "Instinct",
    text: "Your attraction is influenced by subconscious patterns:",
    options: [
      { value: 0, label: "Definitely - I see the patterns now" },
      { value: 1, label: "Probably - I'm aware of some" },
      { value: 2, label: "Maybe - hard to tell" },
      { value: 3, label: "No - I make conscious choices" }
    ]
  },
  {
    id: "des_047",
    category: "Instinct",
    text: "You're most attracted when you sense:",
    options: [
      { value: 0, label: "Danger or uncertainty" },
      { value: 1, label: "Potential and growth" },
      { value: 2, label: "Stability and safety" },
      { value: 3, label: "Familiarity" }
    ]
  },
  {
    id: "des_048",
    category: "Instinct",
    text: "Your attraction blueprint is:",
    options: [
      { value: 0, label: "Unconscious and drives me" },
      { value: 1, label: "Partially aware, partially instinct" },
      { value: 2, label: "Mostly conscious" },
      { value: 3, label: "Fully intentional" }
    ]
  },
  {
    id: "des_049",
    category: "Instinct",
    text: "You pursue certain people because:",
    options: [
      { value: 0, label: "Something in me recognizes them" },
      { value: 1, label: "They align with my values" },
      { value: 2, label: "They're a good match logically" },
      { value: 3, label: "I don't know - it just happens" }
    ]
  }
];

const DESIRE_LOGIC_ARCHETYPES = [
  {
    id: "des_arch_0",
    name: "The Intellectual Pursuit",
    description: "Your attraction is primarily mental. You're drawn to intelligence, curiosity, and the ability to engage in deep, challenging conversations. You lose interest quickly if someone can't keep up intellectually.",
    characteristics: [
      "Drawn to expertise and knowledge",
      "Needs mental stimulation",
      "Values intellectual debates",
      "Loses attraction to simple minds"
    ],
    suggestions: [
      "Notice if you're using intellect as an avoidance strategy",
      "Explore emotional attraction alongside mental",
      "Allow space for different types of intelligence"
    ]
  },
  {
    id: "des_arch_1",
    name: "The Emotional Magnet",
    description: "You're pulled toward emotional intensity, vulnerability, and depth. You're most attracted when someone opens up to you or needs your emotional support. You pursue people you can heal or who can heal you.",
    characteristics: [
      "Attracted to emotional vulnerability",
      "Seeks intensity and connection",
      "Drawn to people who need you",
      "Loses interest if too independent"
    ],
    suggestions: [
      "Notice if you're drawn to fixable people",
      "Balance giving with receiving",
      "Check if intensity equals compatibility"
    ]
  },
  {
    id: "des_arch_2",
    name: "The Social Climber",
    description: "Your attraction is tied to social status, popularity, and how others perceive your partner. You're drawn to people who elevate your social standing or who are sought after by others. Social proof significantly influences you.",
    characteristics: [
      "Influenced by social proof",
      "Drawn to status and popularity",
      "Wants to be with the 'it' person",
      "Loses attraction if socially rejected"
    ],
    suggestions: [
      "Question if attraction is real or social validation",
      "Focus on individual connection over status",
      "Notice if you're competing for attention"
    ]
  },
  {
    id: "des_arch_3",
    name: "The Pattern Repeater",
    description: "You're unconsciously drawn to familiar emotional patterns, even unhealthy ones. You pursue people who remind you of past partners or family dynamics. Your attraction blueprint is driven by unresolved patterns.",
    characteristics: [
      "Repeats relationship patterns",
      "Drawn to familiar dynamics",
      "Unconscious attraction triggers",
      "Ignores red flags if pattern matches"
    ],
    suggestions: [
      "Identify the pattern you're repeating",
      "Notice who you're drawn to and why",
      "Break the cycle with conscious choice"
    ]
  },
  {
    id: "des_arch_4",
    name: "The Balanced Pursuer",
    description: "Your attraction comes from a mix of mental, emotional, and social factors. You're flexible and drawn to different types of people. You pursue based on genuine connection rather than a single trigger.",
    characteristics: [
      "Balanced attraction triggers",
      "Flexible and open-minded",
      "Seeks genuine connection",
      "Less influenced by patterns"
    ],
    suggestions: [
      "Continue being intentional about choices",
      "Trust your balanced instincts",
      "Maintain awareness of unconscious patterns"
    ]
  },
  {
    id: "des_arch_5",
    name: "The Instinctual Chaser",
    description: "You follow your gut feeling completely, even when it doesn't make logical sense. You're drawn to people who feel familiar or trigger something deep inside. Your attraction is driven by instincts you can't always explain.",
    characteristics: [
      "Trusts gut feelings completely",
      "Drawn to familiar energy",
      "Attraction feels instinctual",
      "May ignore logical red flags"
    ],
    suggestions: [
      "Balance instinct with self-awareness",
      "Explore why certain people feel familiar",
      "Notice if instincts serve your highest good"
    ]
  }
];

function calculateDesireLogicArchetype(answers) {
  let mentalScore = 0;
  let emotionalScore = 0;
  let socialScore = 0;
  let instinctScore = 0;
  let mentalCount = 0;
  let emotionalCount = 0;
  let socialCount = 0;
  let instinctCount = 0;

  Object.entries(answers).forEach(([key, value]) => {
    const q = DESIRE_LOGIC_QUIZ_ITEMS.find(i => i.id === key);
    if (q) {
      if (q.category === 'Mental') {
        mentalScore += value;
        mentalCount++;
      }
      if (q.category === 'Emotional Desire') {
        emotionalScore += value;
        emotionalCount++;
      }
      if (q.category === 'Social') {
        socialScore += value;
        socialCount++;
      }
      if (q.category === 'Instinct') {
        instinctScore += value;
        instinctCount++;
      }
    }
  });

  const avgMental = mentalCount > 0 ? mentalScore / mentalCount : 0;
  const avgEmotional = emotionalCount > 0 ? emotionalScore / emotionalCount : 0;
  const avgSocial = socialCount > 0 ? socialScore / socialCount : 0;
  const avgInstinct = instinctCount > 0 ? instinctScore / instinctCount : 0;

  // Determine dominant trigger
  if (avgMental < 1.0 && avgEmotional >= 1.5 && avgSocial >= 1.5) {
    return DESIRE_LOGIC_ARCHETYPES[0]; // The Intellectual Pursuit
  }
  if (avgEmotional < 1.0) {
    return DESIRE_LOGIC_ARCHETYPES[1]; // The Emotional Magnet
  }
  if (avgSocial < 1.0) {
    return DESIRE_LOGIC_ARCHETYPES[2]; // The Social Climber
  }
  if (avgInstinct < 1.0 && avgEmotional < 1.5) {
    return DESIRE_LOGIC_ARCHETYPES[3]; // The Pattern Repeater
  }
  if (Math.abs(avgMental - avgEmotional) < 0.5 && Math.abs(avgSocial - avgInstinct) < 0.5) {
    return DESIRE_LOGIC_ARCHETYPES[4]; // The Balanced Pursuer
  }
  
  return DESIRE_LOGIC_ARCHETYPES[5]; // The Instinctual Chaser (default)
}



// Dealbreaker Map Pack - 50 Questions (Ultra Exclusive)
// Your hard lines, soft lines, blind spots, and contradictions.
// Users see the secret standards they enforce, the ones they break under pressure, what they ignore when attracted, and what instantly shuts things down.
// © 2025 GEISTS, LLC. All rights reserved.

const DEALBREAKER_MAP_QUIZ_ITEMS = [
  // Hard Lines (13 questions)
  {
    id: "deal_000",
    category: "HardLines",
    text: "What instantly ends your interest?",
    options: [
      { value: 0, label: "Lying or deception" },
      { value: 1, label: "Disrespect or rudeness" },
      { value: 2, label: "Different values on key issues" },
      { value: 3, label: "Not many things are instant dealbreakers" }
    ]
  },
  {
    id: "deal_001",
    category: "HardLines",
    text: "You have a hard line about:",
    options: [
      { value: 0, label: "Honesty and transparency" },
      { value: 1, label: "How they treat others" },
      { value: 2, label: "Lifestyle compatibility" },
      { value: 3, label: "Core moral values" }
    ]
  },
  {
    id: "deal_002",
    category: "HardLines",
    text: "A dealbreaker you never compromise on:",
    options: [
      { value: 0, label: "Cheating or infidelity" },
      { value: 1, label: "Substance abuse" },
      { value: 2, label: "Abusive behavior" },
      { value: 3, label: "Incompatible life goals" }
    ]
  },
  {
    id: "deal_003",
    category: "HardLines",
    text: "You end things immediately if someone:",
    options: [
      { value: 0, label: "Lies about something significant" },
      { value: 1, label: "Treats service workers poorly" },
      { value: 2, label: "Shows disrespect to you" },
      { value: 3, label: "Crosses a clear boundary" }
    ]
  },
  {
    id: "deal_004",
    category: "HardLines",
    text: "Your non-negotiable standard is:",
    options: [
      { value: 0, label: "Complete honesty" },
      { value: 1, label: "Mutual respect" },
      { value: 2, label: "Shared core values" },
      { value: 3, label: "I don't have absolute non-negotiables" }
    ]
  },
  {
    id: "deal_005",
    category: "HardLines",
    text: "You have zero tolerance for:",
    options: [
      { value: 0, label: "Dishonesty in any form" },
      { value: 1, label: "Disrespectful behavior" },
      { value: 2, label: "Toxic communication" },
      { value: 3, label: "Major incompatibilities" }
    ]
  },
  {
    id: "deal_006",
    category: "HardLines",
    text: "What would make you walk away permanently?",
    options: [
      { value: 0, label: "Betrayal of trust" },
      { value: 1, label: "Repeated boundary violations" },
      { value: 2, label: "Fundamental value mismatch" },
      { value: 3, label: "It depends on the situation" }
    ]
  },
  {
    id: "deal_007",
    category: "HardLines",
    text: "Your most rigid standard is:",
    options: [
      { value: 0, label: "Integrity and truthfulness" },
      { value: 1, label: "How they treat you" },
      { value: 2, label: "Life goals alignment" },
      { value: 3, label: "I'm flexible on most things" }
    ]
  },
  {
    id: "deal_008",
    category: "HardLines",
    text: "You never give second chances for:",
    options: [
      { value: 0, label: "Lying or cheating" },
      { value: 1, label: "Physical or emotional abuse" },
      { value: 2, label: "Repeated disrespect" },
      { value: 3, label: "I believe in second chances" }
    ]
  },
  {
    id: "deal_009",
    category: "HardLines",
    text: "A hard line that others might find strict:",
    options: [
      { value: 0, label: "Complete transparency" },
      { value: 1, label: "No contact with exes" },
      { value: 2, label: "Specific lifestyle choices" },
      { value: 3, label: "I don't think I have strict lines" }
    ]
  },
  {
    id: "deal_010",
    category: "HardLines",
    text: "You consider it unforgivable if someone:",
    options: [
      { value: 0, label: "Lies repeatedly" },
      { value: 1, label: "Betrays your trust" },
      { value: 2, label: "Crosses a clear boundary" },
      { value: 3, label: "Very few things are unforgivable" }
    ]
  },
  {
    id: "deal_011",
    category: "HardLines",
    text: "Your dealbreakers are:",
    options: [
      { value: 0, label: "Very clear and firm" },
      { value: 1, label: "Clear but flexible in context" },
      { value: 2, label: "Somewhat flexible" },
      { value: 3, label: "Mostly flexible" }
    ]
  },
  {
    id: "deal_012",
    category: "HardLines",
    text: "You enforce your hard lines:",
    options: [
      { value: 0, label: "Immediately and consistently" },
      { value: 1, label: "Usually, with some exceptions" },
      { value: 2, label: "When it really matters" },
      { value: 3, label: "Depends on the situation" }
    ]
  },

  // Soft Lines (12 questions)
  {
    id: "deal_013",
    category: "SoftLines",
    text: "Something that bothers you but isn't a dealbreaker:",
    options: [
      { value: 0, label: "Different communication styles" },
      { value: 1, label: "Messy living habits" },
      { value: 2, label: "Different interests" },
      { value: 3, label: "Most things are negotiable" }
    ]
  },
  {
    id: "deal_014",
    category: "SoftLines",
    text: "You have soft lines about:",
    options: [
      { value: 0, label: "Texting habits and responsiveness" },
      { value: 1, label: "Social media behavior" },
      { value: 2, label: "Spending habits" },
      { value: 3, label: "Very few things - I'm flexible" }
    ]
  },
  {
    id: "deal_015",
    category: "SoftLines",
    text: "Something you'd overlook if you're really attracted:",
    options: [
      { value: 0, label: "Inconsistent communication" },
      { value: 1, label: "Different hobbies" },
      { value: 2, label: "Past relationship patterns" },
      { value: 3, label: "Most things if attraction is strong" }
    ]
  },
  {
    id: "deal_016",
    category: "SoftLines",
    text: "You're flexible about:",
    options: [
      { value: 0, label: "Communication preferences" },
      { value: 1, label: "Lifestyle differences" },
      { value: 2, label: "Personality quirks" },
      { value: 3, label: "Almost everything" }
    ]
  },
  {
    id: "deal_017",
    category: "SoftLines",
    text: "A preference that becomes flexible under pressure:",
    options: [
      { value: 0, label: "How often you see each other" },
      { value: 1, label: "Their friend group" },
      { value: 2, label: "Their career path" },
      { value: 3, label: "Most preferences if needed" }
    ]
  },
  {
    id: "deal_018",
    category: "SoftLines",
    text: "You're willing to compromise on:",
    options: [
      { value: 0, label: "Communication style" },
      { value: 1, label: "Time together" },
      { value: 2, label: "Some lifestyle choices" },
      { value: 3, label: "Almost everything if it's right" }
    ]
  },
  {
    id: "deal_019",
    category: "SoftLines",
    text: "Something you'd accept if everything else is perfect:",
    options: [
      { value: 0, label: "Different social needs" },
      { value: 1, label: "Career-focused lifestyle" },
      { value: 2, label: "Past baggage" },
      { value: 3, label: "Many things for the right person" }
    ]
  },
  {
    id: "deal_020",
    category: "SoftLines",
    text: "Your soft lines are:",
    options: [
      { value: 0, label: "Clear preferences but negotiable" },
      { value: 1, label: "Flexible based on context" },
      { value: 2, label: "Very flexible" },
      { value: 3, label: "Almost non-existent" }
    ]
  },
  {
    id: "deal_021",
    category: "SoftLines",
    text: "You break your soft lines when:",
    options: [
      { value: 0, label: "Attraction is strong" },
      { value: 1, label: "You really like someone" },
      { value: 2, label: "You're feeling pressure" },
      { value: 3, label: "You don't really have soft lines" }
    ]
  },
  {
    id: "deal_022",
    category: "SoftLines",
    text: "You're willing to overlook:",
    options: [
      { value: 0, label: "Minor inconsistencies" },
      { value: 1, label: "Communication gaps" },
      { value: 2, label: "Past issues" },
      { value: 3, label: "Many things for connection" }
    ]
  },
  {
    id: "deal_023",
    category: "SoftLines",
    text: "A standard that weakens when you're attracted:",
    options: [
      { value: 0, label: "Response time expectations" },
      { value: 1, label: "Frequency of contact" },
      { value: 2, label: "Social behavior" },
      { value: 3, label: "Many standards if attraction is strong" }
    ]
  },
  {
    id: "deal_024",
    category: "SoftLines",
    text: "You compromise on soft lines:",
    options: [
      { value: 0, label: "Often when attracted" },
      { value: 1, label: "Sometimes if it's important" },
      { value: 2, label: "Rarely" },
      { value: 3, label: "I don't have soft lines to compromise" }
    ]
  },

  // Blind Spots (13 questions)
  {
    id: "deal_025",
    category: "BlindSpots",
    text: "Something you overlook when attracted:",
    options: [
      { value: 0, label: "Red flags in their behavior" },
      { value: 1, label: "Incompatibilities" },
      { value: 2, label: "How they treat you" },
      { value: 3, label: "I try not to overlook things" }
    ]
  },
  {
    id: "deal_026",
    category: "BlindSpots",
    text: "You ignore red flags when:",
    options: [
      { value: 0, label: "You're really attracted" },
      { value: 1, label: "You want it to work" },
      { value: 2, label: "You're invested" },
      { value: 3, label: "I try to notice all red flags" }
    ]
  },
  {
    id: "deal_027",
    category: "BlindSpots",
    text: "Your biggest blind spot is:",
    options: [
      { value: 0, label: "Ignoring how they actually treat you" },
      { value: 1, label: "Overlooking incompatibilities" },
      { value: 2, label: "Believing their words over actions" },
      { value: 3, label: "I don't think I have blind spots" }
    ]
  },
  {
    id: "deal_028",
    category: "BlindSpots",
    text: "You rationalize away:",
    options: [
      { value: 0, label: "Inconsistent behavior" },
      { value: 1, label: "Red flags" },
      { value: 2, label: "Your gut feelings" },
      { value: 3, label: "I try not to rationalize" }
    ]
  },
  {
    id: "deal_029",
    category: "BlindSpots",
    text: "When attracted, you miss:",
    options: [
      { value: 0, label: "How they actually make you feel" },
      { value: 1, label: "Actions that don't match words" },
      { value: 2, label: "Incompatibility signs" },
      { value: 3, label: "I stay pretty aware" }
    ]
  },
  {
    id: "deal_030",
    category: "BlindSpots",
    text: "You make excuses for someone's behavior when:",
    options: [
      { value: 0, label: "You're attracted to them" },
      { value: 1, label: "You want it to work" },
      { value: 2, label: "You're emotionally invested" },
      { value: 3, label: "I don't make excuses" }
    ]
  },
  {
    id: "deal_031",
    category: "BlindSpots",
    text: "Your blind spot is ignoring:",
    options: [
      { value: 0, label: "Repeated patterns of behavior" },
      { value: 1, label: "Your own boundaries" },
      { value: 2, label: "Gut feelings about incompatibility" },
      { value: 3, label: "I try to see everything clearly" }
    ]
  },
  {
    id: "deal_032",
    category: "BlindSpots",
    text: "You're blind to:",
    options: [
      { value: 0, label: "How their actions affect you" },
      { value: 1, label: "Fundamental incompatibilities" },
      { value: 2, label: "Your own needs being unmet" },
      { value: 3, label: "I try to stay aware" }
    ]
  },
  {
    id: "deal_033",
    category: "BlindSpots",
    text: "When you really like someone, you overlook:",
    options: [
      { value: 0, label: "Their actual availability" },
      { value: 1, label: "How they prioritize you" },
      { value: 2, label: "Consistency issues" },
      { value: 3, label: "I try to see the full picture" }
    ]
  },
  {
    id: "deal_034",
    category: "BlindSpots",
    text: "You don't see that you're:",
    options: [
      { value: 0, label: "Accepting less than you deserve" },
      { value: 1, label: "Ignoring your own standards" },
      { value: 2, label: "Making excuses for them" },
      { value: 3, label: "I stay pretty self-aware" }
    ]
  },
  {
    id: "deal_035",
    category: "BlindSpots",
    text: "Your biggest blind spot when attracted:",
    options: [
      { value: 0, label: "Their true intentions" },
      { value: 1, label: "Your own boundaries" },
      { value: 2, label: "Compatibility reality" },
      { value: 3, label: "I don't think I have blind spots" }
    ]
  },
  {
    id: "deal_036",
    category: "BlindSpots",
    text: "You miss seeing:",
    options: [
      { value: 0, label: "How their words don't match actions" },
      { value: 1, label: "That you're settling" },
      { value: 2, label: "Red flags you'd see in others" },
      { value: 3, label: "I try to see everything clearly" }
    ]
  },
  {
    id: "deal_037",
    category: "BlindSpots",
    text: "When attracted, you're blind to:",
    options: [
      { value: 0, label: "Your own dealbreakers being crossed" },
      { value: 1, label: "Incompatibility signs" },
      { value: 2, label: "Your gut telling you no" },
      { value: 3, label: "I stay aware of everything" }
    ]
  },

  // Contradictions (12 questions)
  {
    id: "deal_038",
    category: "Contradictions",
    text: "You say you won't tolerate X, but then you do when:",
    options: [
      { value: 0, label: "You're really attracted" },
      { value: 1, label: "You want it to work" },
      { value: 2, label: "You're emotionally invested" },
      { value: 3, label: "I'm consistent with my standards" }
    ]
  },
  {
    id: "deal_039",
    category: "Contradictions",
    text: "Your biggest contradiction is:",
    options: [
      { value: 0, label: "Saying you have high standards but accepting less" },
      { value: 1, label: "Wanting consistency but tolerating inconsistency" },
      { value: 2, label: "Saying no drama but choosing drama" },
      { value: 3, label: "I don't think I contradict myself" }
    ]
  },
  {
    id: "deal_040",
    category: "Contradictions",
    text: "You contradict yourself by:",
    options: [
      { value: 0, label: "Setting boundaries then breaking them" },
      { value: 1, label: "Saying what you want then accepting opposite" },
      { value: 2, label: "Having standards then ignoring them" },
      { value: 3, label: "I try to be consistent" }
    ]
  },
  {
    id: "deal_041",
    category: "Contradictions",
    text: "You say one thing but do another about:",
    options: [
      { value: 0, label: "What you'll accept" },
      { value: 1, label: "Your boundaries" },
      { value: 2, label: "Your dealbreakers" },
      { value: 3, label: "I'm pretty consistent" }
    ]
  },
  {
    id: "deal_042",
    category: "Contradictions",
    text: "Your standards contradict when:",
    options: [
      { value: 0, label: "Attraction is strong" },
      { value: 1, label: "You're lonely" },
      { value: 2, label: "You're pressured" },
      { value: 3, label: "They're pretty consistent" }
    ]
  },
  {
    id: "deal_043",
    category: "Contradictions",
    text: "You contradict yourself by wanting:",
    options: [
      { value: 0, label: "Stability but choosing chaos" },
      { value: 1, label: "Respect but accepting less" },
      { value: 2, label: "Clarity but staying confused" },
      { value: 3, label: "I know what I want clearly" }
    ]
  },
  {
    id: "deal_044",
    category: "Contradictions",
    text: "You're inconsistent about:",
    options: [
      { value: 0, label: "What you'll tolerate" },
      { value: 1, label: "Your boundaries" },
      { value: 2, label: "Your dealbreakers" },
      { value: 3, label: "I try to be consistent" }
    ]
  },
  {
    id: "deal_045",
    category: "Contradictions",
    text: "Your biggest contradiction is between:",
    options: [
      { value: 0, label: "What you say you want and what you accept" },
      { value: 1, label: "Your standards and your actions" },
      { value: 2, label: "Your boundaries and your tolerance" },
      { value: 3, label: "I don't have contradictions" }
    ]
  },
  {
    id: "deal_046",
    category: "Contradictions",
    text: "You contradict your own values by:",
    options: [
      { value: 0, label: "Accepting behavior you wouldn't do" },
      { value: 1, label: "Staying when you'd tell others to leave" },
      { value: 2, label: "Ignoring your own advice" },
      { value: 3, label: "I live by my values consistently" }
    ]
  },
  {
    id: "deal_047",
    category: "Contradictions",
    text: "Your standards become contradictory when:",
    options: [
      { value: 0, label: "You're attracted to someone" },
      { value: 1, label: "You want a relationship" },
      { value: 2, label: "You're feeling pressure" },
      { value: 3, label: "They stay pretty consistent" }
    ]
  },
  {
    id: "deal_048",
    category: "Contradictions",
    text: "You say you won't but then you do:",
    options: [
      { value: 0, label: "Accept certain behaviors" },
      { value: 1, label: "Break your own boundaries" },
      { value: 2, label: "Stay when you should leave" },
      { value: 3, label: "I stick to what I say" }
    ]
  },
  {
    id: "deal_049",
    category: "Contradictions",
    text: "Your contradictions show you:",
    options: [
      { value: 0, label: "Have blind spots about your standards" },
      { value: 1, label: "Aren't clear on what you really want" },
      { value: 2, label: "Prioritize connection over standards" },
      { value: 3, label: "Are pretty clear and consistent" }
    ]
  }
];

const DEALBREAKER_MAP_ARCHETYPES = [
  {
    id: "deal_arch_0",
    name: "The Uncompromising",
    description: "You have clear, firm hard lines and you stick to them. You know what you won't tolerate and you enforce your boundaries consistently. Your standards are non-negotiable.",
    characteristics: [
      "Clear hard lines",
      "Consistent enforcement",
      "Non-negotiable standards",
      "Willing to walk away"
    ],
    suggestions: [
      "Ensure your hard lines serve you, not limit you",
      "Balance firmness with flexibility where appropriate",
      "Notice if hard lines are protecting you or isolating you"
    ]
  },
  {
    id: "deal_arch_1",
    name: "The Flexible Standard Bearer",
    description: "You have preferences and soft lines that you're willing to bend when needed. You're adaptable and willing to compromise on many things, but you know your core non-negotiables.",
    characteristics: [
      "Flexible soft lines",
      "Willing to compromise",
      "Clear on core values",
      "Adaptable to context"
    ],
    suggestions: [
      "Ensure flexibility doesn't mean losing yourself",
      "Keep core values clear even when compromising",
      "Notice if you're compromising too much"
    ]
  },
  {
    id: "deal_arch_2",
    name: "The Attraction Blind",
    description: "When you're attracted to someone, you develop major blind spots. You overlook red flags, ignore incompatibilities, and rationalize away concerns. Your judgment gets clouded by attraction.",
    characteristics: [
      "Blind spots when attracted",
      "Overlooks red flags",
      "Rationalizes concerns",
      "Misses incompatibilities"
    ],
    suggestions: [
      "Get outside perspective when attracted",
      "Write down your standards before getting involved",
      "Notice when you're making excuses"
    ]
  },
  {
    id: "deal_arch_3",
    name: "The Contradictory Standard Holder",
    description: "You have clear standards but you contradict yourself regularly. You say you won't tolerate certain things, then you do. You set boundaries but break them when attracted. Your words and actions don't match.",
    characteristics: [
      "Contradicts own standards",
      "Says one thing, does another",
      "Breaks boundaries when attracted",
      "Inconsistent enforcement"
    ],
    suggestions: [
      "Get clear on why you contradict yourself",
      "Align your actions with your stated standards",
      "Notice the gap between what you say and do"
    ]
  },
  {
    id: "deal_arch_4",
    name: "The Balanced Boundary Setter",
    description: "You have clear hard lines you never compromise, soft lines you're flexible on, and awareness of your blind spots. You're consistent but not rigid, and you stay aware of when attraction clouds your judgment.",
    characteristics: [
      "Clear hard and soft lines",
      "Aware of blind spots",
      "Consistent but flexible",
      "Self-aware about contradictions"
    ],
    suggestions: [
      "Continue maintaining this balance",
      "Regularly reassess your standards",
      "Trust your balanced judgment"
    ]
  },
  {
    id: "deal_arch_5",
    name: "The Boundaryless",
    description: "You don't have clear dealbreakers or standards. You're extremely flexible and willing to adapt to almost anything. You may struggle to know what you actually won't tolerate, leading to accepting less than you deserve.",
    characteristics: [
      "No clear hard lines",
      "Extremely flexible",
      "Accepts almost anything",
      "Struggles with boundaries"
    ],
    suggestions: [
      "Identify your core non-negotiables",
      "Practice saying no to things you don't want",
      "Notice if you're accepting less than you deserve"
    ]
  }
];

function calculateDealbreakerMapArchetype(answers) {
  let hardLinesScore = 0;
  let softLinesScore = 0;
  let blindSpotsScore = 0;
  let contradictionsScore = 0;
  let hardLinesCount = 0;
  let softLinesCount = 0;
  let blindSpotsCount = 0;
  let contradictionsCount = 0;

  Object.entries(answers).forEach(([key, value]) => {
    const q = DEALBREAKER_MAP_QUIZ_ITEMS.find(i => i.id === key);
    if (q) {
      if (q.category === 'HardLines') {
        hardLinesScore += value;
        hardLinesCount++;
      }
      if (q.category === 'SoftLines') {
        softLinesScore += value;
        softLinesCount++;
      }
      if (q.category === 'BlindSpots') {
        blindSpotsScore += value;
        blindSpotsCount++;
      }
      if (q.category === 'Contradictions') {
        contradictionsScore += value;
        contradictionsCount++;
      }
    }
  });

  const avgHardLines = hardLinesCount > 0 ? hardLinesScore / hardLinesCount : 0;
  const avgSoftLines = softLinesCount > 0 ? softLinesScore / softLinesCount : 0;
  const avgBlindSpots = blindSpotsCount > 0 ? blindSpotsScore / blindSpotsCount : 0;
  const avgContradictions = contradictionsCount > 0 ? contradictionsScore / contradictionsCount : 0;

  // Determine archetype
  if (avgHardLines < 1.0 && avgSoftLines >= 2.0 && avgBlindSpots >= 2.0 && avgContradictions >= 2.0) {
    return DEALBREAKER_MAP_ARCHETYPES[0]; // The Uncompromising
  }
  if (avgSoftLines < 1.5 && avgHardLines >= 1.5) {
    return DEALBREAKER_MAP_ARCHETYPES[1]; // The Flexible Standard Bearer
  }
  if (avgBlindSpots < 1.0) {
    return DEALBREAKER_MAP_ARCHETYPES[2]; // The Attraction Blind
  }
  if (avgContradictions < 1.0) {
    return DEALBREAKER_MAP_ARCHETYPES[3]; // The Contradictory Standard Holder
  }
  if (Math.abs(avgHardLines - avgSoftLines) < 0.5 && avgBlindSpots >= 1.5 && avgContradictions >= 1.5) {
    return DEALBREAKER_MAP_ARCHETYPES[4]; // The Balanced Boundary Setter
  }
  
  return DEALBREAKER_MAP_ARCHETYPES[5]; // The Boundaryless (default)
}



// Identity Performance Pack - 50 Questions (Ultra Exclusive)
// How you perform your identity on dates, apps, and IRL — consciously and unconsciously.
// Analyzes your dating persona, your calibration to the room, your signaling, how people read your behavior, and how consistent or adaptable you are.
// © 2025 GEISTS, LLC. All rights reserved.

const IDENTITY_PERFORMANCE_QUIZ_ITEMS = [
  // Dating Persona (13 questions)
  {
    id: "idp_000",
    category: "Persona",
    text: "On dates, you tend to be:",
    options: [
      { value: 0, label: "Your authentic self from the start" },
      { value: 1, label: "A polished version of yourself" },
      { value: 2, label: "Different depending on who you're with" },
      { value: 3, label: "Whoever they seem to want" }
    ]
  },
  {
    id: "idp_001",
    category: "Persona",
    text: "Your dating profile shows:",
    options: [
      { value: 0, label: "The real you, flaws and all" },
      { value: 1, label: "Your best self" },
      { value: 2, label: "Who you think they want" },
      { value: 3, label: "A curated persona" }
    ]
  },
  {
    id: "idp_002",
    category: "Persona",
    text: "On first dates, you:",
    options: [
      { value: 0, label: "Show up exactly as you are" },
      { value: 1, label: "Put your best foot forward" },
      { value: 2, label: "Adapt to match their energy" },
      { value: 3, label: "Perform a role you think works" }
    ]
  },
  {
    id: "idp_003",
    category: "Persona",
    text: "Your dating persona is:",
    options: [
      { value: 0, label: "100% authentic" },
      { value: 1, label: "Mostly you, slightly enhanced" },
      { value: 2, label: "Adaptive based on the person" },
      { value: 3, label: "A performance of who you think they want" }
    ]
  },
  {
    id: "idp_004",
    category: "Persona",
    text: "You present yourself as:",
    options: [
      { value: 0, label: "Exactly who you are" },
      { value: 1, label: "Your best version" },
      { value: 2, label: "Different versions for different people" },
      { value: 3, label: "Whoever gets the best response" }
    ]
  },
  {
    id: "idp_005",
    category: "Persona",
    text: "On dating apps, you:",
    options: [
      { value: 0, label: "Are completely honest about yourself" },
      { value: 1, label: "Highlight your best qualities" },
      { value: 2, label: "Tailor your profile to attract specific types" },
      { value: 3, label: "Create a persona that gets matches" }
    ]
  },
  {
    id: "idp_006",
    category: "Persona",
    text: "You reveal your authentic self:",
    options: [
      { value: 0, label: "Immediately - first date" },
      { value: 1, label: "Gradually over time" },
      { value: 2, label: "When you feel safe" },
      { value: 3, label: "Rarely - you keep up the performance" }
    ]
  },
  {
    id: "idp_007",
    category: "Persona",
    text: "Your dating persona vs. real you:",
    options: [
      { value: 0, label: "Identical - no difference" },
      { value: 1, label: "Very similar, slightly enhanced" },
      { value: 2, label: "Similar but adapted to context" },
      { value: 3, label: "Quite different - you perform a role" }
    ]
  },
  {
    id: "idp_008",
    category: "Persona",
    text: "You feel most authentic when:",
    options: [
      { value: 0, label: "Showing all sides of yourself" },
      { value: 1, label: "Presenting your best self" },
      { value: 2, label: "Adapting to the situation" },
      { value: 3, label: "When you know what they want" }
    ]
  },
  {
    id: "idp_009",
    category: "Persona",
    text: "Your dating persona is:",
    options: [
      { value: 0, label: "Unconscious - you don't think about it" },
      { value: 1, label: "Semi-conscious - you're aware but natural" },
      { value: 2, label: "Conscious - you adapt intentionally" },
      { value: 3, label: "Very calculated - you perform strategically" }
    ]
  },
  {
    id: "idp_010",
    category: "Persona",
    text: "You show your flaws:",
    options: [
      { value: 0, label: "Early - you want them to see real you" },
      { value: 1, label: "Gradually as trust builds" },
      { value: 2, label: "Only when necessary" },
      { value: 3, label: "Rarely - you hide them" }
    ]
  },
  {
    id: "idp_011",
    category: "Persona",
    text: "Your dating persona is created by:",
    options: [
      { value: 0, label: "Just being yourself naturally" },
      { value: 1, label: "Highlighting your strengths" },
      { value: 2, label: "Observing what works and adapting" },
      { value: 3, label: "Strategic performance based on desired outcome" }
    ]
  },
  {
    id: "idp_012",
    category: "Persona",
    text: "You perform your identity:",
    options: [
      { value: 0, label: "Never - you're always authentic" },
      { value: 1, label: "Minimally - slight enhancement" },
      { value: 2, label: "Moderately - you adapt to context" },
      { value: 3, label: "Significantly - you perform roles" }
    ]
  },

  // Calibration (12 questions)
  {
    id: "idp_013",
    category: "Calibration",
    text: "You adjust your behavior based on:",
    options: [
      { value: 0, label: "What feels natural to you" },
      { value: 1, label: "Reading their energy and matching it" },
      { value: 2, label: "What seems to work best" },
      { value: 3, label: "Whatever gets a positive response" }
    ]
  },
  {
    id: "idp_014",
    category: "Calibration",
    text: "In social situations, you:",
    options: [
      { value: 0, label: "Stay true to yourself regardless" },
      { value: 1, label: "Slightly adjust to fit the room" },
      { value: 2, label: "Significantly adapt to the group" },
      { value: 3, label: "Transform to match expectations" }
    ]
  },
  {
    id: "idp_015",
    category: "Calibration",
    text: "You read the room and:",
    options: [
      { value: 0, label: "Stay authentic anyway" },
      { value: 1, label: "Make minor adjustments" },
      { value: 2, label: "Adapt to fit in" },
      { value: 3, label: "Change yourself to match" }
    ]
  },
  {
    id: "idp_016",
    category: "Calibration",
    text: "Your ability to adapt is:",
    options: [
      { value: 0, label: "Low - you stay consistent" },
      { value: 1, label: "Moderate - you adjust slightly" },
      { value: 2, label: "High - you adapt easily" },
      { value: 3, label: "Very high - you're a chameleon" }
    ]
  },
  {
    id: "idp_017",
    category: "Calibration",
    text: "You calibrate to the room:",
    options: [
      { value: 0, label: "Never - you're always you" },
      { value: 1, label: "Minimally - slight shifts" },
      { value: 2, label: "Moderately - you adapt" },
      { value: 3, label: "Completely - you become who they need" }
    ]
  },
  {
    id: "idp_018",
    category: "Calibration",
    text: "When someone seems different from you, you:",
    options: [
      { value: 0, label: "Stay true to yourself" },
      { value: 1, label: "Find common ground naturally" },
      { value: 2, label: "Adapt to bridge the gap" },
      { value: 3, label: "Change yourself to match them" }
    ]
  },
  {
    id: "idp_019",
    category: "Calibration",
    text: "Your calibration level is:",
    options: [
      { value: 0, label: "Low - consistent across situations" },
      { value: 1, label: "Medium - adaptable when needed" },
      { value: 2, label: "High - you adapt frequently" },
      { value: 3, label: "Very high - you're constantly adjusting" }
    ]
  },
  {
    id: "idp_020",
    category: "Calibration",
    text: "You match someone's energy:",
    options: [
      { value: 0, label: "Rarely - you have your own energy" },
      { value: 1, label: "Sometimes if it feels right" },
      { value: 2, label: "Often to create connection" },
      { value: 3, label: "Always - you mirror them" }
    ]
  },
  {
    id: "idp_021",
    category: "Calibration",
    text: "You adapt your communication style:",
    options: [
      { value: 0, label: "Never - you communicate your way" },
      { value: 1, label: "Slightly based on context" },
      { value: 2, label: "Moderately to connect better" },
      { value: 3, label: "Completely to match them" }
    ]
  },
  {
    id: "idp_022",
    category: "Calibration",
    text: "Your calibration happens:",
    options: [
      { value: 0, label: "Unconsciously - naturally" },
      { value: 1, label: "Semi-consciously - with awareness" },
      { value: 2, label: "Consciously - intentional adjustment" },
      { value: 3, label: "Very consciously - strategic adaptation" }
    ]
  },
  {
    id: "idp_023",
    category: "Calibration",
    text: "You adjust based on their response:",
    options: [
      { value: 0, label: "Never - you stay consistent" },
      { value: 1, label: "Minimally - you notice but stay you" },
      { value: 2, label: "Moderately - you adapt to connect" },
      { value: 3, label: "Significantly - you change to please" }
    ]
  },
  {
    id: "idp_024",
    category: "Calibration",
    text: "Your calibration to the room is:",
    options: [
      { value: 0, label: "Non-existent - you're always you" },
      { value: 1, label: "Minimal - slight situational awareness" },
      { value: 2, label: "Moderate - you adapt when helpful" },
      { value: 3, label: "Maximum - you transform for context" }
    ]
  },

  // Signaling (13 questions)
  {
    id: "idp_025",
    category: "Signaling",
    text: "You signal who you are through:",
    options: [
      { value: 0, label: "Just being yourself naturally" },
      { value: 1, label: "Your words and actions matching" },
      { value: 2, label: "Intentionally chosen signals" },
      { value: 3, label: "Strategic messaging" }
    ]
  },
  {
    id: "idp_026",
    category: "Signaling",
    text: "Your signals are:",
    options: [
      { value: 0, label: "Unconscious - just who you are" },
      { value: 1, label: "Natural but aware" },
      { value: 2, label: "Intentionally crafted" },
      { value: 3, label: "Very calculated" }
    ]
  },
  {
    id: "idp_027",
    category: "Signaling",
    text: "You signal your availability:",
    options: [
      { value: 0, label: "Naturally through behavior" },
      { value: 1, label: "Through clear communication" },
      { value: 2, label: "Through mixed signals" },
      { value: 3, label: "Through intentional ambiguity" }
    ]
  },
  {
    id: "idp_028",
    category: "Signaling",
    text: "People read you as:",
    options: [
      { value: 0, label: "Exactly who you are" },
      { value: 1, label: "Mostly authentic" },
      { value: 2, label: "Sometimes confusing" },
      { value: 3, label: "Hard to read" }
    ]
  },
  {
    id: "idp_029",
    category: "Signaling",
    text: "Your signaling is:",
    options: [
      { value: 0, label: "Clear and consistent" },
      { value: 1, label: "Mostly clear" },
      { value: 2, label: "Mixed or confusing" },
      { value: 3, label: "Intentional ambiguity" }
    ]
  },
  {
    id: "idp_030",
    category: "Signaling",
    text: "You signal interest through:",
    options: [
      { value: 0, label: "Direct communication" },
      { value: 1, label: "Actions matching words" },
      { value: 2, label: "Subtle hints" },
      { value: 3, label: "Playing hard to get" }
    ]
  },
  {
    id: "idp_031",
    category: "Signaling",
    text: "Your signals are consistent:",
    options: [
      { value: 0, label: "Always - you're clear" },
      { value: 1, label: "Usually - mostly consistent" },
      { value: 2, label: "Sometimes - mixed signals" },
      { value: 3, label: "Rarely - confusing" }
    ]
  },
  {
    id: "idp_032",
    category: "Signaling",
    text: "You use signaling to:",
    options: [
      { value: 0, label: "Express who you authentically are" },
      { value: 1, label: "Attract compatible people" },
      { value: 2, label: "Control how you're perceived" },
      { value: 3, label: "Manipulate outcomes" }
    ]
  },
  {
    id: "idp_033",
    category: "Signaling",
    text: "People interpret your signals as:",
    options: [
      { value: 0, label: "Genuine and clear" },
      { value: 1, label: "Mostly authentic" },
      { value: 2, label: "Confusing or mixed" },
      { value: 3, label: "Hard to decipher" }
    ]
  },
  {
    id: "idp_034",
    category: "Signaling",
    text: "Your signaling style is:",
    options: [
      { value: 0, label: "Direct and transparent" },
      { value: 1, label: "Clear but nuanced" },
      { value: 2, label: "Subtle and indirect" },
      { value: 3, label: "Calculated and strategic" }
    ]
  },
  {
    id: "idp_035",
    category: "Signaling",
    text: "You're aware of the signals you send:",
    options: [
      { value: 0, label: "Not really - you're just you" },
      { value: 1, label: "Somewhat - you notice" },
      { value: 2, label: "Yes - you're intentional" },
      { value: 3, label: "Very aware - you craft them" }
    ]
  },
  {
    id: "idp_036",
    category: "Signaling",
    text: "Your signals match your reality:",
    options: [
      { value: 0, label: "Always - they're authentic" },
      { value: 1, label: "Usually - mostly aligned" },
      { value: 2, label: "Sometimes - mixed" },
      { value: 3, label: "Rarely - they're performance" }
    ]
  },
  {
    id: "idp_037",
    category: "Signaling",
    text: "You signal your identity:",
    options: [
      { value: 0, label: "Naturally through being yourself" },
      { value: 1, label: "Through authentic expression" },
      { value: 2, label: "Through intentional presentation" },
      { value: 3, label: "Through strategic performance" }
    ]
  },

  // Consistency (12 questions)
  {
    id: "idp_038",
    category: "Consistency",
    text: "You're consistent across different situations:",
    options: [
      { value: 0, label: "Always - you're the same everywhere" },
      { value: 1, label: "Usually - mostly consistent" },
      { value: 2, label: "Sometimes - you adapt" },
      { value: 3, label: "Rarely - you're different everywhere" }
    ]
  },
  {
    id: "idp_039",
    category: "Consistency",
    text: "Your identity performance is:",
    options: [
      { value: 0, label: "Consistent - same you everywhere" },
      { value: 1, label: "Mostly consistent with minor variations" },
      { value: 2, label: "Adaptive - different in different contexts" },
      { value: 3, label: "Inconsistent - very different everywhere" }
    ]
  },
  {
    id: "idp_040",
    category: "Consistency",
    text: "Between apps, dates, and IRL, you're:",
    options: [
      { value: 0, label: "Exactly the same" },
      { value: 1, label: "Very similar" },
      { value: 2, label: "Noticeably different" },
      { value: 3, label: "Completely different" }
    ]
  },
  {
    id: "idp_041",
    category: "Consistency",
    text: "Your consistency level is:",
    options: [
      { value: 0, label: "High - very consistent" },
      { value: 1, label: "Medium - mostly consistent" },
      { value: 2, label: "Low - adaptive" },
      { value: 3, label: "Very low - highly variable" }
    ]
  },
  {
    id: "idp_042",
    category: "Consistency",
    text: "People see the same you:",
    options: [
      { value: 0, label: "Everywhere - totally consistent" },
      { value: 1, label: "Most places - mostly the same" },
      { value: 2, label: "Sometimes - you adapt" },
      { value: 3, label: "Rarely - different you everywhere" }
    ]
  },
  {
    id: "idp_043",
    category: "Consistency",
    text: "Your adaptability vs. consistency:",
    options: [
      { value: 0, label: "High consistency, low adaptability" },
      { value: 1, label: "Balanced - consistent but adaptable" },
      { value: 2, label: "More adaptable, less consistent" },
      { value: 3, label: "Very adaptable, low consistency" }
    ]
  },
  {
    id: "idp_044",
    category: "Consistency",
    text: "You maintain your core identity:",
    options: [
      { value: 0, label: "Always, no matter the context" },
      { value: 1, label: "Usually, with minor adaptations" },
      { value: 2, label: "Sometimes, you adapt significantly" },
      { value: 3, label: "Rarely, you transform for context" }
    ]
  },
  {
    id: "idp_045",
    category: "Consistency",
    text: "Your consistency is:",
    options: [
      { value: 0, label: "Unconscious - you're just naturally consistent" },
      { value: 1, label: "Natural - consistent by nature" },
      { value: 2, label: "Intentional - you try to stay consistent" },
      { value: 3, label: "Low - you adapt too much to be consistent" }
    ]
  },
  {
    id: "idp_046",
    category: "Consistency",
    text: "You're the same person:",
    options: [
      { value: 0, label: "Everywhere, always" },
      { value: 1, label: "Most places, most of the time" },
      { value: 2, label: "Sometimes, depending on context" },
      { value: 3, label: "Rarely - context changes you" }
    ]
  },
  {
    id: "idp_047",
    category: "Consistency",
    text: "Your identity performance varies:",
    options: [
      { value: 0, label: "Never - always consistent" },
      { value: 1, label: "Minimally - slight variations" },
      { value: 2, label: "Moderately - noticeable differences" },
      { value: 3, label: "Significantly - very different" }
    ]
  },
  {
    id: "idp_048",
    category: "Consistency",
    text: "Between conscious and unconscious performance:",
    options: [
      { value: 0, label: "You're always just you naturally" },
      { value: 1, label: "Mostly natural, slight awareness" },
      { value: 2, label: "Mix of conscious and unconscious" },
      { value: 3, label: "Very conscious performance" }
    ]
  },
  {
    id: "idp_049",
    category: "Consistency",
    text: "Your consistency across situations shows:",
    options: [
      { value: 0, label: "Strong sense of self" },
      { value: 1, label: "Authentic core with adaptations" },
      { value: 2, label: "Adaptability over consistency" },
      { value: 3, label: "Unclear sense of self" }
    ]
  }
];

const IDENTITY_PERFORMANCE_ARCHETYPES = [
  {
    id: "idp_arch_0",
    name: "The Authentic Performer",
    description: "You show up as yourself consistently across all contexts. Your identity performance is authentic - you're the same person on apps, dates, and in real life. You don't adapt or perform roles; you just are who you are.",
    characteristics: [
      "Consistent across all contexts",
      "Authentic persona",
      "Low calibration/adapation",
      "Clear signaling"
    ],
    suggestions: [
      "Maintain your authenticity while being open to growth",
      "Notice if consistency serves you in all contexts",
      "Consider slight adaptations where helpful"
    ]
  },
  {
    id: "idp_arch_1",
    name: "The Adaptive Authentic",
    description: "You have a strong authentic core but you adapt to context. You calibrate to the room while staying true to yourself. Your identity performance is mostly consistent with natural variations based on situation.",
    characteristics: [
      "Authentic core with adaptations",
      "Moderate calibration",
      "Clear but nuanced signaling",
      "Balanced consistency"
    ],
    suggestions: [
      "Continue balancing authenticity with adaptability",
      "Ensure adaptations don't compromise your core",
      "Stay aware of when you adapt vs. perform"
    ]
  },
  {
    id: "idp_arch_2",
    name: "The Chameleon",
    description: "You significantly adapt your identity performance based on context, person, and desired outcome. You calibrate heavily to the room and transform to match expectations. Your consistency is low because you're highly adaptable.",
    characteristics: [
      "High adaptability",
      "Low consistency",
      "Heavy calibration",
      "Context-dependent persona"
    ],
    suggestions: [
      "Identify your authentic core beneath adaptations",
      "Notice if adaptability serves you or exhausts you",
      "Practice consistency in safe relationships"
    ]
  },
  {
    id: "idp_arch_3",
    name: "The Strategic Performer",
    description: "You consciously craft and perform your identity based on desired outcomes. Your persona is intentional and calculated. You signal strategically to control how you're perceived. You may lose track of who you authentically are.",
    characteristics: [
      "Conscious performance",
      "Strategic signaling",
      "Calculated persona",
      "Outcome-focused adaptation"
    ],
    suggestions: [
      "Explore who you are without performance",
      "Notice if strategic performance serves or limits you",
      "Practice showing up authentically in safe spaces"
    ]
  },
  {
    id: "idp_arch_4",
    name: "The Unconscious Adapter",
    description: "You unconsciously adapt your identity performance without realizing it. You calibrate to situations automatically and may send mixed signals. You're not fully aware of how much you change between contexts.",
    characteristics: [
      "Unconscious adaptation",
      "Mixed signaling",
      "Variable consistency",
      "Low awareness of performance"
    ],
    suggestions: [
      "Increase awareness of when and how you adapt",
      "Notice patterns in your identity shifts",
      "Explore your authentic core beneath adaptations"
    ]
  },
  {
    id: "idp_arch_5",
    name: "The Polished Self",
    description: "You present a polished, best version of yourself rather than your raw authentic self. You're aware of your performance and enhance your qualities. You calibrate moderately and maintain consistency in your polished persona.",
    characteristics: [
      "Enhanced best self",
      "Moderate calibration",
      "Clear consistent signaling",
      "Conscious enhancement"
    ],
    suggestions: [
      "Gradually reveal more authentic sides",
      "Balance polish with vulnerability",
      "Notice if polish creates distance or connection"
    ]
  }
];

function calculateIdentityPerformanceArchetype(answers) {
  let personaScore = 0;
  let calibrationScore = 0;
  let signalingScore = 0;
  let consistencyScore = 0;
  let personaCount = 0;
  let calibrationCount = 0;
  let signalingCount = 0;
  let consistencyCount = 0;

  Object.entries(answers).forEach(([key, value]) => {
    const q = IDENTITY_PERFORMANCE_QUIZ_ITEMS.find(i => i.id === key);
    if (q) {
      if (q.category === 'Persona') {
        personaScore += value;
        personaCount++;
      }
      if (q.category === 'Calibration') {
        calibrationScore += value;
        calibrationCount++;
      }
      if (q.category === 'Signaling') {
        signalingScore += value;
        signalingCount++;
      }
      if (q.category === 'Consistency') {
        consistencyScore += value;
        consistencyCount++;
      }
    }
  });

  const avgPersona = personaCount > 0 ? personaScore / personaCount : 0;
  const avgCalibration = calibrationCount > 0 ? calibrationScore / calibrationCount : 0;
  const avgSignaling = signalingCount > 0 ? signalingScore / signalingCount : 0;
  const avgConsistency = consistencyCount > 0 ? consistencyScore / consistencyCount : 0;

  // Determine archetype
  if (avgPersona < 1.0 && avgCalibration >= 2.0 && avgConsistency < 1.0) {
    return IDENTITY_PERFORMANCE_ARCHETYPES[0]; // The Authentic Performer
  }
  if (avgPersona < 1.5 && avgCalibration < 1.5 && avgConsistency < 1.5) {
    return IDENTITY_PERFORMANCE_ARCHETYPES[1]; // The Adaptive Authentic
  }
  if (avgCalibration < 1.0 && avgConsistency >= 2.0) {
    return IDENTITY_PERFORMANCE_ARCHETYPES[2]; // The Chameleon
  }
  if (avgSignaling < 1.0 && avgPersona < 1.0) {
    return IDENTITY_PERFORMANCE_ARCHETYPES[3]; // The Strategic Performer
  }
  if (avgCalibration < 1.5 && avgSignaling >= 1.5 && avgConsistency >= 1.5) {
    return IDENTITY_PERFORMANCE_ARCHETYPES[4]; // The Unconscious Adapter
  }
  
  return IDENTITY_PERFORMANCE_ARCHETYPES[5]; // The Polished Self (default)
}


// Referral-exclusive quizzes — not sold via IAP

const REFERRAL_FIRST_SPARK_QUIZ_ITEMS = [
  { id: "rfs_001", category: "Spark", text: "On a first date, you usually know within the first hour whether there's chemistry.", options: [{ value: 0, label: "Almost always — I feel it fast" }, { value: 1, label: "Often, but I give it a full date" }, { value: 2, label: "Rarely — chemistry grows for me" }, { value: 3, label: "Almost never on date one" }] },
  { id: "rfs_002", category: "Spark", text: "What makes you lean in on a first meet?", options: [{ value: 0, label: "Playful banter and quick wit" }, { value: 1, label: "Deep conversation that goes somewhere" }, { value: 2, label: "Calm comfort — no pressure" }, { value: 3, label: "Shared curiosity about each other" }] },
  { id: "rfs_003", category: "Spark", text: "If the vibe is good but they're not your usual type, you:", options: [{ value: 0, label: "Go with the spark anyway" }, { value: 1, label: "Stay open and see where it goes" }, { value: 2, label: "Get cautious — type matters to me" }, { value: 3, label: "Usually pass unless logic checks out" }] },
  { id: "rfs_004", category: "Signal", text: "You feel most attracted when someone:", options: [{ value: 0, label: "Is confident and a little bold" }, { value: 1, label: "Is emotionally present and attentive" }, { value: 2, label: "Is low-key but consistent" }, { value: 3, label: "Surprises you with depth" }] },
  { id: "rfs_005", category: "Signal", text: "After a great first date, you typically:", options: [{ value: 0, label: "Text right away while the energy is hot" }, { value: 1, label: "Text the next day with something specific" }, { value: 2, label: "Wait to see if they reach out first" }, { value: 3, label: "Play it cool for a few days" }] },
  { id: "rfs_006", category: "Signal", text: "A 'meh' first date for you usually means:", options: [{ value: 0, label: "Move on — life is short" }, { value: 1, label: "One more try if there's a small spark" }, { value: 2, label: "Give it a third chance if they're kind" }, { value: 3, label: "I rarely write people off quickly" }] },
  { id: "rfs_007", category: "Spark", text: "Your ideal first-date energy is:", options: [{ value: 0, label: "Electric — a little unpredictable" }, { value: 1, label: "Warm — easy to be myself" }, { value: 2, label: "Low-stakes — no performance" }, { value: 3, label: "Intentional — we're both showing up" }] },
  { id: "rfs_008", category: "Signal", text: "When someone flirts with you early, you:", options: [{ value: 0, label: "Love it — match their energy" }, { value: 1, label: "Enjoy it if it feels mutual" }, { value: 2, label: "Prefer subtlety first" }, { value: 3, label: "Need friendship vibes before flirting" }] },
  { id: "rfs_009", category: "Spark", text: "You're most likely to feel a 'first spark' with someone who:", options: [{ value: 0, label: "Makes you laugh and keeps up" }, { value: 1, label: "Asks questions that actually land" }, { value: 2, label: "Feels safe without being boring" }, { value: 3, label: "Has their own world you're curious about" }] },
  { id: "rfs_010", category: "Signal", text: "If there's chemistry but awkward moments, you:", options: [{ value: 0, label: "Laugh through it — charm wins" }, { value: 1, label: "Name it lightly and keep going" }, { value: 2, label: "Pull back until it feels smoother" }, { value: 3, label: "Take it as a sign to slow down" }] }
];

const REFERRAL_FIRST_SPARK_ARCHETYPES = [
  { name: "The Instant Spark", description: "You trust first impressions and move when chemistry hits. You bring momentum early and want reciprocity fast.", characteristics: ["Fast read on chemistry", "Bold follow-through", "High energy early", "Low tolerance for lukewarm"], suggestions: ["Leave room for slow-burn people to open up", "Check that speed isn't masking anxiety", "Name what you want by date two"] },
  { name: "The Warm Signal", description: "You feel spark through attunement — attention, humor, and emotional presence matter more than fireworks.", characteristics: ["Reads subtle signals", "Balanced pacing", "Values reciprocity", "Builds on good moments"], suggestions: ["Say when you're interested instead of hinting", "Don't confuse kindness with chemistry", "Protect your energy from mixed signals"] },
  { name: "The Slow Reveal", description: "Your spark builds over time. First dates are data-gathering; attraction deepens when trust and comfort show up.", characteristics: ["Chemistry grows gradually", "Prefers low pressure", "Observes consistency", "Cautious early investment"], suggestions: ["Tell matches you warm up slowly", "Give one great second date when unsure", "Watch for people who need instant validation"] },
  { name: "The Curious Matcher", description: "You're drawn to depth and novelty. Spark for you is intellectual and emotional — you want to feel seen, not just entertained.", characteristics: ["Depth over flash", "Values uniqueness", "Thoughtful pacing", "High standards for conversation"], suggestions: ["Balance depth with lightness on early dates", "Avoid interviewing people", "Let physical chemistry have time too"] }
];

function calculateReferralFirstSparkArchetype(answers) {
  let spark = 0, signal = 0, sparkCount = 0, signalCount = 0;
  Object.entries(answers).forEach(([key, value]) => {
    const q = REFERRAL_FIRST_SPARK_QUIZ_ITEMS.find(i => i.id === key);
    if (!q) return;
    if (q.category === 'Spark') { spark += value; sparkCount++; }
    if (q.category === 'Signal') { signal += value; signalCount++; }
  });
  const avgSpark = sparkCount ? spark / sparkCount : 0;
  const avgSignal = signalCount ? signal / signalCount : 0;
  if (avgSpark < 1.0) return REFERRAL_FIRST_SPARK_ARCHETYPES[0];
  if (avgSignal < 1.2) return REFERRAL_FIRST_SPARK_ARCHETYPES[1];
  if (avgSpark >= 2.0) return REFERRAL_FIRST_SPARK_ARCHETYPES[2];
  return REFERRAL_FIRST_SPARK_ARCHETYPES[3];
}

const REFERRAL_SLOW_BURN_QUIZ_ITEMS = [
  { id: "rsb_001", category: "Pace", text: "Your ideal timeline from first date to exclusivity is:", options: [{ value: 0, label: "A few weeks if it's right" }, { value: 1, label: "1–2 months of consistent dating" }, { value: 2, label: "3+ months — I need time" }, { value: 3, label: "No fixed timeline — it depends on trust" }] },
  { id: "rsb_002", category: "Pace", text: "When someone wants to define the relationship quickly, you:", options: [{ value: 0, label: "Appreciate the clarity" }, { value: 1, label: "Discuss it but won't rush" }, { value: 2, label: "Feel pressured and pull back" }, { value: 3, label: "Need much more time before labels" }] },
  { id: "rsb_003", category: "Depth", text: "You prefer early dating to feel:", options: [{ value: 0, label: "Fun and light — labels later" }, { value: 1, label: "Steady — consistent plans each week" }, { value: 2, label: "Deep — meaningful talks early" }, { value: 3, label: "Flexible — let it unfold naturally" }] },
  { id: "rsb_004", category: "Depth", text: "How often do you want to see someone you're excited about?", options: [{ value: 0, label: "Multiple times a week quickly" }, { value: 1, label: "Once or twice a week at first" }, { value: 2, label: "Every other week until it's official" }, { value: 3, label: "Depends on my bandwidth" }] },
  { id: "rsb_005", category: "Pace", text: "If they're great but travel a lot early on, you:", options: [{ value: 0, label: "Make it work — chemistry is worth it" }, { value: 1, label: "Stay open if communication is strong" }, { value: 2, label: "Worry momentum will die" }, { value: 3, label: "Usually lose interest without consistency" }] },
  { id: "rsb_006", category: "Depth", text: "You're most comfortable escalating intimacy when:", options: [{ value: 0, label: "Attraction is obvious and mutual" }, { value: 1, label: "We've had several great dates" }, { value: 2, label: "Emotional trust is established" }, { value: 3, label: "We're clearly aligned on intentions" }] },
  { id: "rsb_007", category: "Pace", text: "Mixed signals after three good dates make you:", options: [{ value: 0, label: "Ask directly what's up" }, { value: 1, label: "Give one more week of consistency" }, { value: 2, label: "Step back and protect your energy" }, { value: 3, label: "Move on — pace tells the story" }] },
  { id: "rsb_008", category: "Depth", text: "Your texting pace when you're interested is:", options: [{ value: 0, label: "Frequent — I like ongoing contact" }, { value: 1, label: "Daily check-ins feel right" }, { value: 2, label: "A few thoughtful messages" }, { value: 3, label: "Minimal until we're in person again" }] },
  { id: "rsb_009", category: "Pace", text: "You feel most secure when someone:", options: [{ value: 0, label: "Matches your speed without games" }, { value: 1, label: "Plans ahead and follows through" }, { value: 2, label: "Communicates when they're busy" }, { value: 3, label: "Doesn't rush labels before trust" }] },
  { id: "rsb_010", category: "Depth", text: "A connection that builds slowly but steadily feels:", options: [{ value: 0, label: "Ideal — that's how trust forms" }, { value: 1, label: "Good if there's still spark" }, { value: 2, label: "Frustrating — I need momentum" }, { value: 3, label: "Fine for friendship, harder for romance" }] }
];

const REFERRAL_SLOW_BURN_ARCHETYPES = [
  { name: "The Fast Flame", description: "You build connection quickly when it's right. Momentum, frequency, and clear intent keep you engaged.", characteristics: ["Prefers rapid escalation", "High contact frequency", "Values clarity early", "Low patience for drift"], suggestions: ["Check that speed isn't avoiding deeper compatibility", "Give slow-burn matches one explicit chance", "Watch for love-bombing disguised as pace"] },
  { name: "The Steady Builder", description: "You want consistent rhythm — regular dates, reliable texting, and progress you can feel without pressure.", characteristics: ["Consistent cadence", "Plans ahead", "Balanced depth", "Moderate label timeline"], suggestions: ["Name your preferred cadence early", "Don't mistake busy for disinterest", "Escalate intentionally, not by default"] },
  { name: "The Slow Burn", description: "Trust and emotional safety come before labels or intensity. You need time to know someone is real.", characteristics: ["Long runway to exclusivity", "Depth before speed", "Protective of energy", "Consistency over fireworks"], suggestions: ["Tell matches your pace upfront", "Look for consistency, not grand gestures", "Don't apologize for needing time"] },
  { name: "The Intentional Drifter", description: "You resist rigid timelines but still want alignment. You move when it feels mutual, not when a script says so.", characteristics: ["Flexible pacing", "Context-dependent", "Values mutual initiation", "Anti-pressure"], suggestions: ["Communicate non-negotiables even if timeline is flexible", "Avoid ambiguous situationships", "Check in before assuming you're aligned"] }
];

function calculateReferralSlowBurnArchetype(answers) {
  let pace = 0, depth = 0, paceCount = 0, depthCount = 0;
  Object.entries(answers).forEach(([key, value]) => {
    const q = REFERRAL_SLOW_BURN_QUIZ_ITEMS.find(i => i.id === key);
    if (!q) return;
    if (q.category === 'Pace') { pace += value; paceCount++; }
    if (q.category === 'Depth') { depth += value; depthCount++; }
  });
  const avgPace = paceCount ? pace / paceCount : 0;
  const avgDepth = depthCount ? depth / depthCount : 0;
  if (avgPace < 1.0) return REFERRAL_SLOW_BURN_ARCHETYPES[0];
  if (avgPace < 1.8 && avgDepth < 2.0) return REFERRAL_SLOW_BURN_ARCHETYPES[1];
  if (avgPace >= 2.0) return REFERRAL_SLOW_BURN_ARCHETYPES[2];
  return REFERRAL_SLOW_BURN_ARCHETYPES[3];
}

const REFERRAL_TRUST_LINE_QUIZ_ITEMS = [
  { id: "rtl_001", category: "Trust", text: "You usually start trusting someone new when they:", options: [{ value: 0, label: "Are consistent over a few weeks" }, { value: 1, label: "Follow through on small promises" }, { value: 2, label: "Are vulnerable with me first" }, { value: 3, label: "Respect my boundaries without pushback" }] },
  { id: "rtl_002", category: "Trust", text: "If someone love-bombs you early, you:", options: [{ value: 0, label: "Enjoy it — finally someone matches my energy" }, { value: 1, label: "Appreciate it but stay observant" }, { value: 2, label: "Get suspicious — it's too much" }, { value: 3, label: "Pull back immediately" }] },
  { id: "rtl_003", category: "Boundary", text: "When a match cancels last minute twice, you:", options: [{ value: 0, label: "Assume life happens — no big deal" }, { value: 1, label: "Ask if timing is hard for them" }, { value: 2, label: "Lower investment until they show up" }, { value: 3, label: "Consider it a compatibility flag" }] },
  { id: "rtl_004", category: "Boundary", text: "You're most likely to open up emotionally after:", options: [{ value: 0, label: "One great deep conversation" }, { value: 1, label: "Several dates of steady behavior" }, { value: 2, label: "Clear exclusivity" }, { value: 3, label: "Months of proven consistency" }] },
  { id: "rtl_005", category: "Trust", text: "Secrets or vague answers about their past make you:", options: [{ value: 0, label: "Curious — everyone has privacy" }, { value: 1, label: "Ask gently once" }, { value: 2, label: "Uneasy until it's clearer" }, { value: 3, label: "Done — trust needs transparency" }] },
  { id: "rtl_006", category: "Boundary", text: "Your phone and privacy boundaries early in dating are:", options: [{ value: 0, label: "Open — I don't mind sharing" }, { value: 1, label: "Mostly open with a few private areas" }, { value: 2, label: "Private until we're committed" }, { value: 3, label: "Firm — trust is earned slowly" }] },
  { id: "rtl_007", category: "Trust", text: "When someone gets jealous early, you interpret it as:", options: [{ value: 0, label: "They really like me" }, { value: 1, label: "Insecurity I can talk through" }, { value: 2, label: "A yellow flag to watch" }, { value: 3, label: "A red flag — trust issue" }] },
  { id: "rtl_008", category: "Boundary", text: "You feel safest sharing your location or plans when:", options: [{ value: 0, label: "I'm excited about them" }, { value: 1, label: "We've met several times" }, { value: 2, label: "We're exclusive" }, { value: 3, label: "I fully trust their intentions" }] },
  { id: "rtl_009", category: "Trust", text: "Apologies without changed behavior make you:", options: [{ value: 0, label: "Willing to keep giving chances" }, { value: 1, label: "Hopeful but cautious" }, { value: 2, label: "Require proof next time" }, { value: 3, label: "Lose trust quickly" }] },
  { id: "rtl_010", category: "Boundary", text: "Your non-negotiable for building trust is:", options: [{ value: 0, label: "Honesty even when it's awkward" }, { value: 1, label: "Reliability on plans and words" }, { value: 2, label: "Respect when I say no" }, { value: 3, label: "Transparency about intentions" }] }
];

const REFERRAL_TRUST_LINE_ARCHETYPES = [
  { name: "The Open Trust", description: "You extend trust generously and repair quickly when someone shows good intent. You believe people are mostly trying.", characteristics: ["Fast trust grant", "Forgiving early slips", "Optimistic read on people", "Values honesty when named"], suggestions: ["Watch for consistency, not just apologies", "Keep boundaries even when you like someone", "Don't confuse charisma with integrity"] },
  { name: "The Proof Seeker", description: "Trust is built through repeated follow-through. You need behavior over words and time over promises.", characteristics: ["Behavior-based trust", "Steady escalation", "Observes patterns", "Moderate boundary setting"], suggestions: ["Communicate what proof looks like for you", "Avoid testing people with games", "Celebrate small consistent wins"] },
  { name: "The Guarded Heart", description: "You protect access until safety is clear. Early intensity reads as risk, not romance.", characteristics: ["Slow vulnerability", "High boundary awareness", "Skeptical of intensity", "Trust after exclusivity"], suggestions: ["Share your timeline so good matches don't bounce", "Distinguish past hurt from present data", "Let micro-trust build in layers"] },
  { name: "The Boundary First", description: "Respect is your trust prerequisite. How someone handles 'no' tells you everything about whether they're safe.", characteristics: ["Boundary-led trust", "Low tolerance for pressure", "Clear non-negotiables", "Integrity over charm"], suggestions: ["State boundaries early without over-explaining", "Don't negotiate core safety needs", "Notice who gets defensive vs curious"] }
];

function calculateReferralTrustLineArchetype(answers) {
  let trust = 0, boundary = 0, trustCount = 0, boundaryCount = 0;
  Object.entries(answers).forEach(([key, value]) => {
    const q = REFERRAL_TRUST_LINE_QUIZ_ITEMS.find(i => i.id === key);
    if (!q) return;
    if (q.category === 'Trust') { trust += value; trustCount++; }
    if (q.category === 'Boundary') { boundary += value; boundaryCount++; }
  });
  const avgTrust = trustCount ? trust / trustCount : 0;
  const avgBoundary = boundaryCount ? boundary / boundaryCount : 0;
  if (avgTrust < 1.0) return REFERRAL_TRUST_LINE_ARCHETYPES[0];
  if (avgTrust < 1.8 && avgBoundary < 2.0) return REFERRAL_TRUST_LINE_ARCHETYPES[1];
  if (avgBoundary >= 2.0) return REFERRAL_TRUST_LINE_ARCHETYPES[3];
  return REFERRAL_TRUST_LINE_ARCHETYPES[2];
}


function calculatePackArchetype(packId, answers) {
  const map = {"love-language":"calculateLoveLanguageArchetype","situationship":"calculateSituationshipArchetype","self-sabotage":"calculateSelfSabotageArchetype","social-battery":"calculateSocialBatteryArchetype","messaging":"calculateMessagingArchetype","boundaries":"calculateBoundaryArchetype","attraction":"calculateAttractionArchetype","desire-logic":"calculateDesireLogicArchetype","dealbreaker-map":"calculateDealbreakerMapArchetype","identity-performance":"calculateIdentityPerformanceArchetype","referral-first-spark":"calculateReferralFirstSparkArchetype","referral-slow-burn":"calculateReferralSlowBurnArchetype","referral-trust-line":"calculateReferralTrustLineArchetype"};
  const fnName = map[packId];
  const fn = globalThis[fnName];
  if (typeof fn !== 'function') return null;
  return fn(answers);
}
