import Foundation
import SwiftData

@Model
class Entry {
    var bodyText: String
    var bodyHTML: String? // Store rich text as HTML
    var date: Date
    @Attribute(.externalStorage) var photos: [Data]? // Store photo data
    @Attribute(.externalStorage) var videos: [Data]? // Store video data
    var isFavorite: Bool = false

    init (bodyText: String, date: Date, bodyHTML: String? = nil, photos: [Data]? = nil, videos: [Data]? = nil, isFavorite: Bool = false) {
        self.bodyText = bodyText
        self.bodyHTML = bodyHTML
        self.date = date
        self.photos = photos
        self.videos = videos
        self.isFavorite = isFavorite
    }

    static let sampleEntries = [
        // January 2025
        Entry(bodyText: "Happy New Year! Setting intentions for 2025: focus on health, learning, and meaningful connections.", 
              date: dateFrom(year: 2025, month: 1, day: 1),
              bodyHTML: "<b>Happy New Year!</b> Setting intentions for 2025: <span style=\"background-color: #FFEB3B;\">focus on health</span>, <i>learning</i>, and <u>meaningful connections</u>."),
        
        Entry(bodyText: "First morning run of the year. The cold air was refreshing and cleared my mind.", 
              date: dateFrom(year: 2025, month: 1, day: 3),
              bodyHTML: "First <b>morning run</b> of the year. The <span style=\"color: #2196F3;\">cold air</span> was refreshing and cleared my mind."),
        
        Entry(bodyText: "Started a new book series today. Already hooked after the first chapter!", 
              date: dateFrom(year: 2025, month: 1, day: 5),
              bodyHTML: "Started a <i>new book series</i> today. <b>Already hooked</b> after the <span style=\"background-color: #FFE082;\">first chapter!</span>"),
        
        Entry(bodyText: "Made homemade pizza from scratch. The dough turned out perfectly crispy.", 
              date: dateFrom(year: 2025, month: 1, day: 8),
              bodyHTML: "Made <b style=\"color: #FF5722;\">homemade pizza</b> from scratch. The dough turned out <u>perfectly crispy</u>."),
        
        Entry(bodyText: "Had a great video call with old college friends. We should do this more often.", 
              date: dateFrom(year: 2025, month: 1, day: 12),
              bodyHTML: "Had a <span style=\"background-color: #B2DFDB;\">great video call</span> with <i>old college friends</i>. We should do this <b>more often</b>."),
        
        Entry(bodyText: "Finally organized my workspace. A clean desk really does help productivity.", 
              date: dateFrom(year: 2025, month: 1, day: 15),
              bodyHTML: "<b>Finally organized</b> my workspace. A <span style=\"color: #4CAF50;\">clean desk</span> really does help <u>productivity</u>."),
        
        Entry(bodyText: "Tried meditation for the first time. It was harder than I expected but I'll keep practicing.", 
              date: dateFrom(year: 2025, month: 1, day: 18),
              bodyHTML: "Tried <i>meditation</i> for the first time. It was <span style=\"background-color: #CE93D8;\">harder than I expected</span> but I'll <b>keep practicing</b>."),
        
        Entry(bodyText: "Discovered a new coffee shop downtown. The ambiance is perfect for reading.", 
              date: dateFrom(year: 2025, month: 1, day: 22),
              bodyHTML: "Discovered a <b style=\"color: #795548;\">new coffee shop</b> downtown. The <i>ambiance</i> is <span style=\"background-color: #FFF9C4;\">perfect for reading</span>."),
        
        Entry(bodyText: "Attended a workshop on digital photography. Learned so many useful techniques.", 
              date: dateFrom(year: 2025, month: 1, day: 26),
              bodyHTML: "Attended a workshop on <b>digital photography</b>. Learned <u>so many</u> <span style=\"color: #9C27B0;\">useful techniques</span>."),
        
        Entry(bodyText: "Cozy evening spent watching the rain and reading. Simple pleasures are the best.", 
              date: dateFrom(year: 2025, month: 1, day: 30),
              bodyHTML: "<i>Cozy evening</i> spent watching the <span style=\"color: #2196F3;\">rain</span> and reading. <b style=\"background-color: #FFF59D;\">Simple pleasures</b> are the best."),
        
        // February 2025
        Entry(bodyText: "Started learning Spanish on a language app. ¡Hola! Let's see how far I can go.", 
              date: dateFrom(year: 2025, month: 2, day: 2),
              bodyHTML: "Started learning <b>Spanish</b> on a language app. <span style=\"color: #FF9800;\">¡Hola!</span> Let's see how far I can go."),
        
        Entry(bodyText: "Baked chocolate chip cookies. The kitchen smells amazing!", 
              date: dateFrom(year: 2025, month: 2, day: 5),
              bodyHTML: "Baked <b style=\"color: #795548;\">chocolate chip cookies</b>. The kitchen smells <span style=\"background-color: #FFCCBC;\">amazing!</span>"),
        
        Entry(bodyText: "Had an inspiring conversation about sustainability and climate action.", 
              date: dateFrom(year: 2025, month: 2, day: 9),
              bodyHTML: "Had an <i>inspiring conversation</i> about <span style=\"color: #4CAF50;\"><b>sustainability</b></span> and <u>climate action</u>."),
        
        Entry(bodyText: "Valentine's Day! Spent it with loved ones sharing memories and laughter.", 
              date: dateFrom(year: 2025, month: 2, day: 14),
              bodyHTML: "<b style=\"color: #E91E63;\">Valentine's Day!</b> Spent it with <i>loved ones</i> sharing <span style=\"background-color: #F8BBD0;\">memories and laughter</span>."),
        
        Entry(bodyText: "Finished a challenging project at work. Feeling accomplished and ready for the weekend.", 
              date: dateFrom(year: 2025, month: 2, day: 17),
              bodyHTML: "<b>Finished</b> a <u>challenging project</u> at work. Feeling <span style=\"color: #4CAF50;\">accomplished</span> and ready for the weekend."),
        
        Entry(bodyText: "Went hiking on a new trail. The view from the summit was breathtaking.", 
              date: dateFrom(year: 2025, month: 2, day: 21),
              bodyHTML: "Went <b>hiking</b> on a new trail. The view from the summit was <span style=\"background-color: #B2EBF2;\"><i>breathtaking</i></span>."),
        
        Entry(bodyText: "Started journaling daily. It's becoming a meaningful practice for reflection.", 
              date: dateFrom(year: 2025, month: 2, day: 25),
              bodyHTML: "Started <b style=\"color: #9C27B0;\">journaling daily</b>. It's becoming a <i>meaningful practice</i> for <u>reflection</u>."),
        
        Entry(bodyText: "Tried a new recipe: Thai green curry. Spicy but delicious!", 
              date: dateFrom(year: 2025, month: 2, day: 28),
              bodyHTML: "Tried a new recipe: <b style=\"color: #4CAF50;\">Thai green curry</b>. <span style=\"background-color: #FFCDD2;\">Spicy</span> but <i>delicious!</i>"),
        
        // March 2025
        Entry(bodyText: "Spring is coming! Saw the first flowers blooming in the garden.", 
              date: dateFrom(year: 2025, month: 3, day: 3),
              bodyHTML: "<b style=\"color: #FF4081;\">Spring is coming!</b> Saw the first <span style=\"background-color: #F8BBD0;\">flowers blooming</span> in the <i>garden</i>."),
        
        Entry(bodyText: "Had a productive day coding. Finally solved that bug that was bothering me for days.", 
              date: dateFrom(year: 2025, month: 3, day: 7),
              bodyHTML: "Had a <b>productive day coding</b>. <span style=\"color: #4CAF50;\">Finally solved</span> that <span style=\"background-color: #FFCDD2;\">bug</span> that was bothering me for days."),
        
        Entry(bodyText: "Attended a local concert. Live music always lifts my spirits.", 
              date: dateFrom(year: 2025, month: 3, day: 11),
              bodyHTML: "Attended a local <b>concert</b>. <i style=\"color: #9C27B0;\">Live music</i> always <span style=\"background-color: #E1BEE7;\">lifts my spirits</span>."),
        
        Entry(bodyText: "Started a new fitness routine. Day 1: sore but motivated!", 
              date: dateFrom(year: 2025, month: 3, day: 14),
              bodyHTML: "Started a <b style=\"color: #FF5722;\">new fitness routine</b>. Day 1: <s>sore</s> but <span style=\"background-color: #C8E6C9;\"><b>motivated!</b></span>"),
        
        Entry(bodyText: "Visited an art gallery. The contemporary exhibit was thought-provoking.", 
              date: dateFrom(year: 2025, month: 3, day: 18),
              bodyHTML: "Visited an <i>art gallery</i>. The <b>contemporary exhibit</b> was <span style=\"color: #673AB7;\">thought-provoking</span>."),
        
        Entry(bodyText: "Spring cleaning day. Donated clothes and decluttered the apartment.", 
              date: dateFrom(year: 2025, month: 3, day: 22),
              bodyHTML: "<b>Spring cleaning day</b>. <u>Donated clothes</u> and <span style=\"background-color: #DCEDC8;\">decluttered the apartment</span>."),
        
        Entry(bodyText: "Had a wonderful dinner with family. Grateful for these moments together.", 
              date: dateFrom(year: 2025, month: 3, day: 26),
              bodyHTML: "Had a <i>wonderful dinner</i> with <b>family</b>. <span style=\"color: #E91E63;\">Grateful</span> for these <span style=\"background-color: #FCE4EC;\">moments together</span>."),
        
        Entry(bodyText: "Started reading about stoic philosophy. Finding it quite relevant to modern life.", 
              date: dateFrom(year: 2025, month: 3, day: 29),
              bodyHTML: "Started reading about <b style=\"color: #607D8B;\">stoic philosophy</b>. Finding it <u>quite relevant</u> to <i>modern life</i>."),
        
        // April 2025
        Entry(bodyText: "April showers today. Perfect weather for staying in and reading.", 
              date: dateFrom(year: 2025, month: 4, day: 2),
              bodyHTML: "<span style=\"color: #2196F3;\"><i>April showers</i></span> today. <b>Perfect weather</b> for staying in and <span style=\"background-color: #FFF9C4;\">reading</span>."),
        
        Entry(bodyText: "Tried rock climbing for the first time. Challenging but exhilarating!", 
              date: dateFrom(year: 2025, month: 4, day: 6),
              bodyHTML: "Tried <b style=\"color: #FF5722;\">rock climbing</b> for the first time. <u>Challenging</u> but <span style=\"background-color: #FFCCBC;\">exhilarating!</span>"),
        
        Entry(bodyText: "Had a breakthrough moment in my creative project. Everything is clicking now.", 
              date: dateFrom(year: 2025, month: 4, day: 10),
              bodyHTML: "Had a <span style=\"background-color: #FFF59D;\"><b>breakthrough moment</b></span> in my <i>creative project</i>. <span style=\"color: #4CAF50;\">Everything is clicking now</span>."),
        
        Entry(bodyText: "Planted herbs in the garden: basil, mint, and rosemary. Can't wait to use them in cooking.", 
              date: dateFrom(year: 2025, month: 4, day: 14),
              bodyHTML: "Planted <b style=\"color: #4CAF50;\">herbs</b> in the garden: <i>basil</i>, <i>mint</i>, and <i>rosemary</i>. <span style=\"background-color: #C8E6C9;\">Can't wait to use them in cooking</span>."),
        
        Entry(bodyText: "Reconnected with an old friend. It's like no time has passed at all.", 
              date: dateFrom(year: 2025, month: 4, day: 18),
              bodyHTML: "<b>Reconnected</b> with an <i>old friend</i>. It's like <span style=\"color: #9C27B0;\">no time has passed</span> at all."),
        
        Entry(bodyText: "Finished a 1000-piece puzzle. The satisfaction of placing that last piece!", 
              date: dateFrom(year: 2025, month: 4, day: 22),
              bodyHTML: "Finished a <b>1000-piece puzzle</b>. The <span style=\"background-color: #B39DDB;\">satisfaction</span> of placing that <u>last piece!</u>"),
        
        Entry(bodyText: "Watched the sunrise from the beach. Absolutely magical start to the day.", 
              date: dateFrom(year: 2025, month: 4, day: 26),
              bodyHTML: "Watched the <span style=\"color: #FF9800;\"><b>sunrise</b></span> from the beach. <i style=\"background-color: #FFECB3;\">Absolutely magical</i> start to the day."),
        
        Entry(bodyText: "Learned a new guitar chord progression. Music practice is becoming my favorite hobby.", 
              date: dateFrom(year: 2025, month: 4, day: 29),
              bodyHTML: "Learned a new <b>guitar chord progression</b>. <span style=\"color: #9C27B0;\">Music practice</span> is becoming my <span style=\"background-color: #E1BEE7;\"><i>favorite hobby</i></span>."),
        
        // May 2025
        Entry(bodyText: "May flowers are everywhere! The neighborhood looks beautiful.", 
              date: dateFrom(year: 2025, month: 5, day: 2),
              bodyHTML: "<b style=\"color: #FF4081;\">May flowers</b> are everywhere! The neighborhood looks <span style=\"background-color: #F8BBD0;\">beautiful</span>."),
        
        Entry(bodyText: "Had a picnic in the park. Perfect weather for outdoor activities.", 
              date: dateFrom(year: 2025, month: 5, day: 6),
              bodyHTML: "Had a <i>picnic in the park</i>. <span style=\"color: #4CAF50;\">Perfect weather</span> for <b>outdoor activities</b>."),
        
        Entry(bodyText: "Started volunteering at the local animal shelter. The dogs are so sweet!", 
              date: dateFrom(year: 2025, month: 5, day: 10),
              bodyHTML: "Started <b>volunteering</b> at the local <span style=\"color: #795548;\">animal shelter</span>. The dogs are <span style=\"background-color: #FFCCBC;\"><i>so sweet!</i></span>"),
        
        Entry(bodyText: "Tried pottery class. My bowl is lopsided but I love it anyway!", 
              date: dateFrom(year: 2025, month: 5, day: 14),
              bodyHTML: "Tried <b>pottery class</b>. My bowl is <s>lopsided</s> but I <span style=\"color: #E91E63;\">love it anyway!</span>"),
        
        Entry(bodyText: "Celebrated a friend's birthday. Great food, great company, great memories.", 
              date: dateFrom(year: 2025, month: 5, day: 18),
              bodyHTML: "Celebrated a friend's <b style=\"background-color: #FFECB3;\">birthday</b>. <u>Great food</u>, <u>great company</u>, <u>great memories</u>."),
        
        Entry(bodyText: "Finished reading a thought-provoking novel. Stories have such power.", 
              date: dateFrom(year: 2025, month: 5, day: 22),
              bodyHTML: "Finished reading a <i>thought-provoking novel</i>. <b style=\"color: #673AB7;\">Stories</b> have such <span style=\"background-color: #D1C4E9;\">power</span>."),
        
        Entry(bodyText: "Went kayaking on the lake. The water was so calm and peaceful.", 
              date: dateFrom(year: 2025, month: 5, day: 26),
              bodyHTML: "Went <b style=\"color: #2196F3;\">kayaking</b> on the lake. The water was <i>so calm</i> and <span style=\"background-color: #B3E5FC;\">peaceful</span>."),
        
        Entry(bodyText: "Experimented with watercolor painting. Not perfect but it's therapeutic.", 
              date: dateFrom(year: 2025, month: 5, day: 30),
              bodyHTML: "Experimented with <b>watercolor painting</b>. <s>Not perfect</s> but it's <span style=\"color: #9C27B0;\"><i>therapeutic</i></span>."),
        
        // June 2025
        Entry(bodyText: "Summer is here! Time for outdoor adventures and long sunny days.", 
              date: dateFrom(year: 2025, month: 6, day: 3),
              bodyHTML: "<b style=\"color: #FF9800; background-color: #FFF3E0;\">Summer is here!</b> Time for <u>outdoor adventures</u> and <i>long sunny days</i>."),
        
        Entry(bodyText: "Started a new series on streaming. Already binge-watched three episodes!", 
              date: dateFrom(year: 2025, month: 6, day: 7),
              bodyHTML: "Started a <i>new series</i> on streaming. <b>Already binge-watched</b> <span style=\"background-color: #E1BEE7;\">three episodes!</span>"),
        
        Entry(bodyText: "Farmers market haul: fresh berries, vegetables, and homemade bread.", 
              date: dateFrom(year: 2025, month: 6, day: 11),
              bodyHTML: "<b style=\"color: #4CAF50;\">Farmers market haul:</b> <i>fresh berries</i>, <i>vegetables</i>, and <span style=\"background-color: #FFECB3;\">homemade bread</span>."),
        
        Entry(bodyText: "Had a bonfire with friends. S'mores, stories, and stargazing.", 
              date: dateFrom(year: 2025, month: 6, day: 15),
              bodyHTML: "Had a <b style=\"color: #FF5722;\">bonfire</b> with friends. <u>S'mores</u>, <u>stories</u>, and <span style=\"background-color: #283593; color: #FFD54F;\">stargazing</span>."),
        
        Entry(bodyText: "Tried stand-up paddleboarding. Fell in the water but had so much fun!", 
              date: dateFrom(year: 2025, month: 6, day: 19),
              bodyHTML: "Tried <b style=\"color: #2196F3;\">stand-up paddleboarding</b>. <s>Fell in the water</s> but had <span style=\"background-color: #B3E5FC;\">so much fun!</span>"),
        
        Entry(bodyText: "Attended an outdoor movie screening. Classic film under the stars.", 
              date: dateFrom(year: 2025, month: 6, day: 23),
              bodyHTML: "Attended an <b>outdoor movie screening</b>. <i>Classic film</i> under the <span style=\"color: #FFD54F;\">stars</span>."),
        
        Entry(bodyText: "Made fresh lemonade from scratch. Tastes like summer in a glass.", 
              date: dateFrom(year: 2025, month: 6, day: 27),
              bodyHTML: "Made <b style=\"color: #FFEB3B;\">fresh lemonade</b> from scratch. Tastes like <span style=\"background-color: #FFF9C4;\"><i>summer in a glass</i></span>."),
        
        // July 2025
        Entry(bodyText: "Fourth of July celebration with fireworks and BBQ. Love this holiday!", 
              date: dateFrom(year: 2025, month: 7, day: 4),
              bodyHTML: "<b style=\"color: #F44336;\">Fourth of July</b> celebration with <span style=\"background-color: #FFCDD2;\">fireworks</span> and <span style=\"color: #FF5722;\">BBQ</span>. <i>Love this holiday!</i>"),
        
        Entry(bodyText: "Beach day! Sun, sand, and ocean waves. Perfect summer afternoon.", 
              date: dateFrom(year: 2025, month: 7, day: 8),
              bodyHTML: "<b style=\"color: #FF9800;\">Beach day!</b> <u>Sun</u>, <u>sand</u>, and <span style=\"color: #2196F3;\">ocean waves</span>. <i style=\"background-color: #FFECB3;\">Perfect summer afternoon</i>."),
        
        Entry(bodyText: "Started a photography project: capturing everyday beauty.", 
              date: dateFrom(year: 2025, month: 7, day: 12),
              bodyHTML: "Started a <b>photography project</b>: capturing <span style=\"color: #9C27B0; background-color: #F3E5F5;\">everyday beauty</span>."),
        
        Entry(bodyText: "Had an amazing farm-to-table dinner. Fresh ingredients make all the difference.", 
              date: dateFrom(year: 2025, month: 7, day: 16),
              bodyHTML: "Had an <b style=\"color: #4CAF50;\">amazing farm-to-table dinner</b>. <i>Fresh ingredients</i> make <span style=\"background-color: #C8E6C9;\">all the difference</span>."),
        
        Entry(bodyText: "Went to a music festival. Three days of incredible performances and good vibes.", 
              date: dateFrom(year: 2025, month: 7, day: 20),
              bodyHTML: "Went to a <b style=\"color: #9C27B0;\">music festival</b>. <u>Three days</u> of <i>incredible performances</i> and <span style=\"background-color: #E1BEE7;\">good vibes</span>."),
        
        Entry(bodyText: "Camping trip in the mountains. Fresh air, campfire stories, and star-filled skies.", 
              date: dateFrom(year: 2025, month: 7, day: 24),
              bodyHTML: "<b>Camping trip</b> in the <span style=\"color: #4CAF50;\">mountains</span>. <i>Fresh air</i>, <span style=\"color: #FF5722;\">campfire stories</span>, and <span style=\"background-color: #283593; color: #FFD54F;\">star-filled skies</span>."),
        
        Entry(bodyText: "Tried making ice cream at home. Vanilla bean - simple and delicious!", 
              date: dateFrom(year: 2025, month: 7, day: 28),
              bodyHTML: "Tried making <b style=\"background-color: #E1F5FE;\">ice cream</b> at home. <span style=\"color: #795548;\">Vanilla bean</span> - <i>simple</i> and <u>delicious!</u>"),
        
        // August 2025
        Entry(bodyText: "Long bike ride through the countryside. The fields are golden and beautiful.", 
              date: dateFrom(year: 2025, month: 8, day: 1),
              bodyHTML: "Long <b>bike ride</b> through the countryside. The fields are <span style=\"color: #FF9800; background-color: #FFF3E0;\">golden</span> and <i>beautiful</i>."),
        
        Entry(bodyText: "Started reading about astronomy. The universe is mind-blowing!", 
              date: dateFrom(year: 2025, month: 8, day: 5),
              bodyHTML: "Started reading about <b style=\"color: #3F51B5;\">astronomy</b>. The universe is <span style=\"background-color: #C5CAE9;\"><i>mind-blowing!</i></span>"),
        
        Entry(bodyText: "Had a game night with friends. Lots of laughter and friendly competition.", 
              date: dateFrom(year: 2025, month: 8, day: 9),
              bodyHTML: "Had a <b>game night</b> with friends. Lots of <span style=\"color: #FF9800;\">laughter</span> and <u>friendly competition</u>."),
        
        Entry(bodyText: "Visited a butterfly garden. Such delicate and beautiful creatures.", 
              date: dateFrom(year: 2025, month: 8, day: 13),
              bodyHTML: "Visited a <b style=\"color: #9C27B0;\">butterfly garden</b>. Such <i>delicate</i> and <span style=\"background-color: #F3E5F5;\">beautiful creatures</span>."),
        
        Entry(bodyText: "Made homemade pasta for the first time. Labor-intensive but worth it!", 
              date: dateFrom(year: 2025, month: 8, day: 17),
              bodyHTML: "Made <b style=\"color: #FF5722;\">homemade pasta</b> for the first time. <s>Labor-intensive</s> but <span style=\"background-color: #FFCCBC;\">worth it!</span>"),
        
        Entry(bodyText: "Watched the meteor shower. Saw dozens of shooting stars - made wishes on each one.", 
              date: dateFrom(year: 2025, month: 8, day: 21),
              bodyHTML: "Watched the <b style=\"color: #3F51B5;\">meteor shower</b>. Saw <u>dozens of shooting stars</u> - made <span style=\"background-color: #FFF9C4;\">wishes on each one</span>."),
        
        Entry(bodyText: "Tried a new yoga class. Feeling stretched and relaxed.", 
              date: dateFrom(year: 2025, month: 8, day: 25),
              bodyHTML: "Tried a new <b style=\"color: #9C27B0;\">yoga class</b>. Feeling <i>stretched</i> and <span style=\"background-color: #E1BEE7;\">relaxed</span>."),
        
        Entry(bodyText: "Last beach day of summer. Savoring every moment of sunshine.", 
              date: dateFrom(year: 2025, month: 8, day: 29),
              bodyHTML: "<b>Last beach day</b> of summer. Savoring every moment of <span style=\"color: #FF9800; background-color: #FFECB3;\">sunshine</span>."),
        
        // September 2025
        Entry(bodyText: "September already! Time flies. Setting new goals for the fall.", 
              date: dateFrom(year: 2025, month: 9, day: 2),
              bodyHTML: "<b style=\"color: #FF5722;\">September already!</b> <i>Time flies</i>. Setting <span style=\"background-color: #FFCCBC;\">new goals</span> for the fall."),
        
        Entry(bodyText: "Went apple picking. Made fresh apple pie - house smells incredible!", 
              date: dateFrom(year: 2025, month: 9, day: 6),
              bodyHTML: "Went <b style=\"color: #F44336;\">apple picking</b>. Made fresh <span style=\"background-color: #FFECB3;\">apple pie</span> - house smells <i>incredible!</i>"),
        
        Entry(bodyText: "Started a book club with neighbors. Our first meeting was great!", 
              date: dateFrom(year: 2025, month: 9, day: 10),
              bodyHTML: "Started a <b>book club</b> with neighbors. Our <span style=\"color: #4CAF50;\">first meeting</span> was <u>great!</u>"),
        
        Entry(bodyText: "Autumn colors are starting to appear. The trees are beautiful.", 
              date: dateFrom(year: 2025, month: 9, day: 14),
              bodyHTML: "<span style=\"color: #FF9800;\"><b>Autumn colors</b></span> are starting to appear. The trees are <i style=\"background-color: #FFECB3;\">beautiful</i>."),
        
        Entry(bodyText: "Had a productive brainstorming session. Excited about new ideas!", 
              date: dateFrom(year: 2025, month: 9, day: 18),
              bodyHTML: "Had a <b>productive brainstorming session</b>. <span style=\"color: #9C27B0;\">Excited</span> about <span style=\"background-color: #E1BEE7;\">new ideas!</span>"),
        
        Entry(bodyText: "Visited a pumpkin patch. Got some decorative gourds for the house.", 
              date: dateFrom(year: 2025, month: 9, day: 22),
              bodyHTML: "Visited a <b style=\"color: #FF9800;\">pumpkin patch</b>. Got some <i>decorative gourds</i> for the house."),
        
        Entry(bodyText: "Cozy sweater weather is here. Love this time of year!", 
              date: dateFrom(year: 2025, month: 9, day: 26),
              bodyHTML: "<span style=\"background-color: #BCAAA4;\"><b>Cozy sweater weather</b></span> is here. <i style=\"color: #E91E63;\">Love this time of year!</i>"),
        
        Entry(bodyText: "Made butternut squash soup. Perfect comfort food for fall.", 
              date: dateFrom(year: 2025, month: 9, day: 30),
              bodyHTML: "Made <b style=\"color: #FF9800;\">butternut squash soup</b>. <span style=\"background-color: #FFECB3;\">Perfect comfort food</span> for fall."),
        
        // October 2025
        Entry(bodyText: "October vibes! Pumpkin spice everything and falling leaves.", 
              date: dateFrom(year: 2025, month: 10, day: 4),
              bodyHTML: "<b style=\"color: #FF5722;\">October vibes!</b> <span style=\"background-color: #FFCCBC;\">Pumpkin spice everything</span> and <i style=\"color: #FF9800;\">falling leaves</i>."),
        
        Entry(bodyText: "Went on a scenic drive to see the fall foliage. Absolutely stunning.", 
              date: dateFrom(year: 2025, month: 10, day: 8),
              bodyHTML: "Went on a <b>scenic drive</b> to see the <span style=\"color: #FF9800;\">fall foliage</span>. <i style=\"background-color: #FFF3E0;\">Absolutely stunning</i>."),
        
        Entry(bodyText: "Carved pumpkins for Halloween. Mine turned out better than expected!", 
              date: dateFrom(year: 2025, month: 10, day: 12),
              bodyHTML: "Carved <b style=\"color: #FF9800;\">pumpkins</b> for Halloween. Mine turned out <span style=\"background-color: #C8E6C9;\">better than expected!</span>"),
        
        Entry(bodyText: "Attended a harvest festival. Hayrides, corn maze, and apple cider.", 
              date: dateFrom(year: 2025, month: 10, day: 16),
              bodyHTML: "Attended a <b style=\"color: #FF5722;\">harvest festival</b>. <u>Hayrides</u>, <u>corn maze</u>, and <span style=\"background-color: #FFECB3;\">apple cider</span>."),
        
        Entry(bodyText: "Started a new knitting project. Making a scarf for winter.", 
              date: dateFrom(year: 2025, month: 10, day: 20),
              bodyHTML: "Started a new <b>knitting project</b>. Making a <span style=\"color: #2196F3;\">scarf</span> for <i>winter</i>."),
        
        Entry(bodyText: "Movie marathon: classic horror films for Halloween season.", 
              date: dateFrom(year: 2025, month: 10, day: 24),
              bodyHTML: "<b>Movie marathon:</b> <i style=\"color: #9C27B0;\">classic horror films</i> for <span style=\"background-color: #FF6F00; color: #FFFFFF;\">Halloween season</span>."),
        
        Entry(bodyText: "Halloween party! Great costumes, spooky decorations, and fun games.", 
              date: dateFrom(year: 2025, month: 10, day: 31),
              bodyHTML: "<b style=\"color: #FF6F00; background-color: #000000;\">Halloween party!</b> <u>Great costumes</u>, <span style=\"color: #9C27B0;\">spooky decorations</span>, and <i>fun games</i>."),
        
        // November 2025
        Entry(bodyText: "November already. Reflecting on gratitude and all the good things this year.", 
              date: dateFrom(year: 2025, month: 11, day: 3),
              bodyHTML: "<b>November already</b>. Reflecting on <span style=\"color: #FF9800;\">gratitude</span> and all the <span style=\"background-color: #FFF9C4;\">good things</span> this year."),
        
        Entry(bodyText: "First fire in the fireplace this season. So cozy and warm.", 
              date: dateFrom(year: 2025, month: 11, day: 7),
              bodyHTML: "First <b style=\"color: #FF5722;\">fire in the fireplace</b> this season. <i style=\"background-color: #FFCCBC;\">So cozy and warm</i>."),
        
        Entry(bodyText: "Tried a new bread recipe. The smell of fresh bread is unbeatable.", 
              date: dateFrom(year: 2025, month: 11, day: 11),
              bodyHTML: "Tried a new <b style=\"color: #795548;\">bread recipe</b>. The smell of <span style=\"background-color: #FFECB3;\">fresh bread</span> is <u>unbeatable</u>."),
        
        Entry(bodyText: "Attended a poetry reading. Words have such power to move us.", 
              date: dateFrom(year: 2025, month: 11, day: 15),
              bodyHTML: "Attended a <b style=\"color: #673AB7;\">poetry reading</b>. <i>Words</i> have such <span style=\"background-color: #D1C4E9;\">power</span> to move us."),
        
        Entry(bodyText: "Rainy day spent organizing photos from the year. So many good memories!", 
              date: dateFrom(year: 2025, month: 11, day: 19),
              bodyHTML: "<span style=\"color: #2196F3;\">Rainy day</span> spent organizing <b>photos</b> from the year. So many <span style=\"background-color: #FFF9C4;\">good memories!</span>"),
        
        Entry(bodyText: "Thanksgiving! Grateful for family, friends, health, and all the little joys.", 
              date: dateFrom(year: 2025, month: 11, day: 27),
              bodyHTML: "<b style=\"color: #FF9800; background-color: #FFF3E0;\">Thanksgiving!</b> <i>Grateful</i> for <u>family</u>, <u>friends</u>, <u>health</u>, and all the <span style=\"color: #E91E63;\">little joys</span>."),
        
        // December 2025
        Entry(bodyText: "December is here! Holiday season brings so much joy and warmth.", 
              date: dateFrom(year: 2025, month: 12, day: 1),
              bodyHTML: "<b style=\"color: #F44336;\">December is here!</b> Holiday season brings <span style=\"background-color: #FFCDD2;\">so much joy</span> and <i>warmth</i>."),
        
        Entry(bodyText: "Put up the holiday decorations. The house feels festive and magical.", 
              date: dateFrom(year: 2025, month: 12, day: 5),
              bodyHTML: "Put up the <b style=\"color: #4CAF50;\">holiday decorations</b>. The house feels <i>festive</i> and <span style=\"background-color: #FFF9C4;\">magical</span>."),
        
        Entry(bodyText: "Made gingerbread cookies. Decorating them is my favorite part!", 
              date: dateFrom(year: 2025, month: 12, day: 9),
              bodyHTML: "Made <b style=\"color: #795548;\">gingerbread cookies</b>. <u>Decorating them</u> is my <span style=\"background-color: #FFCCBC;\">favorite part!</span>"),
        
        Entry(bodyText: "Attended a holiday concert. The music filled me with seasonal cheer.", 
              date: dateFrom(year: 2025, month: 12, day: 13),
              bodyHTML: "Attended a <b style=\"color: #9C27B0;\">holiday concert</b>. The <i>music</i> filled me with <span style=\"background-color: #E1BEE7;\">seasonal cheer</span>."),
        
        Entry(bodyText: "Ice skating at the outdoor rink. Cold but so much fun!", 
              date: dateFrom(year: 2025, month: 12, day: 17),
              bodyHTML: "<b style=\"color: #2196F3;\">Ice skating</b> at the outdoor rink. <span style=\"color: #2196F3;\">Cold</span> but <span style=\"background-color: #B3E5FC;\">so much fun!</span>"),
        
        Entry(bodyText: "Wrapped presents while listening to holiday music. Love this tradition.", 
              date: dateFrom(year: 2025, month: 12, day: 21),
              bodyHTML: "<b>Wrapped presents</b> while listening to <i style=\"color: #4CAF50;\">holiday music</i>. <span style=\"background-color: #C8E6C9;\">Love this tradition</span>."),
        
        Entry(bodyText: "Christmas celebration with loved ones. Gifts, laughter, and togetherness.", 
              date: dateFrom(year: 2025, month: 12, day: 25),
              bodyHTML: "<b style=\"color: #F44336; background-color: #C8E6C9;\">Christmas celebration</b> with <i>loved ones</i>. <u>Gifts</u>, <u>laughter</u>, and <span style=\"color: #E91E63;\">togetherness</span>."),
        
        Entry(bodyText: "Reflecting on 2025. What a year of growth, learning, and beautiful moments.", 
              date: dateFrom(year: 2025, month: 12, day: 29),
              bodyHTML: "<b>Reflecting on 2025</b>. What a year of <span style=\"color: #4CAF50;\">growth</span>, <span style=\"color: #2196F3;\">learning</span>, and <span style=\"background-color: #FFF9C4;\">beautiful moments</span>."),
        
        Entry(bodyText: "New Year's Eve! Ready to welcome 2026 with hope and excitement.", 
              date: dateFrom(year: 2025, month: 12, day: 31),
              bodyHTML: "<b style=\"color: #FF9800; background-color: #000000;\">New Year's Eve!</b> Ready to welcome <span style=\"color: #9C27B0;\">2026</span> with <i>hope</i> and <span style=\"background-color: #FFF9C4;\">excitement</span>."),
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
