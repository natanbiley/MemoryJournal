import Foundation
import SwiftData

@Model
class Entry {
    var bodyText: String
    var date: Date
    var isFavorite: Bool = false

    init (bodyText: String, date: Date, isFavorite: Bool = false) {
        self.bodyText = bodyText
        self.date = date
        self.isFavorite = isFavorite
    }

    static let sampleEntries = [
        // January 2025
        Entry(bodyText: "Happy New Year! Setting intentions for 2025: focus on health, learning, and meaningful connections.",
              date: dateFrom(year: 2025, month: 1, day: 1)),

        Entry(bodyText: "Woke up feeling refreshed and ready for the new year. Made a delicious breakfast and spent time planning my goals.",
              date: dateFrom(year: 2025, month: 1, day: 2)),
        Entry(bodyText: "Woke up feeling refreshed and ready for the new year. Made a delicious breakfast and spent time planning my goals.",
              date: dateFrom(year: 2024, month: 1, day: 2)),
        Entry(bodyText: "Woke up feeling refreshed and ready for the new year. Made a delicious breakfast and spent time planning my goals.",
              date: dateFrom(year: 2023, month: 1, day: 2)),

        Entry(bodyText: "First morning run of the year. The cold air was refreshing and cleared my mind.",
              date: dateFrom(year: 2025, month: 1, day: 3)),

        Entry(bodyText: "Started a new book series today. Already hooked after the first chapter!",
              date: dateFrom(year: 2025, month: 1, day: 5)),

        Entry(bodyText: "Made homemade pizza from scratch. The dough turned out perfectly crispy.",
              date: dateFrom(year: 2025, month: 1, day: 8)),

        Entry(bodyText: "Had a great video call with old college friends. We should do this more often.",
              date: dateFrom(year: 2025, month: 1, day: 12)),

        Entry(bodyText: "Finally organized my workspace. A clean desk really does help productivity.",
              date: dateFrom(year: 2025, month: 1, day: 15)),

        Entry(bodyText: "Tried meditation for the first time. It was harder than I expected but I'll keep practicing.",
              date: dateFrom(year: 2025, month: 1, day: 18)),

        Entry(bodyText: "Discovered a new coffee shop downtown. The ambiance is perfect for reading.",
              date: dateFrom(year: 2025, month: 1, day: 22)),

        Entry(bodyText: "Attended a workshop on digital photography. Learned so many useful techniques.",
              date: dateFrom(year: 2025, month: 1, day: 26)),

        Entry(bodyText: "Cozy evening spent watching the rain and reading. Simple pleasures are the best.",
              date: dateFrom(year: 2025, month: 1, day: 30)),

        // February 2025
        Entry(bodyText: "Started learning Spanish on a language app. ¡Hola! Let's see how far I can go.",
              date: dateFrom(year: 2025, month: 2, day: 2)),

        Entry(bodyText: "Baked chocolate chip cookies. The kitchen smells amazing!",
              date: dateFrom(year: 2025, month: 2, day: 5)),

        Entry(bodyText: "Had an inspiring conversation about sustainability and climate action.",
              date: dateFrom(year: 2025, month: 2, day: 9)),

        Entry(bodyText: "Valentine's Day! Spent it with loved ones sharing memories and laughter.",
              date: dateFrom(year: 2025, month: 2, day: 14)),

        Entry(bodyText: "Finished a challenging project at work. Feeling accomplished and ready for the weekend.",
              date: dateFrom(year: 2025, month: 2, day: 17)),

        Entry(bodyText: "Went hiking on a new trail. The view from the summit was breathtaking.",
              date: dateFrom(year: 2025, month: 2, day: 21)),

        Entry(bodyText: "Started journaling daily. It's becoming a meaningful practice for reflection.",
              date: dateFrom(year: 2025, month: 2, day: 25)),

        Entry(bodyText: "Tried a new recipe: Thai green curry. Spicy but delicious!",
              date: dateFrom(year: 2025, month: 2, day: 28)),
        
        // March 2025
        Entry(bodyText: "Spring is coming! Saw the first flowers blooming in the garden.",
              date: dateFrom(year: 2025, month: 3, day: 3)),
        Entry(bodyText: "Had a productive day coding. Finally solved that bug that was bothering me for days.",
              date: dateFrom(year: 2025, month: 3, day: 7)),
        Entry(bodyText: "Attended a local concert. Live music always lifts my spirits.",
              date: dateFrom(year: 2025, month: 3, day: 11)),
        Entry(bodyText: "Started a new fitness routine. Day 1: sore but motivated!",
              date: dateFrom(year: 2025, month: 3, day: 14)),
        Entry(bodyText: "Visited an art gallery. The contemporary exhibit was thought-provoking.",
              date: dateFrom(year: 2025, month: 3, day: 18)),
        Entry(bodyText: "Spring cleaning day. Donated clothes and decluttered the apartment.",
              date: dateFrom(year: 2025, month: 3, day: 22)),
        Entry(bodyText: "Had a wonderful dinner with family. Grateful for these moments together.",
              date: dateFrom(year: 2025, month: 3, day: 26)),
        Entry(bodyText: "Started reading about stoic philosophy. Finding it quite relevant to modern life.",
              date: dateFrom(year: 2025, month: 3, day: 29)),

        // April 2025
        Entry(bodyText: "April showers today. Perfect weather for staying in and reading.",
              date: dateFrom(year: 2025, month: 4, day: 2)),
        Entry(bodyText: "Tried rock climbing for the first time. Challenging but exhilarating!",
              date: dateFrom(year: 2025, month: 4, day: 6)),
        Entry(bodyText: "Had a breakthrough moment in my creative project. Everything is clicking now.",
              date: dateFrom(year: 2025, month: 4, day: 10)),
        Entry(bodyText: "Planted herbs in the garden: basil, mint, and rosemary. Can't wait to use them in cooking.",
              date: dateFrom(year: 2025, month: 4, day: 14)),
        Entry(bodyText: "Reconnected with an old friend. It's like no time has passed at all.",
              date: dateFrom(year: 2025, month: 4, day: 18)),
        Entry(bodyText: "Finished a 1000-piece puzzle. The satisfaction of placing that last piece!",
              date: dateFrom(year: 2025, month: 4, day: 22)),
        Entry(bodyText: "Watched the sunrise from the beach. Absolutely magical start to the day.",
              date: dateFrom(year: 2025, month: 4, day: 26)),
        Entry(bodyText: "Learned a new guitar chord progression. Music practice is becoming my favorite hobby.",
              date: dateFrom(year: 2025, month: 4, day: 29)),

        // May 2025
        Entry(bodyText: "May flowers are everywhere! The neighborhood looks beautiful.",
              date: dateFrom(year: 2025, month: 5, day: 2)),
        Entry(bodyText: "Had a picnic in the park. Perfect weather for outdoor activities.",
              date: dateFrom(year: 2025, month: 5, day: 6)),
        Entry(bodyText: "Started volunteering at the local animal shelter. The dogs are so sweet!",
              date: dateFrom(year: 2025, month: 5, day: 10)),
        Entry(bodyText: "Tried pottery class. My bowl is lopsided but I love it anyway!",
              date: dateFrom(year: 2025, month: 5, day: 14)),
        Entry(bodyText: "Celebrated a friend's birthday. Great food, great company, great memories.",
              date: dateFrom(year: 2025, month: 5, day: 18)),
        Entry(bodyText: "Finished reading a thought-provoking novel. Stories have such power.",
              date: dateFrom(year: 2025, month: 5, day: 22)),
        Entry(bodyText: "Went kayaking on the lake. The water was so calm and peaceful.",
              date: dateFrom(year: 2025, month: 5, day: 26)),
        Entry(bodyText: "Experimented with watercolor painting. Not perfect but it's therapeutic.",
              date: dateFrom(year: 2025, month: 5, day: 30)),

        // June 2025
        Entry(bodyText: "Summer is here! Time for outdoor adventures and long sunny days.",
              date: dateFrom(year: 2025, month: 6, day: 3)),
        Entry(bodyText: "Started a new series on streaming. Already binge-watched three episodes!",
              date: dateFrom(year: 2025, month: 6, day: 7)),
        Entry(bodyText: "Farmers market haul: fresh berries, vegetables, and homemade bread.",
              date: dateFrom(year: 2025, month: 6, day: 11)),
        Entry(bodyText: "Had a bonfire with friends. S'mores, stories, and stargazing.",
              date: dateFrom(year: 2025, month: 6, day: 15)),
        Entry(bodyText: "Tried stand-up paddleboarding. Fell in the water but had so much fun!",
              date: dateFrom(year: 2025, month: 6, day: 19)),
        Entry(bodyText: "Attended an outdoor movie screening. Classic film under the stars.",
              date: dateFrom(year: 2025, month: 6, day: 23)),
        Entry(bodyText: "Made fresh lemonade from scratch. Tastes like summer in a glass.",
              date: dateFrom(year: 2025, month: 6, day: 27)),

        // July 2025
        Entry(bodyText: "Fourth of July celebration with fireworks and BBQ. Love this holiday!",
              date: dateFrom(year: 2025, month: 7, day: 4)),
        Entry(bodyText: "Beach day! Sun, sand, and ocean waves. Perfect summer afternoon.",
              date: dateFrom(year: 2025, month: 7, day: 8)),
        Entry(bodyText: "Started a photography project: capturing everyday beauty.",
              date: dateFrom(year: 2025, month: 7, day: 12)),
        Entry(bodyText: "Had an amazing farm-to-table dinner. Fresh ingredients make all the difference.",
              date: dateFrom(year: 2025, month: 7, day: 16)),
        Entry(bodyText: "Went to a music festival. Three days of incredible performances and good vibes.",
              date: dateFrom(year: 2025, month: 7, day: 20)),
        Entry(bodyText: "Camping trip in the mountains. Fresh air, campfire stories, and star-filled skies.",
              date: dateFrom(year: 2025, month: 7, day: 24)),
        Entry(bodyText: "Tried making ice cream at home. Vanilla bean - simple and delicious!",
              date: dateFrom(year: 2025, month: 7, day: 28)),

        // August 2025
        Entry(bodyText: "Long bike ride through the countryside. The fields are golden and beautiful.",
              date: dateFrom(year: 2025, month: 8, day: 1)),
        Entry(bodyText: "Started reading about astronomy. The universe is mind-blowing!",
              date: dateFrom(year: 2025, month: 8, day: 5)),
        Entry(bodyText: "Had a game night with friends. Lots of laughter and friendly competition.",
              date: dateFrom(year: 2025, month: 8, day: 9)),
        Entry(bodyText: "Visited a butterfly garden. Such delicate and beautiful creatures.",
              date: dateFrom(year: 2025, month: 8, day: 13)),
        Entry(bodyText: "Made homemade pasta for the first time. Labor-intensive but worth it!",
              date: dateFrom(year: 2025, month: 8, day: 17)),
        Entry(bodyText: "Watched the meteor shower. Saw dozens of shooting stars - made wishes on each one.",
              date: dateFrom(year: 2025, month: 8, day: 21)),
        Entry(bodyText: "Tried a new yoga class. Feeling stretched and relaxed.",
              date: dateFrom(year: 2025, month: 8, day: 25)),
        Entry(bodyText: "Last beach day of summer. Savoring every moment of sunshine.",
              date: dateFrom(year: 2025, month: 8, day: 29)),

        // September 2025
        Entry(bodyText: "September already! Time flies. Setting new goals for the fall.",
              date: dateFrom(year: 2025, month: 9, day: 2)),
        Entry(bodyText: "Went apple picking. Made fresh apple pie - house smells incredible!",
              date: dateFrom(year: 2025, month: 9, day: 6)),
        Entry(bodyText: "Started a book club with neighbors. Our first meeting was great!",
              date: dateFrom(year: 2025, month: 9, day: 10)),
        Entry(bodyText: "Autumn colors are starting to appear. The trees are beautiful.",
              date: dateFrom(year: 2025, month: 9, day: 14)),
        Entry(bodyText: "Had a productive brainstorming session. Excited about new ideas!",
              date: dateFrom(year: 2025, month: 9, day: 18)),
        Entry(bodyText: "Visited a pumpkin patch. Got some decorative gourds for the house.",
              date: dateFrom(year: 2025, month: 9, day: 22)),
        Entry(bodyText: "Cozy sweater weather is here. Love this time of year!",
              date: dateFrom(year: 2025, month: 9, day: 26)),
        Entry(bodyText: "Made butternut squash soup. Perfect comfort food for fall.",
              date: dateFrom(year: 2025, month: 9, day: 30)),

        // October 2025
        Entry(bodyText: "October vibes! Pumpkin spice everything and falling leaves.",
              date: dateFrom(year: 2025, month: 10, day: 4)),
        Entry(bodyText: "Went on a scenic drive to see the fall foliage. Absolutely stunning.",
              date: dateFrom(year: 2025, month: 10, day: 8)),
        Entry(bodyText: "Carved pumpkins for Halloween. Mine turned out better than expected!",
              date: dateFrom(year: 2025, month: 10, day: 12)),
        Entry(bodyText: "Attended a harvest festival. Hayrides, corn maze, and apple cider.",
              date: dateFrom(year: 2025, month: 10, day: 16)),
        Entry(bodyText: "Started a new knitting project. Making a scarf for winter.",
              date: dateFrom(year: 2025, month: 10, day: 20)),
        Entry(bodyText: "Movie marathon: classic horror films for Halloween season.",
              date: dateFrom(year: 2025, month: 10, day: 24)),
        Entry(bodyText: "Halloween party! Great costumes, spooky decorations, and fun games.",
              date: dateFrom(year: 2025, month: 10, day: 31)),

        // November 2025
        Entry(bodyText: "November already. Reflecting on gratitude and all the good things this year.",
              date: dateFrom(year: 2025, month: 11, day: 3)),
        Entry(bodyText: "First fire in the fireplace this season. So cozy and warm.",
              date: dateFrom(year: 2025, month: 11, day: 7)),
        Entry(bodyText: "Tried a new bread recipe. The smell of fresh bread is unbeatable.",
              date: dateFrom(year: 2025, month: 11, day: 11)),
        Entry(bodyText: "Attended a poetry reading. Words have such power to move us.",
              date: dateFrom(year: 2025, month: 11, day: 15)),
        Entry(bodyText: "Rainy day spent organizing photos from the year. So many good memories!",
              date: dateFrom(year: 2025, month: 11, day: 19)),
        Entry(bodyText: "Thanksgiving! Grateful for family, friends, health, and all the little joys.",
              date: dateFrom(year: 2025, month: 11, day: 27)),

        // December 2025
        Entry(bodyText: "December is here! Holiday season brings so much joy and warmth.",
              date: dateFrom(year: 2025, month: 12, day: 1)),
        Entry(bodyText: "Put up the holiday decorations. The house feels festive and magical.",
              date: dateFrom(year: 2025, month: 12, day: 5)),
        Entry(bodyText: "Made gingerbread cookies. Decorating them is my favorite part!",
              date: dateFrom(year: 2025, month: 12, day: 9)),
        Entry(bodyText: "Attended a holiday concert. The music filled me with seasonal cheer.",
              date: dateFrom(year: 2025, month: 12, day: 13)),
        Entry(bodyText: "Ice skating at the outdoor rink. Cold but so much fun!",
              date: dateFrom(year: 2025, month: 12, day: 17)),
        Entry(bodyText: "Wrapped presents while listening to holiday music. Love this tradition.",
              date: dateFrom(year: 2025, month: 12, day: 21)),
        Entry(bodyText: "Christmas celebration with loved ones. Gifts, laughter, and togetherness.",
              date: dateFrom(year: 2025, month: 12, day: 25)),
        Entry(bodyText: "Reflecting on 2025. What a year of growth, learning, and beautiful moments.",
              date: dateFrom(year: 2025, month: 12, day: 29)),
        Entry(bodyText: "New Year's Eve! Ready to welcome 2026 with hope and excitement.",
              date: dateFrom(year: 2025, month: 12, day: 31)),
    ];
    
    private static func dateFrom(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        let calendar = Calendar.current
        return calendar.date(from: components) ?? Date()
    }
}
